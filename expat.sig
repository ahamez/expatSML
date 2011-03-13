signature EXPAT = sig

  type parser

  (* Create a new parser *)
  val mkParser                : unit -> parser

  (* Reset the parser: it removes all associated handlers *)
  val parserReset             : parser -> parser

  (* Provide a parser handlers for start and end tags *)
  val setElementHandlers      : parser
                                (* start tag handler *)
                                -> (string -> (string * string) list -> unit)
                                (* end tag handler *)
                                -> (string -> unit)
                                -> parser

  (* Provide a parser an handler for text *)
  val setCharacterDataHandler : parser
                                (* text handler *)
                                -> (string -> unit)
                                -> parser

  (* Launch parse. Second parameter tells if it's the last string to be
     processed.
  *)
  val parse                   : parser -> string -> bool -> parser

  (* Error type, error description, line, column *)
  exception Error of ExpatErrors.error * string * int * int
  exception CannotReset

end
