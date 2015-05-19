#include "chisock.bi"

namespace chi
	
	function socket.get_data _ 
		( _ 
			byval data_ as any ptr, _
			byval size as int32_t, _ 
			byval peek_only as int32_t _
		) as int32_t
		
		if( size <= 0 ) then
			exit function
		end if
		
		dim as socket_lock lock_ = p_recv_lock
		
		'' handle speed limits
		if( p_recv_limit > 0 ) then
			
			if( abs(timer-p_recv_timer) >= (1 / BUFF_RATE) ) then
				p_recv_timer = timer
				
				p_recv_accum -= (p_recv_limit / BUFF_RATE)
				
				if( p_recv_accum < 0 ) then p_recv_accum = 0
				
			end if
			
			if( p_recv_accum + size > p_recv_limit ) then
				
				size = p_recv_limit - p_recv_accum
				
				if ( p_recv_accum = p_recv_limit ) or ( size <= 0 ) then
				    exit function
				EndIf
				
			end if
			
		end if
		
		'' update bytes/sec calc... reset counter
		if( abs(timer-p_recv_disp_timer) >= 1 ) then
			
			p_recv_rate = p_recv_accum
			p_recv_disp_timer = timer
			
			if( p_recv_limit = 0 ) then p_recv_accum = 0
			
		end if		
				
		dim as int32_t available_data = length( )
		
		'' read data?
		if( size <= available_data ) then
			
			'' write to user pointer
			memcpy( data_, @p_recv_data[p_recv_caret], size )
			
			'' not peeking? update caret
			if( peek_only = FALSE ) then
				p_recv_caret += size
				p_recv_accum += size
			end if
			
			'' return bytes read
			function = size
			
		end if
		
	end function
	
function InstrAsm_(ByVal Start As int32_t, ByRef TEXT as string, ByVal CHAR as int32_t) as int32_t

#if 1
  return Instr( Start, TEXT, chr( CHAR ) )

#else

  'Written by Mysoft
  Start -= 1

  asm

    mov EDI,[TEXT]          ' Get String header pointer
    mov ECX,[EDI+4]         ' Get string sz ptr
    xor EAX,EAX             ' clear EAX

    mov EDX,[Start]
    cmp EDX,ECX
    jge _IAOEndInstr_

    mov ESI,[EDI]           ' Get string text ptr
    mov EBX,[CHAR]          ' CHAR to search :)
    add ESI,EDX             ' Apply Start position to string
    mov EDI,ESI             ' copy of the string start ptr

    Sub ECX,EDX             ' Apply Start position to len
    cmp ECX,4               ' Lenght is less than 4?
    jb _IAOLess4_           ' then skip 4 blocks part...
    mov EDX,ECX             ' copy of counter
    and EDX,(not 3)         ' align in 4 bytes

    _IAONext4Char_:
    mov EAX,[ESI]           'load 4 bytes
    cmp AL,BL               'check byte 4
    je _IAOfound1_          'found?
    shr eax,8               'point byte 3
    cmp AL,BL               'check byte 3
    je _IAOfound2_          'found?
    shr eax,8               'point byte 2
    cmp AL,BL               'check byte 2
    je _IAOfound3_          'found?
    shr eax,8               'point byte 1
    cmp AL,BL               'check byte 1
    jz _IAOfound4_          'found?
    add ESI,4
    sub EDX,4               'go check more 4 bytes
    jnz _IAONext4Char_      'until its done

    xor eax,eax             'clear eax (to not mess with the result)

    _IAOLess4_:
    and ecx,3              'now will check only the last bytes
    jz _IAOEndInstr_       'nothing else to find (so it will be 0)
    cmp [ESI],bl           ' Compare 1
    je _IAOfound1_         ' Is equal? found 1
    dec ecx                ' decrement... finished? 1
    jz _IAOEndInstr_       ' yes then go send result 1
    cmp [ESI+1],bl         ' Compare 2
    je _IAOfound2_         ' Is equal? found 2
    dec ecx                ' decrement... finished? 2
    jz _IAOEndInstr_       ' yes then go send result 2
    cmp [ESI+2],bl         ' Compare 3
    je _IAOfound3_         ' Is equal? found 3
    jmp _IAOEndInstr_      ' not found... (0)

    _IAOfound4_:
    mov EAX,ESI            '  \ Get function result
    sub EAX,EDI            '  / (Actual ptr) - start ptr = result :P
    add EAX,4
    jmp _IAOfound_
    _IAOfound3_:
    mov EAX,ESI            '  \ Get function result
    sub EAX,EDI            '  / (Actual ptr) - start ptr = result :P
    add EAX,3
    jmp _IAOfound_
    _IAOfound2_:
    mov EAX,ESI            '  \ Get function result
    sub EAX,EDI            '  / (Actual ptr) - start ptr = result :P
    add EAX,2
    jmp _IAOfound_
    _IAOfound1_:
    mov EAX,ESI            '  \ Get function result
    sub EAX,EDI            '  / (Actual ptr) - start ptr = result :P
    Inc EAX

    _IAOfound_:
    add EAX, [Start]

    _IAOEndInstr_:
    mov [function], EAX    ' save result

  end asm

#endif

end Function
	
	function socket.get_until _ 
		( _ 
			byref target as string _
		) as string
		
		dim as int32_t ins, l, r_len, gotten
		dim as int32_t tl = quick_len(target)
		var start = 1
		var in_buffer = space(512)
		var res = space(512)
		quick_len( res ) = 0
		
		do 
			
			l = length( )
			if( l ) then
				
				r_len = quick_len( res )				
				if l > 512 then l = 512
				
				gotten = get( in_buffer[0], l, , TRUE )
				quick_len( in_buffer ) = gotten
				
				res += in_buffer
				
				if( gotten > 0 ) then
					
					'ins = instr( /'iif( tl >= r_len, 1, r_len - tl-1 ),'/ res, target )
					ins = instrASM_( start, res, target[ tl - 1 ] )
					start = quick_len( res ) + 1
					
					if ( ins <> 0 ) and ( tl = 2 ) then
					   
					   if ins = 1 then
					      ins = 0
					   elseif res[ ins - 2 ] = target[ 0 ] then
					      ins -= 1
					   else
					      ins = 0
					   EndIf
					   
					EndIf
					
					if( ins ) then
						quick_len( res ) = ins + tl - 1						
						gotten = ins + tl - 1 - r_len
					end if
					
					dump_data( gotten )
				end if
				
				if( ins ) then exit do
			
			else
			
			   sleep 1, 1
			
			end if
			
			if( is_closed( ) ) then
				if( length( ) = 0 ) then
					exit do 
				end if
			end if
			
		loop
		
		function = res
		
	end function
	
	function socket.get_line _ 
		( _ 
		) as string
		
		var res = get_until( chr(13, 10) )
		function = left(res, len(res)-2)
		
	end function
	
	function socket.dump_data _ 
		( _ 
			byval size as int32_t _ 
		) as int32_t
		
		dim as socket_lock lock_ = p_recv_lock
		
		dim as int32_t available_data = length( )
		if( size <= available_data ) then
			p_recv_caret += size
			function = TRUE
		end if
		
	end function
	
end namespace
