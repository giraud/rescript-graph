%%raw(`import '../../../example/App.css'`)

@val @scope("document")
external getElementById: string => Js.nullable<Dom.element> = "getElementById"

let sample_one = "1"
let sample1 = "1|2|3||1-2|1-3"
let sample2 = "1|2|3|4|5|6|7||1-2|1-3|1-5|2-3|2-7|4-1|6-6"

let parse = instructions => {
  instructions
  ->Js.String2.split("|")
  ->Belt.Array.keep(line => line->Js.String2.length > 0)
  ->Belt.Array.reduce(([], []), ((nodes, edges) as acc, line) => {
    switch line->Js.String2.split("-") {
    | [node] => (nodes->Belt.Array.concat([node]), edges)
    | [source, target] => (nodes, edges->Belt.Array.concat([(source, target)]))
    | _ => acc
    }
  })
}

let renderArray = (a, fn) => a->Belt.Array.map(fn)->React.array

module App = {
  @react.component
  let make = () => {
    let (initialNodes, initialEdges) = parse(sample2)

    let (id, setId) = React.useState(() => initialNodes->Belt.Array.length)
    let (orientation, setOrientation) = React.useState(() => #vertical)
    let (start, setStart) = React.useState(() => "")
    let (end, setEnd) = React.useState(() => "")
    let (nodes, setNodes) = React.useState(() => initialNodes)
    let (edges, setEdges) = React.useState(() => initialEdges)

    let (fitToView, reset, setCommands) = Diagram.useDiagramCommands()

    let flip = () =>
      setOrientation(prev =>
        switch prev {
        | #vertical => #horizontal
        | _ => #vertical
        }
      )

    let clear = _e => {
      setId(_ => 0)
      setStart(_ => "")
      setEnd(_ => "")
      setNodes(_ => [])
      setEdges(_ => [])
      reset()
    }

    let addNode = _ => {
      setNodes(prev => prev->Belt.Array.concat([Js.Int.toString(id + 1)]))
      setId(id => id + 1)
    }

    let addEdge = _ => {
      setEdges(prev => prev->Belt.Array.concat([(start, end)]))
      setStart(_ => "")
      setEnd(_ => "")
    }

    let selectNode = id => {
      if id == start {
        setStart(_ => "")
      } else if id == end {
        setEnd(_ => "")
      } else if start == "" {
        setStart(_ => id)
      } else if end == "" {
        setEnd(_ => id)
      }
    }

    let selectNodes = (v, w) => {
      if start == v && end == w {
        setStart(_ => "")
        setEnd(_ => "")
      } else {
        setStart(_ => v)
        setEnd(_ => w)
      }
    }

    <main>
      <div className="toolbar">
        <button onClick={addNode}> {"Add node"->React.string} </button>
        <button onClick={addEdge} disabled={start == "" || end == ""}>
          {"Add edge"->React.string}
        </button>
        <button onClick={clear}> {"Clear"->React.string} </button>
        <button onClick={_ => reset()}> {"Reset"->React.string} </button>
        <button onClick={_ => fitToView()}> {"Fit to view"->React.string} </button>
        <button onClick={_ => flip()}> {"Flip"->React.string} </button>
        <a href="https://github.com/giraud/rescript-diagram"> {"Github"->React.string} </a>
      </div>
      <Diagram
        className="diagram"
        width="100%"
        height="100%"
        orientation
        boundingBox={true}
        onCreation={setCommands}
        onLayoutUpdate={fitToView}>
        {nodes->renderArray(nodeId =>
          <Diagram.Node
            key={nodeId}
            nodeId={nodeId}
            className={start == nodeId ? "start" : end == nodeId ? "end" : ""}
            onClick={_ => selectNode(nodeId)}>
            {("Node " ++ nodeId)->React.string}
          </Diagram.Node>
        )}
        {edges->renderArray(((source, target)) =>
          <Diagram.Edge
            key={source ++ "-" ++ target}
            source
            target
            label={"edge from " ++ source ++ " to " ++ target}
            onClick={_ => selectNodes(source, target)}
          />
        )}
        // <Diagram.Map className="minimap" />
      </Diagram>
      <div className="info">
        {"Use middle mouse button to drag, mouse wheel to zoom"->React.string}
      </div>
    </main>
  }
}

switch getElementById("root")->Js.toOption {
| Some(root) => ReactDOM.render(<React.StrictMode> <App /> </React.StrictMode>, root)
| None => ()
}
