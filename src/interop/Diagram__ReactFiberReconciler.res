type t = {
  createContainer: (. Dom.element, bool, bool, Js.nullable<Dom.element>) => Dom.element,
  updateContainer: (. React.element, Dom.element, Js.nullable<Dom.element>) => unit,
  getPublicRootInstance: (. Dom.element) => Dom.element,
}

type rootContainer = Dom.element
type instance = Dom.element
type timestamp
type elementType = string
type props<'a> = Js.t<'a>
type internalHandle
type containerInfo = Dom.element

// https://github.com/facebook/react/tree/main/packages/react-reconciler
type hostConfig<'context, 'a> = {
  isPrimaryRenderer: bool,
  supportsMutation: bool,
  createInstance: (
    elementType,
    props<'a>,
    rootContainer,
    'context,
    internalHandle,
  ) => Js.nullable<Dom.element>,
  createTextInstance: string /* , props, internalInstanceHandle */ => Dom.element,
  /**
   This method should mutate the parentInstance and add the child to its list of children.
   For example, in the DOM this would translate to a parentInstance.appendChild(child) call.

   This method happens in the render phase.
   It can mutate parentInstance and child, but it must not modify any other nodes.
   It's called while the tree is still being built up and not connected to the actual tree on the screen.
 */
  appendInitialChild: (Dom.element, Dom.element) => unit,
  /**
   In this method, you can perform some final mutations on the instance.
   Unlike with createInstance, by the time finalizeInitialChildren is called, all the initial children have already been added to the instance,
   but the instance itself has not yet been connected to the tree on the screen.

   This method happens in the render phase.
   It can mutate instance, but it must not modify any other nodes.
   It's called while the tree is still being built up and not connected to the actual tree on the screen.

   There is a second purpose to this method.
   It lets you specify whether there is some work that needs to happen when the node is connected to the tree on the screen.
   If you return true, the instance will receive a commitMount call later. See its documentation below.

   If you don't want to do anything here, you should return false.
 */
  finalizeInitialChildren: (instance, elementType, props<'a>, rootContainer, 'context) => bool,
  shouldSetTextContent: unit => bool,
  getRootHostContext: rootContainer => 'context,
  getChildHostContext: ('context, elementType, rootContainer) => 'context,
  getPublicInstance: instance => instance,
  //  prepareUpdate: (Dom.element, elementType, props<'a>, props<'a>, rootContainer, 'context) => unit,
  prepareForCommit: containerInfo => unit,
  resetAfterCommit: containerInfo => unit,
  //  preparePortalMount: unit => unit,
  //  now: unit => timestamp,
  //  scheduleTimeout: unit => unit,
  //  cancelTimeout: unit => unit,
  //  noTimeout: int,
  //  supportsMicrotask: unit => unit,
  //  getCurrentEventPriority: unit => unit,
  //  createContainerChildSet: unit => unit,
  //  appendChildToContainerChildSet: unit => unit,
  //  finalizeContainerChildren: unit => unit,
  //  replaceContainerChildren: unit => unit,
  //   Mutation methods

  /**
   This method should mutate the parentInstance and add the child to its list of children.
   For example, in the DOM this would translate to a parentInstance.appendChild(child) call.

   Although this method currently runs in the commit phase, you still should not mutate any other nodes in it.
   If you need to do some additional work when a node is definitely connected to the visible tree, look at commitMount.
 */
  appendChild: (Dom.element, Dom.element) => unit,
  /**
   Same as appendChild, but for when a node is attached to the root container.
   This is useful if attaching to the root has a slightly different implementation,
   or if the root container nodes are of a different type than the rest of the tree.
 */
  appendChildToContainer: (Dom.element, Dom.element) => unit,
  //  insertBefore: unit => unit,
  //  insertInContainerBefore: unit => unit,

  /**
   This method should mutate the parentInstance to remove the child from the list of its children.

   React will only call it for the top-level node that is being removed.
   It is expected that garbage collection would take care of the whole subtree.
   You are not expected to traverse the child tree in it.
 */
  removeChild: (Dom.element, Dom.element) => unit,
  /**
   Same as removeChild, but for when a node is detached from the root container.
   This is useful if attaching to the root has a slightly different implementation, or if the root container nodes are of a different type
   than the rest of the tree.
 */
  removeChildFromContainer: (Dom.element, Dom.element) => unit,
  //  resetTextContent: unit => unit,
  //  commitTextUpdate: unit => unit,
  /**
   This method is only called if you returned true from finalizeInitialChildren for this instance.

   It lets you do some additional work after the node is actually attached to the tree on the screen for the first time.
   For example, the DOM renderer uses it to trigger focus on nodes with the autoFocus attribute.

   Note that commitMount does not mirror removeChild one to one because removeChild is only called for the top-level removed node.
   This is why ideally commitMount should not mutate any nodes other than the instance itself.
   For example, if it registers some events on some node above, it will be your responsibility to traverse the tree in removeChild and clean them up,
   which is not ideal.

   The internalHandle data structure is meant to be opaque.
   If you bend the rules and rely on its internal fields, be aware that it may change significantly between versions.
   You're taking on additional maintenance risk by reading from it, and giving up all guarantees if you write something to it.

   If you never return true from finalizeInitialChildren, you can leave it empty.
 */
  commitMount: (instance, elementType, props<'a>, internalHandle) => unit,
  //  commitUpdate: unit => unit,
  //  hideInstance: unit => unit,
  //  hideTextInstance: unit => unit,
  //  unhideInstance: unit => unit,
  //  unhideTextInstance: unit => unit,
  /**
  This method should mutate the container root node and remove all children from it.
 */
  clearContainer: Dom.element /* container */ => unit,
}

@module("react-reconciler")
external make: hostConfig<'context, 'a> => t = "default"
