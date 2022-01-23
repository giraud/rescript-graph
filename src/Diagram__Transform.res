@deriving(abstract)
type t = {mutable scale: float}

@set external attach: (Dom.element, t) => unit = "_transform_"
@get external get: Dom.element => t = "_transform_"
