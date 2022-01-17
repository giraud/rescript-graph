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
        <button onClick={reset}> {"Reset"->React.string} </button>
      </div>
      <Diagram className="diagram" width="100%" height="100%">
        {nodes
        ->Belt.Array.map(nodeId =>
          <Diagram.Node
            key={nodeId}
            nodeId={nodeId}
            className={start == nodeId ? "start" : end == nodeId ? "end" : ""}
            onClick={_ => selectNode(nodeId)}>
            {("Node " ++ nodeId)->React.string}
          </Diagram.Node>
        )
        ->React.array}
        {edges
        ->Belt.Array.map(edge =>
          switch edge {
          | [source, target] =>
            <Diagram.Edge
              key={source ++ "-" ++ target}
              source
              target
              label="edge"
              onClick={_ => selectNodes(source, target)}
            />
          | _ => React.null
          }
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
