import {useState} from 'react'
import './App.css'
import {edgesType as Edges, edgeType as Edge, make as ReGraph, nodeType as Node} from '../lib/es6_global/src/ReGraph.bs'

function App() {
    let [id, setId] = useState(0)
    let [start, setStart] = useState(0)
    let [end, setEnd] = useState(0)
    let [nodes, setNodes] = useState([])
    let [edges, setEdges] = useState([])

    let reset = () => {
        setId(0)
        setStart(0)
        setEnd(0)
        setNodes([])
        setEdges([])
    }

    let addNode = () => {
        setNodes(prev => [...prev, id + 1])
        setId(id + 1)
    }

    let addEdge = () => {
        setEdges(prev => [...prev, [start, end]])
        setStart(0)
        setEnd(0)
    }

    let selectNode = (id) => {
        if (id === start) {
            setStart(0)
        }
        else if (id === end) {
            setEnd(0)
        }
        else if (start === 0) {
            setStart(id)
        }
        else if (end === 0) {
            setEnd(id)
        }
    }

    let selectNodes = (v, w) => {
        setStart(v)
        setEnd(w)
    }

    return (//
        <main>
            <div className="toolbar">
                <button type="button" onClick={addNode}>Add node</button>
                <button type="button" onClick={addEdge} disabled={start === 0 || end === 0}>Add edge</button>
                <button type="button" onClick={reset}>Reset</button>
            </div>
            <ReGraph className="graph" width='100%' height='100%'>
                <Edges>
                    {edges.map(edge => (<Edge key={edge[0] + "-" + edge[1]}
                                              from={"n" + edge[0]} to={"n" + edge[1]} label={"edge"}
                                              onClick={() => selectNodes(edge[0], edge[1])}
                    />))}
                </Edges>
                {nodes.map(nodeId => ( //
                    <Node key={"n" + nodeId} id={"n" + nodeId} className={start === nodeId ? "start" : end === nodeId ? "end" : ""}
                          onClick={() => selectNode(nodeId)}>
                        Node {nodeId}
                    </Node>))}
            </ReGraph>
        </main>)
}

export default App
