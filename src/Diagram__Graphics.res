@val @scope("Math")
external pi: float = "PI"

let normalizeVector = (x, y) => {
  let magnitude = Js.Math.sqrt(x *. x +. y *. y)
  magnitude == 0. ? (0., 0.) : (x /. magnitude, y /. magnitude)
}

let normalizePoints = (x1, y1, x2, y2) => {
  // translate vector to 0
  let xt = x2 -. x1
  let yt = y2 -. y1
  // normalize vector
  normalizeVector(xt, yt)
}

let computeAngleFromVector = (x, y) => {
  let (xn, yn) = normalizeVector(x, y) // normalize vector
  Js.Math.atan2(~x=xn, ~y=yn, ()) // compute angle
}

let computeAngleFromPoints = (x1, y1, x2, y2) => {
  // translate vector to 0
  let xt = x2 -. x1
  let yt = y2 -. y1
  // normalize vector
  let magnitude = Js.Math.sqrt(xt *. xt +. yt *. yt)
  let xn = xt /. magnitude
  let yn = 1. *. yt /. magnitude
  // compute angle
  Js.Math.atan2(~x=xn, ~y=yn, ())
}

// x2, y2 is the end path, head of arrow
let createArrowPoints = (x1, y1, x2, y2, useEndPoint) => {
  // angle
  let radAngle = computeAngleFromPoints(x1, y1, x2, y2)
  let c = Js.Math.cos(radAngle)
  let s = Js.Math.sin(radAngle)

  let ax1 = useEndPoint ? x2 : x1
  let ay1 = useEndPoint ? y2 : y1
  let ax2 = -8. *. c -. 4. *. s
  let ay2 = -8. *. s +. 4. *. c
  let ax3 = -8. *. c +. 4. *. s
  let ay3 = -8. *. s -. 4. *. c

  Js.Float.toString(ax1) ++
  "," ++
  Js.Float.toString(ay1) ++
  " " ++
  Js.Float.toString(ax2 +. (useEndPoint ? x2 : x1)) ++
  "," ++
  Js.Float.toString(ay2 +. (useEndPoint ? y2 : y1)) ++
  " " ++
  Js.Float.toString(ax3 +. (useEndPoint ? x2 : x1)) ++
  "," ++
  Js.Float.toString(ay3 +. (useEndPoint ? y2 : y1))
}

let buildPath = (x, y, points) =>
  points->Belt.Array.reduce("M", (acc, p: Diagram__Dagre.point) =>
    acc ++ Js.Float.toString(p.x -. x) ++ " " ++ Js.Float.toString(p.y -. y) ++ " "
  )
