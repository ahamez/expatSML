#include <expat.h>
#include "export.h"

static void
dispatch_start_tag(void* data, const char* el, const char** attr)
{
  const int pos = ((int*)data)[0];
  SML_callStartHandler(pos, (void*)el, (void*)attr);
}

static void
dispatch_end_tag(void* data, const char* el)
{
  const int pos = ((int*)data)[1];
  SML_callEndHandler(pos, (void*)el);
}

void
C_SetElementHandler(XML_Parser p)
{
  XML_SetElementHandler(p, dispatch_start_tag, dispatch_end_tag);
}
