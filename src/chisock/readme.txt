chiSock is free for all kinds of use, I'd like credit.

cha0s here, my e-mail address is rubentbstk (AT) gmail [DOT] com

The API is organized under the namespace "chi"

UDP sockets are bound internally using "connect". There is no option for 
connectionless UDP sockets atm, let me know if you want that. (If 'nough interest...)

To compile the library, shell to the directory and issue:

"fbc *.bas -g -mt -lib -x chisock"

Then, for ease of use, copy the libchisock.a file to your FreeBASIC/lib/win32 directory. 
You may also wish to copy the *.bi files to your FreeBASIC/inc directory.

There is libchisock.a present already compiled in the bin/win32 directory, for Windows.

----------------------------------------------------------------------------------------------

function client( byval ip as integer, 
                 byval port as integer ) as integer
	
	o Create a TCP client with the 32-bit IP address "ip" on port "port".
	
	ex: 
		dim as chi.socket foo
		dim as integer localhost = 127 or (0 shl 8) or (0 shl 16) or (7 shl 24)
		if( foo.client( localhost, 80 ) <> chi.SOCKET_OK ) then print "Error!"
	
	* Returns "chi.SOCKET_OK" on success, else error.
		
----------------------------------------------------------------------------------------------

function client( byref server as string, 
                 byval port as integer ) as integer
	
	o Create a TCP client with the hostname "server" on the port "port"
	
	ex: 
		dim as chi.socket foo
		if( foo.client( "www.google.com", 80 ) <> chi.SOCKET_OK ) then print "Error!"
		
	* Returns "chi.SOCKET_OK" on success, else error.
		
----------------------------------------------------------------------------------------------

function server( byval port as integer, 
                 byval max_queue as integer = 4 ) as integer
	
	o Create a TCP server that listens on port "port". It can queue up to "max_queue" 
	  incoming connections. When a socket connects, it is added to the queue. When
	  listen() is used with the listening socket, it removes a socket from the queue
	  if one exists. The default queue size is 4 pending connections.
	
	ex:
		dim as chi.socket foo
		if( foo.server( 12345 ) <> chi.SOCKET_OK ) then print "Error!"
		
	* Returns "chi.SOCKET_OK" on success, else error.
		
----------------------------------------------------------------------------------------------

function UDP_client( byval ip as integer, 
                     byval port as integer ) as integer
	
	o Create a UDP client with the 32-bit IP address "ip" on port "port".
	
	ex: 
		dim as chi.socket foo
		dim as integer localhost = 127 or (0 shl 8) or (0 shl 16) or (7 shl 24)
		if( foo.UDP_client( localhost, 80 ) <> chi.SOCKET_OK ) then print "Error!"
		
	* Returns "chi.SOCKET_OK" on success, else error.
		
----------------------------------------------------------------------------------------------

function UDP_client( byref server as string, 
                     byval port as integer ) as integer
	
	o Create a UDP client with the hostname "server" on the port "port"
	
	ex: 
		dim as chi.socket foo
		if( foo.UDP_client( "www.somewhere.com", 23712 ) <> chi.SOCKET_OK ) then print "Error!"
		
	* Returns "chi.SOCKET_OK" on success, else error.
		
----------------------------------------------------------------------------------------------

function UDP_server( byval port as integer ) as integer
	
	o Create a UDP server that listens on port "port"
	
	ex: 
		dim as chi.socket foo
		if( foo.UDP_server( 23712 ) <> chi.SOCKET_OK ) then print "Error!"
		
	* Returns "chi.SOCKET_OK" on success, else error.
		
----------------------------------------------------------------------------------------------	

function is_closed( ) as integer
	
	o Poll the socket to see if its connection is still alive.
	
	ex: 
		dim as chi.socket foo
		if( foo.client( "www.google.com", 80 ) <> chi.SOCKET_OK ) then print "Error!"
		
		if( foo.is_closed( ) = TRUE ) then
			print "They hung up on me!"
		end if
		
	* Returns TRUE if the connection is closed, else FALSE.
	
----------------------------------------------------------------------------------------------	

declare function listen( byref timeout as double = 0,
                         byref info as socket_info ptr = NULL ) as integer 
	
	o Listen on a server socket for incoming connections. If "timeout" is 0,
	  then the socket blocks indefinitely until a connection is recieved. 
	  Otherwise, the socket blocks for "timeout" seconds. If "info" is NULL,
	  the peer info is discarded, otherwise it is returned through info. 
	  The connection socket is the same as the listener. 
	  Better to use listen_to_new() most of the time.
	
	ex: 
		dim as chi.socket foo
		if( foo.server( 12345 ) <> chi.SOCKET_OK ) then print "Error!"
		
		'' I'm waiting 3 seconds!
		if( foo.listen( 3 ) = FALSE ) then
			print "I got ditched. :("
		end if
		
	* Returns TRUE if a connection was recieved, else FALSE.
	
----------------------------------------------------------------------------------------------	

function listen_to_new( byref listener as socket, _ 
                        byval timeout as double = 0, _ 
                        byref info as socket_info ptr = NULL ) as integer

	o Listen on the "listener" socket for incoming connections. If "timeout" is 0,
	  then the socket blocks indefinitely until a connection is recieved. 
	  Otherwise, the socket blocks for "timeout" seconds. If "info" is NULL,
	  the peer info is discarded, otherwise it is returned through info.
	  The socket that calls listen_to_new() recieves the new connection.
	
	ex: 
		dim as chi.socket foo, bar
		if( foo.server( 12345 ) <> chi.SOCKET_OK ) then print "Error!"
		
		'' Ok... 10 seconds!
		bar.listen_to_new( foo, 10 )
		if( bar.is_closed( ) = FALSE ) then
			print "They picked me up!"
		end if
		
	* Returns TRUE if a connection was recieved, else FALSE.
	
----------------------------------------------------------------------------------------------	

function get overload ( byref data_ as t, _
                        byref elems as integer = 1, _ 
                        byval time_out as integer = ONLY_ONCE, _ 
                        byval peek_only as integer = FALSE ) as integer
	
	o "t" can be UBYTE, SHORT, INTEGER, DOUBLE, or STRING.
	  "elems" specifies how many "t"s to retrieve. "time_out" can be 
	  "chi.socket.ONLY_ONCE" (only tries retriving one time before giving up)
	  "chi.socket.BLOCK" (blocks forever until enough data is there to retrieve)
	  or, any other number specifies the number of milliseconds to try before 
	  giving up. Upon return "elems" contains the amount of "t"s that were 
	  successfully recieved. If "peek_only" is FALSE, the data is removed from
	  the socket stream.
	
	ex: 
		dim as chi.socket foo
		if( foo.client( 12345 ) <> chi.SOCKET_OK ) then print "Error!"
		
		'' I'm gonna get a message!
		dim as string message
		if( foo.get( message ) = TRUE ) then
			print "I got: " & message
		end if
		
	* Returns TRUE if all data was recieved, else FALSE.
	
----------------------------------------------------------------------------------------------	

function put overload ( byref data_ as t, _
                        byref elems as integer = 1, _ 
                        byval time_out as integer = 0 ) as integer
	
	o "t" can be UBYTE, SHORT, INTEGER, DOUBLE, or STRING.
	  "elems" specifies how many "t"s to put in the stream. "time_out" can be 
	  "chi.socket.ONLY_ONCE" (only tries putting one time before giving up)
	  "chi.socket.BLOCK" (blocks forever until enough data can be put)
	  or, any other number specifies the number of milliseconds to try before 
	  giving up. Upon return "elems" contains the amount of "t"s that were 
	  successfully sent.
	
	ex: 
		dim as chi.socket foo
		if( foo.client( 12345 ) <> chi.SOCKET_OK ) then print "Error!"
		
		'' I'm gonna give 'em a message!
		dim as string message = "Hello my fellow earthling!"
		if( foo.put( message ) = FALSE ) then
			print "That didn't go over well. :("
		end if
		
	* Returns TRUE if all data was sent, else FALSE.
	
----------------------------------------------------------------------------------------------

function dump_data( byval size as integer ) as integer
	
	o Discard "size" bytes of data from the socket stream.
	
	ex: 
		dim as chi.socket foo
		if( foo.client( "www.google.com", 80 ) <> chi.SOCKET_OK ) then print "Error!"
		
		'' no null term needed.
		if( foo.dump_data( 20 ) = FALSE ) then
			print "Not even 20 measly bytes in the socket stream!"
		end if
		
	* Returns TRUE on success, FALSE on error.
	
----------------------------------------------------------------------------------------------	

function close( ) as integer
	
	o Close the specified socket, and shut it down.
	
	ex: 
		dim as chi.socket foo
		if( foo.client( "www.google.com", 80 ) <> chi.SOCKET_OK ) then print "Error!"
		
		'' haha, pranked 'em.
		if( foo.close( ) <> chi.SOCKET_OK ) then print "Burn! :("
		
	* Returns chi.SOCKET_OK on successful close/shutdown, else error.
	
----------------------------------------------------------------------------------------------	

function length( ) as integer
	
	o Retrieve the length of the receive buffer.
	
	ex: 
		dim as chi.socket foo
		if( foo.client( "www.google.com", 80 ) <> chi.SOCKET_OK ) then print "Error!"
		
		print foo.length( ) '' how much have we gotten so far?
		
	* Returns chi.SOCKET_OK on successful close/shutdown, else error.
	
----------------------------------------------------------------------------------------------

function put_data( byval data_ as any ptr, 
                   byval size as integer ) as integer
	
	o Attempt to commit "size" bytes of data at "data_" to the socket stream.
	
	ex: 
		dim as chi.socket foo
		if( foo.client( "www.google.com", 80 ) <> chi.SOCKET_OK ) then print "Error!"
		
		'' no null term needed.
		if( foo.put_data( @"Hello are you there?", 20 ) = FALSE ) then
			print "Not enough room in the stream, try later."
		end if
		
	* Returns TRUE on success, FALSE on error.
	
	Note: This function is considered low-level and isn't necessary to use.
		
----------------------------------------------------------------------------------------------	

function get_data( byval data_ as any ptr, 
                   byval size as integer, 
                   byval peek_only as integer = FALSE ) as integer
	
	o Attempt to retrieve "size" bytes of data from the socket stream, filling 
	  "data_". If "peek_only" is FALSE (default), then the data is removed from
	  the socket stream as well.
	
	ex: 
		dim as chi.socket foo
		if( foo.client( "www.google.com", 80 ) <> chi.SOCKET_OK ) then print "Error!"
		
		dim as ubyte data_in(63)
		if( foo.get_data( @data_in(0), 64 ) = TRUE ) then
			print "Ooooh! I got a message from Goooogle!"
		end if
		
	* Returns TRUE on success, FALSE on error.
	
	Note: This function is considered low-level and isn't necessary to use.
		
----------------------------------------------------------------------------------------------	

property recv_limit ( byref limit as double )
	
	o Set the reception speed limit of the socket, in bytes
	
	ex: 
		dim as chi.socket foo
		foo.recv_limit = 1800 '' kinda like a 14.4 connection
		
	* No return value.
	
----------------------------------------------------------------------------------------------	

property recv_limit ( ) as double
	
	o Get the reception speed limit of the socket, in bytes
	
	ex: 
		dim as chi.socket foo
		print foo.recv_limit '' 1800, if the example above was called first
		
	* Returns the max incoming transfer speed in bytes.
	
----------------------------------------------------------------------------------------------	

property send_limit ( byref limit as double )
	
	o Set the send speed limit of the socket, in bytes
	
	ex: 
		dim as chi.socket foo
		foo.send_limit = 3600 '' kinda like a 28.8 connection
		
	* No return value.
	
----------------------------------------------------------------------------------------------	

property send_limit ( ) as double
	
	o Get the send speed limit of the socket, in bytes
	
	ex: 
		dim as chi.socket foo
		print foo.recv_limit '' 1800, if the example above was called first
		
	* Returns the max outgoing transfer speed in bytes.
	
----------------------------------------------------------------------------------------------	

function recv_rate ( ) as integer
	
	o Get the number of bytes received per second
	
	ex: 
		dim as chi.socket foo
		if( foo.client( "www.google.com", 80 ) <> chi.SOCKET_OK ) then print "Error!"
		
		print foo.recv_rate '' probably 0, no HTTP header was sent yet
		
	* Returns the number of bytes recieved over the last second.
	
----------------------------------------------------------------------------------------------	

function send_rate ( ) as integer
	
	o Get the number of bytes sent per second
	
	ex: 
		dim as chi.socket foo
		if( foo.client( "www.google.com", 80 ) <> chi.SOCKET_OK ) then print "Error!"
		
		print foo.send_rate '' probably 0, no HTTP header was sent yet
		
	* Returns the number of bytes sent over the last second.
	
----------------------------------------------------------------------------------------------

Thanks for downloading chiSock!
