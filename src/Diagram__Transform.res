@deriving(abstract)
type t = {
  mutable origin: (float, float),
  mutable scale: float,
  mutable tl: (float, float),
  mutable br: (float, float),
}

let resetBBox = transform => {
  transform->tlSet((9999., 9999.))
  transform->brSet((0., 0.))
  ()
}

let computeBBox = (transform, node: Diagram__Dagre.nodeInfo) => {
  let (left, top) = transform->tlGet
  let (right, bottom) = transform->brGet

  let hw = node.width /. 2.
  let hh = node.height /. 2.

  let left' = node.x -. hw
  let top' = node.y -. hh
  let right' = node.x +. hw
  let bottom' = node.y +. hh

  transform->tlSet((Js.Math.min_float(left, left'), Js.Math.min_float(top, top')))
  transform->brSet((Js.Math.max_float(right, right'), Js.Math.max_float(bottom, bottom')))
  ()
}

let bbox = transform => {
  let (left, top) = transform->tlGet
  let (right, bottom) = transform->brGet
  (
    Js.Float.toString(Js.Math.max_float(0., right -. left)) ++ "px",
    Js.Float.toString(Js.Math.max_float(0., bottom -. top)) ++ "px",
  )
}

@set external attach: (Dom.element, t) => unit = "_transform_"
@get external get: Dom.element => t = "_transform_"
