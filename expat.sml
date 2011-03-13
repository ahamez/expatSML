(* -------------------------------------------------------------------------- *)
(* -------------------------------------------------------------------------- *)
signature EXPAT = sig

  type parser

  val mkParser           : unit -> parser
  val setElementHandlers : parser
                           (* start tag handler *)
                           -> (string -> (string * string) list -> unit)
                           (* end tag handler *)
                           -> (string -> unit)
                           -> parser
  val setTextHandler     : parser
                           (* text handler *)
                           -> (string -> unit)
                           -> parser
  val parseString        : parser -> string -> unit

  exception DoNotPanic

end

(* -------------------------------------------------------------------------- *)
(* -------------------------------------------------------------------------- *)
structure Expat : EXPAT = struct

(* -------------------------------------------------------------------------- *)
structure Pt = MLton.Pointer
structure Fz = MLton.Finalizable
structure Ar = Array

(* -------------------------------------------------------------------------- *)
type parser = Pt.t Fz.t * int Ar.array

(* -------------------------------------------------------------------------- *)
exception DoNotPanic

(* -------------------------------------------------------------------------- *)
fun getPointer p = Fz.withValue (p, fn x => x)

(* -------------------------------------------------------------------------- *)
val cSetUserData =
  _import "XML_SetUserData" public: (Pt.t * int Ar.array) -> unit;

(* -------------------------------------------------------------------------- *)
(* Global registry of all handlers for all parsers.
   Needed by callbacks called from the C side to dispatch on the correct
   function.
*)
val startHandlers = ref []
val endHandlers   = ref []
val textHandlers  = ref []

(* -------------------------------------------------------------------------- *)
fun mkParser () =
let
  val cCreate  = _import "XML_ParserCreate" public: Pt.t -> Pt.t;
  val cFree    = _import "XML_ParserFree" public: Pt.t -> unit;
  val cRes     = cCreate Pt.null
  val res      = Fz.new cRes
  val _        = Fz.addFinalizer (res, fn x => cFree x)
  (* pos 0 => startHandler
     pos 1 => endHandler
     pos 2 => textHandler

    '0' content => no associated handler
  *)
  val handlers = Ar.array (3, 0)
  val _        = cSetUserData (cRes, handlers)
in
  (res, handlers)
end

(* -------------------------------------------------------------------------- *)
fun strlen p =
let
  fun loop i =
    if 0w0 = MLton.Pointer.getWord8 (p, i) then
      i
    else
      loop (i + 1)
in
  loop 0
end

(* -------------------------------------------------------------------------- *)
fun fetchCString p =
  CharVector.tabulate ( strlen p
                      , fn i => Byte.byteToChar (MLton.Pointer.getWord8 (p,i))
                      )

(* -------------------------------------------------------------------------- *)
fun fetchCStringWithSize p len =
  CharVector.tabulate ( len
                      , fn i => Byte.byteToChar (MLton.Pointer.getWord8 (p,i))
                      )

(* -------------------------------------------------------------------------- *)
fun registerStartHandler handler =
let
  val _ = startHandlers := !startHandlers @ [handler]
in
  length (!startHandlers)
end

(* -------------------------------------------------------------------------- *)
fun registerEndHandler handler =
let
  val _ = endHandlers := !endHandlers @ [handler]
in
  length (!endHandlers)
end

(* -------------------------------------------------------------------------- *)
fun registerTextHandler handler =
let
  val _ = textHandlers := !textHandlers @ [handler]
in
  length (!textHandlers)
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
val cCallStartHandler =
  _export "SML_callStartHandler" : (int * Pt.t * Pt.t -> unit) -> unit;
val _ = cCallStartHandler callStartHandler

(* -------------------------------------------------------------------------- *)
fun callEndHandler (0, _) = ()
|   callEndHandler (pos, data) =
  List.nth (!endHandlers, pos - 1) (fetchCString data)

(* -------------------------------------------------------------------------- *)
val cCallEndHandler =
  _export "SML_callEndHandler" : (int * Pt.t -> unit) -> unit;
val _ = cCallEndHandler callEndHandler

(* -------------------------------------------------------------------------- *)
fun callTextHandler (0, _, _) = ()
|   callTextHandler (pos, data, len) =
  List.nth (!textHandlers, pos - 1) (fetchCStringWithSize data len)

(* -------------------------------------------------------------------------- *)
val cCallTextHandler =
  _export "SML_callTextHandler" : (int * Pt.t * int -> unit) -> unit;
val _ = cCallTextHandler callTextHandler

(* -------------------------------------------------------------------------- *)
fun setElementHandlers (x, handlers) stardHandler endHandler =
let

  val cSetElementHandler  =
    _import "C_SetElementHandler" public: Pt.t -> unit;

  val p = getPointer x
  val startPos = registerStartHandler stardHandler
  val endPos   = registerEndHandler endHandler
  val _ = Ar.update (handlers, 0, startPos)
  val _ = Ar.update (handlers, 1, endPos)
  val _ = cSetElementHandler p
in
  (x, handlers)
end

(* -------------------------------------------------------------------------- *)
fun setTextHandler (x, handlers) handler =
let

  val cSetTextHandler  =
    _import "C_SetTextHandler" public: Pt.t -> unit;

  val p   = getPointer x
  val pos = registerTextHandler handler
  val _   = Ar.update (handlers, 2, pos)
  val _   = cSetTextHandler p
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

(* -------------------------------------------------------------------------- *)
(* -------------------------------------------------------------------------- *)
