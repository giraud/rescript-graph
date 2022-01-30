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

module Map = {
  @module("../../../src/interop/Diagram__NodeTypes") @react.component
  external make: (~className: string=?) => React.element = "Map"
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

module Commands = Diagram__DOMRenderer.Commands

@react.component
let make = (
  ~width,
  ~height,
  ~className=?,
  ~minScale=0.1,
  ~maxScale=1.5,
  ~boundingBox=false,
  ~onCreation=?,
  ~children,
) => {
  let diagramNode = React.useRef(None)
  let canvasNode = React.useRef(None)
  let slidingEnabled = React.useRef(false)
  Js.log(boundingBox)

  let initRender = domNode => {
    diagramNode.current = domNode->Js.toOption
    switch diagramNode.current {
    | Some(container) =>
      open Belt.Option
      canvasNode.current = container->Diagram__Dom.firstChild->Js.toOption
      Diagram__DOMRenderer.render(children, container, (t, l) => {
        let reset = () => {
          t->Diagram__Transform.originSet((0., 0.))
          t->Diagram__Transform.scaleSet(1.)
          canvasNode.current->forEach(canvas => canvas->Diagram__Dom.setTransform(0., 0., 1.))
        }
        l->Diagram__Layout.setDisplayBBox(boundingBox)
        onCreation->forEach(fn => fn(Diagram__DOMRenderer.Commands.make(reset)))
      })
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
      switch (diagramNode.current, canvasNode.current) {
      | (Some(container), Some(canvas)) =>
        let transform = container->Diagram__Transform.get

        let (x, y) = transform->Diagram__Transform.originGet
        let scale = transform->Diagram__Transform.scaleGet

        let x' = x +. Js.Int.toFloat(e->ReactEvent.Mouse.movementX)
        let y' = y +. Js.Int.toFloat(e->ReactEvent.Mouse.movementY)
        transform->Diagram__Transform.originSet((x', y'))

        canvas->Diagram__Dom.setTransform(x', y', scale)
      | _ => ()
      }
    }

  let stopSliding = (. e) => {
    slidingEnabled.current = false
    e
    ->Diagram__Dom.mouseEventTarget
    ->Diagram__Dom.releasePointerCapture(e->Diagram__Dom.mousePointerId)
  }

  let zoom = e =>
    switch (diagramNode.current, canvasNode.current) {
    | (Some(container), Some(canvas)) =>
      let transform = container->Diagram__Transform.get
      let (x, y) = transform->Diagram__Transform.originGet
      let scale = transform->Diagram__Transform.scaleGet

      let pointerX = e->Diagram__Dom.clientX
      let pointerY = e->Diagram__Dom.clientY

      let x' = (pointerX -. x) /. scale
      let y' = (pointerY -. y) /. scale

      let scale' = scale +. e->ReactEvent.Wheel.deltaY *. -0.0005 *. scale
      let scale'' = Js.Math.min_float(maxScale, Js.Math.max_float(minScale, scale'))

      let x'' = pointerX -. x' *. scale''
      let y'' = pointerY -. y' *. scale''

      transform->Diagram__Transform.originSet((x'', y''))
      transform->Diagram__Transform.scaleSet(scale'')

      canvas->Diagram__Dom.setTransform(x'', y'', scale'')
    | _ => ()
    }

  <WithPointerEvents onPointerDown=beginSliding onPointerUp=stopSliding onPointerMove=slide>
    <div
      ref={ReactDOM.Ref.callbackDomRef(initRender)}
      ?className
      style={ReactDOM.Style.make(~width, ~height, ~position="relative", ~overflow="hidden", ())}
      onWheel={zoom}>
      <div style={ReactDOM.Style.make(~position="relative", ~transformOrigin="0 0", ())} />
    </div>
  </WithPointerEvents>
}
