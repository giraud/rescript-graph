type t = {
  engine: ref<Diagram__Dagre.t>,
  count: ref<int>,
  processed: ref<int>,
  scale: ref<float>,
}

let updateScale = (layout, scale) => layout.scale := scale

let setNode = (layout, id, width, height) => {
  layout.engine.contents->Diagram__Dagre.setNode(
    id,
    {
      "label": "node_" ++ id,
      "width": Js.Math.ceil_float(width /. layout.scale.contents),
      "height": Js.Math.ceil_float(height /. layout.scale.contents),
    },
  )
  layout.processed := layout.processed.contents + 1
}

let setEdge = (layout, source, target) => {
  layout.engine.contents->Diagram__Dagre.setEdge({
    "v": source,
    "w": target,
  })
  layout.processed := layout.processed.contents + 1
}

let incrementCount = (layout, elementType) =>
  switch elementType {
  | "Node" => layout.count := layout.count.contents + 1
  | "Edge" => layout.count := layout.count.contents + 1
  | _ => ()
  }

let allNodesProcessed = layout => layout.processed.contents == layout.count.contents

let processNodes = (layout, fn) =>
  layout.engine.contents
  ->Diagram__Dagre.nodes
  ->Belt.Array.forEach(id =>
    switch layout.engine.contents->Diagram__Dagre.node(id)->Js.toOption {
    | None => Js.log("Can't find node info for " ++ id)
    | Some(nodeInfo) => fn(id, nodeInfo)
    }
  )

let processEdges = (layout, fn) =>
  layout.engine.contents
  ->Diagram__Dagre.edges
  ->Belt.Array.forEach(edge => {
    let id = edge.v ++ "-" ++ edge.w
    switch layout.engine.contents->Diagram__Dagre.edge(edge.v, edge.w)->Js.toOption {
    | None => Js.log("Can't find edge info for " ++ edge.v ++ " " ++ edge.w)
    | Some(edgeInfo) => fn(id, edgeInfo)
    }
  })

let queryNode = (container, id) =>
  container->Diagram__Dom.querySelectorAll("[data-node='" ++ id ++ "']")->Belt.Array.get(0)

let queryEdge = (container, id) =>
  container->Diagram__Dom.querySelectorAll("[data-edge='" ++ id ++ "']")->Belt.Array.get(0)

let computeAngle = (x1, y1, x2, y2) => {
  // translate vector to 0
  let xt = x2 -. x1
  let yt = y2 -. y1
  // normalize vector
  let magnitude = Js.Math.sqrt(xt *. xt +. yt *. yt)
  let xn = xt /. magnitude
  let yn = 1. *. yt /. magnitude
  // compute angle
  Js.Math.atan2(~x=xn, ~y=yn, ())
}

// x2, y2 is the end path, head of arrow
let createArrowPoints = (x1, y1, x2, y2) => {
  // angle
  let radAngle = computeAngle(x1, y1, x2, y2)
  let c = Js.Math.cos(radAngle)
  let s = Js.Math.sin(radAngle)

  let ax1 = x2
  let ay1 = y2
  let ax2 = -8. *. c -. 4. *. s
  let ay2 = -8. *. s +. 4. *. c
  let ax3 = -8. *. c +. 4. *. s
  let ay3 = -8. *. s -. 4. *. c

  Js.Float.toString(ax1) ++
  "," ++
  Js.Float.toString(ay1) ++
  " " ++
  Js.Float.toString(ax2 +. x2) ++
  "," ++
  Js.Float.toString(ay2 +. y2) ++
  " " ++
  Js.Float.toString(ax3 +. x2) ++
  "," ++
  Js.Float.toString(ay3 +. y2)
}

let buildPath = (x, y, points) =>
  points->Belt.Array.reduce("M", (acc, p: Diagram__Dagre.point) =>
    acc ++ Js.Float.toString(p.x -. x) ++ "," ++ Js.Float.toString(p.y -. y) ++ " "
  )

let run = (layout, container) => {
  // Compute positions
  Diagram__Dagre.layout(layout.engine.contents)

  // Process all nodes in Dom and adapt styles
  layout->processNodes((id, node) =>
    switch container->queryNode(id) {
    | None => ()
    | Some(domNode) =>
      let hw = node.width /. 2.
      let hh = node.height /. 2.
      domNode->Diagram__Dom.setTranslate3d(node.x -. hw, node.y -. hh)
    }
  )

  // Process all edges and adapt styles and co
  layout->processEdges((id, {points}) =>
    switch container->queryEdge(id) {
    | None => ()
    | Some(domEdge) =>
      module Dom = Diagram__Dom

      switch domEdge->Dom.children {
      | [path, start, arrow] =>
        // adjust and move svg viewBox
        let (minX, maxX, minY, maxY) = points->Belt.Array.reduce((9999., 0., 9999., 0.), (
          (minX, maxX, minY, maxY),
          {x, y},
        ) => {
          (minX < x ? minX : x, maxX > x ? maxX : x, minY < y ? minY : y, maxY > y ? maxY : y)
        })
        let width = Js.Math.ceil_float(maxX -. minX +. 10.)
        let height = Js.Math.ceil_float(maxY -. minY +. 10.)

        domEdge->Dom.setAttribute(
          "viewBox",
          "0 0 " ++ Js.Float.toString(width) ++ " " ++ Js.Float.toString(height),
        )
        domEdge->Dom.setAttribute("width", Js.Float.toString(width) ++ "px")
        domEdge->Dom.setAttribute("height", Js.Float.toString(height) ++ "px")
        domEdge->Dom.setTranslate3d(minX -. 5., minY -. 5.)
        let minX' = minX -. 5.
        let minY' = minY -. 5.

        // update connector
        path->Dom.setAttribute("d", buildPath(minX', minY', points))
        // update start circle
        switch points->Belt.Array.get(0) {
        | None => ()
        | Some({x, y}) =>
          start->Dom.setAttribute("cx", Js.Float.toString(x -. minX'))
          start->Dom.setAttribute("cy", Js.Float.toString(y -. minY'))
        }
        // use last line segment to create arrow
        let pointsCount = points->Belt.Array.length
        switch (points->Belt.Array.get(pointsCount - 2), points->Belt.Array.get(pointsCount - 1)) {
        | (Some({x, y}), Some({x: x1, y: y1})) =>
          let arrowPolygon = createArrowPoints(x -. minX', y -. minY', x1 -. minX', y1 -. minY')
          arrow->Dom.setAttribute("points", arrowPolygon)

          // update text label
          switch (domEdge->Dom.nextSibling->Js.toOption, points->Belt.Array.get(1)) {
          | (Some(textNode), Some({x, y})) =>
            textNode->Dom.setTranslate3d(x +. 3., y -. 14. /* font-size?? */)
          | _ => ()
          }
        | _ => ()
        }
      | _ => ()
      }
    }
  )
}

let reset = layout => {
  let engine = Diagram__Dagre.make()

  engine->Diagram__Dagre.setGraph(Js.Obj.empty())
  engine->Diagram__Dagre.setDefaultEdgeLabel(_ => Js.Obj.empty())

  layout.engine := engine
}

let make = scale => {
  let engine = Diagram__Dagre.make()
  engine->Diagram__Dagre.setGraph(Js.Obj.empty())
  engine->Diagram__Dagre.setDefaultEdgeLabel(_ => Js.Obj.empty())

  {
    engine: ref(engine),
    count: ref(0),
    processed: ref(0),
    scale: ref(scale),
  }
}

@set external attachLayout: (Dom.element, t) => unit = "layout"
@get external getLayout: Dom.element => t = "layout"
