signature EXPAT = sig

  type parser

  (* Handlers types *)
  type startTagHandler      = parser -> string -> (string * string) list -> unit
  type endTagHandler        = parser -> string -> unit
  type characterDataHandler = parser -> string -> unit
  type commentHandler       = parser -> string -> unit
  type startCdataHandler    = parser -> unit
  type endCdataHandler      = parser -> unit

  (* Create a new parser *)
  val mkParser                    : unit -> parser

  (* Launch parse. Second parameter tells if it's the last string to be
     processed.
  *)
  val parse                       : parser -> string -> bool -> unit

  (* Reset the parser: it removes all associated handlers *)
  val parserReset                 : parser -> unit

  (* Set parser handler for start tags *)
  val setStartElementHandler      : parser
                                    -> startTagHandler option
                                    -> unit

  (* Set parser handler for start tags *)
  val setEndElementHandler        : parser
                                    -> endTagHandler option
                                    -> unit

  (* Set parser handlers for both start and end tags *)
  val setElementHandler           : parser
                                    -> startTagHandler option
                                    -> endTagHandler option
                                    -> unit

  (* Set parser handler for character data *)
  val setCharacterDataHandler     : parser
                                    -> characterDataHandler option
                                    -> unit

  (* Set parser handler for comments *)
  val setCommentHandler           : parser
                                    -> commentHandler option
                                    -> unit

  (* Set parser handler called at the beginning of a CDATA section *)
  val setStartCdataSectionHandler : parser
                                    -> startCdataHandler option
                                    -> unit

  (* Set parser handler called at the end of a CDATA section *)
  val setEndCdataSectionHandler   : parser
                                    -> endCdataHandler option
                                    -> unit

  (* Set parser for both start and end of CDATA sectionq *)
  val setCdataSectionHandler      : parser
                                    -> startCdataHandler option
                                    -> endCdataHandler option
                                    -> unit

  (* Error type, error description, line, column *)
  exception Error of ExpatErrors.error * string * int * int
  exception CannotReset

end
