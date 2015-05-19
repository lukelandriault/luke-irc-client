#include "chisock.bi"

namespace chi
	
	function socket.put_data _ 
		( _ 
			byval data_ as any ptr, _ 
			byval size as int32_t _ 
		) as int32_t
		
		if( size <= 0 ) then
			exit function
		end if
		
		dim as socket_lock lock_ = p_send_lock
			
		'' need more space?
		dim as int32_t max_size = p_send_buff_size-p_send_size
		if( size > max_size ) then
         
         while size > max_size					
			   p_send_buff_size += SEND_BUFF_SIZE
			   max_size += SEND_BUFF_SIZE
			wend
			
			p_send_data = reallocate( p_send_data, p_send_buff_size )
			
		end if
		
		'' add data to buffer
		memcpy( @p_send_data[p_send_size], data_, size )
		p_send_size += size		
		
		function = size
		
	end function
	
	function socket.put_line _ 
		( _ 
			byref text as string _ 
		) as int32_t
		
		dim as integer lt = cast(integer ptr, @text)[1]
		if( lt ) then
			put_data( strptr(text), lt )
		end if
		put_data( strptr(CR_LF), 2 )
		
		function = TRUE
		
	end function
	
	function socket.put_string _ 
		( _ 
			byref text as string _ 
		) as int32_t
		
		if( quick_len(text) = 0 ) then
			return TRUE
		end if
		
		put( text[0], cast( int32_t, quick_len(text) ) )
		
		function = TRUE
		
	end function
	
	function socket.put_http_request _ 
		( _ 
			byref server_name as string, _ 
			byref method as string, _ 
			byref post_data as string _
		) as int32_t
	
		/' does an HTTP request as specified '/
	    
		/' Not a get or put request? '/
		if ucase( method ) <> "GET" then
			if ucase( method ) <> "POST" then
				return FALSE
			end if
		end if
	
		dim as string temp_server = server_name, URI = "/"
		
		/' get first slash, everything past that is a path '/
		dim as int32_t first_slash = instr( temp_server, "/" )
	
		/' there's a path. '/
		if first_slash > 0 then
			
			/' take everything past first slash '/
			URI += mid( temp_server, first_slash + 1 )
			
			/' cut off path from server name '/
			temp_server = left( temp_server, first_slash - 1 )
			
		end if
	
	
		dim as string HTTPRequest
		HTTPRequest += method + " " + URI + " HTTP/1.0"                             + CR_LF + _
		               "Host: " + base_HTTP_path( ltrim( temp_server, "http://" ) ) + CR_LF + _
		               "Accept: text/html"                                          + CR_LF + _
		               "User-Agent: cha0tix .01. Have a nice day!"                  + CR_LF + _
		               "Connection: Close"                                          + CR_LF 
		
		/' POST? Parse variables? '/
		if( method = "POST" ) then
	  
			HTTPRequest += "Content-Type: application/x-www-form-urlencoded" + CR_LF
	
			dim as int32_t iLoc = ANY
			dim as string buffString
	
			do
	
				/' parse URI variables '/
				iLoc = instr( post_data, "&" )
	    
				/' is there another variable? '/
				if iLoc > 0 then
					buffString += left( post_data, iLoc - 1 ) + "&"
					post_data = mid( post_data, iLoc + 1, len( post_data ) )
				else
					exit do
				end if
	
			loop
	  
			/' Add the last variable '/
			buffString += post_data
	  
			/' Tell the server how much we'll send it. '/
			HTTPRequest += "Content-Length: " & len( buffString ) & CR_LF
			HTTPRequest += CR_LF      
	  
			/' Add the POST variables to the request '/
			HTTPRequest += buffString
	  
		end if
	
		/' Add a final CRLF '/
		HTTPRequest += CR_LF
	
		/' Send our request '/
		put( HTTPRequest[0], len(HTTPRequest) )
	
		return TRUE
	
	end function
	
	function socket.put_IRC_auth _ 
		( _ 
			byref nick as string, _ 
			byref realname as string, _ 
			byref pass as string _
		) as int32_t
    
		/' Password given? '/
		if pass <> "" then
			put_line( "PASS " & pass )
		end if
    	
		put_line( "USER " & realname & " * * *" )
		put_line( "NICK " & nick )
		
		function = TRUE
		
	end function
	
end namespace
