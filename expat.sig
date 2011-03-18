(* Copyright LAAS/CNRS (2011)

Contributors:
- Alexandre Hamez     <alexandre.hamez@gmail.com>

This software is governed by the CeCILL-B license under French law and abiding
by the rules of distribution of free software. You can use, modify and/ or
redistribute the software under the terms of the CeCILL-B license as circulated
by CEA, CNRS and INRIA at the following URL "http://www.cecill.info".

The fact that you are presently reading this means that you have had knowledge
of the CeCILL-B license and that you accept its terms.

You should have received a copy of the CeCILL-B license along with
expatSML-light. See the file LICENSE. *)

signature EXPAT = sig

  (* Handlers types *)
  type startTagHandler      = string -> (string * string) list -> unit
  type endTagHandler        = string -> unit
  type characterDataHandler = string -> unit
  type commentHandler       = string -> unit
  type startCdataHandler    = unit -> unit
  type endCdataHandler      = unit -> unit

  (* Launch parse. Second parameter tells if it's the last string to be
     processed.
  *)
  val parse                       : string -> bool -> unit

  (* Reset the parser: it removes all associated handlers *)
  val parserReset                 : unit -> unit

  (* Set parser handler for start tags *)
  val setStartElementHandler      : startTagHandler option -> unit

  (* Set parser handler for start tags *)
  val setEndElementHandler        : endTagHandler option -> unit

  (* Set parser handlers for both start and end tags *)
  val setElementHandler           : startTagHandler option
                                    -> endTagHandler option
                                    -> unit

  (* Set parser handler for character data *)
  val setCharacterDataHandler     : characterDataHandler option -> unit

  (* Set parser handler for comments *)
  val setCommentHandler           : commentHandler option -> unit

  (* Set parser handler called at the beginning of a CDATA section *)
  val setStartCdataSectionHandler : startCdataHandler option -> unit

  (* Set parser handler called at the end of a CDATA section *)
  val setEndCdataSectionHandler   : endCdataHandler option -> unit

  (* Set parser for both start and end of CDATA sectionq *)
  val setCdataSectionHandler      : startCdataHandler option
                                    -> endCdataHandler option
                                    -> unit

  (* Error type, error description, line, column *)
  exception Error of ExpatErrors.error * string * int * int
  exception CannotReset

end
