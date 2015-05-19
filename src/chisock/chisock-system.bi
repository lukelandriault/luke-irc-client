#pragma once

#include "crt.bi"

#ifdef __fb_win32__

	#define SO_SNDTIMEO &h1005

	#include "winsockets.bi"
	#inclib "user32"

#endif

#ifdef __fb_linux__

	#include "crt/sys/select.bi"
	#include "crt/arpa/inet.bi"
	#include "crt/netdb.bi"
	#include "crt/unistd.bi"

	#define h_addr h_addr_list[0]

#endif

#undef socket
#undef TRUE
#undef FALSE
#undef opaque

const as int32_t TRUE = (0 = 0), FALSE = (0 = 1)

namespace chi
	
	const as int32_t C_TRUE = 1
	
	enum SOCKET_ERRORS
	
		SOCKET_OK
		FAILED_INIT
		FAILED_RESOLVE
		FAILED_CONNECT
		FAILED_REUSE
		FAILED_BIND
		FAILED_LISTEN
	
	end enum
	
	type socket_info
		
		data as sockaddr_in
		declare property port( ) as ushort
		
		declare operator cast( ) as string
		declare operator cast( ) as sockaddr ptr
		
	end type
	
	declare function translate_error _ 
		( _ 
			byval err_code as int32_t _
		) as string
	
	declare function resolve _ 
		( _ 
			byref host as string _ 
		) as uint32_t
	
	declare function TCP_client overload _ 
		( _ 
			byref result as uint32_t, _ 
			byref info as socket_info, _ 
			byref server as string, _ 
			byval port as int32_t _ 
		) as int32_t
	
	declare function TCP_client overload _ 
		( _ 
			byref result as uint32_t, _ 
			byref info as socket_info, _ 
			byval ip as int32_t, _ 
			byval port as int32_t _ 
		) as int32_t
	
	declare function client_core _ 
		( _ 
			byref result as uint32_t, _ 
			byref info as socket_info, _ 
			byval ip as int32_t, _ 
			byval port as int32_t, _ 
			byval from_socket as uint32_t, _ 
			byval do_connect as int32_t = TRUE _
		) as int32_t
	
	declare function TCP_server _ 
		( _ 
			byref result as uint32_t, _ 
			byref info as socket_info, _ 
			byval port as int32_t, _ 
			byval max_queue as int32_t = 4 _ 
		) as int32_t
	
	declare function TCP_server_accept _ 
		( _ 
			byref result as uint32_t, _ 
			byref timeout as double, _ 
			byref client_info as sockaddr_in ptr, _ 
			byval listener as uint32_t _ 
		) as int32_t 
		
	declare function server_core _ 
		( _ 
			byref result as uint32_t, _ 
			byref info as socket_info, _ 
			byval port as int32_t, _ 
			byval ip as int32_t = INADDR_ANY, _
			byval from_socket as uint32_t _
		) as int32_t
	
	declare function UDP_server _ 
		( _ 
			byref result as uint32_t, _ 
			byref info as socket_info, _ 
			byval port as int32_t, _
			byval ip as int32_t = INADDR_ANY _
		) as int32_t
	
	declare function UDP_client overload _ 
		( _ 
			byref result as uint32_t _ 
		) as int32_t
	
	declare function UDP_client _ 
		( _ 
			byref result as uint32_t, _
			byref info as socket_info, _ 
			byref server_ as string, _ 
			byval port_ as int32_t _ 
		) as int32_t
		
	declare function UDP_client _ 
		( _ 
			byref result as uint32_t, _ 
			byref info as socket_info, _
			byref ip as int32_t, _ 
			byval port_ as int32_t _ 
		) as int32_t
		
	declare function is_readable _ 
		( _ 
			byval socket_ as uint32_t _ 
		) as int32_t
	
	declare function close _
		( _ 
			byval sock_ as uint32_t _ 
		) as int32_t
	
	declare function new_sockaddr overload( byval serv as int32_t, byval port as short ) as socket_info ptr
	declare function new_sockaddr( byref serv as string, byval port as short ) as socket_info ptr

	declare	function base_HTTP_path( byref thing as string ) as string

	const as uint32_t NOT_AN_IP = -1
	
	#define new_socket socket_
	
end namespace
