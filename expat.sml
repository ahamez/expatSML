(* -------------------------------------------------------------------------- *)
structure Expat : EXPAT = struct

(* -------------------------------------------------------------------------- *)
structure Pt = MLton.Pointer
structure Fz = MLton.Finalizable
structure Ar = Array
open ExpatUtil

(* -------------------------------------------------------------------------- *)
type parser = Pt.t Fz.t * int Ar.array
type startTagHandler      = string -> (string * string) list -> unit
type endTagHandler        = string -> unit
type characterDataHandler = string -> unit
type commentHandler       = string -> unit
type startCdataHandler    = unit -> unit
type endCdataHandler      = unit -> unit

(* -------------------------------------------------------------------------- *)
exception DoNotPanic
exception Error of ExpatErrors.error * string * int * int
exception CannotReset

(* -------------------------------------------------------------------------- *)
(* Return the parser stored in a Finalizable *)
fun getPointer p = Fz.withValue (p, fn x => x)

(* -------------------------------------------------------------------------- *)
structure HandlerType0STLElement : STLELEMENT = struct

  type t = (unit -> unit)
  fun default () = ()

end

structure HT0V = STLVectorFun (structure E = HandlerType0STLElement)

(* -------------------------------------------------------------------------- *)
structure HandlerType1STLElement : STLELEMENT = struct

  type t = (string -> unit)
  fun default _ = ()

end

structure HT1V = STLVectorFun (structure E = HandlerType1STLElement)

(* -------------------------------------------------------------------------- *)
structure HandlerType2STLElement : STLELEMENT = struct

  type t = (string -> (string * string) list -> unit)
  fun default _ _ = ()

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
fun mkParser () =
let

  val cCreate  =
    _import "XML_ParserCreate" public: Pt.t -> Pt.t;

  val cFree    =
    _import "XML_ParserFree" public: Pt.t -> unit;

  val cSetUserData =
    _import "XML_SetUserData" public: (Pt.t * int Ar.array) -> unit;

  val cRes     = cCreate Pt.null
  val res      = Fz.new cRes
  (* Will free the parser when res is no longer reachable in SML *)
  val _        = Fz.addFinalizer (res, fn x => cFree x)

  (* '0' content => no associated handler *)
  val handlers = Ar.array (64, 0)
  val _        = cSetUserData (cRes, handlers)
in
  (res, handlers)
end

(* -------------------------------------------------------------------------- *)
fun parserReset (x, handlers) =
let

  val cReset  =
    _import "XML_ParserReset" public: (Pt.t * Pt.t) -> int;

  val p = getPointer x

in
  if cReset (p, Pt.null) = 1 then
    (x, handlers)
  else
    raise CannotReset
end

(* -------------------------------------------------------------------------- *)
fun setStartElementHandler (x, handlers) handlerOpt =
let

  val cSetHandler =
    _import "C_SetStartElementHandler" public: Pt.t -> unit;

  val cUnsetHandler =
    _import "C_UnsetStartElementHandler" public: Pt.t -> unit;

  fun callStartHandler (0, _, _) = raise DoNotPanic
  |   callStartHandler (pos, cName, cAttrs) =
  let

    fun loop acc ptr =
      (* end of attributes *)
      if Pt.getPointer(ptr, 0) = Pt.null then
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
    HT2V.at startHandlers (pos - 1) name attrs
  end

  val cCallStartHandler =
    _export "SML_callStartHandler" : (int * Pt.t * Pt.t -> unit) -> unit;
  val _ = cCallStartHandler callStartHandler

  val p = getPointer x

  val _ = case handlerOpt of
            NONE   => cUnsetHandler p
          | SOME h =>
          let
            val pos = HT2V.size (HT2V.pushBack startHandlers h)
            val _ = Ar.update (handlers, startHandlerIndex, pos)
            val _ = cSetHandler p
          in
            ()
          end
in
  (x, handlers)
end

(* -------------------------------------------------------------------------- *)
fun setEndElementHandler (x, handlers) handlerOpt =
let

  val cSetHandler =
    _import "C_SetEndElementHandler" public: Pt.t -> unit;

  val cUnsetHandler =
    _import "C_UnsetEndElementHandler" public: Pt.t -> unit;

  fun callEndHandler (0, _) = raise DoNotPanic
  |   callEndHandler (pos, data) =
    HT1V.at endHandlers (pos - 1) (fetchCString data)

  val cCallEndHandler =
    _export "SML_callEndHandler" : (int * Pt.t -> unit) -> unit;
  val _ = cCallEndHandler callEndHandler

  val p = getPointer x

  val _ = case handlerOpt of
            NONE   => cUnsetHandler p
          | SOME h =>
          let
            val pos = HT1V.size (HT1V.pushBack endHandlers h)
            val _ = Ar.update (handlers, endHandlerIndex, pos)
            val _ = cSetHandler p
          in
            ()
          end

in
  (x, handlers)
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
fun setCharacterDataHandler (x, handlers) handlerOpt =
let

  val cSetHandler  =
    _import "C_SetCharacterDataHandler" public: Pt.t -> unit;

  val cUnsetHandler =
    _import "C_UnsetCharacterDataHandler" public: Pt.t -> unit;

  fun callbackHandler (0, _, _) = raise DoNotPanic
  |   callbackHandler (pos, data, len) =
    HT1V.at characterDataHandlers (pos -1 ) (fetchCStringWithSize data len)

  val cCall =
    _export "SML_callCharacterDataHandler" : (int * Pt.t * int -> unit) -> unit;
  val _ = cCall callbackHandler

  val p   = getPointer x
  val _ = case handlerOpt of
            NONE   => cUnsetHandler p
          | SOME h =>
          let
            val pos = HT1V.size (HT1V.pushBack characterDataHandlers h)
            val _ = Ar.update (handlers, characterDataHandlerIndex, pos)
            val _ = cSetHandler p
          in
            ()
          end

in
  (x, handlers)
end

(* -------------------------------------------------------------------------- *)
fun setCommentHandler (x, handlers) handlerOpt =
let

  val cSetHandler  =
    _import "C_SetCommentHandler" public: Pt.t -> unit;

  val cUnsetHandler =
    _import "C_UnsetCommentHandler" public: Pt.t -> unit;

  fun callbackHandler (0, _) = raise DoNotPanic
  |   callbackHandler (pos, data) =
    HT1V.at commentHandlers (pos-1) (fetchCString data)

  val cCall =
    _export "SML_callCommentHandler" : (int * Pt.t -> unit) -> unit;
  val _ = cCall callbackHandler

  val p   = getPointer x
  val _ = case handlerOpt of
            NONE   => cUnsetHandler p
          | SOME h =>
          let
            val pos = HT1V.size (HT1V.pushBack commentHandlers h)
            val _ = Ar.update (handlers, commentHandlerIndex, pos)
            val _ = cSetHandler p
          in
            ()
          end
in
  (x, handlers)
end

(* -------------------------------------------------------------------------- *)
fun setStartCdataSectionHandler (x, handlers) handlerOpt =
let

  val cSetHandler  =
    _import "C_SetStartCdataHandler" public: Pt.t -> unit;

  val cUnsetHandler =
    _import "C_UnsetStartCdataHandler" public: Pt.t -> unit;

  fun callbackHandler 0   = raise DoNotPanic
  |   callbackHandler pos =
    HT0V.at startCdataHandlers (pos-1) ()

  val cCall =
    _export "SML_callStartCdataHandler" : (int -> unit) -> unit;
  val _ = cCall callbackHandler

  val p   = getPointer x
  val _ = case handlerOpt of
            NONE   => cUnsetHandler p
          | SOME h =>
          let
            val pos = HT0V.size (HT0V.pushBack startCdataHandlers h)
            val _ = Ar.update (handlers, startCdataHandlerIndex, pos)
            val _ = cSetHandler p
          in
            ()
          end
in
  (x, handlers)
end

(* -------------------------------------------------------------------------- *)
fun setEndCdataSectionHandler (x, handlers) handlerOpt =
let

  val cSetHandler  =
    _import "C_SetEndCdataHandler" public: Pt.t -> unit;

  val cUnsetHandler =
    _import "C_UnsetEndCdataHandler" public: Pt.t -> unit;

  fun callbackHandler 0   = raise DoNotPanic
  |   callbackHandler pos =
    HT0V.at endCdataHandlers (pos-1) ()

  val cCall =
    _export "SML_callEndCdataHandler" : (int -> unit) -> unit;
  val _ = cCall callbackHandler

  val p   = getPointer x
  val _ = case handlerOpt of
            NONE   => cUnsetHandler p
          | SOME h =>
          let
            val pos = HT0V.size (HT0V.pushBack endCdataHandlers h)
            val _ = Ar.update (handlers, endCdataHandlerIndex, pos)
            val _ = cSetHandler p
          in
            ()
          end
in
  (x, handlers)
end

(* -------------------------------------------------------------------------- *)
fun getError (x, handlers) =
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
fun parse (x, handlers) str isFinal =
let

  val cParse =
    _import "XML_Parse" public: (Pt.t * string * int * bool) -> int;

  val p = getPointer x
  val res = cParse (p, str, String.size str, isFinal)
in
  if res = 0 then
    raise (getError (x, handlers))
  else
    (x, handlers)
end

(* -------------------------------------------------------------------------- *)
end
