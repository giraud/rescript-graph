type t

type nodeInfo = {x: float, y: float, width: float, height: float}
type edge = {v: string, w: string}
type point = {x: float, y: float}
type edgeInfo = {points: array<point>}

@send
external setGraph: (t, Js.t<'a>) => unit = "setGraph"
@send
external setDefaultEdgeLabel: (t, 'a => Js.t<'b>) => unit = "setDefaultEdgeLabel"
@send
external setNode: (t, string, Js.t<'a>) => unit = "setNode"
@send
external setEdge: (t, Js.t<'a>) => unit = "setEdge"

@send
external nodes: t => array<string> = "nodes"
@send
external edges: t => array<edge> = "edges"
@send
external node: (t, string) => Js.nullable<nodeInfo> = "node"
@send
external edge: (t, string, string) => Js.nullable<edgeInfo> = "edge"

@module("dagre")
external layout: t => unit = "layout"

@module("dagre") @scope("graphlib") @new
external make: unit => t = "Graph"
