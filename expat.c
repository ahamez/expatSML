// Copyright LAAS/CNRS (2011)
//
// Contributors:
// - Alexandre Hamez <alexandre.hamez@gmail.com>
//
// This software is governed by the CeCILL-B license under French law and
// abiding by the rules of distribution of free software. You can use, modify
// and/ or redistribute the software under the terms of the CeCILL-B license as
// circulated by CEA, CNRS and INRIA at the following URL
// "http://www.cecill.info".
//
// The fact that you are presently reading this means that you have had
// knowledge of the CeCILL-B license and that you accept its terms.
//
// You should have received a copy of the CeCILL-B license along with expatSML.
// See the file LICENSE.

#include <expat.h>
#include "SMLExpat.h"

////////////////////////////////////////////////////////////////////////////////

// C_* functions are imported by SML
// SML_* functions are exported by SML

////////////////////////////////////////////////////////////////////////////////

static void
callbackStartTagHandler(void* data, const char* el, const char** attr)
{
  const int pos = ((int*)data)[0];
  SML_callStartHandler(pos, (void*)el, (void*)attr);
}

void
C_SetStartElementHandler(XML_Parser p)
{
  XML_SetStartElementHandler(p, callbackStartTagHandler);
}

void
C_UnsetStartElementHandler(XML_Parser p)
{
  XML_SetStartElementHandler(p, NULL);
}

////////////////////////////////////////////////////////////////////////////////

static void
callbackEndTagHandler(void* data, const char* el)
{
  const int pos = ((int*)data)[1];
  SML_callEndHandler(pos, (void*)el);
}

void
C_SetEndElementHandler(XML_Parser p)
{
  XML_SetEndElementHandler(p, callbackEndTagHandler);
}

void
C_UnsetEndElementHandler(XML_Parser p)
{
  XML_SetEndElementHandler(p, NULL);
}

////////////////////////////////////////////////////////////////////////////////

static void
callbackCharacterDataHandler(void* data, const char* el, int len)
{
  const int pos = ((int*)data)[2];
  SML_callCharacterDataHandler(pos, (void*)el, len);
}

void
C_SetCharacterDataHandler(XML_Parser p)
{
  XML_SetCharacterDataHandler(p, callbackCharacterDataHandler);
}

void
C_UnsetCharacterDataHandler(XML_Parser p)
{
  XML_SetCharacterDataHandler(p, NULL);
}

////////////////////////////////////////////////////////////////////////////////

static void
callbackCommentHandler(void* data, const char* el)
{
  const int pos = ((int*)data)[3];
  SML_callCommentHandler(pos, (void*)el);
}

void
C_SetCommentHandler(XML_Parser p)
{
  XML_SetCommentHandler(p, callbackCommentHandler);
}

void
C_UnsetCommentHandler(XML_Parser p)
{
  XML_SetCommentHandler(p, NULL);
}

////////////////////////////////////////////////////////////////////////////////

static void
callbackStartCdataHandler(void* data)
{
  const int pos = ((int*)data)[4];
  SML_callStartCdataHandler(pos);
}

void
C_SetStartCdataHandler(XML_Parser p)
{
  XML_SetStartCdataSectionHandler(p, callbackStartCdataHandler);
}

void
C_UnsetStartCdataHandler(XML_Parser p)
{
  XML_SetStartCdataSectionHandler(p, NULL);
}

////////////////////////////////////////////////////////////////////////////////

static void
callbackEndCdataHandler(void* data)
{
  const int pos = ((int*)data)[5];
  SML_callEndCdataHandler(pos);
}

void
C_SetEndCdataHandler(XML_Parser p)
{
  XML_SetEndCdataSectionHandler(p, callbackEndCdataHandler);
}

void
C_UnsetEndCdataHandler(XML_Parser p)
{
  XML_SetEndCdataSectionHandler(p, NULL);
}
