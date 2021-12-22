type t = {
  createContainer: (. Dom.element, bool) => Dom.element,
  updateContainer: (. Dom.element, Dom.element, Js.nullable<Dom.element>) => unit,
}

type instance
type timestamp
type elementType = string
type props<'a> = Js.t<'a>
type internalInstanceHandle

// https://github.com/facebook/react/tree/main/packages/react-reconciler
type hostConfig<'element, 'context, 'a> = {
  supportsMutation: bool,
  supportsPersistence: bool,
  // Core methods
  createInstance: (elementType, props<'a>, internalInstanceHandle) => Js.nullable<'element>,
  createTextInstance: string /* , props, internalInstanceHandle */ => Dom.element,
  /**
   This method should mutate the parentInstance and add the child to its list of children.
   For example, in the DOM this would translate to a parentInstance.appendChild(child) call.

   This method happens in the render phase.
   It can mutate parentInstance and child, but it must not modify any other nodes.
   It's called while the tree is still being built up and not connected to the actual tree on the screen.
 */
  appendInitialChild: (Dom.element, Dom.element) => unit,
  finalizeInitialChildren: unit => bool,
  prepareUpdate: unit => bool,
  shouldSetTextContent: unit => bool,
  getRootHostContext: unit => Js.nullable<'context>,
  getChildHostContext: (string, string) => Js.t<'context>,
  getPublicInstance: instance => instance,
  prepareForCommit: unit => unit,
  resetAfterCommit: unit => unit,
  preparePortalMount: unit => unit,
  now: unit => timestamp,
  scheduleTimeout: unit => unit,
  cancelTimeout: unit => unit,
  noTimeout: int,
  supportsMicrotask: unit => unit,
  isPrimaryRenderer: bool,
  getCurrentEventPriority: unit => unit,
  // ?
  createContainerChildSet: unit => unit,
  appendChildToContainerChildSet: unit => unit,
  finalizeContainerChildren: unit => unit,
  replaceContainerChildren: unit => unit,
  // Mutation methods
  appendChild: (Dom.element, Dom.element) => unit,
  appendChildToContainer: (Dom.element, Dom.element) => unit,
  insertBefore: unit => unit,
  insertInContainerBefore: unit => unit,
  removeChild: unit => unit,
  removeChildFromContainer: unit => unit,
  resetTextContent: unit => unit,
  commitTextUpdate: unit => unit,
  commitMount: unit => unit,
  commitUpdate: unit => unit,
  hideInstance: unit => unit,
  hideTextInstance: unit => unit,
  unhideInstance: unit => unit,
  unhideTextInstance: unit => unit,
  clearContainer: unit => unit,
}

@module("react-reconciler")
external make: hostConfig<'element, 'context, 'a> => t = "default"
