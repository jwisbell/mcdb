#ifndef INCLUDED_NSS_MCDB_NETDB_H
#define INCLUDED_NSS_MCDB_NETDB_H

enum {
  NSS_H_ADDRTYPE =  0,
  NSS_H_LENGTH   =  8,
  NSS_HE_MEM_STR = 16,
  NSS_HE_LST_STR = 20,
  NSS_HE_MEM     = 24,
  NSS_HE_MEM_NUM = 28,
  NSS_HE_LST_NUM = 32,
  NSS_HE_HDRSZ   = 36
};

enum {
  NSS_N_NET      =  0,
  NSS_N_ADDRTYPE =  8,
  NSS_NE_MEM_STR = 16,
  NSS_NE_MEM     = 20,
  NSS_NE_MEM_NUM = 24,
  NSS_NE_HDRSZ   = 28
};

enum {
  NSS_P_PROTO    =  0,
  NSS_PE_MEM_STR =  8,
  NSS_PE_MEM     = 12,
  NSS_PE_MEM_NUM = 16,
  NSS_PE_HDRSZ   = 20
};

enum {
  NSS_R_NUMBER   =  0,
  NSS_RE_MEM_STR =  8,
  NSS_RE_MEM     = 12,
  NSS_RE_MEM_NUM = 16,
  NSS_RE_HDRSZ   = 20
};

enum {
  NSS_S_PORT     =  0,
  NSS_S_NAME     =  8,
  NSS_SE_MEM_STR = 12,
  NSS_SE_MEM     = 16,
  NSS_SE_MEM_NUM = 20,
  NSS_SE_HDRSZ   = 24
};


/* _BSD_SOURCE or _SVID_SOURCE for struct rpcent on Linux */
#ifndef _BSD_SOURCE
#define _BSD_SOURCE
#endif

#include "nss_mcdb.h"
#include "code_attributes.h"

#include <netdb.h>

void _nss_mcdb_sethostent(void);
void _nss_mcdb_endhostent(void);
void _nss_mcdb_setnetent(void);
void _nss_mcdb_endnetent(void);
void _nss_mcdb_setprotoent(void);
void _nss_mcdb_endprotoent(void);
void _nss_mcdb_setrpcent(void);
void _nss_mcdb_endrpcent(void);
void _nss_mcdb_setservent(void);
void _nss_mcdb_endservent(void);

nss_status_t
_nss_mcdb_gethostent_r(struct hostent * restrict, char * restrict, size_t,
                       int * restrict, int * restrict)
  __attribute_nonnull__  __attribute_warn_unused_result__;

nss_status_t
_nss_mcdb_gethostbyname2_r(const char * restrict, int,
                           struct hostent * restrict, char * restrict, size_t,
                           int * restrict, int * restrict)
  __attribute_nonnull__  __attribute_warn_unused_result__;

nss_status_t
_nss_mcdb_gethostbyname_r(const char * restrict,
                          struct hostent * restrict, char * restrict, size_t,
                          int * restrict, int * restrict)
  __attribute_nonnull__  __attribute_warn_unused_result__;

nss_status_t
_nss_mcdb_gethostbyaddr_r(const void * restrict, socklen_t, int,
                          struct hostent * restrict, char * restrict, size_t,
                          int * restrict, int * restrict)
  __attribute_nonnull__  __attribute_warn_unused_result__;

#if 0  /* implemented, but not enabling by default; often used only with NIS+ */

void _nss_mcdb_setnetgrent(void);
void _nss_mcdb_endnetgrent(void);

nss_status_t
_nss_mcdb_getnetgrent_r(char ** restrict, char ** restrict, char ** restrict,
                        char * restrict, size_t, int * restrict)
  __attribute_nonnull__  __attribute_warn_unused_result__;

#endif

nss_status_t
_nss_mcdb_getnetent_r(struct netent * restrict, char * restrict, size_t,
                      int * restrict, int * restrict)
  __attribute_nonnull__  __attribute_warn_unused_result__;

nss_status_t
_nss_mcdb_getnetbyname_r(const char * restrict,
                         struct netent * restrict, char * restrict, size_t,
                         int * restrict, int * restrict)
  __attribute_nonnull__  __attribute_warn_unused_result__;

nss_status_t
_nss_mcdb_getnetbyaddr_r(const uint32_t, int,
                         struct netent * restrict, char * restrict, size_t,
                         int * restrict, int * restrict)
  __attribute_nonnull__  __attribute_warn_unused_result__;

nss_status_t
_nss_mcdb_getprotoent_r(struct protoent * restrict, char * restrict, size_t,
                        int * restrict)
  __attribute_nonnull__  __attribute_warn_unused_result__;

nss_status_t
_nss_mcdb_getprotobyname_r(const char * restrict,
                           struct protoent * restrict, char * restrict, size_t,
                           int * restrict)
  __attribute_nonnull__  __attribute_warn_unused_result__;

nss_status_t
_nss_mcdb_getprotobynumber_r(int,
                             struct protoent * restrict, char * restrict,size_t,
                             int * restrict)
  __attribute_nonnull__  __attribute_warn_unused_result__;

nss_status_t
_nss_mcdb_getrpcent_r(struct rpcent * restrict, char * restrict, size_t,
                      int * restrict)
  __attribute_nonnull__  __attribute_warn_unused_result__;

nss_status_t
_nss_mcdb_getrpcbyname_r(const char * restrict,
                         struct rpcent * restrict, char * restrict, size_t,
                         int * restrict)
  __attribute_nonnull__  __attribute_warn_unused_result__;

nss_status_t
_nss_mcdb_getrpcbynumber_r(int,
                           struct rpcent * restrict, char * restrict, size_t,
                           int * restrict)
  __attribute_nonnull__  __attribute_warn_unused_result__;

nss_status_t
_nss_mcdb_getservent_r(struct servent * restrict, char * restrict, size_t,
                       int * restrict)
  __attribute_nonnull__  __attribute_warn_unused_result__;

nss_status_t
_nss_mcdb_getservbyname_r(const char * restrict, const char * restrict,
                          struct servent * restrict, char * restrict, size_t,
                          int * restrict)
  __attribute_nonnull__  __attribute_warn_unused_result__;

nss_status_t
_nss_mcdb_getservbyport_r(int, const char * restrict,
                          struct servent * restrict, char * restrict, size_t,
                          int * restrict)
  __attribute_nonnull__  __attribute_warn_unused_result__;


#endif
