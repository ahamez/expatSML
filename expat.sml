(* Copyright LAAS/CNRS (2011)

Contributors:
- Alexandre Hamez <alexandre.hamez@gmail.com>

This software is governed by the CeCILL-B license under French law and abiding
by the rules of distribution of free software. You can use, modify and/ or
redistribute the software under the terms of the CeCILL-B license as circulated
by CEA, CNRS and INRIA at the following URL "http://www.cecill.info".

The fact that you are presently reading this means that you have had knowledge
of the CeCILL-B license and that you accept its terms.

You should have received a copy of the CeCILL-B license along with expatSML. See
the file LICENSE. *)

(* -------------------------------------------------------------------------- *)
structure Expat : EXPAT = struct

(* -------------------------------------------------------------------------- *)
structure Pt = MLton.Pointer
structure Fz = MLton.Finalizable
structure Ar = Array
open ExpatUtil

(* -------------------------------------------------------------------------- *)
type parser = Pt.t Fz.t
type startTagHandler      = string -> (string * string) list -> unit
type endTagHandler        = string -> unit
type characterDataHandler = string -> unit
type commentHandler       = string -> unit
type startCdataHandler    = unit -> unit
type endCdataHandler      = unit -> unit

(* -------------------------------------------------------------------------- *)
exception Error of ExpatErrors.error * string * int * int
exception CannotReset

(* -------------------------------------------------------------------------- *)
(* Return the parser stored in a Finalizable *)
fun getPointer p = Fz.withValue (p, fn x => x)

(* -------------------------------------------------------------------------- *)
fun mkParser () =
let

  val cCreate  =
    _import "XML_ParserCreate" public: Pt.t -> Pt.t;

  val cFree    =
    _import "XML_ParserFree" public: Pt.t -> unit;

  val cRes     = cCreate Pt.null
  val res      = Fz.new cRes
  (* Will free the parser when res is no longer reachable in SML *)
  val _        = Fz.addFinalizer (res, fn x => cFree x)
in
  res
end

(* -------------------------------------------------------------------------- *)
(* Global parser *)
val parser = mkParser ()

(* -------------------------------------------------------------------------- *)
fun parserReset () =
let

  val cReset  =
    _import "XML_ParserReset" public: (Pt.t * Pt.t) -> int;

  val p = getPointer parser

in
  if cReset (p, Pt.null) = 1 then
    ()
  else
    raise CannotReset
end

(* -------------------------------------------------------------------------- *)
fun setStartElementHandler handlerOpt =
let

  val cSetHandler =
    _import "C_SetStartElementHandler" public: Pt.t -> unit;

  val cUnsetHandler =
    _import "C_UnsetStartElementHandler" public: Pt.t -> unit;

  val cCall =
    _export "SML_callStartHandler" : (Pt.t * Pt.t -> unit) -> unit;

  fun callbackHandler user (cName, cAttrs) =
  let

    fun loop acc ptr =
      if Pt.getPointer(ptr, 0) = Pt.null then
        (* end of attributes *)
        acc
      else
      let
        (* Each attribute seen in a start (or empty) tag occupies 2 consecutive 
           places in this vector: the attribute name followed by the attribute
           value
        *)
        val attr = fetchCString (Pt.getPointer (ptr, 0))
        val cont = fetchCString (Pt.getPointer (ptr, 1))
      in
        loop ((attr,cont)::acc)
             (Pt.add (ptr, Pt.sizeofPointer * (Word.fromInt 2)))
      end

    val attrs = loop [] cAttrs
    val name  = fetchCString cName
  in
    user name attrs
  end

  val p = getPointer parser
  val _ = case handlerOpt of
            NONE   => cUnsetHandler p
          | SOME u => ( cCall (callbackHandler u)
                      ; cSetHandler p
                      )
in
  ()
end

(* -------------------------------------------------------------------------- *)
fun setEndElementHandler handlerOpt =
let

  val cSetHandler =
    _import "C_SetEndElementHandler" public: Pt.t -> unit;

  val cUnsetHandler =
    _import "C_UnsetEndElementHandler" public: Pt.t -> unit;

  val cCall =
    _export "SML_callEndHandler" : (Pt.t -> unit) -> unit;

  fun callbackHandler user data =
    user (fetchCString data)

  val p = getPointer parser
  val _ = case handlerOpt of
            NONE   => cUnsetHandler p
          | SOME u => ( cCall (callbackHandler u)
                      ; cSetHandler p
                      )
in
  ()
end

(* -------------------------------------------------------------------------- *)
fun setElementHandler startHandlerOpt endHandlerOpt =
let
  val _ = setStartElementHandler startHandlerOpt
  val _ = setEndElementHandler endHandlerOpt
in
  ()
end

(* -------------------------------------------------------------------------- *)
fun setCharacterDataHandler handlerOpt =
let
  val cSetHandler  =
    _import "C_SetCharacterDataHandler" public: Pt.t -> unit;

  val cUnsetHandler =
    _import "C_UnsetCharacterDataHandler" public: Pt.t -> unit;

  val cCall =
    _export "SML_callCharacterDataHandler" : (Pt.t * int -> unit) -> unit;

  fun callbackHandler user (data, len) =
    user (fetchCStringWithSize data len)

  val p = getPointer parser
  val _ = case handlerOpt of
            NONE   => cUnsetHandler p
          | SOME u => ( cCall (callbackHandler u)
                      ; cSetHandler p
                      )
in
  ()
end

(* -------------------------------------------------------------------------- *)
fun setCommentHandler handlerOpt =
let
  val cSetHandler  =
    _import "C_SetCommentHandler" public: Pt.t -> unit;

  val cUnsetHandler =
    _import "C_UnsetCommentHandler" public: Pt.t -> unit;

  val cCall =
    _export "SML_callCommentHandler" : (Pt.t -> unit) -> unit;

  fun callbackHandler user data =
    user (fetchCString data)

  val p = getPointer parser
  val _ = case handlerOpt of
            NONE   => cUnsetHandler p
          | SOME u => ( cCall (callbackHandler u)
                      ; cSetHandler p
                      )
in
  ()
end

(* -------------------------------------------------------------------------- *)
fun setStartCdataSectionHandler handlerOpt =
let
  val cSetHandler  =
    _import "C_SetStartCdataHandler" public: Pt.t -> unit;

  val cUnsetHandler =
    _import "C_UnsetStartCdataHandler" public: Pt.t -> unit;

  val cCall =
    _export "SML_callStartCdataHandler" : (unit -> unit) -> unit;

  fun callbackHandler user () =
    user ()

  val p = getPointer parser
  val _ = case handlerOpt of
            NONE   => cUnsetHandler p
          | SOME u => ( cCall (callbackHandler u)
                      ; cSetHandler p
                      )
in
  ()
end

(* -------------------------------------------------------------------------- *)
fun setEndCdataSectionHandler handlerOpt =
let
  val cSetHandler  =
    _import "C_SetEndCdataHandler" public: Pt.t -> unit;

  val cUnsetHandler =
    _import "C_UnsetEndCdataHandler" public: Pt.t -> unit;

  val cCall =
    _export "SML_callEndCdataHandler" : (unit -> unit) -> unit;

  fun callbackHandler user () =
    user ()

  val p = getPointer parser
  val _ = case handlerOpt of
            NONE   => cUnsetHandler p
          | SOME u => ( cCall (callbackHandler u)
                      ; cSetHandler p
                      )
in
  ()
end

(* -------------------------------------------------------------------------- *)
fun setCdataSectionHandler startHandler endHandler =
let
  val _ = setStartCdataSectionHandler startHandler
  val _ = setEndCdataSectionHandler   endHandler
in
  ()
end

(* -------------------------------------------------------------------------- *)
fun getError () =
let

  val cGetErrorCode =
    _import "XML_GetErrorCode" public: Pt.t -> int;

  val cErrorString =
    _import "XML_ErrorString" public: int -> Pt.t;

  val cGetLine =
    _import "XML_GetCurrentLineNumber" public: Pt.t ->int;

  val cGetColumn =
    _import "XML_GetCurrentColumnNumber" public: Pt.t ->int;

  val p = getPointer parser
  val errorCode = cGetErrorCode p
  val error = ExpatErrors.errorFromCode errorCode
  val str = fetchCString (cErrorString errorCode)
  val line = cGetLine p
  val col = cGetColumn p

in
  Error (error, str, line, col)
end

(* -------------------------------------------------------------------------- *)
fun parse str isFinal =
let

  val cParse =
    _import "XML_Parse" public: (Pt.t * string * int * bool) -> int;

  val p = getPointer parser
  val res = cParse (p, str, String.size str, isFinal)
in
  if res = 0 then
    raise (getError ())
  else
    ()
end

(* -------------------------------------------------------------------------- *)
end
