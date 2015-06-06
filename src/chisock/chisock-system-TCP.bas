#include "chisock-system.bi"

namespace chi
	
	function TCP_client _ 
		( _ 
			byref result as uint32_t, _ 
			byref info as socket_info, _
			byref server_ as string, _ 
			byval port as int32_t _ 
		) as int32_t
	
		dim as uint32_t ip = resolve( server_ )
		if( ip = NOT_AN_IP ) then
			return FAILED_RESOLVE
		end if
		
		function = TCP_client( result, info, ip, port )
		
	end function
	
	function TCP_client _ 
		( _ 
			byref result as uint32_t, _ 
			byref info as socket_info, _
			byval ip as int32_t, _ 
			byval port as int32_t _ 
		) as int32_t
	
		dim as uint32_t new_sock = new_socket( AF_INET, SOCK_STREAM, IPPROTO_IP )
		if new_sock = SOCKET_ERROR then
			return FAILED_INIT
		end if
	
		function = client_core( result, info, ip, port, new_sock )
	
	end function
	
	function TCP_server _ 
		( _ 
			byref result as uint32_t, _ 
			byref info as socket_info, _
			byval port as int32_t, _ 
			byval max_queue as int32_t _ 
		) as int32_t
	
		dim as uint32_t res = new_socket( AF_INET, SOCK_STREAM, IPPROTO_IP ), func_res
		if( res = SOCKET_ERROR ) then 
			return FAILED_INIT
		end if
	
		func_res = server_core( result, info, port, , res )
		if( func_res <> SOCKET_OK ) then
			return func_res
		end if
	
		if listen( result, max_queue ) = SOCKET_ERROR then
			result = SOCKET_ERROR
			return FAILED_LISTEN
		end if
	
	end function
	
	function TCP_accept _ 
		( _ 
			byref result as uint32_t, _ 
			byref client_info as sockaddr_in ptr, _ 
			byval listener as uint32_t _ 
		) as int32_t 
		
		dim as integer size = len(sockaddr_in)
		dim as sockaddr_in discard
		
		result = accept( listener, _ 
		                 cast(any ptr, iif( client_info, client_info, @discard )), _ 
		                 varptr(size) )
		
		if( result = SOCKET_ERROR ) then
			exit function
		end if
		
		function = -1
		
	end function
		
	function TCP_server_accept _ 
		( _ 
			byref result as uint32_t, _ 
			byref then_ as double, _ 
			byref client_info as sockaddr_in ptr, _ 
			byval listener as uint32_t _ 
		) as int32_t 
		
		dim as uint32_t socket
		dim as double now_ = timer
		dim as int32_t func_res
		
		if( listener ) then
			if( then_ = 0 ) then
				func_res = TCP_accept( socket, client_info, listener )
			else
				do
					if( is_readable( listener ) ) then
						func_res = TCP_accept( socket, client_info, listener )
						exit do
					end if
		    
					if( abs(timer-now_) >= then_ ) then 
						exit do
					end if
		    
					sleep 1, 1
				loop
			end if
		end if
		
	    if( func_res = -1 ) then
	    	swap socket, result
			function = -1
	    end if
		
	end function
	
end namespace