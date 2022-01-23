module Node = {
  @module("../../../src/interop/Diagram__NodeTypes") @react.component
  external make: (
    ~nodeId: string,
    ~className: string=?,
    ~children: React.element,
    ~onClick: ReactEvent.Mouse.t => unit=?,
  ) => React.element = "Node"
}

module Edge = {
  @module("../../../src/interop/Diagram__NodeTypes") @react.component
  external make: (
    ~source: string,
    ~target: string,
    ~label: string=?,
    ~onClick: ReactEvent.Mouse.t => unit=?,
  ) => React.element = "Edge"
}

// pointer events are not declared in React bindings, need a workaround until ReactScript is updated...
module WithPointerEvents = {
  type mouseEvent = (. ReactEvent.Mouse.t) => unit

  @react.component
  let make = (
    ~onPointerDown: option<mouseEvent>=?,
    ~onPointerMove: option<mouseEvent>=?,
    ~onPointerUp: option<mouseEvent>=?,
    ~children,
  ) => {
    React.cloneElement(
      children,
      {"onPointerDown": onPointerDown, "onPointerMove": onPointerMove, "onPointerUp": onPointerUp},
    )
  }
}

@react.component
let make = (~width, ~height, ~className=?, ~minScale=0.1, ~maxScale=1.5, ~children) => {
  let diagramNode = React.useRef(None)
  let canvasNode = React.useRef(None)
  let slidingEnabled = React.useRef(false)
  let origin = React.useRef((0., 0.))

  let initRender = domNode => {
    canvasNode.current = domNode->Js.toOption
    switch canvasNode.current {
    | Some(container) =>
      diagramNode.current = container->Diagram__Dom.parentNode->Js.toOption
      Diagram__DOMRenderer.render(children, container)
    | None => ()
    }
  }

  let beginSliding = (. e) =>
    switch diagramNode.current {
    | Some(node) if e->Diagram__Dom.mouseEventTarget == node =>
      e
      ->Diagram__Dom.mouseEventTarget
      ->Diagram__Dom.setPointerCapture(e->Diagram__Dom.mousePointerId)
      slidingEnabled.current = true
    | _ => ()
    }

  let slide = (. e) =>
    if slidingEnabled.current {
      switch canvasNode.current {
      | None => ()
      | Some(container) =>
        let (x, y) = origin.current
        let x' = x +. Js.Int.toFloat(e->ReactEvent.Mouse.movementX)
        let y' = y +. Js.Int.toFloat(e->ReactEvent.Mouse.movementY)
        origin.current = (x', y')

        let scale = container->Diagram__Transform.get->Diagram__Transform.scaleGet
        container->Diagram__Dom.setTransform(x', y', scale)
      }
    }

  let stopSliding = (. e) => {
    slidingEnabled.current = false
    e
    ->Diagram__Dom.mouseEventTarget
    ->Diagram__Dom.releasePointerCapture(e->Diagram__Dom.mousePointerId)
  }

  let zoom = e =>
    switch canvasNode.current {
    | None => ()
    | Some(container) =>
      let (x, y) = origin.current
      let pointerX = e->Diagram__Dom.clientX
      let pointerY = e->Diagram__Dom.clientY
      let scale = container->Diagram__Transform.get->Diagram__Transform.scaleGet

      let x' = (pointerX -. x) /. scale
      let y' = (pointerY -. y) /. scale

      let scale' = scale +. e->ReactEvent.Wheel.deltaY *. -0.0005 *. scale
      let scale'' = Js.Math.min_float(maxScale, Js.Math.max_float(minScale, scale'))

      let x'' = pointerX -. x' *. scale''
      let y'' = pointerY -. y' *. scale''

      origin.current = (x'', y'')
      container->Diagram__Transform.get->Diagram__Transform.scaleSet(scale'')

      container->Diagram__Dom.setTransform(x'', y'', scale'')
    }

  <WithPointerEvents onPointerDown=beginSliding onPointerUp=stopSliding onPointerMove=slide>
    <div
      ?className
      style={ReactDOM.Style.make(~width, ~height, ~position="relative", ~overflow="hidden", ())}
      onWheel={zoom}>
      <div
        ref={ReactDOM.Ref.callbackDomRef(initRender)}
        style={ReactDOM.Style.make(~position="relative", ~transformOrigin="0 0", ())}
      />
    </div>
  </WithPointerEvents>
}
