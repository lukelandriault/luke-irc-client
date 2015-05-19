#Include Once "lic.bi"
#Include Once "file.bi"

#if LIC_DCC

Declare Sub DCC_PrintHelp( )

Sub DCC_TRACKER.ThreadEnd( )

   MutexLock( Mutex )

   if this.Thread <> 0 then
      'assure the thread handle is cleaned up
      dim as event_type e
      e.id = Thread_wait
      e._ptr = this.Thread
      e.when = Timer + 20
      Global_IRC.Event_Handler.Add( @e )
   end if

   this.Thread = 0
   If this.socket <> 0 Then
      Delete this.Socket
      this.socket = 0
   EndIf

   MutexUnLock( Mutex )

End Sub

Sub DCC_TRACKER.SetStatus( ByRef NewStatus As Integer, ByRef ErrorNum As Integer = 0 )
   MutexLock( Mutex )
   status = NewStatus
   If ErrorNum <> 0 Then error_id = ErrorNum
   MutexUnLock( Mutex )
End Sub

Function DCC_TRACKER.GetStatus( ) As String

   Dim As String Ret, T
   ScopeLock( mutex )

   If Type_ = DCC_SEND Then

      Select Case status
         Case DCC_STATUS.Init
            T = "Initializing"

         Case DCC_STATUS.Connecting
            T = "Connecting"

         case DCC_STATUS.Listening
            T = "Listening"

         Case DCC_STATUS.Transferring
            T = "Transferring"

         Case DCC_STATUS.Complete
            T = "Complete"

         Case DCC_STATUS.Failed
            T = "Failed " & GetError( )

      End Select

      Ret = "#" & id & " " & user & *IIf( ip, @" Incoming", @" Outgoing" ) & _
         " File '" & argument & "' " & T & " " & CalcSize( bytes_xfer )

      If status <> DCC_STATUS.Complete Then _
         Ret &= " / " & CalcSize( filesize ) & "  (" & _
            Left( Str( bytes_xfer / filesize * 100 ), 4 ) & "%)"

      If speed > 0 Then Ret &= " Current Speed: " & CalcSize( speed ) & "/s"
      If avgspeed > 0 Then
         Ret &= " Average Speed: " & CalcSize( avgspeed ) & "/s"
         If status = DCC_STATUS.Transferring Then _
            Ret &= " ETR: ~" & CalcTime( ( filesize - bytes_xfer ) / avgspeed )
      EndIf

      Function = Ret

   Else

      Function = ""

   EndIf

End Function

Function DCC_TRACKER.GetError( ) As String

   Select Case Error_ID

      Case DCC_ERROR.NoError
         Function = ""

      Case DCC_ERROR.TimedOut
         Function = "Timed Out"

      Case DCC_ERROR.Cancelled
         Function = "Cancelled"

      Case DCC_ERROR.Rejected
         Function = "Rejected"

      Case DCC_ERROR.NetworkError
         Function = "Network Error"

      Case DCC_ERROR.FileReadError
         Function = "File Read Error"

      Case DCC_ERROR.FileWriteError
         Function = "File Write Error"

      case Else
         Function = "Unknown Error"
         LIC_DEBUG( "\\DCC Unknown Error: " & Error_ID )

   End Select

End Function

function DCC_BIND( byval sock as any ptr, byref port as ushort ) as integer

   dim as integer ret
   dim as chi.socket ptr s = sock

   For i as integer = 0 To 1023

      ret = s->server( cast( long, port ) )
      If ret = chi.SOCKET_OK Then
         return ret
      EndIf

      if port = 65535 then
         port = 1025
      else
         port += 1
      EndIf

   Next

   function = ret

End Function

Sub DCC_REQUEST( ByRef DCC_USER As String, ByRef DCC_TYPE As Integer, ByRef DCC_ARGUMENT As String )

   #Ifdef __FB_WIN32__
      var delimit = InStrRev( DCC_ARGUMENT, "\" ) + 1
   #Else '__FB_LINUX__
      Var delimit = InStrRev( DCC_ARGUMENT, "/" ) + 1
   #EndIf

   Var IP = CInt( htonl( Global_IRC.CurrentRoom->Server_Ptr->ExternalIP ) )

   if Global_IRC.Global_Options.DCC_Passive <> 0 then
      Var DT = New DCC_TRACKER
      Global_IRC.DCC_list.Add( DT )

      DT->user = DCC_USER
      DT->type_ = DCC_TYPE
      DT->argument = DCC_ARGUMENT
      DT->Token = DT->id
      DT->ServerPtr = Global_IRC.CurrentRoom->Server_Ptr
      DT->filesize = FileLen( DCC_ARGUMENT )

      Var filename = Mid( DCC_ARGUMENT, delimit )
      if DCC_TYPE = DCC_SEND then
         Notice_Gui( "** DCC: " & DT->GetStatus( ), Global_IRC.Global_Options.ServerMessageColour )
         Global_IRC.CurrentRoom->Server_Ptr->SendLine( _
            "PRIVMSG " & DCC_USER & !" :\1DCC SEND """ & filename & """ " & _
            IP & " 0 " & DT->Filesize & " " & DT->Token & !"\1" )
      else
         Notice_Gui( "** DCC: Sent Chat request to " & DCC_USER, Global_IRC.Global_Options.ServerMessageColour )
         Global_IRC.CurrentRoom->Server_Ptr->SendLine( _
            "PRIVMSG " & DCC_USER & !" :\1DCC CHAT chat " & IP & " 0 " & DT->Token & !"\1" )
      endif
      exit sub
   EndIf

   Var DCC_SOCK = New chi.socket
   If DCC_SOCK = 0 Then Exit Sub

   dim as ushort DCC_PORT = Global_IRC.Global_Options.DCC_port
   dim as integer sock_status = DCC_BIND( DCC_SOCK, DCC_PORT )

   If sock_status <> chi.SOCKET_OK Then
      Notice_Gui( "** DCC ERROR: Could not create listen port", Global_IRC.Global_Options.ServerMessageColour )
      DCC_SOCK->Close( )
      sleep( 2000, 1 )
      Delete DCC_SOCK
      Exit Sub
   EndIf

   Var DT = New DCC_TRACKER

   DT->socket = DCC_SOCK
   DT->port = DCC_PORT
   DT->user = DCC_USER
   DT->argument = DCC_ARGUMENT
   DT->type_ = DCC_TYPE
   DT->ServerPtr = Global_IRC.CurrentRoom->Server_Ptr

   Global_IRC.DCC_list.Add( DT )

   Select Case DCC_TYPE

   case DCC_CHAT
':Luke!nobody@cable.rogers.com PRIVMSG LukeL :?DCC CHAT chat 1676831686 1024?

      DCC_SOCK->hold = TRUE
      DCC_SOCK->p_send_sleep = 50
      DCC_SOCK->hold = FALSE

      var t = new threadconnect
      t->mutex = DT->Mutex
      t->sock = DCC_SOCK
      t->ret = @( DT->SockStatus )
      t->timeout = 45

      DT->SockStatus = NO_RETURN
      DT->SetStatus( DCC_STATUS.Listening )

      DT->Thread = ThreadCreate( cptr( any ptr, ProcPtr( chiListen ) ), t, 1024 * 10 )

      Notice_Gui( "** DCC: Sending chat request to " & DCC_USER, Global_IRC.Global_Options.ServerMessageColour )

      Global_IRC.CurrentRoom->Server_Ptr->SendLine ( _
         "PRIVMSG " & DCC_USER & !" :\1DCC CHAT chat " & IP & " " & DCC_PORT & !"\1" )

   Case DCC_SEND

      DCC_SOCK->hold = TRUE
      DCC_SOCK->p_send_sleep = 1
      DCC_SOCK->hold = FALSE

      DT->filesize = FileLen( DCC_ARGUMENT )

      Var length = DT->Filesize
      Var filename = Mid( DCC_ARGUMENT, delimit )

      DT->Thread = ThreadCreate( CPtr( Any Ptr, ProcPtr( DCC_FILE_SEND_THREAD ) ), DT, 128 )

      'Filename, IP, port, filesize.

      MutexLock( DT->Mutex )
      sleep( 100, 1 )
      MutexUnLock( DT->Mutex )

      Notice_Gui( "** DCC: " & DT->GetStatus( ), Global_IRC.Global_Options.ServerMessageColour )

      Global_IRC.CurrentRoom->Server_Ptr->SendLine( _
         "PRIVMSG " & DCC_USER & !" :\1DCC SEND """ & filename & """ " & _
         IP & " " & DCC_PORT & " " & length & !"\1" )


   End Select

End Sub

Sub DCC_Parse( ByRef In_ As String )

   Dim As Integer DCC_TYPE
   Dim As String DCC_ARGUMENT, DCC_USER, DCC_COMMAND
   Dim As UInteger Delimit1 = InStr( In_, " " ), Delimit2
   Dim As UInteger id
   Dim As DCC_TRACKER Ptr ptr_

   If Delimit1 = 0 Then
      DCC_COMMAND = UCase( In_ )
   Else
      DCC_COMMAND = UCase( Left( In_, Delimit1 - 1 ) )
      Delimit2 = InStr( Delimit1 + 1, In_, " " )
      if Delimit2 = 0 then Delimit2 = len( In_ ) + 1
      DCC_USER = Mid( In_, Delimit1 + 1, Delimit2 - Delimit1 - 1 )
   EndIf

   id = ValInt( Mid( In_, Delimit1 + 1 ) )
   If id > 0 Then
      For i As Integer = 1 To Global_IRC.DCC_List.Allocated
         If Global_IRC.DCC_List.tracker[i - 1] = 0 Then Continue For
         If Global_IRC.DCC_List.tracker[i - 1]->id = id Then
            ptr_ = Global_IRC.DCC_List.tracker[i - 1]
            Exit For
         EndIf
      Next
   EndIf

   Select Case DCC_COMMAND
      Case "LIST", "L"
         var Xfers = 0
         If Global_IRC.DCC_List.Used > 0 Then
            For i As Integer = 1 To Global_IRC.DCC_List.Allocated
               If Global_IRC.DCC_List.tracker[i - 1] = 0 Then Continue For
               if Global_IRC.DCC_List.tracker[i - 1]->Type_ = DCC_SEND then Xfers += 1
            Next
         endif

         if Xfers = 0 then
            Notice_Gui( "** No DCC Transfers", Global_IRC.Global_Options.ServerMessageColour )
         Else
            Global_IRC.CurrentRoom->AddLOT( "", Global_IRC.Global_Options.ServerMessageColour, 0, LineBreak )
            For i As Integer = 1 To Global_IRC.DCC_List.Allocated
               If Global_IRC.DCC_List.tracker[i - 1] = 0 Then Continue For
               if Global_IRC.DCC_List.tracker[i - 1]->Type_ = DCC_CHAT then Continue for
               Global_IRC.CurrentRoom->AddLOT( "** DCC: " & Global_IRC.DCC_List.tracker[i - 1]->GetStatus( ), Global_IRC.Global_Options.ServerMessageColour, 0, Notification, , , TRUE )
            Next
            Global_IRC.CurrentRoom->AddLOT( "", Global_IRC.Global_Options.ServerMessageColour, 1, LineBreak )
         EndIf

      Case "CHAT"
         if len_hack( DCC_USER ) > 0 then
            DCC_REQUEST( DCC_USER, DCC_CHAT, Global_IRC.CurrentRoom->Server_Ptr->CurrentNick )
         EndIf

      Case "SEND", "S"
         DCC_ARGUMENT = Trim( Mid( In_, Delimit2 + 1 ), Any " """ )

         if len( DCC_ARGUMENT ) = 0 then
            dim as string title = "DCC file transfer -> " & DCC_USER
            #ifdef __FB_WIN32__
            dim as NonBlockingProc NBP = NonBlockingProc( cptr( any ptr, @w32_GetFilename ), strptr( title ) )
            #else
            dim as NonBlockingProc NBP = NonBlockingProc( cptr( any ptr, @lin_GetFilename ), @title )
            #endif
            do until NBP.done( )
         	   MutexUnlock( Global_IRC.Mutex )
         	   sleep( 125, 1 )
         	   MutexLock( Global_IRC.Mutex )
         	   LIC_Main( )
         	Loop

      #if 1 'magic
         	DCC_ARGUMENT = *cptr( string ptr, NBP.return_value )
      #else 'proper
         	DCC_ARGUMENT = *cptr( zstring ptr, str_loc( *cptr( string ptr, NBP.return_value ) ) )
        	   deallocate( cptr( any ptr, str_loc( *cptr( string ptr, NBP.return_value ) ) ) )
      #endif

#ifdef __FB_WIN32__
         else
            DCC_ARGUMENT = String_Replace( "/", "\", DCC_ARGUMENT )
#endif
         End If

         If Len( DCC_ARGUMENT ) = 0 Then
            DCC_PrintHelp( )
         ElseIf FileExists( DCC_ARGUMENT ) = 0 Then
            Notice_Gui( "** DCC: File '" & DCC_ARGUMENT & "' does not exist", Global_IRC.Global_Options.ServerMessageColour )
         else
            DCC_USER = Global_IRC.CurrentRoom->Server_Ptr->Ucase_( DCC_USER )
            DCC_REQUEST( DCC_USER, DCC_SEND, DCC_ARGUMENT )
         EndIf

      Case "ACCEPT", "A", !"\255A"
         dim as string msg
         If ptr_ <> 0 Then

            MutexLock( ptr_->Mutex )
            var Status = ptr_->Status
            var ip = ptr_->ip
            var t = ptr_->type_
            var port = ptr_->port
            var server = cptr( Server_Type ptr, ptr_->ServerPtr )
            MutexUnLock( ptr_->Mutex )

            if ip = 0 then exit sub '*IIf( ip, @" Incoming", @" Outgoing" )

            if t = DCC_SEND then

               If Status = DCC_STATUS.Init Then
                  if ptr_->ResumeRequest = 0 then
                     ptr_->thread = ThreadCreate( CPtr( any Ptr, ProcPtr( DCC_FILE_ACCEPT_THREAD ) ), ptr_, 128 )
                  else
                     ptr_->ResumeRequest = 2
                  end if
               else
                  msg = " has already been started"
               EndIf

            elseif t = DCC_CHAT then

               if Status = DCC_STATUS.Init then

                  ScopeLock( ptr_->Mutex )

                  ptr_->socket = New chi.socket
                  ptr_->socket->p_send_sleep = 50

                  ptr_->SockStatus = NO_RETURN
                  ptr_->Argument = server->CurrentNick

                  var t = new threadconnect

                  if ptr_->token = 0 then
                     *t = type( ptr_->socket, 0, ip, port, 0, ptr_->Mutex, @( ptr_->SockStatus ) )
                     ptr_->status = DCC_STATUS.Connecting
                     ptr_->thread = threadcreate( cptr( any ptr, @chiconnect ), t, 1024 * 64 )
                     ptr_->RoomPtr = cptr( Server_type ptr, ptr_->ServerPtr )->AddRoom( ptr_->user, DccChat )
                     cptr( UserRoom_type ptr, ptr_->RoomPtr )->AddLOT( "** Connecting to " + ptr_->user + " please wait...", Global_IRC.Global_Options.ServerMessageColour, 1, , , , TRUE )
                     if DCC_COMMAND[0] <> 255 then
                        Global_IRC.SwitchRoom( cptr( UserRoom_type ptr, ptr_->RoomPtr ) )
                     EndIf
                  else
                     var tmpstatus = DCC_BIND( ptr_->Socket, ptr_->Port )

                     if tmpstatus = chi.SOCKET_OK then
                        t->mutex = ptr_->Mutex
                        t->sock = ptr_->socket
                        t->ret = @( ptr_->SockStatus )
                        t->timeout = 45
                        ptr_->status = DCC_STATUS.Listening
                        ptr_->Thread = ThreadCreate( cptr( any ptr, ProcPtr( chiListen ) ), t, 1024 * 10 )
                     else
                        ptr_->status = DCC_STATUS.Failed
                        msg = " failed. Could not bind to address."
                     endif
                  endif

               EndIf

            endif

            if ( ptr_->token <> 0 ) and ( Status = DCC_STATUS.Init ) then
               'reverse DCC
               sleep( 250, 1 )
               ScopeLock( ptr_->mutex )
               port = ptr_->port
               ip = CInt( htonl( server->ExternalIP ) )
               if ptr_->Status = DCC_STATUS.Listening then
                  if t = DCC_SEND then
                     server->SendLine( _
                        "PRIVMSG " & ptr_->user & !" :\1DCC SEND """ & ptr_->argument & """ " & ip & " " & port & " " & ptr_->filesize & " " & ptr_->token & !"\1" )
                  elseif t = DCC_CHAT then
                     server->SendLine ( _
                        "PRIVMSG " & ptr_->user & !" :\1DCC CHAT chat " & ip & " " & port & " " & ptr_->token & !"\1" )
                  endif
               endif
            EndIf

         else
            msg = " does not exist"
         EndIf
         if len_hack( msg ) then
            Notice_Gui( "** DCC: ID#" & id & msg, Global_IRC.Global_Options.ServerMessageColour )
         EndIf
      Case "CANCEL", "C"
         var Status = DCC_STATUS.Complete
         if ptr_ <> 0 then
            if ptr_->Type_ <> DCC_SEND then exit sub
            MutexLock( ptr_->Mutex )
            Status = ptr_->Status
            select case Status
               case DCC_STATUS.Transferring, DCC_STATUS.Init, DCC_STATUS.Connecting, DCC_STATUS.Listening
                  ptr_->Status = DCC_STATUS.Failed
                  ptr_->error_id = DCC_ERROR.Cancelled
                  ptr_->speedlimit = 1
                  if Status <> DCC_STATUS.Init then ptr_->socket->Close( )
            end select
            mutexUnlock( ptr_->Mutex )
         EndIf
         select case Status
            case DCC_STATUS.Transferring, DCC_STATUS.Init, DCC_STATUS.Connecting, DCC_STATUS.Listening
            case else
               Notice_Gui( "** DCC: ID#" & id & " either does not exist, or cannot be cancelled.", Global_IRC.Global_Options.ServerMessageColour )
         end select
      case "LIMIT"
         if ( ptr_ <> 0 ) andalso ( ptr_->Type_ = DCC_SEND ) then
            var limit = Val( Mid( In_, Delimit2 + 1 ) )
            mutexlock( ptr_->mutex )
            if ( ptr_->Type_ <> DCC_SEND ) then
               mutexunlock( ptr_->mutex )
               DCC_PrintHelp( )
               Exit Sub
            EndIf
            ptr_->speedlimit = limit * 1024
            mutexunlock( ptr_->mutex )
            var msg = "** DCC: ID#" & id & " setting speed limit to "
            if limit > 0 then
               msg &= limit & " kB/s"
            else
               msg &= "unlimited"
            EndIf
            Notice_Gui( msg, Global_IRC.Global_Options.ServerMessageColour )
         else
            DCC_PrintHelp( )
         EndIf
      Case Else
         DCC_PrintHelp( )
   End Select

End Sub

Sub DCC_PrintHelp( )

   static as zstring ptr msg( 4 ) = { _
      @"/dcc CHAT <nick>", _
      @"/dcc SEND <nick> <file>", _
      @"/dcc LIST", _
      @"/dcc CANCEL ID# : Cancel a dcc file transfer", _
      @"/dcc LIMIT ID# <speed> : Set a file transfer speed limit in kB/second" _
   }

   with *( Global_IRC.CurrentRoom )

   .AddLOT( "Proper DCC Usage:", Global_IRC.Global_Options.ServerMessageColour, 0, LineBreak )
   for i as integer = 0 to ubound( msg )
      .AddLOT( "   " & *msg( i ), Global_IRC.Global_Options.YourChatColour, 0, Notification, 0, 0, TRUE )
   Next
   .AddLOT( "", Global_IRC.Global_Options.ServerMessageColour, 1, LineBreak )

   end with

End Sub

Constructor DCC_TRACKER( )

   mutex = MutexCreate( )
   CreationTime = Timer

End Constructor

Destructor DCC_TRACKER( )

   LIC_DESTRUCTOR1

   MutexDestroy( Mutex )

   user = ""
   argument = ""

   If socket <> 0 Then
      if socket->IS_Closed( ) = FALSE then
         socket->Close( )
         sleep( 2000, 1 )
      EndIf
      Delete Socket
      Socket = 0
   EndIf

   LIC_DESTRUCTOR2

End Destructor

Destructor DCC_LIST_TYPE( )

   LIC_DESTRUCTOR1

   For i As Integer = 0 To allocated - 1
      If tracker[i] <> 0 Then
         Delete tracker[i]
         tracker[i] = 0
      EndIf
   Next

   If Allocated > 0 Then DeAllocate( tracker )

   Tracker = 0
   Allocated = 0
   Used = 0
   Count = 0

   LIC_DESTRUCTOR2

End Destructor

Sub DCC_LIST_TYPE.Remove( ByVal ID As UInteger )

   For i As Integer = 0 To Allocated - 1
      if tracker[i] = 0 then continue for
      If tracker[i]->ID = ID Then
         Delete tracker[i]
         tracker[i] = 0
         used -= 1
         Exit For
      EndIf
   Next

   If ( Used = 0 ) And ( Allocated > 0 ) Then
      DeAllocate( tracker )
      tracker = 0
      Allocated = 0
   EndIf

End Sub

Sub DCC_LIST_TYPE.Add( ByVal DT As DCC_TRACKER Ptr )

   If Allocated = Used Then

      Dim As DCC_TRACKER Ptr Ptr NewSpace

      Allocated += 4

      NewSpace = Callocate( Allocated * SizeOf( Any Ptr ) )

      If Used > 0 Then
         memcpy( NewSpace, tracker, Used * SizeOf( Any Ptr ) )
      EndIf

      DeAllocate( tracker )
      tracker = NewSpace

   EndIf

   Used += 1
   count += 1
   DT->id = count

   For i As UInteger = 0 To Allocated - 1
      If tracker[i] = 0 Then
         tracker[i] = DT
         Exit Sub
      EndIf
   Next

End Sub

Function DCC_LIST_TYPE.Find( ByRef user_ As String, ByRef port_ As UShort, ByRef status_ As uinteger, byref token_ as integer = 0 ) As DCC_TRACKER Ptr

   If used = 0 Then Exit Function

   For i As Integer = 0 To Allocated - 1
      If tracker[i] = 0 Then Continue For
      ScopeLock( tracker[i]->mutex )
      If ( tracker[i]->port = port_ ) And ( tracker[i]->status = status_ ) and ( tracker[i]->token = token_ ) Then
         If StringEqualASM( UCase( tracker[i]->user ), UCase( user_ ) ) Then
            Return tracker[i]
         EndIf
      EndIf
   Next

End Function

Function DCC_LIST_TYPE.Find( Byref URT as any ptr ) as DCC_TRACKER ptr

   If used = 0 Then Exit Function

   for i as integer = 0 to Allocated - 1
      if tracker[i] then
         if tracker[i]->RoomPtr = URT then Return tracker[i]
      end if
   Next

End Function

Sub DCC_LIST_TYPE.Shutdown( )

   If used > 0 Then

      For i As Integer = 0 To Allocated - 1
         If tracker[i] = 0 Then Continue For
         MutexLock( tracker[i]->Mutex )
         If tracker[i]->Thread <> 0 Then
            tracker[i]->Socket->Close( )
            MutexUnLock( tracker[i]->Mutex )
            ThreadWait( tracker[i]->Thread )
         Else
            MutexUnLock( tracker[i]->Mutex )
         EndIf
      Next

   endif

End Sub

Sub DCC_LIST_TYPE.FreeZombies( )

   If used = 0 Then Exit Sub

   For i As Integer = 0 To Allocated - 1
      If tracker[i] = 0 Then Continue For
      if tracker[i]->Type_ <> DCC_SEND then Continue For

      Var T = Timer

      MutexLock( tracker[i]->Mutex )

      If ( tracker[i]->thread <> 0 ) Or ( T < ( tracker[i]->CreationTime + 600 ) ) Then
         MutexUnLock( tracker[i]->Mutex )
         Continue For
      EndIf

      Select Case tracker[i]->Status

         Case DCC_STATUS.Init
            Notice_Gui( "** DCC: Incoming file from " & tracker[i]->User & " '" & tracker[i]->argument & "' timed out and is being removed.", Global_IRC.Global_Options.ServerMessageColour )
            MutexUnLock( tracker[i]->Mutex )
            this.Remove( tracker[i]->ID )

         'Case DCC_STATUS.Complete
            'If T > ( tracker[i]->CreationTime +  )
            ' Auto Remove complete?

         Case Else
            MutexUnLock( tracker[i]->Mutex )

      End Select

   Next

End Sub

Function DCC_CHAT_Out( byref s as string ) as integer

   var tracker = Global_IRC.DCC_List.Find( Global_IRC.CurrentRoom )

   if tracker = 0 then exit function

   ScopeLock( tracker->Mutex )

   if tracker->status = DCC_STATUS.Transferring then
      
      tracker->socket->p_send_sleep = 1
      tracker->socket->put_line( s )

      var URT = cptr( UserRoom_Type ptr, tracker->RoomPtr )
      var n = 1, c = 1, count = 0, msglen = len_hack( s )
      var msg = ""

      while n <> 0
         n = InStrASM( c, s, asc( !"\n" ) )
         msg = mid( s, c, n - c )
         RTrim2( msg, !"\r" )
         LIC_DEBUG( "DCC:" & tracker->id & ":" & msg )
         c = n + 1
         if len_hack( msg ) > 2 andalso ( (msg[0] = 1) and (msg[len_hack( msg ) - 1] = 1) ) then
            msg = trim( msg, chr(1) )
            select case ucase( mid( msg, 1, InStrASM( 1, msg, asc(" ") ) - 1 ) )
            case "ACTION"
               URT->AddLOT( "*" & tracker->Argument & Mid( msg, 7 ), _
                     Global_IRC.Global_Options.YourChatColour, iif( n = 0, 1, 0 ), ActionEmote )
            case else
               URT->AddLOT( "[ " + tracker->Argument + " ]: " + msg, _
                  Global_IRC.Global_Options.YourChatColour, iif( n = 0, 1, 0 ), NormalChat )
            end select
         else
            URT->AddLOT( "[ " + tracker->Argument + " ]: " + msg, _
               Global_IRC.Global_Options.YourChatColour, iif( n = 0, 1, 0 ), NormalChat )
         end if
         count += 1
         if count = 512 then
            count = 0
            MutexUnLock( Global_IRC.Mutex )
            sleep( 1, 1 )
            MutexLock( Global_IRC.Mutex )
            MutexUnlock( tracker->Mutex )
            LIC_Main( )
            MutexLock( tracker->Mutex )
         EndIf
      Wend
      
      if msglen > 30000 then
         sleep( 250, 1 )
      end if
      tracker->socket->p_send_sleep = 50
      
      Function = -1      

   EndIf

End Function

Sub DCC_LIST_TYPE.Proc( )

   if Used = 0 then Exit Sub

   For i As Integer = 0 To Allocated - 1

      If tracker[i] = 0 Then Continue For
      if tracker[i]->Type_ <> DCC_CHAT then Continue For

      with *( tracker[i] )
      
      ScopeLock( .Mutex )
      
      var msg = ""
      var URT = cptr( UserRoom_type ptr, .RoomPtr )      

      select case .Status

      case DCC_STATUS.Listening

         select case .SockStatus

         case NO_RETURN
            Continue for

         case TRUE
            .Status = DCC_STATUS.Transferring
            URT = cptr( Server_Type ptr, .ServerPtr )->AddRoom( .User, DccChat )
            URT->AddLOT( "Connection established, you may now chat",  Global_IRC.Global_Options.JoinColour, , , , , TRUE )
            .RoomPtr = URT

         case FALSE
            .Status = DCC_STATUS.Failed
            Notice_GUI( "** DCC CHAT: " & .User & " did not respond or there was a network error", Global_IRC.Global_Options.ServerMessageColour )
            Remove( .ID )
            Exit Sub

         End Select

      case DCC_STATUS.Connecting

         select case .SockStatus

         case NO_RETURN
            Continue For

         case chi.SOCKET_OK
            .Status = DCC_STATUS.Transferring
            msg = "** Connection established, you may now chat"

         case else
            .Status = DCC_STATUS.Failed
            msg = "** Connection failed. " & chi.translate_error( .SockStatus )

         End Select

         if len_hack( msg ) > 0 then
            URT->AddLOT( msg, Global_IRC.Global_Options.ServerMessageColour, , , , , TRUE )
         EndIf

      case DCC_STATUS.Transferring

         var l = .Socket->Length( )

         #define MAX_SIZE 1024 * 16 - 1

         if l > 0 then

            if l > MAX_SIZE then l = MAX_SIZE
            dim as ubyte ptr buffer = allocate( l + 1 )

            l = .Socket->get_data( buffer, l, TRUE )
            buffer[ l ] = 0

            msg = *cptr( zstring ptr, buffer )

            if ( l <> MAX_SIZE ) and ( .Socket->IS_Closed( ) = TRUE ) then
               msg += !"\n"
            end if
            
            var n = InStrASM( 1, msg, 10 )

            if n > 0 then
               l = 0
               while n > 0
                  str_len( msg ) = n - 1
                  msg[ n - 1 ] = 0
                  RTrim2( msg, !"\r" )                  
                  LIC_DEBUG( "DCC:" & .id & ":" & msg )
                  StripColour( msg )
                  if ( asc( msg ) = 1 ) and ( asc( msg, len_hack( msg ) ) = 1 ) then
                     CharKill( msg )
                     select case ucase( mid( msg, 1, InStrASM( 1, msg, asc(" ") ) - 1 ) )
                     case "ACTION"
                        URT->AddLOT( "*" & .user & Mid( msg, 7 ), _
                           Global_IRC.Global_Options.WhisperColour, 1, ActionEmote )
                     case else
                        URT->AddLOT( "[ " + .user + " ]: " + msg, _
                           Global_IRC.Global_Options.WhisperColour, 1, NormalChat )
                     end select
                  else
                     CharKill( msg )
                     URT->AddLOT( "[ " & .user & " ]: " & msg, Global_IRC.Global_Options.WhisperColour, 1, NormalChat )
                  end if
                  l += n
                  msg = *cptr( zstring ptr, buffer + l )
                  n = InStrASM( 1, msg, 10 )
               Wend

            elseif l = MAX_SIZE then

               'if they send a very long ACTION it will not be displayed properly (oh well?)
               LIC_DEBUG( "DCC:" & .id & ":" & msg )
               URT->AddLOT( "[ " & .user & " ]: " & msg & " [...]", Global_IRC.Global_Options.WhisperColour, 1, NormalChat )

            else
               l = 0

            endif

            if l > 0 then
               .Socket->Dump_Data( l )
            EndIf

            deallocate( buffer )

            if ( l = MAX_SIZE ) and ( n = 0 ) then
               MutexUnlock( .Mutex )
               'LIC_DEBUG( "Recursing" )
               Proc( )
               MutexLock( .Mutex )
            EndIf

         elseif .Socket->IS_Closed( ) = TRUE then

            URT->AddLOT( "** Lost connection to " & .user, Global_IRC.Global_Options.LeaveColour, , , , , TRUE )
            .Status = DCC_STATUS.Complete

         End If

      End select

      End With

   next

End Sub
#endif