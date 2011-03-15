signature EXPAT = sig

  type parser

  (* Handlers types *)
  type startTagHandler      = string -> (string * string) list -> unit
  type endTagHandler        = string -> unit
  type characterDataHandler = string -> unit
  type commentHandler       = string -> unit
  type startCdataHandler    = unit -> unit
  type endCdataHandler      = unit -> unit

  (* Create a new parser *)
  val mkParser                    : unit -> parser

  (* Launch parse. Second parameter tells if it's the last string to be
     processed.
  *)
  val parse                       : parser -> string -> bool -> parser

  (* Reset the parser: it removes all associated handlers *)
  val parserReset                 : parser -> parser

  (* Set parser handler for start tags *)
  val setStartElementHandler      : parser
                                    -> startTagHandler option
                                    -> parser

  (* Set parser handler for start tags *)
  val setEndElementHandler        : parser
                                    -> endTagHandler option
                                    -> parser

  (* Set parser handlers for both start and end tags *)
  val setElementHandler           : parser
                                    -> startTagHandler option
                                    -> endTagHandler option
                                    -> parser

  (* Set parser handler for character data *)
  val setCharacterDataHandler     : parser
                                    -> characterDataHandler option
                                    -> parser

  (* Set parser handler for comments *)
  val setCommentHandler           : parser
                                    -> commentHandler option
                                    -> parser

  (* Set parser handler called at the beginning of a CDATA section *)
  val setStartCdataSectionHandler : parser
                                    -> startCdataHandler option
                                    -> parser

  (* Set parser handler called at the end of a CDATA section *)
  val setEndCdataSectionHandler   : parser
                                    -> endCdataHandler option
                                    -> parser

  (* Set parser for both start and end of CDATA sectionq *)
  val setCdataSectionHandler      : parser
                                    -> startCdataHandler option
                                    -> endCdataHandler option
                                    -> parser

  (* Error type, error description, line, column *)
  exception Error of ExpatErrors.error * string * int * int
  exception CannotReset

end
