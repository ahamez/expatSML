(* -------------------------------------------------------------------------- *)
(* -------------------------------------------------------------------------- *)
signature EXPAT = sig

  type parser
  type tagHandler = string -> unit

  val mkParser    : unit -> parser
  val setHandlers : parser 
                    -> tagHandler (* start handler *)
                    -> tagHandler (* end handler   *)
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

(* -------------------------------------------------------------------------- *)
type parser = Pt.t Fz.t
type tagHandler = string -> unit

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
val (startHandlers : tagHandler list ref) = ref []
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
fun callStartHandler (pos, data) =
  List.nth (!startHandlers, pos) (fetchCString data)

val cCallStartHandler =
  _export "callStartHandler" : (int * Pt.t -> unit) -> unit;
val _ = cCallStartHandler callStartHandler

(* -------------------------------------------------------------------------- *)
fun callEndHandler (pos, data) =
  List.nth (!endHandlers, pos) (fetchCString data)

val cCallEndHandler =
  _export "callEndHandler" : (int * Pt.t -> unit) -> unit;
val _ = cCallEndHandler callEndHandler

(* -------------------------------------------------------------------------- *)
fun setHandlers x stardHandler endHandler =
let

  val cSetElementHandler  =
    _import "SML_SetElementHandler" public: Pt.t -> unit;
  val cSetUserData =
    _import "XML_SetUserData" public: (Pt.t * int Array.array) -> unit;

  val p = getPointer x
  val startPos = registerStartHandler stardHandler
  val endPos   = registerEndHandler endHandler
  val arr = Array.fromList [startPos,endPos]
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
