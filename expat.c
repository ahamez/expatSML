#include <expat.h>
#include "export.h"

static void
dispatch_start_tag_handler(void* data, const char* el, const char** attr)
{
  const int pos = ((int*)data)[0];
  SML_callStartHandler(pos, (void*)el, (void*)attr);
}

static void
dispatch_end_tag_handler(void* data, const char* el)
{
  const int pos = ((int*)data)[1];
  SML_callEndHandler(pos, (void*)el);
}

static void
dispatch_text_handler(void* data, const char* el, int len)
{
  const int pos = ((int*)data)[2];
  SML_callTextHandler(pos, (void*)el, len);
}

void
C_SetElementHandler(XML_Parser p)
{
  XML_SetElementHandler(p, dispatch_start_tag_handler, dispatch_end_tag_handler);
}

void
C_SetTextHandler(XML_Parser p)
{
  XML_SetCharacterDataHandler(p, dispatch_text_handler);
}
