#include <expat.h>
#include "SMLExpat.h"

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
dispatch_character_data_handler(void* data, const char* el, int len)
{
  const int pos = ((int*)data)[2];
  SML_callCharacterDataHandler(pos, (void*)el, len);
}

// All C_* functions are imported by the SML side

void
C_SetElementHandler(XML_Parser p)
{
  XML_SetElementHandler(p, dispatch_start_tag_handler, dispatch_end_tag_handler);
}

void
C_SetCharacterDataHandler(XML_Parser p)
{
  XML_SetCharacterDataHandler(p, dispatch_character_data_handler);
}
