type t

type orientation = [#vertical | #horizontal]

let displayBBox: t => bool
let setDisplayBBox: (t, bool) => unit

let setOrientation: (t, orientation) => unit

let setNode: (t, string, float, float) => unit
let setEdge: (t, string, string, float, float) => unit

let processNodes: (t, (string, Diagram__Dagre.nodeInfo) => unit) => unit
let processEdges: (t, (string, Diagram__Dagre.edgeInfo) => unit) => unit

let run: (t, Dom.element) => unit
let reset: t => unit
let registerListener: (t, unit => unit) => unit
let onUpdate: t => unit

let make: unit => t

@set external attach: (Dom.element, t) => unit = "layout"
@get external get: Dom.element => t = "layout"
