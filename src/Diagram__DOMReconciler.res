module Dom = Diagram__Dom

@module("../../../src/debug.js")
external debugMethods: (
  Diagram__ReactFiberReconciler.hostConfig<'a, 'c, 'commit>,
  array<string>,
) => Diagram__ReactFiberReconciler.hostConfig<'a, 'c, 'commit> = "debugMethods"
@module("../../../src/debug.js")
external noDebugMethods: (
  Diagram__ReactFiberReconciler.hostConfig<'a, 'c, 'commit>,
  array<string>,
) => Diagram__ReactFiberReconciler.hostConfig<'a, 'c, 'commit> = "noDebugMethods"

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

let shallowDiff = (oldObj, newObj) => {
  let oldKeys = Belt.Set.String.fromArray(Js.Obj.keys(oldObj))
  let newKeys = Js.Obj.keys(newObj)

  let uniqueKeys = oldKeys->Belt.Set.String.mergeMany(newKeys)->Belt.Set.String.toArray
  uniqueKeys->Belt.Array.keep(%raw(`name => oldObj[name] !== newObj[name]`))
}

let reconciler = Diagram__ReactFiberReconciler.make(
  debugMethods(
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
          createNode(props["nodeId"]->Belt.Option.getWithDefault("nodeId"))
        | "Edge" =>
          let id =
            props["source"]->Belt.Option.getWithDefault("source") ++
            "-" ++
            props["target"]->Belt.Option.getWithDefault("target")
          rootContainer->Diagram__Layout.get->Diagram__Layout.incrementCount(elementType)
          createEdge(id, props["label"]->Belt.Option.getWithDefault(""))
        | _ => Dom.Document.createElement(elementType)
        }

        element
      },
      createTextInstance: (text, _, _) => Dom.Document.createTextNode(text),
      shouldSetTextContent: (_elementType, props) => {
        let children = props["children"]
        Js.typeof(children) == "string" || Js.typeof(children) == "number"
      },
      getRootHostContext: rootContainer => {
        Js.log(rootContainer->Diagram__Layout.get) //->Diagram__Layout.reset
        Js.Obj.empty()
      },
      getChildHostContext: (parentHostContext, _elementType, _rootContainer) => parentHostContext,
      appendChild: (parentInstance, child) => parentInstance->Dom.appendChild(child),
      appendChildToContainer: (rootContainer, child) => rootContainer->Dom.appendChild(child),
      removeChild: (parentInstance, child) => parentInstance->Dom.removeChild(child),
      removeChildFromContainer: (rootContainer, child) => rootContainer->Dom.removeChild(child),
      insertBefore: (parentInstance, child, beforeChild) =>
        parentInstance->Dom.insertBefore(child, beforeChild),
      insertInContainerBefore: (container, child, beforeChild) =>
        container->Dom.insertBefore(child, beforeChild),
      appendInitialChild: (parentInstance, child) => parentInstance->Dom.appendChild(child),
      finalizeInitialChildren: (domElement, elementType, props, _rootContainer, _hostContext) => {
        props
        ->Js.Obj.keys
        ->Belt.Array.forEach(key => {
          let value = %raw(`props[key]`)
          switch (elementType, key, value) {
          | (_, "children", children) =>
            // Set the textContent only for literal string or number children, whereas
            // nodes will be appended in `appendChild`
            if Js.typeof(children) == "string" || Js.typeof(children) == "number" {
              domElement->Dom.setTextContent(value)
            }
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
      prepareUpdate: (_domElement, _elementType, oldProps, newProps) =>
        shallowDiff(oldProps, newProps),
      commitUpdate: (
        domElement,
        updatePayload,
        _elementType,
        _oldProps,
        _newProps,
        _internalHandle,
      ) => {
        updatePayload->Belt.Array.forEach(propName => {
          let newValue = %raw(`_newProps[propName]`)

          if propName === "children" {
            // children changes is done by the other methods like `commitTextUpdate`
            if Js.typeof(newValue) == "string" || Js.typeof(newValue) == "number" {
              domElement->Dom.setTextContent(newValue)
            }
          } else if propName === "style" {
            // Return a diff between the new and the old styles
            /* const styleDiffs = shallowDiff(oldProps.style, newProps.style);
                          const finalStyles = styleDiffs.reduce((acc, styleName) => {
                            // Style marked to be unset
                            if (!newProps.style[styleName]) acc[styleName] = "";
                            else acc[styleName] = newProps.style[styleName];

                            return acc;
                          }, {});

                          setStyles(domElement, finalStyles); */
            ()
          } else {
            switch newValue {
            | None if isEventName(propName) =>
              // event is not here anymore
              Js.log2("no event", propName)

              let eventName = propName->Js.String2.toLowerCase->Js.String2.replace("on", "")
              domElement->Dom.removeEventListener(eventName, %raw(`_oldProps[propName]`))
            | None =>
              // attribute is not here anymore
              Js.log2("no attr", propName)
              domElement->Dom.removeAttribute(propName)
            | Some(event) if isEventName(propName) =>
              Js.log2("change event", propName)
              let eventName = propName->Js.String2.toLowerCase->Js.String2.replace("on", "")
              domElement->Dom.removeEventListener(eventName, %raw(`_oldProps[propName]`))
              domElement->Dom.addEventListener(eventName, event)
            | Some(attribute) if propName == "className" =>
              Js.log3("update attribute", propName, attribute)
              domElement->Dom.setAttribute("class", attribute)
            | Some(attribute) =>
              Js.log3("update attribute", propName, attribute)
              domElement->Dom.setAttribute(propName, attribute)
            }
          }
        })
      },
      commitTextUpdate: (domElement, _oldText, newText) => {
        domElement->Dom.setNodeValue(newText)
      },
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
            switch props["nodeId"] {
            | None => ()
            | Some(id) =>
              let rect = Dom.getBoundingClientRect(domElement)
              let scale = container->Diagram__Transform.get->Diagram__Transform.scaleGet
              layout->setNode(id, rect.width /. scale, rect.height /. scale)
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
            Js.log("do layout")
            layout->run(container)
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
    [
      /* methods to exclude from debug */
      "shouldSetTextContent",
      "getRootHostContext",
      "getChildHostContext",
    ],
  ),
)
