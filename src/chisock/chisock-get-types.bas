#include "chisock.bi"

#macro DEFINE_SOCKET_GET(t)
	function socket.get _ 
		( _ 
			byref data_ as t, _
			byref elems as int32_t, _ 
			byval time_out as int32_t, _ 
			byval peek_only as int32_t _
		) as int32_t
		
		var current = cast(ubyte ptr, @data_)
		dim as double then_, now_ = timer
		
		then_ = time_out/1000
		
		dim as int32_t chunk_ = elems*len(t), piece
		if( chunk_ ) then
			do
				dim as int32_t available_data = length( )
				if( chunk_ <= available_data ) then
					piece = chunk_
				else
					piece = available_data
				end if
				if( piece > 0 ) then
					assert(current < @data_ + elems)
					var gotten = this.get_data( current, piece, peek_only )
					if( gotten > 0 ) then
						current += gotten
						chunk_  -= gotten
						if( chunk_ = 0 ) then
							function = len(t) * elems
							exit do
						end if
					end if
				end if
				
				if( time_out = ONLY_ONCE ) then
					exit do
				end if
				if( then_ ) then
					if( abs(timer-now_) >= then_ ) then
						exit do
					end if
				end if
				if( is_closed( ) ) then
					if( length( ) = 0 ) then
						exit do 
					end if
				end if
				
				sleep 1, 1
			loop
		end if
		
		elems = ((elems*len(t))-chunk_)/len(t)
		
	end function
#endmacro	

namespace chi
	
	DEFINE_SOCKET_GET(short)
	DEFINE_SOCKET_GET(int32_t)
	DEFINE_SOCKET_GET(double )
	DEFINE_SOCKET_GET(ubyte  )
	
	function socket.get _ 
		( _ 
			byref data_ as string, _
			byref elems as int32_t, _ 
			byval time_out as int32_t, _ 
			byval peek_only as int32_t _
		) as int32_t
		
		dim as double delay, t
		dim as int32_t hdr, no_block = (time_out = ONLY_ONCE), ok_time = (time_out > 0)
		dim as string ptr current = cast(string ptr, @data_)
		
		for i as int32_t = 0 to elems-1
			delay = time_out/1000
			
			t = timer
			if( this.get( hdr, 1, iif(no_block, ONLY_ONCE, iif(ok_time, cint(delay * 1000), 0)), peek_only ) = FALSE ) then
				exit function
			end if
			
			delay -= timer-t
			if( (delay < 0) and ok_time ) then
				exit function
			end if
			
			if( hdr = 0 ) then
				continue for
			end if
			
			*current = space(hdr)
			t = timer
			if( this.get( (*current)[0], hdr, block, peek_only ) = FALSE ) then
				exit function
			end if
			
			delay -= timer-t
			if( (delay < 0) and ok_time ) then
				exit function
			end if
			
			current += 1
		next
		
		function = TRUE
	end function
	
end namespace