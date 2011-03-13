(* -------------------------------------------------------------------------- *)
structure Expat : EXPAT = struct

(* -------------------------------------------------------------------------- *)
structure Pt = MLton.Pointer
structure Fz = MLton.Finalizable
structure Ar = Array
open ExpatUtil

(* -------------------------------------------------------------------------- *)
type parser = Pt.t Fz.t * int Ar.array

(* -------------------------------------------------------------------------- *)
exception Error of ExpatErrors.error * string * int * int
exception CannotReset

(* -------------------------------------------------------------------------- *)
(* Return the parser stored in a Finalizable *)
fun getPointer p = Fz.withValue (p, fn x => x)

(* -------------------------------------------------------------------------- *)
structure SimpleHandlerSTLElement : STLELEMENT = struct

  type t = (string -> unit)
  fun default x = ()

end

structure SHV = STLVectorFun (structure E = SimpleHandlerSTLElement)

(* -------------------------------------------------------------------------- *)
structure StartHandlerSTLElement : STLELEMENT = struct

  type t = (string -> (string * string) list -> unit)
  fun default x ys = ()

end

structure StHV = STLVectorFun (structure E = StartHandlerSTLElement)

(* -------------------------------------------------------------------------- *)
(* Global registry of all handlers for all parsers.
   Needed by callbacks called from the C side to dispatch on the correct
   function.
*)
val startHandlers          = StHV.STLVector NONE
val endHandlers            = SHV.STLVector NONE
val characterDataHandlers  = SHV.STLVector NONE

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

  (* 3 entries:
      - pos 0 => startHandler
      - pos 1 => endHandler
      - pos 2 => textHandler

    '0' content => no associated handler
  *)
  val handlers = Ar.array (3, 0)
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
fun registerHandler handlers handler =
  SHV.size (SHV.pushBack handlers handler)

(* -------------------------------------------------------------------------- *)
fun callStartHandler (0, _, _) = ()
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
  StHV.at startHandlers (pos - 1) name attrs
end

(* -------------------------------------------------------------------------- *)
fun callEndHandler (0, _) = ()
|   callEndHandler (pos, data) =
  SHV.at endHandlers (pos - 1) (fetchCString data)

(* -------------------------------------------------------------------------- *)
fun callCharacterDataHandler (0, _, _) = ()
|   callCharacterDataHandler (pos, data, len) =
  SHV.at characterDataHandlers (pos -1 ) (fetchCStringWithSize data len)

(* -------------------------------------------------------------------------- *)
fun setElementHandlers (x, handlers) startHandler endHandler =
let

  val cSetElementHandler  =
    _import "C_SetElementHandler" public: Pt.t -> unit;

  val cCallStartHandler =
    _export "SML_callStartHandler" : (int * Pt.t * Pt.t -> unit) -> unit;
  val _ = cCallStartHandler callStartHandler

  val cCallEndHandler =
    _export "SML_callEndHandler" : (int * Pt.t -> unit) -> unit;
  val _ = cCallEndHandler callEndHandler

  val p = getPointer x
  val startPos = StHV.size (StHV.pushBack startHandlers startHandler)
  val endPos   = SHV.size  (SHV.pushBack endHandlers endHandler)
  val _ = Ar.update (handlers, 0, startPos)
  val _ = Ar.update (handlers, 1, endPos)
  val _ = cSetElementHandler p
in
  (x, handlers)
end

(* -------------------------------------------------------------------------- *)
fun setCharacterDataHandler (x, handlers) handler =
let

  val cSetCharacterDataHandler  =
    _import "C_SetCharacterDataHandler" public: Pt.t -> unit;

  val cCallCharacterDataHandler =
    _export "SML_callCharacterDataHandler" : (int * Pt.t * int -> unit) -> unit;
  val _ = cCallCharacterDataHandler callCharacterDataHandler

  val p   = getPointer x
  val pos = SHV.size (SHV.pushBack characterDataHandlers handler)
  val _   = Ar.update (handlers, 2, pos)
  val _   = cSetCharacterDataHandler p
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
