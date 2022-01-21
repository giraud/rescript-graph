module Dom = Diagram__Dom

@module("../../../src/debug.js")
external debugMethods: (
  Diagram__ReactFiberReconciler.hostConfig<'context, 'a>,
  array<string>,
) => Diagram__ReactFiberReconciler.hostConfig<'context, 'a> = "debugMethods"
@module("../../../src/debug.js")
external noDebugMethods: (
  Diagram__ReactFiberReconciler.hostConfig<'context, 'a>,
  array<string>,
) => Diagram__ReactFiberReconciler.hostConfig<'context, 'a> = "noDebugMethods"

let getRootContainer = (instance, elementType) =>
  switch (elementType, instance->Dom.parentNode->Js.toOption) {
  | ("Node", parent) => parent
  | ("Edge", Some(parentNode)) => parentNode->Dom.closest("div")->Js.toOption
  | _ => None
  }

let isEventName = name =>
  name->Js.String2.startsWith("on") && Dom.Window.hasOwnProperty(name->Js.String2.toLowerCase)

let createNode = id => {
  let element = Dom.Document.createElement("div")
  element->Dom.setAttribute("data-node", id)
  element->Dom.setAttribute("style", "position:absolute;")
  element
}

let createEdge = (id, label) => {
  let g = Dom.Document.createElement("div")
  g->Dom.setAttribute("style", "display:contents")

  let element = Dom.Document.createElementNS("http://www.w3.org/2000/svg", "svg")
  element->Dom.setAttribute("data-edge", id)
  element->Dom.setAttribute("style", "position:absolute;pointer-events:none;")

  let path = Dom.Document.createElementNS("http://www.w3.org/2000/svg", "path")
  path->Dom.setAttribute("fill", "none")

  let start = Dom.Document.createElementNS("http://www.w3.org/2000/svg", "circle")
  start->Dom.setAttribute("r", "4")

  let arrow = Dom.Document.createElementNS("http://www.w3.org/2000/svg", "polygon")

  let text = Dom.Document.createElement("div")
  text->Dom.setAttribute("data-edge-label", id)
  text->Dom.setAttribute("style", "position:absolute;display:inline-block")
  text->Dom.setTextContent(label)

  element->Dom.appendChild(path)
  element->Dom.appendChild(start)
  element->Dom.appendChild(arrow)

  g->Dom.appendChild(element)
  g->Dom.appendChild(text)

  g
}

let reconciler = Diagram__ReactFiberReconciler.make(
  noDebugMethods(
    {
      isPrimaryRenderer: false,
      supportsMutation: true,
      getPublicInstance: instance => instance,
      prepareForCommit: _containerInfo => (),
      resetAfterCommit: _containerInfo => (),
      //
      createInstance: (elementType, props, rootContainer, _context, _internalHandle) => {
        rootContainer->Diagram__Layout.getLayout->Diagram__Layout.incrementCount(elementType)

        let element = switch elementType {
        | "Node" => createNode(props["nodeId"]->Belt.Option.getWithDefault("nodeId"))
        | "Edge" =>
          let id =
            props["source"]->Belt.Option.getWithDefault("source") ++
            "-" ++
            props["target"]->Belt.Option.getWithDefault("target")
          createEdge(id, props["label"]->Belt.Option.getWithDefault(""))
        | _ => Dom.Document.createElement(elementType)
        }

        Js.Nullable.return(element)
      },
      createTextInstance: text => Dom.Document.createTextNode(text),
      shouldSetTextContent: () => false,
      getRootHostContext: rootContainer => {
        rootContainer->Diagram__Layout.getLayout->Diagram__Layout.reset
        ""
      },
      getChildHostContext: (parentHostContext, _elementType, _rootContainer) => parentHostContext,
      appendChild: (parentInstance, child) => parentInstance->Dom.appendChild(child),
      appendChildToContainer: (rootContainer, child) => rootContainer->Dom.appendChild(child),
      removeChild: (parentInstance, child) => parentInstance->Dom.removeChild(child),
      removeChildFromContainer: (rootContainer, child) => rootContainer->Dom.removeChild(child),
      appendInitialChild: (parentInstance, child) => parentInstance->Dom.appendChild(child),
      finalizeInitialChildren: (domElement, elementType, props, _rootContainer, _hostContext) => {
        props
        ->Js.Obj.keys
        ->Belt.Array.forEach(key => {
          let value = %raw(`props[key]`)
          switch (elementType, key, value) {
          | (_, "children", _) => ()
          | ("Node", "nodeId", _) => ()
          | ("Edge", "from", _) => ()
          | ("Edge", "to", _) => ()
          | ("Edge", "label", _) => ()
          | (_, "className", Some(value)) => domElement->Dom.setAttribute("class", value)
          | (_, name, Some(value)) if isEventName(name) =>
            let eventName = name->Js.String2.toLowerCase->Js.String2.replace("on", "")
            domElement->Dom.addEventListener(eventName, value)
          | (_, name, Some(value)) => domElement->Dom.setAttribute(name, value)
          | (_, _, None) => ()
          }
        })

        elementType == "Node" || elementType == "Edge"
      },
      //
      commitMount: (domElement, elementType, props, _internalHandle) => {
        switch getRootContainer(domElement, elementType) {
        | None => ()
        | Some(container) =>
          open Diagram__Layout
          let layout = container->getLayout

          switch elementType {
          | "Node" =>
            switch props["nodeId"] {
            | None => ()
            | Some(id) =>
              let rect = Dom.getBoundingClientRect(domElement)
              layout->setNode(id, rect.width, rect.height)
            }
          | "Edge" =>
            switch (props["source"], props["target"]) {
            | (Some(source), Some(target)) => layout->setEdge(source, target)
            | _ => ()
            }
          | _ => ()
          }

          if layout->allNodesProcessed {
            // do it
            layout->run(container)
          }
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
    },
    [],
  ),
)
