module Dom = Diagram__Dom

@module("../../../src/debug.js")
external debugMethods: (
  Diagram__ReactFiberReconciler.hostConfig<'a, 'b, 'c>,
  array<string>,
) => Diagram__ReactFiberReconciler.hostConfig<'a, 'b, 'c> = "debugMethods"
@module("../../../src/debug.js")
external noDebugMethods: (
  Diagram__ReactFiberReconciler.hostConfig<'a, 'b, 'c>,
  array<string>,
) => Diagram__ReactFiberReconciler.hostConfig<'a, 'b, 'c> = "noDebugMethods"

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

let setStyles = (domElement, styles) =>
  Js.Dict.keys(styles)->Belt.Array.forEach(name => {
    let style = domElement->Dom.style
    switch styles->Js.Dict.unsafeGet(name)->Js.toOption {
    | None => style->Js.Dict.set(name, "")
    | Some(value) if value == "" => style->Js.Dict.set(name, "")
    | Some(value) if Js.typeof(value) == "boolean" => style->Js.Dict.set(name, "")
    | Some(value) => style->Js.Dict.set(name, value)
    }
  })

let shallowDiff = (oldObj, newObj) => {
  let oldKeys = Js.Dict.keys(oldObj)
  let newKeys = Js.Dict.keys(newObj)
  let uniqueKeys = oldKeys->Belt.Set.String.fromArray->Belt.Set.String.mergeMany(newKeys)

  uniqueKeys
  ->Belt.Set.String.toArray
  ->Belt.Array.keep(name => oldObj->Js.Dict.unsafeGet(name) !== newObj->Js.Dict.unsafeGet(name))
}

let reconciler = Diagram__ReactFiberReconciler.make(
  noDebugMethods(
    {
      isPrimaryRenderer: false,
      supportsMutation: true,
      useSyncScheduling: true,
      getPublicInstance: instance => instance,
      prepareForCommit: _ => Js.Nullable.null,
      resetAfterCommit: _ => (),
      //
      createInstance: (elementType, props, rootContainer, _context, _internalHandle) => {
        let element = switch elementType {
        | "Node" =>
          rootContainer->Diagram__Layout.get->Diagram__Layout.incrementCount(elementType)
          createNode(props->Js.Dict.get("nodeId")->Belt.Option.getWithDefault("nodeId"))
        | "Edge" =>
          let id =
            props->Js.Dict.get("source")->Belt.Option.getWithDefault("source") ++
            "-" ++
            props->Js.Dict.get("target")->Belt.Option.getWithDefault("target")
          rootContainer->Diagram__Layout.get->Diagram__Layout.incrementCount(elementType)
          createEdge(id, props->Js.Dict.get("label")->Belt.Option.getWithDefault(""))
        | _ => Dom.Document.createElement(elementType)
        }

        element
      },
      //
      createTextInstance: (text, _, _) => Dom.Document.createTextNode(text),
      shouldSetTextContent: (_elementType, props) => {
        let children = props->Js.Dict.unsafeGet("children")
        Js.typeof(children) == "string" || Js.typeof(children) == "number"
      },
      //
      getRootHostContext: _rootContainer => {
        Js.Obj.empty()
      },
      getChildHostContext: (parentHostContext, _elementType, _rootContainer) => parentHostContext,
      //
      appendInitialChild: (parentInstance, child) => parentInstance->Dom.appendChild(child),
      appendChild: (parentInstance, child) => parentInstance->Dom.appendChild(child),
      appendChildToContainer: (rootContainer, child) => rootContainer->Dom.appendChild(child),
      removeChild: (parentInstance, child) => parentInstance->Dom.removeChild(child),
      removeChildFromContainer: (rootContainer, child) => rootContainer->Dom.removeChild(child),
      insertBefore: (parentInstance, child, beforeChild) =>
        parentInstance->Dom.insertBefore(child, beforeChild),
      insertInContainerBefore: (container, child, beforeChild) =>
        container->Dom.insertBefore(child, beforeChild),
      //
      finalizeInitialChildren: (domElement, elementType, props, _rootContainer, _hostContext) => {
        props
        ->Js.Dict.keys
        ->Belt.Array.forEach(key => {
          switch (elementType, key) {
          | ("Node", "nodeId") => ()
          | ("Node", "style") => ()
          | ("Edge", "from") => ()
          | ("Edge", "to") => ()
          | ("Edge", "label") => ()
          | ("Edge", "style") => ()
          | (_, "children") =>
            // Set the textContent only for literal string or number children, whereas
            // nodes will be appended in `appendChild`
            let children = props->Js.Dict.unsafeGet("children")
            if Js.typeof(children) == "string" || Js.typeof(children) == "number" {
              domElement->Dom.setTextContent(children)
            }
          | (_, "className") =>
            domElement->Dom.setAttribute("class", props->Js.Dict.unsafeGet("className"))
          | (_, "style") => domElement->setStyles(Obj.magic(props->Js.Dict.unsafeGet("style")))
          | (_, name /* , value */) if isEventName(name) =>
            let eventName = name->Js.String2.toLowerCase->Js.String2.replace("on", "")
            domElement->Dom.addEventListener(eventName, props->Js.Dict.unsafeGet(name))
          | (_, name /* , value */) =>
            domElement->Dom.setAttribute(name, props->Js.Dict.unsafeGet(name))
          //          | (_, _, None) => ()
          }
        })

        elementType == "Node" || elementType == "Edge"
      },
      //
      prepareUpdate: (_domElement, _elementType, oldProps, newProps) =>
        shallowDiff(oldProps, newProps),
      //
      commitUpdate: (
        domElement,
        updatePayload,
        _elementType,
        oldProps,
        newProps,
        _internalHandle,
      ) => {
        updatePayload->Belt.Array.forEach(propName => {
          let newValue = newProps->Js.Dict.get(propName)

          if propName === "children" {
            // children changes is done by the other methods like `commitTextUpdate`
            if Js.typeof(newValue) == "string" || Js.typeof(newValue) == "number" {
              domElement->Dom.setTextContent(Obj.magic(newValue))
            }
          } else if propName === "style" {
            // Return a diff between the new and the old styles
            let oldStyle: Js.Dict.t<'a> = Obj.magic(oldProps->Js.Dict.unsafeGet("style"))
            let newStyle: Js.Dict.t<'a> = Obj.magic(newProps->Js.Dict.unsafeGet("style"))
            let styleDiffs = shallowDiff(oldStyle, newStyle)

            let finalStyles = styleDiffs->Belt.Array.reduce(Js.Dict.empty(), (acc, styleName) => {
              let newStyleValue = newStyle->Js.Dict.get(styleName)
              switch newStyleValue {
              | None => acc->Js.Dict.set(styleName, Js.Nullable.return(""))
              | Some(value) => acc->Js.Dict.set(styleName, Js.Nullable.return(value))
              }
              acc
            })

            domElement->setStyles(finalStyles)
          } else {
            switch newValue {
            | None if isEventName(propName) =>
              // event is not here anymore
              let eventName = propName->Js.String2.toLowerCase->Js.String2.replace("on", "")
              domElement->Dom.removeEventListener(eventName, oldProps->Js.Dict.unsafeGet(propName))
            | None =>
              // attribute is not here anymore
              domElement->Dom.removeAttribute(propName)
            | Some(event) if isEventName(propName) =>
              let eventName = propName->Js.String2.toLowerCase->Js.String2.replace("on", "")
              domElement->Dom.removeEventListener(eventName, oldProps->Js.Dict.unsafeGet(propName))
              domElement->Dom.addEventListener(eventName, event)
            | Some(attribute) if propName == "className" =>
              domElement->Dom.setAttribute("class", attribute)
            | Some(attribute) => domElement->Dom.setAttribute(propName, attribute)
            }
          }
        })
      },
      //
      commitTextUpdate: (domElement, _oldText, newText) => {
        domElement->Dom.setNodeValue(newText)
      },
      //
      resetTextContent: domElement => {
        domElement->Dom.setTextContent("")
      },
      //
      commitMount: (domElement, elementType, props, _internalHandle) =>
        switch getRootContainer(domElement, elementType) {
        | None => ()
        | Some(container) =>
          open Diagram__Layout
          let layout = container->get

          switch elementType {
          | "Node" =>
            switch props->Js.Dict.get("nodeId") {
            | None => ()
            | Some(id) =>
              let rect = Dom.getBoundingClientRect(domElement)
              let scale = container->Diagram__Transform.get->Diagram__Transform.scaleGet
              layout->setNode(id, rect.width /. scale, rect.height /. scale)
            }
          | "Edge" =>
            switch (props->Js.Dict.get("source"), props->Js.Dict.get("target")) {
            | (Some(source), Some(target)) => layout->setEdge(source, target)
            | _ => ()
            }
          | _ => ()
          }

          if layout->allNodesProcessed {
            // do it
            layout->run(container)
          }
        },
      //
      clearContainer: container => {
        let nodeType = container->Dom.nodeType
        if nodeType == Dom.NodeType.element {
          container->Dom.setTextContent("")
        } else if nodeType == Dom.NodeType.document {
          Dom.Document.getBody->Js.toOption->Belt.Option.forEach(doc => doc->Dom.setTextContent(""))
        }
      },
    },
    [
      /* methods to exclude from debug */
      "shouldSetTextContent",
      "getRootHostContext",
      "getChildHostContext",
    ],
  ),
)
