@val @scope("document")
external getElementById: string => Js.nullable<Dom.element> = "getElementById"

module App = {
  @module("../../../example/App") @react.component
  external make: unit => React.element = "default"
}

switch getElementById("root")->Js.toOption {
| Some(root) => ReactDOM.render(<React.StrictMode> <App /> </React.StrictMode>, root)
| None => ()
}
