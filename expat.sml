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
type parser = Pt.t Fz.t * int
type startTagHandler      = parser -> string -> (string * string) list -> unit
type endTagHandler        = parser -> string -> unit
type characterDataHandler = parser -> string -> unit
type commentHandler       = parser -> string -> unit
type startCdataHandler    = parser -> unit
type endCdataHandler      = parser -> unit

(* -------------------------------------------------------------------------- *)
exception Error of ExpatErrors.error * string * int * int
exception CannotReset

(* -------------------------------------------------------------------------- *)
(* Return the parser stored in a Finalizable *)
fun getPointer p = Fz.withValue (p, fn x => x)

(* -------------------------------------------------------------------------- *)
structure HandlerType0STLElement : STLELEMENT = struct

  type t = (parser -> unit)
  fun default _ = ()

end

structure HT0V = STLVectorFun (structure E = HandlerType0STLElement)

(* -------------------------------------------------------------------------- *)
structure HandlerType1STLElement : STLELEMENT = struct

  type t = (parser -> string -> unit)
  fun default _ _ = ()

end

structure HT1V = STLVectorFun (structure E = HandlerType1STLElement)

(* -------------------------------------------------------------------------- *)
structure HandlerType2STLElement : STLELEMENT = struct

  type t = (parser -> string -> (string * string) list -> unit)
  fun default _ _ _ = ()

end

structure HT2V = STLVectorFun (structure E = HandlerType2STLElement)

(* -------------------------------------------------------------------------- *)
(* Global registry of all handlers for all parsers.
   Needed by callbacks called from the C side to dispatch on the correct
   function.
*)
val startHandlerIndex         = 0
val startHandlers             = HT2V.STLVector NONE

val endHandlerIndex           = 1
val endHandlers               = HT1V.STLVector NONE

val characterDataHandlerIndex = 2
val characterDataHandlers     = HT1V.STLVector NONE

val commentHandlerIndex       = 3
val commentHandlers           = HT1V.STLVector NONE

val startCdataHandlerIndex    = 4
val startCdataHandlers        = HT0V.STLVector NONE

val endCdataHandlerIndex      = 5
val endCdataHandlers          = HT0V.STLVector NONE

(* -------------------------------------------------------------------------- *)
(* The storage of callbacks indices is handled by the C side.
   Otherwise, a Standard ML arrary might be moved by the GC and
   thus its pointer given to C would be invalid.
*)

(* #define MAX_PARSERS in expat.c *)
val maxParsers  = 64
(* #define MAX_HANDLERS in expat.c *)
val maxHandlers = 64

val cSetParserHandler =
  _import "C_setParserHandlerCallback" : int * int * int -> unit;

val cInitParserHandlers =
  _import "C_initParserHandlers" : unit -> unit;
val _ = cInitParserHandlers ()

(* We need to affect a unique identifier to each parser in order to associate
   each parser a list of callbacks indices.
*)
val nextParserId = ref 0

(* -------------------------------------------------------------------------- *)
(* Global registry of all parsers, indexed by their pid *)
val parsers = Ar.array (maxParsers, Fz.new Pt.null)

(* -------------------------------------------------------------------------- *)
fun mkParser () =
let

  val cCreate  =
    _import "XML_ParserCreate" public: Pt.t -> Pt.t;

  val cFree    =
    _import "XML_ParserFree" public: Pt.t -> unit;

  val cSetUserData =
    _import "XML_SetUserData" public: (Pt.t * Pt.t) -> unit;

  val cGetParserPtr =
    _import "C_getParserHandlersPtr" public: int -> Pt.t;

  val cRes     = cCreate Pt.null
  val res      = Fz.new cRes
  (* Will free the parser when res is no longer reachable in SML *)
  val _        = Fz.addFinalizer (res, fn x => cFree x)

  val pid      = !nextParserId
  val _        = nextParserId := !nextParserId + 1
  (* Register in global val parsers *)
  val _        = Ar.update (parsers, pid, res)

  (* We use the user data facility of expat to store the address of the array
     that contains the indices of the callbacks to the user's handlers.
  *)
  val ptr      = cGetParserPtr pid
  val _        = cSetUserData (cRes, ptr)
in
  (res, pid)
end

(* -------------------------------------------------------------------------- *)
(*fun setUserData (x, pid) data =*)

(* -------------------------------------------------------------------------- *)
fun parserReset (x, pid) =
let

  val cReset  =
    _import "XML_ParserReset" public: (Pt.t * Pt.t) -> int;

  val p = getPointer x

in
  if cReset (p, Pt.null) = 1 then
    (x, pid)
  else
    raise CannotReset
end

(* -------------------------------------------------------------------------- *)
fun setStartElementHandler (x, pid) handlerOpt =
let

  val cSetHandler =
    _import "C_SetStartElementHandler" public: Pt.t -> unit;

  val cUnsetHandler =
    _import "C_UnsetStartElementHandler" public: Pt.t -> unit;

  fun callbackHandler (pid, pos, cName, cAttrs) =
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
    val p = Ar.sub(parsers, pid)

  in
    HT2V.at startHandlers pos (p, pid) name attrs
  end

  val cCall =
    _export "SML_callStartHandler" : (int * int * Pt.t * Pt.t -> unit) -> unit;
  val _ = cCall callbackHandler

  val p = getPointer x
  val _ = case handlerOpt of
            NONE   => cUnsetHandler p
          | SOME h =>
          let
            val pos = HT2V.size (HT2V.pushBack startHandlers h)
            val _   = cSetParserHandler (pid, startHandlerIndex, pos-1)
            val _   = cSetHandler p
          in
            ()
          end
in
  (x, pid)
end

(* -------------------------------------------------------------------------- *)
fun setEndElementHandler (x, pid) handlerOpt =
let

  val cSetHandler =
    _import "C_SetEndElementHandler" public: Pt.t -> unit;

  val cUnsetHandler =
    _import "C_UnsetEndElementHandler" public: Pt.t -> unit;

  fun callbackHandler (pid, pos, data) =
  let
    val p = Ar.sub(parsers, pid)
  in
    HT1V.at endHandlers pos (p, pid) (fetchCString data)
  end

  val cCall =
    _export "SML_callEndHandler" : (int * int * Pt.t -> unit) -> unit;
  val _ = cCall callbackHandler

  val p = getPointer x
  val _ = case handlerOpt of
            NONE   => cUnsetHandler p
          | SOME h =>
          let
            val pos = HT1V.size (HT1V.pushBack endHandlers h)
            val _   = cSetParserHandler (pid, endHandlerIndex, pos-1)
            val _   = cSetHandler p
          in
            ()
          end

in
  (x, pid)
end

(* -------------------------------------------------------------------------- *)
fun setElementHandler x startHandlerOpt endHandlerOpt =
let
  val _ = setStartElementHandler x startHandlerOpt
  val _ = setEndElementHandler x endHandlerOpt
in
  x
end

(* -------------------------------------------------------------------------- *)
fun setCharacterDataHandler (x, pid) handlerOpt =
let
  val cSetHandler  =
    _import "C_SetCharacterDataHandler" public: Pt.t -> unit;

  val cUnsetHandler =
    _import "C_UnsetCharacterDataHandler" public: Pt.t -> unit;

  fun callbackHandler (pid, pos, data, len) =
  let
    val p = Ar.sub(parsers, pid)
  in
    HT1V.at characterDataHandlers pos (p, pid) (fetchCStringWithSize data len)
  end

  val cCall =
    _export "SML_callCharacterDataHandler" : (int * int * Pt.t * int -> unit)
                                             -> unit;
  val _ = cCall callbackHandler

  val p = getPointer x
  val _ = case handlerOpt of
            NONE   => cUnsetHandler p
          | SOME h =>
          let
            val pos = HT1V.size (HT1V.pushBack characterDataHandlers h)
            val _   = cSetParserHandler (pid, characterDataHandlerIndex, pos-1)
            val _   = cSetHandler p
          in
            ()
          end

in
  (x, pid)
end

(* -------------------------------------------------------------------------- *)
fun setCommentHandler (x, pid) handlerOpt =
let
  val cSetHandler  =
    _import "C_SetCommentHandler" public: Pt.t -> unit;

  val cUnsetHandler =
    _import "C_UnsetCommentHandler" public: Pt.t -> unit;

  fun callbackHandler (pid, pos, data) =
  let
    val p = Ar.sub(parsers, pid)
  in
    HT1V.at commentHandlers pos (p, pid) (fetchCString data)
  end

  val cCall =
    _export "SML_callCommentHandler" : (int * int * Pt.t -> unit) -> unit;
  val _ = cCall callbackHandler

  val p = getPointer x
  val _ = case handlerOpt of
            NONE   => cUnsetHandler p
          | SOME h =>
          let
            val pos = HT1V.size (HT1V.pushBack commentHandlers h)
            val _   = cSetParserHandler (pid, commentHandlerIndex, pos-1)
            val _   = cSetHandler p
          in
            ()
          end
in
  (x, pid)
end

(* -------------------------------------------------------------------------- *)
fun setStartCdataSectionHandler (x, pid) handlerOpt =
let
  val cSetHandler  =
    _import "C_SetStartCdataHandler" public: Pt.t -> unit;

  val cUnsetHandler =
    _import "C_UnsetStartCdataHandler" public: Pt.t -> unit;

  fun callbackHandler (pid, pos) =
  let
    val p = Ar.sub(parsers, pid)
  in
    HT0V.at startCdataHandlers pos (p,pid)
  end

  val cCall =
    _export "SML_callStartCdataHandler" : (int * int -> unit) -> unit;
  val _ = cCall callbackHandler

  val p = getPointer x
  val _ = case handlerOpt of
            NONE   => cUnsetHandler p
          | SOME h =>
          let
            val pos = HT0V.size (HT0V.pushBack startCdataHandlers h)
            val _   = cSetParserHandler (pid, startCdataHandlerIndex, pos-1)
            val _   = cSetHandler p
          in
            ()
          end
in
  (x, pid)
end

(* -------------------------------------------------------------------------- *)
fun setEndCdataSectionHandler (x, pid) handlerOpt =
let
  val cSetHandler  =
    _import "C_SetEndCdataHandler" public: Pt.t -> unit;

  val cUnsetHandler =
    _import "C_UnsetEndCdataHandler" public: Pt.t -> unit;

  fun callbackHandler (pid, pos) =
  let
    val p = Ar.sub(parsers, pid)
  in
    HT0V.at endCdataHandlers pos (p,pid)
  end

  val cCall =
    _export "SML_callEndCdataHandler" : (int * int -> unit) -> unit;
  val _ = cCall callbackHandler

  val p = getPointer x
  val _ = case handlerOpt of
            NONE   => cUnsetHandler p
          | SOME h =>
          let
            val pos = HT0V.size (HT0V.pushBack endCdataHandlers h)
            val _   = cSetParserHandler (pid, endCdataHandlerIndex, pos-1)
            val _   = cSetHandler p
          in
            ()
          end
in
  (x, pid)
end

(* -------------------------------------------------------------------------- *)
fun setCdataSectionHandler x startHandler endHandler =
let
  val _ = setStartCdataSectionHandler x startHandler
  val _ = setEndCdataSectionHandler x endHandler
in
  x
end

(* -------------------------------------------------------------------------- *)
fun getError (x, _) =
let

  val cGetErrorCode =
    _import "XML_GetErrorCode" public: Pt.t -> int;

  val cErrorString =
    _import "XML_ErrorString" public: int -> Pt.t;

  val cGetLine =
    _import "XML_GetCurrentLineNumber" public: Pt.t ->int;

  val cGetColumn =
    _import "XML_GetCurrentColumnNumber" public: Pt.t ->int;

  val p = getPointer x
  val errorCode = cGetErrorCode p
  val error = ExpatErrors.errorFromCode errorCode
  val str = fetchCString (cErrorString errorCode)
  val line = cGetLine p
  val col = cGetColumn p

in
  Error (error, str, line, col)
end

(* -------------------------------------------------------------------------- *)
fun parse (x, pid) str isFinal =
let

  val cParse =
    _import "XML_Parse" public: (Pt.t * string * int * bool) -> int;

  val p = getPointer x
  val res = cParse (p, str, String.size str, isFinal)
in
  if res = 0 then
    raise (getError (x, pid))
  else
    (x, pid)
end

(* -------------------------------------------------------------------------- *)
end
