type t = {
  mutable origin: (float, float),
  mutable scale: float,
  mutable tl: (float, float),
  mutable br: (float, float),
}

let maxSafeFloat = %raw(`Number.MAX_SAFE_INTEGER`)
let minSafeFloat = %raw(`Number.MIN_SAFE_INTEGER`)

let origin = transform => transform.origin
let scale = transform => transform.scale

let update = (transform, origin, scale) => {
  transform.origin = origin
  transform.scale = scale
}

let reset = transform => {
  transform.origin = (0., 0.)
  transform.scale = 1.
}

let resetBBox = transform => {
  transform.tl = (maxSafeFloat, maxSafeFloat)
  transform.br = (minSafeFloat, minSafeFloat)
}

let computeBBox = (transform, node: Diagram__Dagre.nodeInfo) => {
  let (left, top) = transform.tl
  let (right, bottom) = transform.br

  let hw = node.width /. 2.
  let hh = node.height /. 2.

  let left' = node.x -. hw
  let top' = node.y -. hh
  let right' = node.x +. hw
  let bottom' = node.y +. hh

  transform.tl = (Js.Math.min_float(left, left'), Js.Math.min_float(top, top'))
  transform.br = (Js.Math.max_float(right, right'), Js.Math.max_float(bottom, bottom'))
  ()
}

let toPixels = transform => {
  let (left, top) = transform.tl
  let (right, bottom) = transform.br
  (
    Js.Float.toString(Js.Math.max_float(0., right -. left)) ++ "px",
    Js.Float.toString(Js.Math.max_float(0., bottom -. top)) ++ "px",
  )
}

let make = () => {
  origin: (0., 0.),
  scale: 1.,
  tl: (maxSafeFloat, maxSafeFloat),
  br: (minSafeFloat, minSafeFloat),
}

@set external attach: (Dom.element, t) => unit = "_transform_"
@get external get: Dom.element => t = "_transform_"
