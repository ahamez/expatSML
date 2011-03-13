structure ExpatUtil =
struct

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
fun fetchCStringWithSize p len =
  CharVector.tabulate ( len
                      , fn i => Byte.byteToChar (MLton.Pointer.getWord8 (p,i))
                      )

(* -------------------------------------------------------------------------- *)
fun fetchCString p =
  fetchCStringWithSize p (strlen p)

end