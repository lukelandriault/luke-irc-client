#include "chisock.bi"

namespace chi
	
	function socket.client _
			( _ 
				byval ip as int32_t, _
				byval port as int32_t _
			) as int32_t
			
		dim as int32_t sock_back, result = TCP_client( sock_back, cnx_info, ip, port )
		if( result = SOCKET_OK ) then
			p_kind = SOCK_TCP
			swap p_socket, sock_back
		end if
		function = result
		
	end function
		
	function socket.client _
		( _ 
			byref server_ as string, _
			byval port as int32_t _
		) as int32_t
		
		dim as int32_t sock_back, result = TCP_client( sock_back, cnx_info, server_, port )
		if( result = SOCKET_OK ) then
			p_kind = SOCK_TCP
			swap p_socket, sock_back
		end if
		function = result
		
	end function
	
	function socket.server _
		( _ 
			byval port as int32_t, _
			byval max_queue as int32_t = 4 _
		) as int32_t
		
		dim as int32_t sock_back, result = TCP_server( sock_back, cnx_info, port, max_queue )
		if( result = SOCKET_OK ) then
			p_kind = SOCK_TCP
			swap p_listener, sock_back
		end if
		function = result
		
	end function
	
	function socket.listen _ 
		( _ 
			byref timeout as double _ 
		) as int32_t 
		function = TCP_server_accept( p_socket, timeout, cast(sockaddr_in ptr, @cnx_info), p_listener )
	end function
	
	function socket.listen_to_new _ 
		( _ 
			byref listener as socket, _ 
			byval timeout as double _ 
		) as int32_t 
		function = TCP_server_accept( p_socket, timeout, cast(sockaddr_in ptr, @cnx_info), listener.p_listener )
	end function
	
end namespace