#Define fbc *.bas -lib -mt -x chisock -w 1
#include "chisock.bi"

namespace chi
	
	constructor socket( )
		
		p_recv_lock   = mutexcreate( )
		p_send_lock   = mutexcreate( )
	    p_go_lock     = mutexcreate( )
	    p_hold_lock   = mutexcreate( )
	    
	    p_go_signal   = condcreate( )
	    p_hold_signal = condcreate( )
	    
		p_socket   = SOCKET_ERROR
		p_listener = SOCKET_ERROR
		
		p_recv_thread = threadcreate( @recv_proc, @this, 10140 )
		p_send_thread = threadcreate( @send_proc, @this, 10140 )
		
		p_recv_data = allocate( RECV_BUFF_SIZE )
		p_send_data = allocate( SEND_BUFF_SIZE )
		
	end constructor
	
	destructor socket( )

		hold = FALSE
		
		mutexlock( p_send_lock )
		mutexlock( p_recv_lock )
		
		p_send_size = 0
		p_send_caret = 0
		
		close( )
		
		p_dead = TRUE
		
		mutexunlock( p_send_lock )
		mutexunlock( p_recv_lock )

		threadwait( p_recv_thread )
		threadwait( p_send_thread )

		conddestroy( p_go_signal )
		conddestroy( p_hold_signal )

		mutexdestroy( p_recv_lock )
		mutexdestroy( p_send_lock )
		mutexdestroy( p_go_lock )
		mutexdestroy( p_hold_lock )

		deallocate( p_recv_data )
		deallocate( p_send_data )
		
	end destructor
	
	'' ghetto-sync
	property socket.hold( byval state as int32_t )
		
		select case state
		case TRUE
			
			mutexlock( p_hold_lock )
			
			p_hold = TRUE
			
			condwait( p_hold_signal, p_hold_lock )
			
			mutexunlock( p_hold_lock )
			
			mutexlock( p_go_lock )
			mutexunlock( p_go_lock )
			
		case FALSE
			
			p_hold = FALSE
			
			condsignal( p_go_signal )
			
		end select
		
	end property
	
	function socket.length _ 
		( _ 
		) as int32_t
		
		function = p_recv_size-p_recv_caret
		
	end Function
		
	function socket.close _ 
		( _ 
		) as int32_t
		
		if( ( p_socket = SOCKET_ERROR ) and ( p_listener = SOCKET_ERROR ) ) then exit function
		
		do while (p_send_size or p_send_caret)
			sleep 26, 1
		loop		
	
		dim as socket_lock r_lock = p_recv_lock, s_lock = p_send_lock
		dim as int32_t s=any, res=SOCKET_OK

		if( p_socket <> SOCKET_ERROR ) then
			s = SOCKET_ERROR
			swap p_socket, s
			res = chi.close( s )
		end if

		if( res = SOCKET_OK ) then
			if( p_listener <> SOCKET_ERROR ) then
				s = SOCKET_ERROR
				swap p_listener, s
				res = chi.close( s ) 
			end if
		end if		

		function = res
		
	end function
	
	function socket.is_closed _ 
		( _ 
		) as int32_t
		
		function = ((p_socket = SOCKET_ERROR) and (p_listener = SOCKET_ERROR))
		
	end function
	
	property socket.recv_limit _ 
		( _ 
			byref limit as int32_t _ 
		)
		
		mutexlock( p_recv_lock )
		p_recv_limit = limit
		mutexunlock( p_recv_lock )
		
	end property
	
	property socket.send_limit _ 
		( _ 
			byref limit as int32_t _ 
		)
		
		mutexlock( p_send_lock )
		p_send_limit = limit
		mutexunlock( p_send_lock )
		
	end property
	
	property socket.recv_limit _ 
		( _ 
		) as int32_t
		
		mutexlock( p_recv_lock )
		property = p_recv_limit
		mutexlock( p_recv_lock )
		
	end property
	
	property socket.send_limit _ 
		( _ 
		) as int32_t
		
		mutexlock( p_send_lock )
		property = p_send_limit
		mutexunlock( p_send_lock )
		
	end property
	
	function socket.send_rate _ 
		( _ 
		) as int32_t
		
		mutexlock( p_send_lock )
		function = p_send_rate
		mutexunlock( p_send_lock )

	end function
	
	function socket.recv_rate _ 
		( _ 
		) as int32_t
		
		mutexlock( p_recv_lock )
		function = p_recv_rate
		mutexunlock( p_recv_lock )
		
	end function
	
	function socket.connection_info _ 
		( _
		) as socket_info ptr
		
		function = @cnx_info
		
	end function
	
end namespace