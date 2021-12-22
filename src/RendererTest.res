module StdDom = Dom
@val external document: StdDom.document = "document"

module Performance = {
  @val @scope("performance")
  external now: unit => ReactReconciler.timestamp = "now"
}

module Document = {
  @send
  external createElement: (StdDom.document, string) => Dom.element = "createElement"
  @send
  external createTextNode: (StdDom.document, string) => Dom.element = "createTextNode"
}

module Dom = {
  @send
  external hasOwnProperty: (StdDom.element, string) => bool = "hasOwnProperty"
  @send
  external appendChild: (StdDom.element, StdDom.element) => unit = "appendChild"
  @set
  external setDocument: (StdDom.element, StdDom.element) => unit = "document"
  @send
  external setAttribute: (StdDom.element, string, string) => unit = "setAttribute"
}

let hasKey = %raw(`function hasKey(e,k) { return k in e }`)
let getValue = %raw(`function getValue(o,k) { return o[k] }`)

let createElement = (elementType, props, _internalInstanceHandle) => {
  let element = document->Document.createElement(elementType)
  props
  ->Js.Obj.keys
  ->Belt.Array.forEach(key =>
    switch (key, props->getValue(key)) {
    | ("className", Some(value)) => element->Dom.setAttribute("class", value)
    | ("children", _) => ()
    | (name, Some(value)) => element->Dom.setAttribute(name, value)
    | _ => ()
    }
  )
  Js.Nullable.return(element)
}

let reconciler = ReactReconciler.make({
  supportsMutation: true,
  supportsPersistence: true,
  // Core methods
  createInstance: (elementType, props, internalInstanceHandle) => {
    Js.log2("createInstance", elementType)
    createElement(elementType, props, internalInstanceHandle)
  },
  createTextInstance: text => document->Document.createTextNode(text),
  appendInitialChild: (parentInstance, child) => {
    Js.log2("appendInitialChild", child)
    if hasKey(parentInstance, "appendChild") {
      parentInstance->Dom.appendChild(child)
    } else {
      parentInstance->Dom.setDocument(child)
    }
  },
  finalizeInitialChildren: () => false,
  prepareUpdate: () => true,
  shouldSetTextContent: () => false,
  getRootHostContext: () => Js.Nullable.null,
  getChildHostContext: (_, fiberType) => {"type": fiberType},
  getPublicInstance: instance => instance,
  prepareForCommit: () => (),
  resetAfterCommit: () => (),
  preparePortalMount: () => (),
  now: () => Performance.now(),
  scheduleTimeout: () => (),
  cancelTimeout: () => (),
  noTimeout: -1,
  supportsMicrotask: () => (),
  isPrimaryRenderer: true,
  getCurrentEventPriority: () => (),
  // ?
  createContainerChildSet: () => (),
  appendChildToContainerChildSet: () => (),
  finalizeContainerChildren: () => (),
  replaceContainerChildren: () => (),
  // Mutation methods
  appendChild: (parentInstance, child) => {
    Js.log2("appendChild", child)
    parentInstance->Dom.appendChild(child)
  },
  appendChildToContainer: (parentInstance, child) => {
    Js.log2("appendChildToContainer", child)
    parentInstance->Dom.appendChild(child)
  },
  insertBefore: () => (),
  insertInContainerBefore: () => (),
  removeChild: () => (),
  removeChildFromContainer: () => (),
  resetTextContent: () => (),
  commitTextUpdate: () => (),
  commitMount: () => (),
  commitUpdate: () => (),
  hideInstance: () => (),
  hideTextInstance: () => (),
  unhideInstance: () => (),
  unhideTextInstance: () => (),
  clearContainer: () => (),
})

module ReactDOMDagre = {
  let render = (element, renderDom /* , callback */) => {
    let isAsync = false
    let container = reconciler.createContainer(. renderDom, isAsync)

    let parentComponent = Js.Nullable.null
    reconciler.updateContainer(. element, container, parentComponent /* , callback */)
  }
}
