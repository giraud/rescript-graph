let nodeType = "Node"
let edgeType = "Edge"
let edgesType = "Edges"

@react.component
let make = (~width, ~height, ~className, ~children) => {
  let initRender = domNode => {
    switch domNode->Js.toOption {
    | Some(node) => ReGraph__DOMRenderer.render(children, node)
    | None => ()
    }
  }

  <div
    className
    style={ReactDOM.Style.make(~width, ~height, ~position="relative", ~overflow="hidden", ())}>
    <div
      ref={ReactDOM.Ref.callbackDomRef(initRender)}
      style={ReactDOM.Style.make(~height="100%", ~position="relative", ())}
    />
  </div>
}
