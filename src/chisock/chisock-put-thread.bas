#include "chisock.bi"

namespace chi
	
	sub socket.send_proc( byval opaque as any ptr )
		dim as socket ptr this = opaque
		
		dim as int32_t res, standby, chunk_
		do while( this->p_dead = FALSE )
				
			If( this->p_hold = TRUE ) then 
				
				mutexlock( this->p_hold_lock )
				mutexunlock( this->p_hold_lock )
				
				mutexlock( this->p_go_lock )
				
				condsignal( this->p_hold_signal )
				
				condwait( this->p_go_signal, this->p_go_lock )
				
				mutexunlock( this->p_go_lock )
				
			end if
			
			if( this->p_socket = SOCKET_ERROR ) Then
			   sleep 100, 1
			   continue Do
			EndIf
			
			standby = FALSE
			
			scope
			   
			   dim as socket_lock lock_ = this->p_send_lock			   
			   
   			'' handle speed limits
      		if( this->p_send_limit > 0 ) then
      			
      			if( abs(timer - this->p_send_timer) >= (1 / BUFF_RATE) ) then
      				this->p_send_timer = timer
      				
      				this->p_send_accum -= (this->p_send_limit / BUFF_RATE)
      				
      				if( this->p_send_accum < 0 ) then
      					this->p_send_accum = 0
      				end if
      				
      			end if
      			
      			if( this->p_send_accum < this->p_send_limit ) then
      				chunk_ = this->p_send_limit - this->p_send_accum
      				if chunk_ > ( this->p_send_size - this->p_send_caret ) then
      				   chunk_ = this->p_send_size - this->p_send_caret
      				EndIf
      			else
      				chunk_ = 0
      			end if
      	   
      	   else
      	      chunk_ = this->p_send_size-this->p_send_caret      	      
      	      
      		end if
      		
      		'' update bytes/sec calc... reset counter
      		if( abs(timer - this->p_send_disp_timer) >= 1 ) then
      			
      			this->p_send_rate = this->p_send_accum
      			this->p_send_disp_timer = timer
      			
      			if( this->p_send_limit = 0 ) then
      				this->p_send_accum = 0
      			end if
      			
      		end if
         
         end scope
         
			if chunk_ > 2048 then chunk_ = 2048
			
			'' anything?
			if( chunk_ > 0 ) then
				
				'' send method
				select case as const this->p_kind
				case SOCK_TCP, SOCK_UDP
					
					res = send( this->p_socket, _ 
					            cast(any ptr, @this->p_send_data[this->p_send_caret]), _ 
					            chunk_, _ 
					            0 )
					
				case SOCK_UDP_CONNECTIONLESS
					
					'' send to destination (lock info...)
					if( this->p_send_info ) then
						
						var l = len(*(this->p_send_info))
						res = sendto( this->p_socket, _ 
						              cast(any ptr, @this->p_send_data[this->p_send_caret]), _ 
						              chunk_, _ 
						              0, cast(sockaddr ptr, this->p_send_info), l )
						
					end if
					
				end select
				
				dim as int32_t do_close = FALSE
				select case as const this->p_kind
				case SOCK_TCP
					do_close = (res <= 0)
				case SOCK_UDP
					do_close = (res = -1)
				end select
				
				if( do_close ) then
					
					this->p_send_size = 0
					this->p_send_caret = 0
					
					this->close( )

				end if
				
			else
				
				res = 0
				
			end if
			
			if( res <= 0 ) then
				standby = TRUE
			end if
			
			if( standby = FALSE ) then
				
				dim as socket_lock lock_ = this->p_send_lock
				
				'' update
				this->p_send_caret += res
				this->p_send_accum += res
				
				'' caught up?
				if( this->p_send_caret = this->p_send_size ) then
					this->p_send_size  = 0
					this->p_send_caret = 0
				endif
				
   		else '( standby = TRUE )			
           
   			Sleep this->p_send_sleep, 1
   		
   		endif
			
		loop
		
	end sub
	
end namespace
