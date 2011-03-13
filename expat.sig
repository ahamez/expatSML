signature EXPAT = sig

  type parser

  val mkParser                : unit -> parser

  val setElementHandlers      : parser
                                (* start tag handler *)
                                -> (string -> (string * string) list -> unit)
                                (* end tag handler *)
                                -> (string -> unit)
                                -> parser

  val setCharacterDataHandler : parser
                                (* text handler *)
                                -> (string -> unit)
                                -> parser

  val parseString             : parser -> string -> unit

end
