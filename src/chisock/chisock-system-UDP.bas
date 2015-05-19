#include "chisock-system.bi"

namespace chi
	
	function UDP_client _ 
		( _ 
			byref result as uint32_t _ 
		) as int32_t
	
		dim as uint32_t res = new_socket( AF_INET, SOCK_DGRAM, IPPROTO_IP )
		if( res = SOCKET_ERROR ) then 
			return FAILED_INIT
		end if
		
		dim as socket_info cnx
		function = client_core( result, cnx, INADDR_ANY, 0, res, FALSE )
		
	end function
	
	function UDP_client _ 
		( _ 
			byref result as uint32_t, _ 
			byref info as socket_info, _
			byref server_ as string, _ 
			byval port_ as int32_t _ 
		) as int32_t
	
		dim as int32_t ip = resolve( server_ )
		if( ip = NOT_AN_IP ) then
			return FAILED_RESOLVE
		end if
		
		function = UDP_client( result, info, ip, port_ )
		
	end function
	
	function UDP_client _ 
		( _ 
			byref result as uint32_t, _ 
			byref info as socket_info, _
			byref ip as int32_t, _ 
			byval port_ as int32_t _ 
		) as int32_t
	
		dim as uint32_t res = new_socket( AF_INET, SOCK_DGRAM, IPPROTO_IP )
		if( res = SOCKET_ERROR ) then 
			return FAILED_INIT
		end if
		
		function = client_core( result, info, ip, port_, res, TRUE )
	
	end function
	
	function UDP_server _ 
		( _ 
			byref result as uint32_t, _ 
			byref info as socket_info, _
			byval port as int32_t, _
			byval ip as int32_t _
		) as int32_t
	
		dim as uint32_t res = new_socket( AF_INET, SOCK_DGRAM, IPPROTO_IP )
		if( res = SOCKET_ERROR ) then 
			return FAILED_INIT
		end if
	
		function = server_core( result, info, port, ip, res )
	
	end function

end namespace