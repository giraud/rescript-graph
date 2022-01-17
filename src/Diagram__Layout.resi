type t

let setNode: (t, string, float, float) => unit
let setEdge: (t, string, string) => unit

let incrementCount: (t, string) => unit
let allNodesProcessed: t => bool

let processNodes: (t, (string, Diagram__Dagre.nodeInfo) => unit) => unit
let processEdges: (t, (string, Diagram__Dagre.edgeInfo) => unit) => unit

let updateScale: (t, float) => unit

let run: (t, Dom.element) => unit
let reset: t => unit

let make: float => t

@set external attachLayout: (Dom.element, t) => unit = "layout"
@get external getLayout: Dom.element => t = "layout"
