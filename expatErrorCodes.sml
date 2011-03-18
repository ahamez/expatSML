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

structure ExpatErrors = struct

  datatype error = NO_ERROR
                 | NO_MEMORY
                 | SYNTAX
                 | NO_ELEMENTS
                 | INVALID_TOKEN
                 | UNCLOSED_TOKEN
                 | PARTIAL_CHAR
                 | TAG_MISMATCH
                 | DUPLICATE_ATTRIBUTE
                 | JUNK_AFTER_DOC_ELEMENT
                 | PARAM_ENTITY_REF
                 | UNDEFINED_ENTITY
                 | RECURSIVE_ENTITY_REF
                 | ASYNC_ENTITY
                 | BAD_CHAR_REF
                 | BINARY_ENTITY_REF
                 | ATTRIBUTE_EXTERNAL_ENTITY_REF
                 | MISPLACED_XML_PI
                 | UNKNOWN_ENCODING
                 | INCORRECT_ENCODING
                 | UNCLOSED_CDATA_SECTION
                 | EXTERNAL_ENTITY_HANDLING
                 | NOT_STANDALONE
                 | UNEXPECTED_STATE
                 | ENTITY_DECLARED_IN_PE
                 | FEATURE_REQUIRES_XML_DTD
                 | CANT_CHANGE_FEATURE_ONCE_PARSING
                 | UNBOUND_PREFIX
                 | UNDECLARING_PREFIX
                 | INCOMPLETE_PE
                 | XML_DECL
                 | TEXT_DECL
                 | PUBLICID
                 | SUSPENDED
                 | NOT_SUSPENDED
                 | ABORTED
                 | FINISHED
                 | SUSPEND_PE
                 | RESERVED_PREFIX_XML
                 | RESERVED_PREFIX_XMLNS
                 | RESERVED_NAMESPACE_URI

  fun errorFromCode code =
    case code of
        0  => NO_ERROR
     |  1  => NO_MEMORY
     |  2  => SYNTAX
     |  3  => NO_ELEMENTS
     |  4  => INVALID_TOKEN
     |  5  => UNCLOSED_TOKEN
     |  6  => PARTIAL_CHAR
     |  7  => TAG_MISMATCH
     |  8  => DUPLICATE_ATTRIBUTE
     |  9  => JUNK_AFTER_DOC_ELEMENT
     | 10  => PARAM_ENTITY_REF
     | 11  => UNDEFINED_ENTITY
     | 12  => RECURSIVE_ENTITY_REF
     | 13  => ASYNC_ENTITY
     | 14  => BAD_CHAR_REF
     | 15  => BINARY_ENTITY_REF
     | 16  => ATTRIBUTE_EXTERNAL_ENTITY_REF
     | 17  => MISPLACED_XML_PI
     | 18  => UNKNOWN_ENCODING
     | 19  => INCORRECT_ENCODING
     | 20  => UNCLOSED_CDATA_SECTION
     | 21  => EXTERNAL_ENTITY_HANDLING
     | 22  => NOT_STANDALONE
     | 23  => UNEXPECTED_STATE
     | 24  => ENTITY_DECLARED_IN_PE
     | 25  => FEATURE_REQUIRES_XML_DTD
     | 26  => CANT_CHANGE_FEATURE_ONCE_PARSING
     | 27  => UNBOUND_PREFIX
     | 28  => UNDECLARING_PREFIX
     | 29  => INCOMPLETE_PE
     | 30  => XML_DECL
     | 31  => TEXT_DECL
     | 32  => PUBLICID
     | 33  => SUSPENDED
     | 34  => NOT_SUSPENDED
     | 35  => ABORTED
     | 36  => FINISHED
     | 37  => SUSPEND_PE
     | 38  => RESERVED_PREFIX_XML
     | 39  => RESERVED_PREFIX_XMLNS
     | 40  => RESERVED_NAMESPACE_URI
     | _   => raise Domain

end
