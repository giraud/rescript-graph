module Dom = ReGraph__Dom

module Graph = {
  type t = {
    engine: ReGraph__Dagre.t,
    item_count: ref<int>,
    item_processed: ref<int>,
  }

  let setNode = graph => graph.engine->ReGraph__Dagre.setNode
  let setEdge = graph => graph.engine->ReGraph__Dagre.setEdge
  let incrementCount = (graph, elementType) =>
    switch elementType {
    | "Node" => graph.item_count := graph.item_count.contents + 1
    | "Edge" => graph.item_count := graph.item_count.contents + 1
    | _ => ()
    }

  let make = () => {
    let engine = ReGraph__Dagre.make()
    engine->ReGraph__Dagre.setGraph(Js.Obj.empty())
    engine->ReGraph__Dagre.setDefaultEdgeLabel(_ => Js.Obj.empty())
    {
      engine: engine,
      item_count: ref(0),
      item_processed: ref(0),
    }
  }
}

@set external attachGraph: (Dom.element, Graph.t) => unit = "graph"
@get external getGraph: Dom.element => Graph.t = "graph"

let getRootContainer = (instance, elementType) =>
  switch elementType {
  | "Node" => instance->Dom.parentNode->Js.toOption
  | "Edge" => instance->Dom.closest("div")->Js.toOption
  | _ => None
  }

let isEventName = name => {
  name->Js.String2.startsWith("on") && Dom.Window.hasOwnProperty(name->Js.String2.toLowerCase)
}

let createNode = () => {
  let element = Dom.Document.createElement("div")
  element->Dom.setAttribute("data-node", "")
  element->Dom.setAttribute("style", "position:absolute")
  element
}

//pointer-events:none ?
let createEdgesContainer = (width, height) => {
  let element = Dom.Document.createElementNS("http://www.w3.org/2000/svg", "svg")
  element->Dom.setAttribute("viewBox", "0 0 " ++ width ++ " " ++ height)
  element->Dom.setAttribute("preserveAspectRatio", "none")
  element->Dom.setAttribute("style", "position:absolute;width:100%;height:100%")
  element
}

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

let buildPath = points =>
  points->Belt.Array.reduce("M", (acc, p: ReGraph__Dagre.point) =>
    acc ++ Js.Float.toString(p.x) ++ "," ++ Js.Float.toString(p.y) ++ " "
  )

let createEdge = (id, label) => {
  let element = Dom.Document.createElementNS("http://www.w3.org/2000/svg", "g")
  element->Dom.setAttribute("data-edge", id)

  let path = Dom.Document.createElementNS("http://www.w3.org/2000/svg", "path")
  element->Dom.setAttribute("style", "stroke:#444c56;fill:none;")

  let start = Dom.Document.createElementNS("http://www.w3.org/2000/svg", "circle")
  start->Dom.setAttribute("style", "stroke:#444c56;fill:#22272e;")
  start->Dom.setAttribute("r", "4")

  let arrow = Dom.Document.createElementNS("http://www.w3.org/2000/svg", "polygon")
  arrow->Dom.setAttribute("style", "stroke:#444c56;fill:#22272e;")
  arrow->Dom.setAttribute("points", "12,0 0,-6 0,6")

  let text = Dom.Document.createElementNS("http://www.w3.org/2000/svg", "text")
  text->Dom.setAttribute("data-edge", "label")
  text->Dom.setAttribute("style", "stroke:none;fill:#cdd9e5;")
  text->Dom.setTextContent(label)

  element->Dom.appendChild(path)
  element->Dom.appendChild(text)
  element->Dom.appendChild(start)
  element->Dom.appendChild(arrow)

  element
}

let reconciler = ReGraph__ReactFiberReconciler.make({
  isPrimaryRenderer: false,
  supportsMutation: true,
  getPublicInstance: instance => instance,
  prepareForCommit: _containerInfo => (),
  resetAfterCommit: _containerInfo => (),
  //
  createInstance: (elementType, props, rootContainer, _context, _internalHandle) => {
    rootContainer->getGraph->Graph.incrementCount(elementType)

    let element = switch elementType {
    | "Node" => createNode()
    | "Edges" =>
      // detect resize !
      let bbox = rootContainer->Dom.getBoundingClientRect
      createEdgesContainer(Js.Float.toString(bbox.width), Js.Float.toString(bbox.height))
    | "Edge" =>
      let id =
        props["from"]->Belt.Option.getWithDefault("from") ++
        "-" ++
        props["to"]->Belt.Option.getWithDefault("to")
      createEdge(id, props["label"]->Belt.Option.getWithDefault(""))
    | _ => Dom.Document.createElement(elementType)
    }

    Js.Nullable.return(element)
  },
  createTextInstance: text => Dom.Document.createTextNode(text),
  shouldSetTextContent: () => false,
  appendInitialChild: (parentInstance, child) => parentInstance->Dom.appendChild(child),
  finalizeInitialChildren: (domElement, elementType, props, _rootContainer, _hostContext) => {
    props
    ->Js.Obj.keys
    ->Belt.Array.forEach(key => {
      let value = %raw(`props[key]`)
      switch (elementType, key, value) {
      | (_, "className", Some(value)) => domElement->Dom.setAttribute("class", value)
      | (_, "children", _) => ()
      | ("Edge", "from", _) => ()
      | ("Edge", "to", _) => ()
      | ("Edge", "label", _) => ()
      | (_, name, Some(value)) if isEventName(name) =>
        let eventName = name->Js.String2.toLowerCase->Js.String2.replace("on", "")
        domElement->Dom.addEventListener(eventName, value)
      | (_, name, Some(value)) => domElement->Dom.setAttribute(name, value)
      | (_, _, None) => ()
      }
    })

    elementType == "Node" || elementType == "Edge"
  },
  getRootHostContext: rootContainer => {
    rootContainer->attachGraph(Graph.make())
    ""
  },
  getChildHostContext: (parentHostContext, _elementType, _rootContainer) => parentHostContext,
  appendChild: (parentInstance, child) => parentInstance->Dom.appendChild(child),
  appendChildToContainer: (rootContainer, child) => rootContainer->Dom.appendChild(child),
  removeChild: (parentInstance, child) => parentInstance->Dom.removeChild(child),
  removeChildFromContainer: (rootContainer, child) => rootContainer->Dom.removeChild(child),
  commitMount: (domElement, elementType, props, _internalHandle) => {
    switch getRootContainer(domElement, elementType) {
    | Some(container) =>
      let graph = container->getGraph

      switch elementType {
      | "Node" =>
        let rect = Dom.getBoundingClientRect(domElement)
        graph->Graph.setNode(
          domElement->Dom.id,
          {"label": "node_" ++ domElement->Dom.id, "width": rect.width, "height": rect.height},
        )
        graph.item_processed := graph.item_processed.contents + 1
      | "Edge" =>
        graph->Graph.setEdge({
          "v": props["from"]->Belt.Option.getWithDefault("unknown from"),
          "w": props["to"]->Belt.Option.getWithDefault("unknown to"),
        })
        graph.item_processed := graph.item_processed.contents + 1
      | _ => ()
      }

      if graph.item_processed.contents == graph.item_count.contents {
        ReGraph__Dagre.layout(graph.engine)

        graph.engine
        ->ReGraph__Dagre.nodes
        ->Belt.Array.forEach(id =>
          switch graph.engine->ReGraph__Dagre.node(id)->Js.toOption {
          | None => Js.log("Can't find node info for " ++ id)
          | Some(nodeInfo) =>
            let hw = nodeInfo.width /. 2.
            let hh = nodeInfo.height /. 2.
            Dom.Document.getElementById(id)
            ->Js.toOption
            ->Belt.Option.forEach(
              Dom.setAttribute(
                _,
                "style",
                "position:absolute;transform:translate3d(" ++
                Js.Float.toString(nodeInfo.x -. hw) ++
                "px," ++
                Js.Float.toString(nodeInfo.y -. hh) ++ "px,0px)",
              ),
            )
          }
        )

        graph.engine
        ->ReGraph__Dagre.edges
        ->Belt.Array.forEach(edge => {
          let id = edge.v ++ "-" ++ edge.w
          Dom.Document.querySelectorAll("[data-edge='" ++ id ++ "']")
          ->Belt.Array.get(0)
          ->Belt.Option.forEach(node =>
            switch node->Dom.children {
            | [path, text, start, arrow] =>
              switch graph.engine->ReGraph__Dagre.edge(edge.v, edge.w)->Js.toOption {
              | None => Js.log("Can't find edge info for " ++ edge.v ++ " " ++ edge.w)
              | Some({points}) =>
                let pointsCount = points->Belt.Array.length

                path->Dom.setAttribute("d", buildPath(points))
                switch points->Belt.Array.get(1) {
                | None => ()
                | Some({x, y}) =>
                  text->Dom.setAttribute("x", Js.Float.toString(x))
                  text->Dom.setAttribute("y", Js.Float.toString(y))
                }
                switch points->Belt.Array.get(0) {
                | None => ()
                | Some({x, y}) =>
                  start->Dom.setAttribute("cx", Js.Float.toString(x))
                  start->Dom.setAttribute("cy", Js.Float.toString(y))
                }
                // use last line segment to create arrow
                switch (
                  points->Belt.Array.get(pointsCount - 2),
                  points->Belt.Array.get(pointsCount - 1),
                ) {
                | (Some({x, y}), Some({x: x1, y: y1})) =>
                  let arrowPolygon = createArrowPoints(x, y, x1, y1)
                  arrow->Dom.setAttribute("points", arrowPolygon)
                | _ => ()
                }
              }
            | _ => ()
            }
          )
        })
      }
    | None => ()
    }
  },
  clearContainer: container => {
    let nodeType = container->Dom.nodeType
    if nodeType == Dom.NodeType.element {
      container->Dom.setTextContent("")
    } else if nodeType == Dom.NodeType.document {
      Dom.Document.getBody->Js.toOption->Belt.Option.forEach(doc => doc->Dom.setTextContent(""))
    }
  },
})
