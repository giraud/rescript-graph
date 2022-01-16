module Node = {
  @module("../../../src/interop/Diagram_NodeTypes") @react.component
  external make: (
    ~id: string,
    ~className: string=?,
    ~children: React.element=?,
    ~onClick: ReactEvent.Mouse.t => unit=?,
  ) => React.element = "Node"
}

module Edges = {
  @module("../../../src/interop/Diagram_NodeTypes") @react.component
  external make: (~children: React.element) => React.element = "Edges"
}

module Edge = {
  @module("../../../src/interop/Diagram_NodeTypes") @react.component
  external make: (
    ~source: string,
    ~target: string,
    ~label: string=?,
    ~onClick: ReactEvent.Mouse.t => unit=?,
  ) => React.element = "Edge"
}

@react.component
let make = (~width, ~height, ~className, ~children) => {
  let initRender = domNode => {
    switch domNode->Js.toOption {
    | Some(node) => Diagram__DOMRenderer.render(children, node)
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
