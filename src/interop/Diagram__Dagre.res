type t

type nodeInfo = {x: float, y: float, width: float, height: float}
type edge = {v: string, w: string, name: string}
type point = {x: float, y: float}
// x & y are undefined if there is no label on edge (width & height are 0)
type edgeInfo = {
  points: array<point>,
  x: option<float>,
  y: option<float>,
  width: float,
  height: float,
}

@send
external setGraph: (t, Js.Dict.t<string>) => unit = "setGraph"
@send
external setDefaultEdgeLabel: (t, 'a => Js.t<'b>) => unit = "setDefaultEdgeLabel"
@send
external setNode: (t, string, Js.t<'a>) => unit = "setNode"
@send
external setEdge: (t, string, string, Js.t<'a>, string) => unit = "setEdge"

@send
external nodes: t => array<string> = "nodes"
@send
external edges: t => array<edge> = "edges"
@send
external node: (t, string) => Js.nullable<nodeInfo> = "node"
@send
external edge: (t, string, string) => Js.nullable<edgeInfo> = "edge"
@send
external namedEdge: (t, string, string, string) => Js.nullable<edgeInfo> = "edge"

@module("dagre")
external layout: t => unit = "layout"

@module("dagre") @scope("graphlib") @new
external make: Js.t<'a> => t = "Graph"
