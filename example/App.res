%%raw(`import '../../../example/App.css'`)

@val @scope("document")
external getElementById: string => Js.nullable<Dom.element> = "getElementById"

let sample_one = "1"
let sample1 = "1|2|3||1-2|1-3"
let sample2 = "1|2|3|4|5|6|7||1-2|1-3|1-5|2-3|2-7|4-1|6-6"
let sample3 = "B|C|D||B-C:BtoC|B-C:BtoC_2|B-C:More_BtoC|B-C|C-B:CtoB|C-D:CtoD|D-C:DtoC|B-D:A very very long name to see if layout is correctly updated"

let parse = instructions => {
  instructions
  ->Js.String2.split("|")
  ->Belt.Array.keep(line => line->Js.String2.length > 0)
  ->Belt.Array.reduce(([], []), ((nodes, edges) as acc, line) => {
    switch line->Js.String2.split("-") {
    | [node] => (nodes->Belt.Array.concat([node]), edges)
    | [source, target] =>
      switch target->Js.String2.split(":") {
      | [target', label] => (nodes, edges->Belt.Array.concat([(source, target', label)]))
      | _ => (nodes, edges->Belt.Array.concat([(source, target, "")]))
      }
    | _ => acc
    }
  })
}

let renderArray = (a, fn) => a->Belt.Array.map(fn)->React.array

module App = {
  @react.component
  let make = () => {
    let (initialNodes, initialEdges) = parse(sample3)

    let (id, setId) = React.useState(() => initialNodes->Belt.Array.length)
    let (start, setStart) = React.useState(() => "")
    let (end, setEnd) = React.useState(() => "")
    let (nodes, setNodes) = React.useState(() => initialNodes)
    let (edges, setEdges) = React.useState(() => initialEdges)

    let diagramCommands: Diagram.refCommands = React.useRef(None)
    let (orientation, flip) = Diagram.useOrientation(() => #vertical)

    let clear = _e => {
      setId(_ => 0)
      setStart(_ => "")
      setEnd(_ => "")
      setNodes(_ => [])
      setEdges(_ => [])
      Diagram.reset(diagramCommands)
    }

    let addNode = _ => {
      setNodes(prev => prev->Belt.Array.concat([Js.Int.toString(id + 1)]))
      setId(id => id + 1)
    }

    let removeNode = _ => {
      setNodes(prev => prev->Belt.Array.keep(itemId => itemId != start))
      setEdges(prev =>
        prev->Belt.Array.keep(((itemStart, itemEnd, _)) => itemStart != start && itemEnd != start)
      )
      setStart(_ => "")
      setEnd(_ => "")
    }

    let addEdge = _ => {
      setEdges(prev => prev->Belt.Array.concat([(start, end, "")]))
      setStart(_ => "")
      setEnd(_ => "")
    }

    let removeEdge = _ => {
      setEdges(prev =>
        prev->Belt.Array.keep(((itemStart, itemEnd, _)) => itemStart != start || itemEnd != end)
      )
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
        <button onClick={removeNode} disabled={start == "" || end != ""}>
          {"Remove node"->React.string}
        </button>
        <button onClick={addEdge} disabled={start == "" || end == ""}>
          {"Add edge"->React.string}
        </button>
        <button onClick={removeEdge} disabled={start == "" || end == ""}>
          {"Remove edge"->React.string}
        </button>
        <button onClick={clear}> {"Clear"->React.string} </button>
        <button onClick={_ => Diagram.reset(diagramCommands)}> {"Reset"->React.string} </button>
        <button onClick={_ => Diagram.fitToView(diagramCommands)}>
          {"Fit to view"->React.string}
        </button>
        <button onClick={_ => flip()}> {"Flip"->React.string} </button>
        <a href="https://github.com/giraud/rescript-diagram"> {"Github"->React.string} </a>
      </div>
      <Diagram
        className="diagram"
        width="100%"
        height="100%"
        orientation
        selectionZoom=true
        boundingBox=true
        commands={diagramCommands}
        onLayoutUpdate={() => Diagram.fitToView(diagramCommands)}>
        {nodes->renderArray(nodeId =>
          <Diagram.Node
            key={nodeId}
            nodeId={nodeId}
            className={start == nodeId ? "start" : end == nodeId ? "end" : ""}
            onClick={_ => selectNode(nodeId)}>
            {("Node " ++ nodeId)->React.string}
          </Diagram.Node>
        )}
        {edges->renderArray(((source, target, label)) =>
          <Diagram.Edge
            key={source ++ "-" ++ target ++ "-" ++ label}
            source
            target
            label=?{label->Js.String2.length == 0 ? None : Some(label)}
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
| Some(rootElement) =>
  let root = ReactDOM.Client.createRoot(rootElement)
  ReactDOM.Client.Root.render(
    root,
    <React.StrictMode>
      <App />
    </React.StrictMode>,
  )
| None => ()
}
