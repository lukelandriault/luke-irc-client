#include "chisock-system.bi"

#ifdef __fb_win32__
	dim shared as WSAData w
	if( WSAStartup( (1 shl 8) or 1, @w ) <> 0 ) then
	end if
#endif

namespace chi
	
	operator socket_info.cast( ) as string
		operator = "{address: " & *inet_ntoa( data.sin_addr ) & ", port: " & ntohs( data.sin_port ) & "}"
	end operator
	
	operator socket_info.cast( ) as sockaddr ptr
		operator = cast(sockaddr ptr, @data)
	end operator
	
	function base_HTTP_path( byref thing as string ) as string
		var res = instr( thing, "/" )
		if( res = 0 ) then
			function = thing
		else
			function = left( thing, res - 1 )
		end if
	end function
	
	function translate_error _ 
		( _ 
			byval err_code as int32_t _
		) as string
		
		select case as const err_code
			case SOCKET_OK
				return "No error"
			case FAILED_INIT
				return "Failed initialization"
			case FAILED_RESOLVE
				return "Failed to resolve host"
			case FAILED_CONNECT
				return "Failed connection"
			case FAILED_REUSE
				return "Failed to reuse socket"
			case FAILED_BIND
				return "Failed to bind socket"
			case FAILED_LISTEN
				return "Failed listening"
		end select
	end function
	
	function resolve _ 
		( _ 
			byref host as string _ 
		) as uint32_t
		
		if len( host ) = 0 then
		   return NOT_AN_IP
		EndIf
	 	dim as string host_temp = host
		dim as uint32_t ip = inet_addr( host_temp )
		if( ip = NOT_AN_IP ) then
		 	host_temp = base_HTTP_path( ltrim( host_temp, "http://" ) )
	      
#Ifdef __FB_WIN32__
   'gethostbyname( ) method

			dim as hostent ptr info = gethostbyname( host_temp )
			if( info = NULL ) then
				return NOT_AN_IP
			end if
			function = *cast( uint32_t ptr, info->h_addr )
			
#Else
   'getaddrinfo( ) method
         
         Dim As addrinfo hints
         Dim As addrinfo Ptr servinfo
         Dim As sockaddr_in Ptr addr
         
         'hints.ai_flags = AI_NUMERICHOST
         hints.ai_family = PF_INET
         hints.ai_socktype = SOCK_STREAM

         If( getaddrinfo( host_temp, NULL, @hints, @servinfo ) <> 0 ) Then
            Return NOT_AN_IP
         End If
                         
         While servinfo->ai_family <> AF_INET
            servinfo = servinfo->ai_next
         Wend
         
         addr = cast( sockaddr_in Ptr, servinfo->ai_addr )
         
         function = *cptr( uint32_t Ptr, @( addr->sin_addr ) )
         freeaddrinfo( servinfo )
         
#EndIf

		else
			function = ip
		end if
	
	end function
	
	function client_core _ 
		( _ 
			byref result as uint32_t, _ 
			byref info as socket_info, _
			byval ip as int32_t, _ 
			byval port as int32_t, _ 
			byval from_socket as uint32_t, _ 
			byval do_connect as int32_t = TRUE _
		) as int32_t
		
		dim as long reuse = C_TRUE
		
		if( setsockopt( from_socket, _ 
		               SOL_SOCKET, _ 
		               SO_REUSEADDR, _ 
		               cast(any ptr, @reuse), _ 
		               len(long) ) = SOCKET_ERROR ) then 
			return FAILED_REUSE
		end if
		
		if( do_connect = TRUE ) then
			info = type( AF_INET, htons( port ), ip )
			
			var res = connect( from_socket, cast(sockaddr ptr, @info), len(info) )
			if( res = SOCKET_ERROR ) then
				return FAILED_CONNECT
			end if
		end if
		
		result = from_socket
	
	end function
	
	function server_core _ 
		( _ 
			byref result as uint32_t, _ 
			byref info as socket_info, _
			byval port as int32_t, _ 
			byval ip as int32_t, _
			byval from_socket as uint32_t _
		) as int32_t
	
	#if 0
	   'don't want to reuse..
		dim as int32_t reuse = C_TRUE
		if( setsockopt( from_socket, _ 
		               SOL_SOCKET, _ 
		               SO_REUSEADDR, _ 
		               cast(any ptr, @reuse), _ 
		               len(long) ) = SOCKET_ERROR ) then 
			return FAILED_REUSE
		end if
   #endif
	    
		info = type( AF_INET, htons( port ), ip )
		if bind( from_socket, _ 
		         cast(sockaddr ptr, @info), _ 
		         len(info) ) = SOCKET_ERROR then 
			return FAILED_BIND
		end if
	
		result = from_socket
	
	end function
	
	function close _
		( _ 
			byval sock_ as uint32_t _ 
		) as int32_t
		dim as int32_t res=any
		#ifdef __FB_Win32__
			res = closesocket( sock_ )
		#else
			res = shutdown( sock_, SHUT_RDWR )
		#endif
		function = res
	end function
	
	function is_readable _
		( _ 
			byval sock_ as ulong _ 
		) as int32_t
		
		if( sock_ = SOCKET_ERROR ) then
			exit function
		end if
		
		dim as fd_set set 
		fd_zero( @set )
		fd_set_( sock_, @set )
	
		dim as ulongint timeout = 1
		select_( sock_+1, @set, NULL, NULL, cast(timeval ptr, @timeout) )
	
		return (FD_ISSET( sock_, @set ) <> 0)
		
	end function
	
	function new_sockaddr overload( byval serv as int32_t, byval port as short ) as socket_info ptr
		function = new socket_info( AF_INET, htons( port ), serv )
	end function
	
	function new_sockaddr( byref serv as string, byval port as short ) as socket_info ptr
		var ip = resolve( serv )
		if( ip = NOT_AN_IP ) then
			exit function
		end if
		
		function = new_sockaddr( ip, port )
	end function
	
end namespace
