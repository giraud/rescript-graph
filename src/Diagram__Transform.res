type t = {
  mutable origin: (float, float),
  mutable scale: float,
  mutable tl: (float, float),
  mutable br: (float, float),
}

@val @scope("Number")
external maxSafeFloat: float = "MAX_SAFE_INTEGER"
@val @scope("Number")
external minSafeFloat: float = "MIN_SAFE_INTEGER"

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

let computeBBox = (transform, x, y, width, height) => {
  let (top, left) = transform.tl
  let (bottom, right) = transform.br

  let hw = width /. 2.
  let hh = height /. 2.

  let left' = x -. hw
  let top' = y -. hh
  let right' = x +. hw
  let bottom' = y +. hh

  transform.tl = (Js.Math.min_float(top, top'), Js.Math.min_float(left, left'))
  transform.br = (Js.Math.max_float(bottom, bottom'), Js.Math.max_float(right, right'))
  ()
}

let updateBBox = (transform, left, top, right, bottom) => {
  let (tTop, tLeft) = transform.tl
  let (tBottom, tRight) = transform.br

  transform.tl = (Js.Math.min_float(tTop, top), Js.Math.min_float(tLeft, left))
  transform.br = (Js.Math.max_float(tBottom, bottom), Js.Math.max_float(tRight, right))
  ()
}

let toPixels = transform => {
  let (top, left) = transform.tl
  let (bottom, right) = transform.br
  (
    Js.Float.toString(Js.Math.max_float(0., right -. left)) ++ "px",
    Js.Float.toString(Js.Math.max_float(0., bottom -. top)) ++ "px",
  )
}

let getBBox = transform => {
  let (top, left) = transform.tl
  let (bottom, right) = transform.br
  (Js.Math.max_float(0., right -. left), Js.Math.max_float(0., bottom -. top))
}

let make = () => {
  origin: (0., 0.),
  scale: 1.,
  tl: (maxSafeFloat, maxSafeFloat),
  br: (minSafeFloat, minSafeFloat),
}

@set external attach: (Dom.element, t) => unit = "_transform_"
@get external get: Dom.element => t = "_transform_"
