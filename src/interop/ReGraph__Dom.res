type element = Dom.element

module Document = {
  @val @scope("document")
  external getElementById: string => Js.nullable<Dom.element> = "getElementById"
  @val @scope("document")
  external querySelectorAll: string => array<Dom.element> = "querySelectorAll"
  @val @scope("document")
  external createElementNS: (string, string) => Dom.element = "createElementNS"
  @val @scope("document")
  external createElement: string => Dom.element = "createElement"
  @val @scope("document")
  external createTextNode: string => Dom.element = "createTextNode"
  @val @scope("document")
  external getBody: Js.nullable<Dom.element> = "body"
}

module Window = {
  @val @scope("window")
  external hasOwnProperty: string => bool = "hasOwnProperty"
}

module NodeType = {
  let element = 1
  let document = 9
}

type domRect = {width: float, height: float}

@send
external hasOwnProperty: (Dom.element, string) => bool = "hasOwnProperty"
@send
external appendChild: (Dom.element, Dom.element) => unit = "appendChild"
@send
external removeChild: (Dom.element, Dom.element) => unit = "removeChild"
@send
external setAttribute: (Dom.element, string, string) => unit = "setAttribute"
@send
external addEventListener: (Dom.element, string, 'a) => unit = "addEventListener"
@send
external getBoundingClientRect: Dom.element => domRect = "getBoundingClientRect"
@send
external closest: (Dom.element, string) => Js.nullable<Dom.element> = "closest"

@get
external id: Dom.element => string = "id"
@get
external nodeType: Dom.element => int = "nodeType"
@get
external parentNode: Dom.element => Js.nullable<Dom.element> = "parentNode"
@get
external children: Dom.element => array<Dom.element> = "children"

@set
external setId: (Dom.element, string) => unit = "id"
@set
external setTextContent: (Dom.element, string) => unit = "textContent"
@set
external setDocument: (Dom.element, Dom.element) => unit = "document"
