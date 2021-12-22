let root = ref(None)
let isAsync = false

let render = (whatToRender, renderDom /* , callback */) => {
  let container = switch root.contents {
  | Some(node) => node
  | None =>
    ReGraph__DOMReconciler.reconciler.createContainer(. renderDom, isAsync, false, Js.Nullable.null)
  }

  let parentComponent = Js.Nullable.null
  ReGraph__DOMReconciler.reconciler.updateContainer(.
    whatToRender,
    container,
    parentComponent /* , callback */,
  )
}
