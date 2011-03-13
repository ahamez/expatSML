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
exception DoNotPanic
exception CannotReset

(* -------------------------------------------------------------------------- *)
(* Return the parser stored in a Finalizable *)
fun getPointer p = Fz.withValue (p, fn x => x)

(* -------------------------------------------------------------------------- *)
(* Global registry of all handlers for all parsers.
   Needed by callbacks called from the C side to dispatch on the correct
   function.
*)
val startHandlers          = ref []
val endHandlers            = ref []
val characterDataHandlers  = ref []

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
let
  val _ = handlers := !handlers @ [handler]
in
  length (!handlers)
end

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

in
  List.nth (!startHandlers, pos - 1) (fetchCString cName) attrs
end

(* -------------------------------------------------------------------------- *)
fun callEndHandler (0, _) = ()
|   callEndHandler (pos, data) =
  List.nth (!endHandlers, pos - 1) (fetchCString data)

(* -------------------------------------------------------------------------- *)
fun callCharacterDataHandler (0, _, _) = ()
|   callCharacterDataHandler (pos, data, len) =
  List.nth (!characterDataHandlers, pos - 1) (fetchCStringWithSize data len)

(* -------------------------------------------------------------------------- *)
fun setElementHandlers (x, handlers) stardHandler endHandler =
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
  val startPos = registerHandler startHandlers stardHandler
  val endPos   = registerHandler endHandlers endHandler
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
  val pos = registerHandler characterDataHandlers handler
  val _   = Ar.update (handlers, 2, pos)
  val _   = cSetCharacterDataHandler p
in
  (x, handlers)
end

(* -------------------------------------------------------------------------- *)
fun parseString (x, _) str =
let

  val cParse =
    _import "XML_Parse" public: (Pt.t * string * int * bool) -> int;

  val p = getPointer x
  val res = cParse (p, str, String.size str, true)
in
  if res = 0 then
    raise DoNotPanic
  else
    ()
end

(* -------------------------------------------------------------------------- *)
end
