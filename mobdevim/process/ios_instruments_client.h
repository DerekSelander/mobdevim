#ifndef IOS_INSTRUMENTS_CLIENT
#define IOS_INSTRUMENTS_CLIENT

#include <Foundation/Foundation.h>
#include "cftypes.h"
#include "mobile_device.h"

//-----------------------------------------------------------------------------
struct DTXMessageHeader
{
  uint32_t magic;
  uint32_t cb;
  uint16_t fragmentId;
  uint16_t fragmentCount;
  uint32_t length;
  uint32_t identifier;
  uint32_t conversationIndex;
  uint32_t channelCode;
  uint32_t expectsReply;
};

//-----------------------------------------------------------------------------
struct DTXMessagePayloadHeader
{
  uint32_t flags;
  uint32_t auxiliaryLength;
  uint64_t totalLength;
};

//------------------------------------------------------------------------------
// helper class for serializing method arguments
class message_aux_t
{
  bytevec_t buf;

public:
  void append_int(int32_t val);
  void append_long(int64_t val);
  void append_obj(CFTypeRef obj);
    void append_obj(id obj);

  void get_bytes(bytevec_t *out) const;
};

bool print_proclist(am_device_service_connection *conn);
bool launch_application(am_device_service_connection *conn, const char *_bid, NSArray* args, NSDictionary* env);
bool perform_handshake(am_device_service_connection *conn);
bool kill(am_device_service_connection *conn, int pid);
void* load_extern_implementation(void);
NSArray* get_proclist_matching_name(am_device_service_connection *conn, NSString *searchedName);
#endif // IOS_INSTRUMENTS_CLIENT
