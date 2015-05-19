#pragma once

#include "chisock-system.bi"
#include "crt.bi"

'' we don't need C's variables
#undef socket
#undef TRUE
#undef FALSE

const as int32_t TRUE = (0 = 0), FALSE = (0 = 1)

#undef quick_len
#define quick_len(_s) cast(integer ptr, @_s)[1]

#macro DECLARE_SOCKET_GET(t)
	declare function get overload _ 
		( _ 
			byref data_ as t, _
			byref elems as int32_t = 1, _ 
			byval time_out as int32_t = ONLY_ONCE, _ 
			byval peek_only as int32_t = FALSE _
		) as int32_t
#endmacro
		
#macro DECLARE_SOCKET_PUT(t)
	declare function put overload _ 
		( _ 
			byref data_ as t, _
			byref elems as int32_t = 1, _ 
			byval time_out as int32_t = 0 _ 
		) as int32_t
#endmacro

#undef CR_LF		
#define CR_LF !"\r\n"

#define BUILD_IP( _1, _2, _3, _4 ) _ 
	( ( ( _4 and 255 ) shl 24 ) or _ 
	  ( ( _3 and 255 ) shl 16 ) or _ 
	  ( ( _2 and 255 ) shl  8 ) or _ 
	  ( ( _1 and 255 ) shl  0 ) )

#define BREAK_IP( _octet, _addr ) ( ( _addr shr ( 8 * _octet ) ) and 255 )

namespace chi
	
	type socket_lock
		
		declare constructor( byval lock_ as any ptr )
		declare destructor( )
		
		lock as any ptr
		
	end type
	
	type socket
		
		enum ACCESS_METHOD
		
			ONLY_ONCE = -1
			BLOCK     = 0
			
		end enum
		
		enum PORT
			
			FTP_DATA    = 20
			FTP_CONTROL = 21
			SSH         = 22
			TELNET      = 23
			GOPHER      = 70
			HTTP        = 80
			SFTP        = 115
			IRC         = 6667
			
		end enum
		
		const as int32_t LOCALHOST = BUILD_IP( 127, 0, 0, 1 )
		
		declare constructor( )
		declare destructor( )
		
		declare function client _
			( _ 
				byval ip as long, _
				byval port as long _
			) as int32_t
		
		declare function client _
			( _ 
				byref server as string, _
				byval port as long _
			) as int32_t
		
		declare function UDP_client _
			( _ 
				byval ip as long, _
				byval port as long _
			) as int32_t
		
		declare function UDP_client _
			( _ 
				byref server as string, _
				byval port as long _
			) as int32_t
		
		declare function UDP_client _
			( _ 
			) as int32_t
		
		declare function server _
			( _ 
				byval port as long, _
				byval max_queue as int32_t = 4 _
			) as int32_t
		
		declare function UDP_server _
			( _ 
				byval port as long, _
				byval ip as long = INADDR_ANY _
			) as int32_t
		
		declare function UDP_connectionless_server _
			( _ 
				byval port as long _
			) as int32_t
		
		declare function listen _ 
			( _ 
				byref timeout as double = 0 _ 
			) as int32_t 
		
		declare function listen_to_new _ 
			( _ 
				byref listener as socket, _ 
				byval timeout as double = 0 _ 
			) as int32_t
		
		declare function get_data _ 
			( _ 
				byval data_ as any ptr, _
				byval size as int32_t, _ 
				byval peek_only as int32_t = FALSE _
			) as int32_t
		
		declare function get_line _ 
			( _ 
			) as string
		
		declare function get_until _ 
			( _ 
				byref target as string _
			) as string
		
		DECLARE_SOCKET_GET(short)
		DECLARE_SOCKET_GET(int32_t)
		DECLARE_SOCKET_GET(double )
		DECLARE_SOCKET_GET(ubyte  )
		DECLARE_SOCKET_GET(string )
			
		declare function put_data _ 
			( _ 
				byval data_ as any ptr, _
				byval size as int32_t   _ 
			) as int32_t
			
		DECLARE_SOCKET_PUT(short)
		DECLARE_SOCKET_PUT(int32_t)
		DECLARE_SOCKET_PUT(double )
		DECLARE_SOCKET_PUT(ubyte  )
		DECLARE_SOCKET_PUT(string )
		
		declare function put_line _ 
			( _ 
				byref text as string _ 
			) as int32_t
		
		declare function put_string _ 
			( _ 
				byref text as string _ 
			) as int32_t
		
		declare function put_HTTP_request _ 
			( _ 
				byref server_name as string, _ 
				byref method      as string = "GET", _ 
				byref post_data   as string = ""     _ 
			) as int32_t
		
		declare function put_IRC_auth _ 
			( _ 
				byref nick as string = "undefined", _ 
				byref realname as string = "undefined", _ 
				byref pass as string = "" _
			) as int32_t
		
		declare function dump_data _ 
			( _ 
				byval size as int32_t _ 
			) as int32_t
			
		declare function length _ 
			( _ 
			) as int32_t
					
		declare function is_closed _ 
			( _ 
			) as int32_t
		
		declare function close _ 
			( _ 
			) as int32_t
		
		declare property recv_limit _ 
			( _ 
				byref limit as int32_t _ 
			)
		
		declare property send_limit _ 
			( _ 
				byref limit as int32_t _ 
			)
		
		declare property recv_limit _ 
			( _ 
			) as int32_t
		
		declare property send_limit _ 
			( _ 
			) as int32_t
		
		declare function recv_rate _ 
			( _ 
			) as int32_t
			
		declare function send_rate _ 
			( _ 
			) as int32_t
		
		declare function set_destination _ 
			( _
				byval info as socket_info ptr = NULL _
			) as int32_t
			
		declare function connection_info _ 
			( _
			) as socket_info ptr
			
		declare property hold _ 
			( _ 
				byval as int32_t _ 
			)
		
		'private:
		
		const as int32_t THREAD_BUFF_SIZE = 1024 * 16
		const as int32_t RECV_BUFF_SIZE = 1024 * 64
		const as int32_t SEND_BUFF_SIZE = 1024 * 16
		
		const as int32_t BUFF_RATE = 10
		
		enum KINDS
			
			SOCK_TCP
			SOCK_UDP
			SOCK_UDP_CONNECTIONLESS
			
		end enum
		
		declare static sub recv_proc _ 
			( _ 
				byval opaque as any ptr _ 
			)
		
		declare static sub send_proc _ 
			(  _ 
				byval opaque as any ptr _ 
			)
		
		as int32_t p_hold
		as any ptr p_hold_lock, p_hold_signal
		as any ptr p_go_lock, p_go_signal
		
		p_send_buff_size  as int32_t = SEND_BUFF_SIZE
		p_send_data       as ubyte ptr
		p_send_caret      as int32_t
		p_send_size       as int32_t
		p_send_thread     as any ptr
		p_send_lock       as any ptr
		p_send_limit      as int32_t
		p_send_accum      as int32_t
		p_send_timer      as double
		p_send_disp_timer as double
		p_send_rate       as int32_t
		p_send_info       as socket_info Ptr
		p_send_sleep      As UShort = 1
		
		p_recv_buff_size  as int32_t = RECV_BUFF_SIZE
		p_recv_data       as ubyte ptr
		p_recv_caret      as int32_t
		p_recv_size       as int32_t
		p_recv_thread     as any ptr
		p_recv_lock       as any ptr
		p_recv_limit      as int32_t
		p_recv_accum      as int32_t
		p_recv_timer      as double
		p_recv_disp_timer as double
		p_recv_rate       as int32_t
		p_recv_info       as socket_info
		p_recv_sleep      As UShort = 1
		
		as socket_info cnx_info
		
		as int32_t p_socket, p_listener
		p_dead as int32_t
		
		p_kind as KINDS
		
	end type
	
end namespace

#define SERIAL_UDT(x) *cast(ubyte ptr, @(x)), len(x)

#inclib "chisock"
