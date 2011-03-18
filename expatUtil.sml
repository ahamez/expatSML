(* Copyright LAAS/CNRS (2011)

Contributors:
- Alexandre Hamez     <alexandre.hamez@gmail.com>
- Bernard Berthomieu  <bernard@laas.fr>

This software is governed by the CeCILL-B license under French law and abiding
by the rules of distribution of free software. You can use, modify and/ or
redistribute the software under the terms of the CeCILL-B license as circulated
by CEA, CNRS and INRIA at the following URL "http://www.cecill.info".

The fact that you are presently reading this means that you have had knowledge
of the CeCILL-B license and that you accept its terms.

You should have received a copy of the CeCILL-B license along with
expatSML-light. See the file LICENSE. *)


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
