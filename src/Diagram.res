module Node = {
  @module("../../../src/interop/Diagram__NodeTypes") @react.component
  external make: (
    ~nodeId: string,
    ~className: string=?,
    ~children: React.element=?,
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

@get external mouseEventTarget: ReactEvent.Mouse.t => Dom.element = "target"
@get external mousePointerId: ReactEvent.Mouse.t => string = "pointerId"
@get external clientX: ReactEvent.Wheel.t => float = "clientX"
@get external clientY: ReactEvent.Wheel.t => float = "clientY"

let setTransform = (node, x, y, scale) =>
  node->Diagram__Dom.setStyleTransform(
    "translate3d(" ++
    Js.Float.toString(x) ++
    "px," ++
    Js.Float.toString(y) ++
    "px,0px) scale3d(" ++
    Js.Float.toString(scale) ++
    "," ++
    Js.Float.toString(scale) ++ ",1)",
  )

@react.component
let make = (~width, ~height, ~className, ~minScale=0.1, ~maxScale=1.5, ~children) => {
  let diagramNode = React.useRef(None)
  let canvasNode = React.useRef(None)
  let slidingEnabled = React.useRef(false)
  let origin = React.useRef((0., 0.))
  let scale = React.useRef(1.)

  let initRender = domNode => {
    canvasNode.current = domNode->Js.toOption
    switch canvasNode.current {
    | Some(container) =>
      diagramNode.current = container->Diagram__Dom.parentNode->Js.toOption
      container->Diagram__Layout.attachLayout(Diagram__Layout.make(scale.current))
      Diagram__DOMRenderer.render(children, container)
    | None => ()
    }
  }

  let beginSliding = (. e) =>
    switch diagramNode.current {
    | Some(node) if e->mouseEventTarget == node =>
      e->mouseEventTarget->Diagram__Dom.setPointerCapture(e->mousePointerId)
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

        container->setTransform(x', y', scale.current)
      }
    }

  let stopSliding = (. e) => {
    slidingEnabled.current = false
    e->mouseEventTarget->Diagram__Dom.releasePointerCapture(e->mousePointerId)
  }

  let zoom = e =>
    switch canvasNode.current {
    | None => ()
    | Some(container) =>
      let (x, y) = origin.current

      let pointerX = e->clientX
      let pointerY = e->clientY

      let x' = (pointerX -. x) /. scale.current
      let y' = (pointerY -. y) /. scale.current

      let scale' = scale.current +. e->ReactEvent.Wheel.deltaY *. -0.0005 *. scale.current
      let scale'' = Js.Math.min_float(maxScale, Js.Math.max_float(minScale, scale'))

      let x'' = pointerX -. x' *. scale''
      let y'' = pointerY -. y' *. scale''

      origin.current = (x'', y'')
      scale.current = scale''

      container->Diagram__Layout.getLayout->Diagram__Layout.updateScale(scale'')
      container->setTransform(x'', y'', scale'')
    }

  <WithPointerEvents onPointerDown=beginSliding onPointerUp=stopSliding onPointerMove=slide>
    <div
      className
      style={ReactDOM.Style.make(~width, ~height, ~position="relative", ~overflow="hidden", ())}
      onWheel={zoom}>
      <div
        ref={ReactDOM.Ref.callbackDomRef(initRender)}
        style={ReactDOM.Style.make(~position="relative", ~transformOrigin="0 0", ())}
      />
    </div>
  </WithPointerEvents>
}
