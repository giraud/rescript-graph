type orientation = [#vertical | #horizontal]

type t = {
  engine: ref<Diagram__Dagre.t>,
  mutable listener: unit => unit,
  displayBBox: ref<bool>,
  orientation: ref<orientation>,
}

let displayBBox = layout => layout.displayBBox.contents
let setDisplayBBox = (layout, value) => layout.displayBBox.contents = value

let setOrientation = (layout, value) => layout.orientation.contents = value
let orientationToString = orientation =>
  switch orientation {
  | #horizontal => "LR"
  | _ => "TB"
  }

let setNode = (layout, id, width, height) =>
  layout.engine.contents->Diagram__Dagre.setNode(
    id,
    {
      "label": "node_" ++ id,
      "width": width,
      "height": height,
    },
  )

let setEdge = (layout, source, target, width, height) =>
  layout.engine.contents->Diagram__Dagre.setEdge(
    source,
    target,
    {
      "width": width,
      "height": height,
    },
    "name-" ++ source ++ "-" ++ target,
  )

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
    switch layout.engine.contents
    ->Diagram__Dagre.namedEdge(edge.v, edge.w, edge.name)
    ->Js.toOption {
    | None => Js.log("Can't find edge info for " ++ edge.v ++ " " ++ edge.w)
    | Some(edgeInfo) =>
      // fix pb in dagre where number can be NaN
      fn(
        id,
        {
          ...edgeInfo,
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
      | [path, start, arrow /* , holder */] =>
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

          let midPoint = pointsCount / 2
          switch (
            points->Belt.Array.get(midPoint - 1),
            points->Belt.Array.get(midPoint),
            points->Belt.Array.get(midPoint + 1),
          ) {
          | (Some({x, y}), Some({x: x1, y: y1}), Some({x: x2, y: y2})) =>
            // normalize vectors
            let (norm1x, norm1y) = Diagram__Graphics.normalizePoints(x1, y1, x, y)
            let (norm2x, norm2y) = Diagram__Graphics.normalizePoints(x1, y1, x2, y2)
            // adding two unit vectors, gives a vector that divides the angle between them
            let bx = norm1x +. norm2x
            let by = norm1y +. norm2y
            let (nx, ny) = Diagram__Graphics.normalizeVector(bx, by)

            // invert angle
            let nx' = -.nx
            let ny' = -.ny
            // 0 0 no angle

            // move to
            let mx = x1 -. minX'
            let my = y1 -. minY'
            let mx1 = mx +. nx' *. 10.
            let my1 = my +. ny' *. 10.
            //holder->Dom.setAttribute( "d", "M" ++ Js.Float.toString(mx) ++ " " ++ Js.Float.toString(my) ++ " " ++ Js.Float.toString(mx1) ++ " " ++ Js.Float.toString(my1), )

            // update text label
            switch domEdge->Dom.nextSibling->Js.toOption {
            | Some(textNode) =>
              let textRect = textNode->Dom.getBoundingClientRect
              textNode->Dom.setTranslate3d(
                minX' +. mx1 -. textRect.width /. 2.,
                minY' +. my1 -. textRect.height /. 2.,
              )
            | _ => ()
            }
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
  let engine = Diagram__Dagre.make({"multigraph": true})
  engine->Diagram__Dagre.setGraph(
    Js.Dict.fromArray([("rankdir", layout.orientation.contents->orientationToString)]),
  )
  engine->Diagram__Dagre.setDefaultEdgeLabel(_ => Js.Obj.empty())

  layout.engine := engine
}

let registerListener = (layout, listener) => layout.listener = listener
let onUpdate = layout => layout.listener()

let make = () => {
  let engine = Diagram__Dagre.make({"multigraph": true})
  engine->Diagram__Dagre.setGraph(Js.Dict.fromArray([("rankdir", "TB")]))
  engine->Diagram__Dagre.setDefaultEdgeLabel(_ => Js.Obj.empty())

  {
    engine: ref(engine),
    listener: () => (),
    displayBBox: ref(false),
    orientation: ref(#vertical),
  }
}

@set external attach: (Dom.element, t) => unit = "layout"
@get external get: Dom.element => t = "layout"
