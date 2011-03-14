signature EXPAT = sig

  type parser

  (* Handlers types *)
  type startTagHandler      = string -> (string * string) list -> unit
  type endTagHandler        = string -> unit
  type characterDataHandler = string -> unit
  type commentHandler       = string -> unit

  (* Create a new parser *)
  val mkParser                : unit -> parser

  (* Reset the parser: it removes all associated handlers *)
  val parserReset             : parser -> parser

  (* Set parser handler for start tags *)
  val setStartElementHandler  : parser
                                -> startTagHandler option
                                -> parser

  (* Set parser handler for start tags *)
  val setEndElementHandler    : parser
                                -> endTagHandler option
                                -> parser

  (* Set parser handlers for both start and end tags *)
  val setElementHandler       : parser
                                (* start tag handler *)
                                -> startTagHandler option
                                (* end tag handler *)
                                -> endTagHandler option
                                -> parser

  (* Set parser handler for character data *)
  val setCharacterDataHandler : parser
                                -> characterDataHandler option
                                -> parser

  (* Set parser handler for comments *)
  val setCommentHandler       : parser
                                -> commentHandler option
                                -> parser

  (* Launch parse. Second parameter tells if it's the last string to be
     processed.
  *)
  val parse                   : parser -> string -> bool -> parser

  (* Error type, error description, line, column *)
  exception Error of ExpatErrors.error * string * int * int
  exception CannotReset

end
