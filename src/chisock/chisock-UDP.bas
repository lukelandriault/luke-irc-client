#include "chisock.bi"

namespace chi
	
	function socket.UDP_client _
		( _ 
		) as int32_t
		
		dim as uint32_t sock_back, result = chi.UDP_client( sock_back )
		if( result <> 0 ) then
			return result
		end if
		
		p_kind = SOCK_UDP_CONNECTIONLESS
		swap p_socket, sock_back
		
	end function
		
	function socket.UDP_client _
		( _ 
			byval ip as int32_t, _
			byval port as int32_t _
		) as int32_t
			
		dim as uint32_t sock_back, result = chi.UDP_client( sock_back, cnx_info, ip, port )
		if( result <> 0 ) then
			return result
		end if
		
		p_kind = SOCK_UDP
		swap p_socket, sock_back
		
	end function
		
	function socket.UDP_client _
		( _ 
			byref server_ as string, _
			byval port as int32_t _
		) as int32_t
		
		dim as uint32_t sock_back, result = chi.UDP_client( sock_back, cnx_info, server_, port )
		if( result <> 0 ) then
			return result
		end if
		
		p_kind = SOCK_UDP
		swap p_socket, sock_back
		
	end function
	
	function socket.UDP_server _
		( _ 
			byval port as int32_t, _
			byval ip as int32_t _
		) as int32_t
		
		dim as uint32_t sock_back, result = chi.UDP_server( sock_back, cnx_info, port, ip )
		if( result <> 0 ) then
			return result
		end if
		
		p_kind = SOCK_UDP
		swap p_socket, sock_back
		
	end function
	
	function socket.UDP_connectionless_server _
		( _ 
			byval port as int32_t _
		) as int32_t
		
		dim as socket_info info
		dim as uint32_t sock_back, result = chi.UDP_server( sock_back, info, port, INADDR_ANY )
		if( result <> 0 ) then
			return result
		end if
		
		p_kind = SOCK_UDP_CONNECTIONLESS
		swap p_socket, sock_back
		
	end function
	
	function socket.set_destination _ 
		( _
			byval info as socket_info ptr _
		) as int32_t
		
		if( p_kind <> SOCK_UDP_CONNECTIONLESS ) then
			exit function
		end if
		
		if( p_send_info ) then
			delete p_send_info
		end if
		
		p_send_info = new socket_info
		if( info ) then
			*p_send_info = *info
		else
			*p_send_info = p_recv_info
		end if
		
		function = TRUE
		
	end function
	
end namespace