%%raw(`import '../../../example/App.css'`)

@val @scope("document")
external getElementById: string => Js.nullable<Dom.element> = "getElementById"

module App = {
  @react.component
  let make = () => {
    let (id, setId) = React.useState(() => 0)
    let (start, setStart) = React.useState(() => "")
    let (end, setEnd) = React.useState(() => "")
    let (nodes, setNodes) = React.useState(() => [])
    let (edges, setEdges) = React.useState(() => [])

    let reset = _ => {
      setId(_ => 0)
      setStart(_ => "")
      setEnd(_ => "")
      setNodes(_ => [])
      setEdges(_ => [])
    }

    let addNode = _ => {
      setNodes(prev => prev->Belt.Array.concat(["n" ++ Js.Int.toString(id + 1)]))
      setId(id => id + 1)
    }

    let addEdge = _ => {
      setEdges(prev => prev->Belt.Array.concat([[start, end]]))
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
      setStart(_ => v)
      setEnd(_ => w)
    }

    <main>
      <div className="toolbar">
        <button onClick={addNode}> {"Add node"->React.string} </button>
        <button onClick={addEdge} disabled={start == "" || end == ""}>
          {"Add edge"->React.string}
        </button>
        <button onClick={reset}> {"Reset"->React.string} </button>
      </div>
      <Diagram className="graph" width="100%" height="100%">
        <Diagram.Edges>
          {edges
          ->Belt.Array.map(edge =>
            <Diagram.Edge
              key={edge[0] ++ "-" ++ edge[1]}
              source={edge[0]}
              target={edge[1]}
              label={"edge"}
              onClick={_ => selectNodes(edge[0], edge[1])}
            />
          )
          ->React.array}
        </Diagram.Edges>
        {nodes
        ->Belt.Array.map(nodeId =>
          <Diagram.Node
            key={nodeId}
            id={nodeId}
            className={start == nodeId ? "start" : end == nodeId ? "end" : ""}
            onClick={_ => selectNode(nodeId)}>
            {("Node " ++ nodeId)->React.string}
          </Diagram.Node>
        )
        ->React.array}
      </Diagram>
    </main>
  }
}

switch getElementById("root")->Js.toOption {
| Some(root) => ReactDOM.render(<React.StrictMode> <App /> </React.StrictMode>, root)
| None => ()
}
