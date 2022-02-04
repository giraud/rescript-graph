type t = {
  engine: ref<Diagram__Dagre.t>,
  mutable listener: unit => unit,
  displayBBox: ref<bool>,
}

let displayBBox = layout => layout.displayBBox.contents
let setDisplayBBox = (layout, value) => layout.displayBBox.contents = value

let setNode = (layout, id, width, height) =>
  layout.engine.contents->Diagram__Dagre.setNode(
    id,
    {
      "label": "node_" ++ id,
      "width": width,
      "height": height,
    },
  )

let setEdge = (layout, source, target) =>
  layout.engine.contents->Diagram__Dagre.setEdge({
    "v": source,
    "w": target,
  })

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
    | Some(edgeInfo) =>
      // fix pb in dagre where number can be NaN
      fn(
        id,
        {
          Diagram__Dagre.points: edgeInfo.points->Belt.Array.map(_p => {
            Diagram__Dagre.x: %raw(`_p.x || 0`),
            y: %raw(`_p.y || 0`),
          }),
        },
      )
    }
  })

let queryNode = (container, id) =>
  container->Diagram__Dom.querySelectorAll("[data-node='" ++ id ++ "']")->Belt.Array.get(0)

let queryEdge = (container, id) =>
  container->Diagram__Dom.querySelectorAll("[data-edge='" ++ id ++ "']")->Belt.Array.get(0)

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
        path->Dom.setAttribute("d", Diagram__Graphics.buildPath(minX', minY', points))
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
          let arrowPolygon = Diagram__Graphics.createArrowPoints(
            x -. minX',
            y -. minY',
            x1 -. minX',
            y1 -. minY',
            true,
          )
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

let registerListener = (layout, listener) => layout.listener = listener
let onUpdate = layout => layout.listener()

let make = () => {
  let engine = Diagram__Dagre.make()
  engine->Diagram__Dagre.setGraph(Js.Obj.empty())
  engine->Diagram__Dagre.setDefaultEdgeLabel(_ => Js.Obj.empty())

  {
    engine: ref(engine),
    listener: () => (),
    displayBBox: ref(false),
  }
}

@set external attach: (Dom.element, t) => unit = "layout"
@get external get: Dom.element => t = "layout"
