type t

let origin: t => (float, float)
let scale: t => float

let update: (t, (float, float), float) => unit
let reset: t => unit

let resetBBox: t => unit
let computeBBox: (t, float /* x */, float /* y */, float /* w */, float /* h */) => unit
let toPixels: t => (string, string)
let getBBox: t => (float, float)

let make: unit => t

@set external attach: (Dom.element, t) => unit = "_transform_"
@get external get: Dom.element => t = "_transform_"
