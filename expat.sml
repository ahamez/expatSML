(* -------------------------------------------------------------------------- *)
(* -------------------------------------------------------------------------- *)
signature EXPAT = sig

  type parser

  val mkParser    : unit -> parser
  val setHandlers : parser 
                       (* start tag handler *)
                    -> (string -> (string * string) list -> unit)
                       (* end tag handler *)
                    -> (string -> unit)
                    -> unit
  val parseString : parser -> string -> unit

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
type parser = Pt.t Fz.t

(* -------------------------------------------------------------------------- *)
exception DoNotPanic

(* -------------------------------------------------------------------------- *)
fun getPointer p = Fz.withValue (p, fn x => x)

(* -------------------------------------------------------------------------- *)
fun mkParser () =
let
  val cCreate = _import "XML_ParserCreate" public: Pt.t -> Pt.t;
  val cFree   = _import "XML_ParserFree" public: Pt.t -> unit;
  val cRes    = cCreate Pt.null
  val res     = Fz.new cRes
  val _       = Fz.addFinalizer (res, fn x => cFree x)
in
  res
end

(* -------------------------------------------------------------------------- *)
val startHandlers = ref []
val endHandlers   = ref []

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
fun registerStartHandler handler =
let
  val _ = startHandlers := !startHandlers @ [handler]
in
  length (!startHandlers) - 1
end

(* -------------------------------------------------------------------------- *)
fun registerEndHandler handler =
let
  val _ = endHandlers := !endHandlers @ [handler]
in
  length (!endHandlers) - 1
end

(* -------------------------------------------------------------------------- *)
fun callStartHandler (pos, cName, cAttrs) =
let

  fun loop acc ptr =
    if Pt.getWord8(ptr, 0) = 0w0 then
      acc
    else
    let
      val attr = fetchCString (Pt.getPointer (ptr, 0))
      val cont = fetchCString (Pt.getPointer (ptr, 1))
    in
      loop ((attr,cont)::acc)
           (Pt.add (ptr, Pt.sizeofPointer * (Word.fromInt 2)))
    end

  val attrs = loop [] cAttrs

in
  List.nth (!startHandlers, pos) (fetchCString cName) attrs
end

val cCallStartHandler =
  _export "SML_callStartHandler" : (int * Pt.t * Pt.t -> unit) -> unit;
val _ = cCallStartHandler callStartHandler

(* -------------------------------------------------------------------------- *)
fun callEndHandler (pos, data) =
  List.nth (!endHandlers, pos) (fetchCString data)

val cCallEndHandler =
  _export "SML_callEndHandler" : (int * Pt.t -> unit) -> unit;
val _ = cCallEndHandler callEndHandler

(* -------------------------------------------------------------------------- *)
fun setHandlers x stardHandler endHandler =
let

  val cSetElementHandler  =
    _import "C_SetElementHandler" public: Pt.t -> unit;
  val cSetUserData =
    _import "XML_SetUserData" public: (Pt.t * int Ar.array) -> unit;

  val p = getPointer x
  val startPos = registerStartHandler stardHandler
  val endPos   = registerEndHandler endHandler
  val arr = Ar.fromList [startPos,endPos]
  val _ = cSetUserData (p, arr)
in
  cSetElementHandler p
end

(* -------------------------------------------------------------------------- *)
fun parseString x str =
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
