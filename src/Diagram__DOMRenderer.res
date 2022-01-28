module DataNodeReactRoot = {
  @set external attach: (Dom.element, 'a) => unit = "_reactRootContainer"
  @get external detach: Dom.element => Js.nullable<'a> = "_reactRootContainer"
}

module Commands = {
  type t = {reset: unit => unit}
  let make: (unit => unit) => t = reset => {reset: reset}
}

let render = (element, container, onCreation) => {
  let root = switch container->DataNodeReactRoot.detach->Js.toOption {
  | Some(node) => node
  | None =>
    // Clear container
    container
    ->Diagram__Dom.children
    ->Belt.Array.forEach(node => container->Diagram__Dom.removeChild(node))

    let newRoot = Diagram__DOMReconciler.reconciler.createContainer(. container)
    let transform = Diagram__Transform.t(~scale=1.)
    let layout = Diagram__Layout.make()

    container->DataNodeReactRoot.attach(newRoot)
    container->Diagram__Transform.attach(transform)
    container->Diagram__Layout.attach(layout)

    onCreation(transform)

    newRoot
  }

  Diagram__DOMReconciler.reconciler.updateContainer(. element, root, Js.Nullable.null, None)
}
