module DataNodeReactRoot = {
  @set external attach: (Dom.element, 'a) => unit = "_reactRootContainer"
  @get external detach: Dom.element => Js.nullable<'a> = "_reactRootContainer"
}

let render = (element, container) => {
  let root = switch container->DataNodeReactRoot.detach->Js.toOption {
  | Some(node) => node
  | None =>
    // Clear container
    container
    ->Diagram__Dom.children
    ->Belt.Array.forEach(node => container->Diagram__Dom.removeChild(node))

    let newRoot = Diagram__DOMReconciler.reconciler.createContainer(. container)

    container->DataNodeReactRoot.attach(newRoot)
    container->Diagram__Transform.attach(Diagram__Transform.t(~scale=1.))

    container->Diagram__Layout.attach(Diagram__Layout.make())

    newRoot
  }

  Diagram__DOMReconciler.reconciler.updateContainer(. element, root, Js.Nullable.null)
}
