#include <expat.h>
#include "export.h"

static void
SML_start(void* data, const char* el, const char** attr)
{
  const int pos = ((int*)data)[0];
  callStartHandler(pos, (void*)el);
}

static void
SML_end(void* data, const char* el)
{
  const int pos = ((int*)data)[1];
  callEndHandler(pos, (void*)el);
}

void
SML_SetElementHandler(XML_Parser p)
{
  XML_SetElementHandler(p, SML_start, SML_end);
}
