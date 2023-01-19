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
    ~className: string=?,
    ~label: string=?,
    ~labelPos: Diagram__Layout.labelPos=?,
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

let useDiagramCommands = () => {
  let (commands: option<Commands.t>, setCommands) = React.useState(() => None)

  let reset = () =>
    switch commands {
    | None => ()
    | Some(c) => c.reset()
    }

  let fitToView = () =>
    switch commands {
    | None => ()
    | Some(c) => c.fitToView()
    }

  (fitToView, reset, c => setCommands(_ => Some(c)))
}

let useOrientation = init => {
  let (orientation, setOrientation) = React.useState(init)
  let flip = () =>
    setOrientation(prev =>
      switch prev {
      | #vertical => #horizontal
      | _ => #vertical
      }
    )
  (orientation, flip)
}

@react.component
let make = (
  ~width,
  ~height,
  ~className=?,
  ~minScale=0.1,
  ~maxScale=1.5,
  ~orientation: Diagram__Layout.orientation=#vertical,
  ~boundingBox=false,
  ~onCreation=?,
  ~onLayoutUpdate=?,
  ~children,
) => {
  let diagramNode = React.useRef(None)
  let canvasNode = React.useRef(None)
  let slidingEnabled = React.useRef(false)

  React.useEffect1(() => {
    switch diagramNode.current {
    | Some(container) =>
      container
      ->Diagram__Layout.get
      ->Diagram__Layout.registerListener(onLayoutUpdate->Belt.Option.getWithDefault(() => ()))
    | None => ()
    }
    None
  }, [onLayoutUpdate])

  switch diagramNode.current {
  | Some(container) => container->Diagram__Layout.get->Diagram__Layout.setOrientation(orientation)
  | None => ()
  }

  let initRender = domNode => {
    diagramNode.current = domNode->Js.toOption
    switch diagramNode.current {
    | Some(container) =>
      open Belt.Option
      canvasNode.current = container->Diagram__Dom.firstChild->Js.toOption
      Diagram__DOMRenderer.render(children, container, (t, l) => {
        let update = (changeScale, center, ()) => {
          // compute center
          let (x, y, scale) = if center {
            let (canvasWidth, canvasHeight) = t->Diagram__Transform.getBBox
            if canvasWidth > 0. && canvasHeight > 0. {
              let {width: containerWidth, height: containerHeight} =
                container->Diagram__Dom.getBoundingClientRect
              // change scale if wanted
              let scale = if changeScale {
                let realScale =
                  0.98 /.
                  Js.Math.max_float(canvasWidth /. containerWidth, canvasHeight /. containerHeight)
                Js.Math.min_float(1.0, Js.Math.max_float(minScale, realScale))
              } else {
                t->Diagram__Transform.scale
              }

              let x = containerWidth /. 2. -. scale *. (canvasWidth /. 2.)
              let y = containerHeight /. 2. -. scale *. (canvasHeight /. 2.)
              (x, y, scale)
            } else {
              (0., 0., 1.)
            }
          } else {
            (0., 0., 1.)
          }

          t->Diagram__Transform.update((x, y), scale)
          canvasNode.current->forEach(canvas => canvas->Diagram__Dom.setTransform(x, y, scale))
        }
        l->Diagram__Layout.setDisplayBBox(boundingBox)
        l->Diagram__Layout.setOrientation(orientation)
        onCreation->forEach(fn =>
          fn(Diagram__DOMRenderer.Commands.make(update(true, false), update(true, true)))
        )
      })
    | None => ()
    }
  }

  let beginSliding = (. e) =>
    switch diagramNode.current {
    | Some(node)
      if e->Diagram__Dom.mouseEventTarget == node &&
        e->Diagram__Dom.mouseEventButton == 1 /* middle/wheel */ =>
      e
      ->Diagram__Dom.mouseEventTarget
      ->Diagram__Dom.setPointerCapture(e->Diagram__Dom.mousePointerId)

      node->Diagram__Dom.style->Js.Dict.set("cursor", "move")
      slidingEnabled.current = true
    | _ => ()
    }

  let slide = (. e) =>
    if slidingEnabled.current {
      switch (diagramNode.current, canvasNode.current) {
      | (Some(container), Some(canvas)) =>
        let transform = container->Diagram__Transform.get

        let (x, y) = transform->Diagram__Transform.origin
        let scale = transform->Diagram__Transform.scale

        let x' = x +. Js.Int.toFloat(e->ReactEvent.Mouse.movementX)
        let y' = y +. Js.Int.toFloat(e->ReactEvent.Mouse.movementY)

        transform->Diagram__Transform.update((x', y'), scale)
        canvas->Diagram__Dom.setTransform(x', y', scale)

        let {width, height} = container->Diagram__Dom.getBoundingClientRect
        let ccx = width /. 2.
        let ccy = height /. 2.

        let (bboxWidth, bboxHeight) = transform->Diagram__Transform.getBBox

        let bbwh = bboxWidth *. scale /. 2.
        let bbhh = bboxHeight *. scale /. 2.
        let bbcx = x' +. bbwh // bbox center x
        let bbcy = y' +. bbhh // bbox center y

        let displayGps =
          bbcy +. bbhh < 0. || bbcx +. bbwh < 0. || bbcx -. bbwh > width || bbcy -. bbhh > height

        container
        ->Diagram__Dom.lastChild
        ->Js.toOption
        ->Belt.Option.forEach(gps => {
          gps->Diagram__Dom.style->Js.Dict.set("display", displayGps ? "block" : "none")
          gps->Diagram__Dom.setTranslate3d(ccx -. 25., ccy -. 25.)
          // arrow
          switch gps->Diagram__Dom.lastChild->Js.toOption {
          | Some(arrow) if displayGps =>
            let (vnx, vny) = Diagram__Graphics.normalizeVector(bbcx -. ccx, bbcy -. ccy)
            let vx = 25. *. vnx
            let vy = 25. *. vny

            let arrowPoints = Diagram__Graphics.createArrowPoints(
              25. +. vx,
              25. +. vy,
              25. +. bbcx -. ccx,
              25. +. bbcy -. ccy,
              false,
            )
            arrow->Diagram__Dom.setAttribute("points", arrowPoints)
          | _ => ()
          }
        })

      | _ => ()
      }
    }

  let stopSliding = (. e) =>
    switch diagramNode.current {
    | Some(node) =>
      slidingEnabled.current = false
      node->Diagram__Dom.style->Js.Dict.set("cursor", "initial")
      node
      ->Diagram__Dom.lastChild
      ->Js.toOption
      ->Belt.Option.forEach(n => n->Diagram__Dom.style->Js.Dict.set("display", "none"))
      e
      ->Diagram__Dom.mouseEventTarget
      ->Diagram__Dom.releasePointerCapture(e->Diagram__Dom.mousePointerId)
    | None => ()
    }

  let zoom = e =>
    switch (diagramNode.current, canvasNode.current) {
    | (Some(container), Some(canvas)) =>
      let transform = container->Diagram__Transform.get
      let (x, y) = transform->Diagram__Transform.origin
      let scale = transform->Diagram__Transform.scale

      let eMouse = e->Diagram__Dom.asMouseEvent
      let targetBBox = eMouse->Diagram__Dom.mouseEventTarget->Diagram__Dom.getBoundingClientRect
      let pointerX = eMouse->Diagram__Dom.clientX -. targetBBox.left
      let pointerY = eMouse->Diagram__Dom.clientY -. targetBBox.top

      let x' = (pointerX -. x) /. scale
      let y' = (pointerY -. y) /. scale

      let scale' = scale +. e->ReactEvent.Wheel.deltaY *. -0.0005 *. scale
      let scale'' = Js.Math.min_float(maxScale, Js.Math.max_float(minScale, scale'))

      let x'' = pointerX -. x' *. scale''
      let y'' = pointerY -. y' *. scale''

      transform->Diagram__Transform.update((x'', y''), scale'')
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
      <svg
        xmlns="http://www.w3.org/2000/svg"
        viewBox="0 0 50 50"
        width="50px"
        height="50px"
        style={ReactDOM.Style.make(~pointerEvents="none", ~display="none", ())}>
        <circle cx="25" cy="25" r="12" fill="none" /> <polygon />
      </svg>
    </div>
  </WithPointerEvents>
}
