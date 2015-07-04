#Include Once "lic.bi"
#Include Once "lic-server.bi"
#Include once "lic-numeric.bi"
#include once "file.bi"
#include once "crt/string.bi"

dim shared as integer IDENT_RUNNING

Constructor Server_Type

   Mutex = MutexCreate( )
   Status = NO_RETURN

   With ServerInfo
      .IPrefix( 0 ) = Asc("o") : .VPrefix( 0 ) = Asc("@")
      .IPrefix( 1 ) = Asc("v") : .VPrefix( 1 ) = Asc("+")
      .CHANTYPES( 0 ) = Asc("#")
      .CHANTYPES( 1 ) = Asc("&")
      .CHANTYPES( 2 ) = Asc("!")
      .CHANTYPES( 3 ) = Asc("+")
      .NICKLEN = 9
      .MODES = 4
   End With

   Numeric.RPL_ISUPPORT = 5

End Constructor

Destructor Server_Type

   LIC_DESTRUCTOR1

   MutexLock( Mutex )

'FIXME!!!
#if LIC_CHI
   If ServerSocket.Is_Closed( ) = FALSE Then
      ServerSocket.p_send_sleep = 1
      var msg = "QUIT :"
      if len( Global_IRC.Global_Options.QuitMessage ) <> 0 then
         msg += Global_IRC.Global_Options.QuitMessage
      else
         msg += IRC_Version_name " v" IRC_Version_major "." IRC_Version_minor " build " & IRC_Version_build
      EndIf
      SendLine( msg, TRUE )
      sleep( 100, 1 )
      ServerSocket.Close( )
   EndIf
#else
   closesocket( ServerSocket )
#endif

   var LB_Size = Global_IRC.Global_Options.LogBufferSize
   Global_IRC.Global_Options.LogBufferSize = 0

   If ( Global_IRC.Global_Options.LogToFile <> 0 ) and ( (Lobby->pflags AND ChannelLogging) <> 0 ) then
      LogToFile( "server messages", _
         "=========================================="       & NewLine & _
         "==== Session End: " & Date & " " & Time & " ====" & NewLine & _
         "=========================================="       & NewLine _
      )
   EndIf

   MutexUnLock( Mutex )

   if ServerOptions.ChanInfo <> 0 then
      Delete ServerOptions.ChanInfo
      ServerOptions.ChanInfo = 0
   EndIf

   var URT = FirstRoom

   For i As Integer = 1 To ( NumRooms - 1 )
      URT = URT->NextRoom
      Delete URT->PrevRoom
   Next

   Delete URT
   NumRooms = 0

   Global_IRC.Global_Options.LogBufferSize = LB_Size

   CurrentNick = ""
   SendBuffer = ""
   LogBuffer = ""
   ServerName = ""

   MutexDestroy( Mutex )

   LIC_DESTRUCTOR2

End Destructor

Destructor irc_message

   msg         = ""
   Raw         = ""
   From        = ""
   Parameters  = ""
   Prefix      = ""
   MessageTag  = ""

End Destructor

Sub Server_Type.DetachRoom( Byref room as UserRoom_Type ptr )
   var URT = RoomCheck( room )
   if URT = 0 then
      exit sub
   EndIf

   URT->PrevRoom->NextRoom = URT->NextRoom

   If URT = LastRoom Then
      LastRoom = URT->PrevRoom
   Elseif URT = FirstRoom then
      FirstRoom = URT->NextRoom
      URT->NextRoom->PrevRoom = URT->PrevRoom
   else
      URT->NextRoom->PrevRoom = URT->PrevRoom
   EndIf

   NumRooms -= 1

End Sub

Sub Server_Type.AttachRoom( Byref room as UserRoom_Type ptr )

#if LIC_DCC
   var DT = Global_IRC.DCC_List.Find( room )
   if DT <> 0 then
      DT->ServerPtr = @this
   EndIf
#endif

   room->Server_Ptr = @this
   room->PrevRoom = LastRoom
   room->NextRoom = FirstRoom
   LastRoom->NextRoom = room
   FirstRoom->PrevRoom = room
   LastRoom = room

   NumRooms += 1

End Sub

Sub Server_Type.LoadScriptFile( )

   var f = freefile
   var fo = Open( ServerOptions.ScriptFile for binary access read as #f )
   ServerOptions.ScriptFile = "" 'no need to keep it in memory

   if fo <> 0 then
      exit sub
   EndIf

   dim as string li

   while not( eof( f ) )

      line input #f, li

      if ( len_hack( li ) > 0 ) andalso ( li[0] <> asc("'") ) then
         AddScript( li )
      EndIf

   Wend

   close #f

End Sub

Function Server_Type.AddScript( byref li as string ) as integer

   dim as ParamList_Type PL = li
   dim as event_type et
   dim as integer ret = FALSE

   et._string = li

   select case lcase( PL.s[0] )
   case "filter"
      'filter <host> <command> [ param1 ... ]

      if PL.count < 3 then
         exit function
      EndIf

      et.id = Script_Filter

      if PL.s[1] <> "*" then
         'skip MaskCompare if it's just a wildcard
         et.mask = PL.s[1]
      EndIf

      select case lcase( PL.s[2] )
      case "join"
         et._integer = IRC_JOIN
      case "quit"
         et._integer = IRC_QUIT
      case "part"
         et._integer = IRC_PART
      case "privmsg"
         et._integer = IRC_PRIVMSG
      case "notice"
         et._integer = IRC_NOTICE
      case "nick"
         et._integer = IRC_NICK
      case "mode"
         et._integer = IRC_MODE
      case "kick"
         et._integer = IRC_KICK
      case "*"
         et._integer = 0
         '0 will match all
      case else
         exit function
      End Select

      for i as integer = 4 to iif( PL.count > ubound( et.param ) + 4, ubound( et.param ) + 4, PL.count )
         if PL.s[i - 1] <> "*" then
            et.param(i - 4) = PL.s[i - 1]
         EndIf
      Next

      ret = TRUE

   case "wordfilter"
      'wordfilter <host> <match text>

      if PL.count < 3 then
         exit function
      EndIf

      if PL.s[1] <> "*" then
         'skip MaskCompare if it's just a wildcard
         et.mask = PL.s[1]
      EndIf

      et._integer = IRC_PRIVMSG      
      et.id = Script_WordFilter
      et.param(0) = *cptr( zstring ptr, @li[ PL.start[2] ] )
      ret = TRUE   
      
   case "wordmatch"
      'wordmatch <host> <action1|action2> <match text>
      
      if PL.count < 3 then
         exit function
      EndIf

      if PL.s[1] <> "*" then
         'skip MaskCompare if it's just a wildcard
         et.mask = PL.s[1]
      EndIf

      et._integer = IRC_PRIVMSG
      et.id = Script_WordMatch
      
      if PL.count >= 4 then            
         et.param(0) = *cptr( zstring ptr, @li[ PL.start[3] ] )
      EndIf
      
      PL.s[2] &= "|"
      var start = 1, end_ = instr( start, PL.s[2], "|" )
      while end_ > start
         select case lcase( mid( PL.s[2], start, end_ - start ) )
         case "filter"
            et.action OR= MF_filter
         case "notify"
            et.action OR= MF_notify
         case "hilite"
            et.action OR= MF_hilight
         End Select
         start = end_ + 1
         end_ = instr( start, PL.s[2], "|" )
      Wend
      
      if et.action <> 0 then
         ret = TRUE
      EndIf   

   case "ctcpfilter"
      'ctcpfilter [<host>]

      et.id = Script_CtcpFilter
      if PL.count >= 2 andalso PL.s[1] <> "*" then
         et.mask = PL.s[1]
      end if

      et._integer = IRC_PRIVMSG
      ret = TRUE
   
   case "matchaction"
      'match <host> <command> [ param1 ... ] {mode #mychan +b user!*}{kick #mychan user}{privmsg #mychan :these are curly brackets"{}"}

      if PL.count < 3 then
         exit function
      EndIf
      
      et.id = Script_MatchAction
      
      if PL.s[1] <> "*" then
         et.mask = PL.s[1]
      end if
      
      select case lcase( PL.s[2] )
      case "join"
         et._integer = IRC_JOIN
      case "quit"
         et._integer = IRC_QUIT
      case "part"
         et._integer = IRC_PART
      case "privmsg"
         et._integer = IRC_PRIVMSG
      case "notice"
         et._integer = IRC_NOTICE
      case "nick"
         et._integer = IRC_NICK
      case "mode"
         et._integer = IRC_MODE
      case "kick"
         et._integer = IRC_KICK
      case "*"
         et._integer = 0
         '0 will match all
      case else
         exit function
      End Select
      
      ret = instrasm( 1, PL.copyv, asc("{") )
      
      if ret <= 0 then
         exit function
      EndIf
      
      'Assign the params
      dim as ParamList_Type PL2 = RTrim( left( PL.copyv, ret - 1 ) )
      
      for i as integer = 4 to iif( PL2.count > ubound( et.param ) + 4, ubound( et.param ) + 4, PL2.count )
         if PL2.s[i - 1] <> "*" then
            et.param(i - 4) = PL2.s[i - 1]
         EndIf
      Next
      
      'Actions
      var actions = String_Replace( "}", !"\n", mid( PL.copyv, ret + 1 ) )
      et.saction = String_Replace( "{", "", actions )

      ret = TRUE

   End Select

   if ret = TRUE then
      Event_Handler.Add( @et )
   end if
   
   Function = ret

End function

Function Server_Type.ResizeRoom( ByVal URT as UserRoom_type ptr ) as UserRoom_Type ptr

   dim as string text, TimeStamp
   dim as integer i, max
   dim as uInt32_t colour
   dim as LOT_MultiColour_Descriptor ptr MCD
   dim as LOT_MultiColour_Descriptor ptr ptr MCD_PTR

   var LLH = Global_IRC.Global_Options.LogLoadHistory
   Global_IRC.Global_Options.LogLoadHistory = 0

   var n = AddRoom( URT->RoomName, URT->RoomType )
   Function = n

   for i = 0 to n->NumLines - 1
      delete n->TextArray[i]
   Next
   n->NumLines = 0

   if URT->NumLines > 0 then

      URT->TextArray[0]->MesID AND= &H00FFFFFE

      max = URT->NumLines - 1

      for i = 0 to max

         if ( URT->TextArray[i]->MesID AND 1 ) = 0 then
            swap text, URT->TextArray[i]->Text
            colour = URT->TextArray[i]->Colour
            TimeStamp = URT->TextArray[i]->TimeStamp
            MCD_PTR = @MCD
         else
            text += URT->TextArray[i]->Text
         EndIf

         var MC = URT->TextArray[i]->MultiColour
         while MC <> 0

            *MCD_PTR = new LOT_MultiColour_Descriptor

            with *MCD_PTR[0]
               .TextStart = MC->TextStart
               .TextLen = len_hack( MC->Text )
               .Colour = MC->Colour
               MCD_PTR = @( .NextDesc )
            End With

            MC = MC->NextMC

         Wend

         'var HL = URT->TextArray[i]->HyperLinks
         'while HL <> 0
         '   select case HL->id
         '   case LinkShell
         '      hmm, search in the LOTs?
         '   'case else [ are detected in AddLOT() ]
         '   End Select
         '   HL = HL->NextLink
         'Wend

         if ( i = max ) orelse ( ( URT->TextArray[i + 1]->MesID AND 1 ) = 0 ) then

            var LOT = n->AddLOT( text, colour, 0, URT->TextArray[i]->MesID AND &H00FFFFFE, 0, MCD, TRUE )
            LOT->TimeStamp = TimeStamp

            if MCD <> 0 then
               delete MCD
               MCD = 0
            EndIf

         EndIf

      next

   endif

   n->pflags = URT->pflags
   n->LastModeTime = URT->LastModeTime

   swap n->FirstUser, URT->FirstUser
   swap n->LastUser, URT->LastUser
   swap n->TopDisplayedUser, URT->TopDisplayedUser
   swap n->NumUsers, URT->NumUsers
   swap n->Topic, URT->Topic
   swap n->LastMode, URT->LastMode
   swap n->LogBuffer, URT->LogBuffer
   swap n->OldUsers, URT->OldUsers

#if LIC_DCC
   select case URT->RoomType
   case DccChat
      var tracker = Global_IRC.Dcc_List.Find( URT )
      tracker->RoomPTR = n
   End Select
#endif

   'Disable any special handling by DelRoom()
   URT->RoomType = Channel
   URT->pflags AND= NOT( ChannelLogging )

   DelRoom( URT )

   Global_IRC.Global_Options.LogLoadHistory = LLH

End Function

Function Server_Type.RoomCheck( byref r as any ptr ) as UserRoom_Type ptr

   var ret = lobby
   for i as integer = 1 to NumRooms
      if cptr( any ptr, ret ) = r then
         return ret
      EndIf
      ret = ret->NextRoom
   Next

End Function

Sub Server_type.DelRoom( ByRef r As string )

   var URT = Find( r )
   If URT Then DelRoom( URT )

End Sub

Sub Server_type.DelRoom( Byref Room As UserRoom_type Ptr )

   var URT = Room

   if Room = Global_IRC.SwapRoom then Global_IRC.SwapRoom = 0

   select case Room->RoomType
#if LIC_DCC
   case RoomTypes.DccChat
      var tracker = Global_IRC.DCC_List.Find( Room )
      if tracker <> 0 then
         MutexLock( tracker->Mutex )
         if tracker->SockStatus = NO_RETURN then
            MutexUnlock( tracker->Mutex )
            ThreadWait( tracker->thread )
         else
            MutexUnlock( tracker->Mutex )
         EndIf
         if tracker->socket->Is_Closed( ) = FALSE then
            tracker->socket->Close( )
            sleep( 500, 1 )
         endif
         Global_IRC.DCC_List.Remove( tracker->ID )
      EndIf
#endif
   case RoomTypes.Lobby, RoomTypes.RawOutput
      If Global_IRC.NumVisibleRooms > 1 then
         Room->pflags OR= Hidden
         If Global_IRC.CurrentRoom = URT Then
            URT = GetPrevRoom
            While (URT->pflags AND Hidden)
               URT = GetPrevRoom( URT )
            Wend
            Global_IRC.SwitchRoom( URT )
         EndIf
      End if
      Exit Sub
   End Select

   If (Room->pflags AND ChannelLogging) Then

      If ( Room->RoomType = RoomTypes.Channel ) And ( Global_IRC.Global_Options.LogJoinLeave = 1 ) Then
         Global_IRC.LogLength -= len_hack( Room->LogBuffer )
         Room->LogBuffer += Date & " (" & Time & ") ==== You Left The Room ====" & NewLine
         Global_IRC.LogLength += len_hack( Room->LogBuffer )
      endif

      If ( Global_IRC.Global_Options.LogBufferSize > 0 ) And ( Len_Hack( Room->LogBuffer ) > 0 ) Then
         if Room->RoomType = RoomTypes.DccChat then
            LogToFile( "dcc " + Room->RoomName, Room->LogBuffer )

         else
            LogToFile( Room->RoomName, Room->LogBuffer )

         endif
      endif

   EndIf

   URT->PrevRoom->NextRoom = URT->NextRoom

   If URT = LastRoom Then
      LastRoom = URT->PrevRoom
   Elseif URT = FirstRoom then
      FirstRoom = URT->NextRoom
      URT->NextRoom->PrevRoom = URT->PrevRoom
   else
      URT->NextRoom->PrevRoom = URT->PrevRoom
   EndIf

   If Global_IRC.NumVisibleRooms = 0 Then Lobby->pflags AND= NOT( Hidden )

   If Global_IRC.CurrentRoom = URT Then
      URT = GetPrevRoom
      While (URT->pflags AND Hidden)
         URT = GetPrevRoom( URT )
      Wend
   EndIf

   if ListRoom = Room then
      ListRoom = 0
      ListStatus = Cancelled
   EndIf

   NumRooms -= 1

   If URT <> Room Then
      Global_IRC.SwitchRoom( URT )
   else
      Global_IRC.DrawTabs( )
   EndIf

   Delete Room
   Room = 0

End Sub

Function Server_type.Find( ByRef room As zString Ptr ) As UserRoom_type Ptr

   var URT = FirstRoom
   Var UcaseName = Ucase_( *room )
   Var SortFind = SortCreate( UcaseName )

   For i As Integer = 1 To NumRooms
      If ( URT->RoomType = Channel ) or ( URT->RoomType = PrivateChat ) then
         If URT->Sort = SortFind Then
            If ( len_hack( UcaseName ) < 9 ) and ( len_hack( UcaseName ) = len_hack( URT->RoomName ) ) Then
               Return URT
            Else
               Dim As String Str2 = Ucase_( URT->Roomname )
               If StringEqualAsm( UcaseName, Str2 ) Then
                  Return URT
               EndIf
            endif
         EndIf
      endif
      URT = URT->NextRoom
   Next

End Function

Function Server_type.AddRoom( ByRef r As zString Ptr, byref roomtype as int16_t ) As UserRoom_type Ptr

   dim as string FirstLOT
   dim as uInt32_t FirstColour

   var NewRoom = New UserRoom_type

   NumRooms += 1

   NewRoom->Server_Ptr = @This
   NewRoom->NumAllocated = 128
   NewRoom->TextArray = Allocate( SizeOf( Any Ptr ) * NewRoom->NumAllocated )

   NewRoom->RoomName = *r
   NewRoom->RoomType = roomtype

   NewRoom->pflags OR= iif( Global_IRC.Global_Options.ShowJoinLeave, ChannelJoinLeave, 0 )
   NewRoom->pflags OR= iif( Global_IRC.Global_Options.NotifyOnChat, ChannelNotify, 0 )
   NewRoom->pflags OR= iif( Global_IRC.Global_Options.LogToFile, ChannelLogging, 0 )
   NewRoom->pflags OR= iif( Global_IRC.Global_Options.ShowHostNames, ChannelHostname, 0 )

   If NumRooms > 1 Then
      NewRoom->PrevRoom = LastRoom
      NewRoom->NextRoom = FirstRoom
      LastRoom->NextRoom = NewRoom
      FirstRoom->PrevRoom = NewRoom
   Else
      FirstRoom = NewRoom
      NewRoom->NextRoom = NewRoom
      NewRoom->PrevRoom = NewRoom
   EndIf

   LastRoom = NewRoom
   NewRoom->ChatScrollBarY = Global_IRC.Global_Options.ScreenRes_y - 16

	if roomtype = Channel then
      NewRoom->UserListWidth = Global_IRC.Global_Options.DefaultUserListWidth
      NewRoom->TextBoxWidth = Global_IRC.Global_Options.DefaultTextBoxWidth - iif( NewRoom->UserListWidth = 0, 10, 0 )
      FirstLOT = "Joined the " & NewRoom->RoomName & " channel"
      FirstColour = Global_IRC.Global_Options.JoinColour

      var CIT = ServerOptions.ChanInfo
      while CIT <> 0

         if InStr( CIT->ChanNames, ucase( NewRoom->RoomName ) + " " ) then

            if CIT->Notify <> &b11 then
               if CIT->Notify then NewRoom->pflags OR= ChannelNotify else NewRoom->pflags AND= NOT( ChannelNotify )
            EndIf            
            if CIT->JoinLeave <> &b11 then
               if CIT->JoinLeave then NewRoom->pflags OR= ChannelJoinLeave else NewRoom->pflags AND= NOT( ChannelJoinLeave )
            EndIf
            if CIT->Logging <> &b11 then
               if CIT->Logging then NewRoom->pflags OR= ChannelLogging else NewRoom->pflags AND= NOT( ChannelLogging )
            EndIf
            if CIT->HostName <> &b11 then
               if CIT->HostName then NewRoom->pflags OR= ChannelHostname else NewRoom->pflags AND= NOT( ChannelHostname )
            EndIf

         EndIf

         CIT = CIT->next_ptr
      Wend

      if (NewRoom->pflags AND ChannelLogging) then
         if asc( ServerOptions.LogFolder ) = asc("?") then
            NewRoom->pflags AND= NOT( ChannelLogging )
         elseif MkDirTree( ServerOptions.LogFolder ) <> 0 then
            ServerOptions.LogFolder = "?" + ServerOptions.LogFolder
            NewRoom->pflags AND= NOT( ChannelLogging )
         endif
      EndIf

   Else
      NewRoom->UserListWidth = -1
      NewRoom->TextBoxWidth = Global_IRC.Global_Options.ScreenRes_x - 13
      if asc( ServerOptions.LogFolder ) = asc("?") then NewRoom->pflags AND= NOT( ChannelLogging )

      select case roomtype

         case RoomTypes.PrivateChat
            FirstLOT = "Now Chatting Privately with " & NewRoom->RoomName
            FirstColour = Global_IRC.Global_Options.JoinColour

         case RoomTypes.List
            FirstLOT = ServerOptions.Server & " Channel List, click a channel on the left to view it's full info"
            FirstColour = Global_IRC.Global_Options.ServerMessageColour
            NewRoom->UserListWidth = Global_IRC.Global_Options.ScreenRes_X \ 3
            NewRoom->TextBoxWidth = Global_IRC.Global_Options.ScreenRes_X - 13 - NewRoom->UserListWidth
            NewRoom->pflags AND= NOT( ChannelLogging )
            this.ListRoom = NewRoom

         case RoomTypes.Lobby
            if Global_IRC.Global_Options.LogLobby = 0 then NewRoom->pflags AND= NOT( ChannelLogging )
            NewRoom->AddLOT( "This is a lobby channel for server messages", Global_IRC.Global_Options.ServerMessageColour, 0, Notification, , , TRUE )
            NewRoom->pflags AND= NOT( FlashingTab )
            this.Lobby = NewRoom

         case RoomTypes.DccChat
            FirstLOT = "This is a DCC Private Chat, all messages will go directly to the user. Use ESCAPE to end this session"
            FirstColour = Global_IRC.Global_Options.JoinColour
         
         case RoomTypes.RawOutput
            if Global_IRC.Global_Options.LogRaw = 0 then NewRoom->pflags AND= NOT( ChannelLogging )
            FirstLOT = "This is the raw irc window"
            FirstColour = Global_IRC.Global_Options.ServerMessageColour
            this.RawRoom = NewRoom

      End Select

	Endif

	NewRoom->Sort = SortCreate( Ucase_( NewRoom->RoomName ) )

	if len( FirstLOT ) then
	   NewRoom->AddLOT( FirstLOT, FirstColour, 0, , , , TRUE )
	EndIf

   if ( RoomType = RoomTypes.Channel ) and ( Global_IRC.Global_Options.LogLoadHistory > 0 ) then
      NewRoom->LoadHistory( )
   End If

   Global_IRC.DrawTabs( )

   Function = NewRoom

End Function

Sub IDENT_Server_Thread( )

   dim as integer NumServers, Port, status
   dim as string UserID, SystemID

   with Global_IRC
      MutexLock( .Mutex )
      IDENT_RUNNING  = TRUE
      NumServers     = .NumServers
      Port           = .Global_Options.IdentPort
      UserID         = .Global_Options.IdentUser
      SystemID       = .Global_Options.IdentSystem
      MutexUnLock( .Mutex )
   end with

'FIXME!!!
#if LIC_CHI
   var IdentSocket = New chi.socket

   status = IdentSocket->Server( Port, NumServers )

   if status <> chi.SOCKET_OK then

      SystemID = "ERROR: Ident Failed to create listen socket on port " & Port
      LIC_DEBUG( "\\" + SystemID )
      MutexLock( Global_IRC.Mutex )
      Global_IRC.CurrentRoom->AddLOT( "*** " + SystemID, Global_IRC.Global_Options.LeaveColour, , , , , TRUE )
      MutexUnlock( Global_IRC.Mutex )

   else

      var TimesUp = Timer + 30
      var buffer = space( 512 )

      while Timer < TimesUp

         sleep( 1, 1 )

         dim as chi.socket newsock

         if newsock.listen_to_new( *IdentSocket, 10 ) = TRUE then
         '<port> , <port> : USERID : <system> : <user>

            dim as string request
            dim as integer L

            do while ( len_hack( request ) = 0 ) and ( newsock.Is_Closed( ) = FALSE )

               sleep( 1, 1 )
               L = newsock.length( )
               if L > 0 then

                  if L > 512 then L = 512

                  L = newsock.get_data( @buffer[0], L, TRUE )
                  buffer[L] = 0
                  str_len( buffer ) = L

                  if InStrASM( 1, buffer, asc( !"\n" ) ) > 0 then
                     request = RTrim( buffer, any !"\r\n " )
                     newsock.dump_data( newsock.length( ) )
                  elseif L = 512 then
                     'somethings wrong..?
                     newsock.Close( )
                  EndIf

               EndIf

            loop

            if ( newsock.Is_Closed( ) = TRUE ) or ( len_hack( request ) = 0 ) then
               Continue While
            EndIf

            request += " : USERID : " + SystemID + " : " + UserID
            newsock.put_line( request )
            LIC_DEBUG( "\\Sent Ident Response: " + request )

            sleep( 250, 1 )

            newsock.Close( )

         EndIf

      wend

      IdentSocket->Close( )

   EndIf

   MutexLock( Global_IRC.Mutex )
   IDENT_RUNNING = FALSE
   MutexUnlock( Global_IRC.Mutex )
   if status = chi.SOCKET_OK then
      sleep( 2000, 1 )
   end if
   Delete IdentSocket

#endif

End Sub

sub Server_Type.IRC_Connect( )

   dim as string tmp

   Select Case State
      Case ServerStates.connecting
         ScopeLock( Mutex )
         If Timer > ( LastServerTalk + 30 ) Then
            LIC_Debug( "\\Connection Timed Out [" & ServerNum & "]" )
            #if LIC_CHI
               ServerSocket.Close( )
               Status = chi.FAILED_CONNECT
            #else
               closesocket( ServerSocket )
               'FIXME!!! Status =  
            #endif
            tmp = "Error: 'Connection timed out'"
         elseIf Status = NO_RETURN Then
            Exit sub
         else
         #if LIC_CHI
            tmp = "Error: '" & chi.translate_error( Status ) & "'"
         #endif
         EndIf
      Case ServerStates.disconnected
         If Timer > ( LastServerTalk + ReconnectTime ) Then
            If ReconnectTime < 60 Then ReconnectTime += 5
            tmp = "Attempting to connect to " & ServerOptions.Server & ":" & ServerOptions.Port
            LIC_Debug( "\\" & tmp & " [" & ServerNum & "]" )
            Lobby->AddLOT( tmp & "...", Global_IRC.Global_Options.ServerMessageColour, 1 )
            State = ServerStates.Connecting
            LastServerTalk = Timer
            #if LIC_CHI
            If ServerSocket.Length( ) Then ServerSocket.Dump_Data( ServerSocket.Length( ) )
            #endif
            If ( Global_IRC.Global_Options.IdentEnable <> 0 ) and ( IDENT_RUNNING = FALSE ) then
               dim as event_type e
               e.id = Thread_Wait
               e._ptr = ThreadCreate( CPtr( Any Ptr, ProcPtr( IDENT_Server_Thread ) ), , 1024 * 64 )
               e.when = Timer + 35
               Global_IRC.Event_handler.Add( @e )
               MutexUnlock( Global_IRC.Mutex )
               sleep( 26, 1 )
               MutexLock( Global_IRC.Mutex )
            EndIf

            Status = NO_RETURN
            
            'FIXME!!!
            #if LIC_CHI
            var t = new threadConnect
            *t = type( @ServerSocket, strptr( ServerOptions.Server ), 0, ServerOptions.Port, 0, Mutex, @Status )

            ThreadHandle = ThreadCreate( CPtr( Any Ptr, @chiConnect ), t, 1024 * 64 )
            #endif

         EndIf
         Exit Sub
      Case ServerStates.offline
         Exit Sub
      Case ServerStates.online
         LIC_Debug( "\\Disconnected" & " [" & ServerNum & "]" )
         SendBuffer = ""
         If Global_IRC.Global_Options.AutoReconnect <> 0 Then
            State = ServerStates.Disconnected
            Lobby->AddLOT( "Lost Connection!! Reconnecting...", Global_IRC.Global_Options.LeaveColour )
         Else
            State = ServerStates.Offline
            Lobby->AddLOT( "Lost Connection!! Use '/Connect " & ServerNum + 1 & "' to reconnect", Global_IRC.Global_Options.LeaveColour )
         EndIf
         Var URT = FirstRoom
         For i As Integer = 1 To NumRooms
            If IS_Channel( URT->RoomName ) then
               URT->pflags AND= NOT( pChanFlags.online )
            Endif
            URT = URT->NextRoom
         Next
         Exit Sub
   End Select

   LastServerTalk = Timer

   if ThreadHandle <> 0 then
      ThreadWait( ThreadHandle )
      ThreadHandle = 0
   end if

   If Status <> chi.SOCKET_OK Then
      If Global_IRC.Global_Options.AutoReconnect <> 0 Then
         State = ServerStates.Disconnected
         tmp += " Retrying in " & ReconnectTime & " seconds"
      Else
         State = ServerStates.Offline
         tmp += " Use '/Connect " & ServerNum + 1 & "' to retry"
      EndIf
      Lobby->AddLOT( tmp, Global_IRC.Global_Options.ServerMessageColour )
      LIC_Debug( "\\" & tmp & "[" & ServerNum & "]" )
      Exit Sub
   EndIf
   
   ListStatus = ListFinished
   State = ServerStates.Online
   LIC_Debug( "\\Connected" & " [" & ServerNum & "]" )
   Lobby->AddLOT( "Connected! Now authorizing...", Global_IRC.Global_Options.ServerMessageColour )

   With ServerOptions

   if len( .Password ) > 0 Then
      SendLine( "PASS " & .Password, TRUE )
   EndIf
   SendLine( "USER " + .username + " " + .hostname + " " + .server + " :" + .RealName, TRUE )
   SendLine( "NICK " + .nickname, TRUE )
   if len( .AutoExec ) > 0 then
      sleep( 250, 1 )
      dim as integer n, n2 = instrasm( 1, .AutoExec, 10 )
      do
         SendLine( mid( .AutoExec, n + 1, n2 - n ), TRUE )
         n = n2
         n2 = instrasm( n2 + 1, .AutoExec, 10 )         
      Loop until n2 = 0
   EndIf

   End with

   If Len( EOL ) > 0 Then
      If Len( CurrentNick ) > 0 Then
         'Autojoin the rooms you were currently in
         Var URT = FirstRoom
         ServerOptions.AutoJoin = ""
         For i As Integer = 1 To NumRooms
            If URT->RoomType = Channel then
               ServerOptions.AutoJoin += URT->RoomName & " "
            Endif
            URT = URT->NextRoom
         Next
         RTrim2( ServerOptions.AutoJoin )
      endif
      Exit Sub
   EndIf

   'LIC_Debug( "\\Detecting EOL.." )

   #define MAX_SIZE 1024 * 4 - 1
   tmp = space( MAX_SIZE )
   var N = 1
   var timeout = timer + 10

   Do
      If ServerSocket.Is_Closed( ) = TRUE Then
         ServerSocket.Dump_data( ServerSocket.Length( ) )
         Exit Sub
      elseIf ServerSocket.length( ) > 0 Then
         Var AmountToGet = ServerSocket.Length( )
         If AmountToGet > MAX_SIZE Then AmountToGet = MAX_SIZE
         AmountToGet = ServerSocket.Get_data( @tmp[0], AmountToGet, TRUE )
         tmp[ AmountToGet ] = 0
         N = InstrAsm( N, tmp, asc( !"\n" ) )
         If N > 0 Then
            If N > 1 Then
               if tmp[ N - 2 ] = asc( !"\r" ) then
                  EOL = !"\r\n"
               else
                  EOL = !"\n"
               endif
            Else
               EOL = !"\n"
            EndIf
            Exit Do
         Else
            If AmountToGet = MAX_SIZE Then
               'This should never happen.. but it is not impossible
               LIC_DEBUG( "\\Dumping during EOL search" )
               ServerSocket.Dump_data( MAX_SIZE )
               AmountToGet = 0
            EndIf
            N = AmountToGet + 1
         EndIf
      EndIf
      if timer > timeout then
         ServerSocket.Close( )
         LIC_Debug( "\\EOL Time Out" & " [" & ServerNum & "]" )
         exit sub
      EndIf
      sleep( 50, 1 )
   Loop

   'LIC_Debug( "\\EOL: " & *IIf( Len( EOL ) = 1, @"\n", @"\r\n" ) & " [" & ServerNum & "]" )

End Sub

Sub Server_Type.SendLine( ByRef Message As String, byval BypassAntiFlood as integer = FALSE )

   var l = len_hack( Message ) - 1

   if l <= 0 then Exit Sub
   
   'LIC_DEBUG( "\\SendLine: " & Message )

   if BypassAntiFlood = FALSE then
      SendBuffer += Message
      If Message[ l ] <> asc( !"\n" ) then
         SendBuffer += chr( 10 )
      EndIf   
      PermitTransmission( )
   else
      dim as double OldAF = AntiFlood
      dim as string OldBuff
      swap SendBuffer, OldBuff
      SendBuffer = Message
      If Message[ l ] <> asc( !"\n" ) then
         SendBuffer += chr( 10 )
      EndIf  
      AntiFlood = 0
      PermitTransmission( TRUE )
      AntiFlood = OldAF
      swap SendBuffer, OldBuff
   end if

End Sub

Sub Server_Type.PermitTransmission( byval flush as integer = FALSE )

   'Qualifiers
   If Len_hack( SendBuffer ) <= 0 Then

      If AntiFlood <> 0 Then
         If ( SendTime + AntiFlood ) < Timer Then
            AntiFlood = 0
         EndIf
      EndIf

      Exit Sub

   elseIf ( ( SendTime + AntiFlood ) > Timer ) and ( flush = FALSE ) Then
      Exit Sub
   EndIf

   '''

   Dim As String SendIt, IRC_COMMAND
   Dim As Integer cutoff = InStrAsm( 1, SendBuffer, asc( !"\n" ) )

   If cutoff > 0 Then
      SendIt = Left( SendBuffer, cutoff - 1 )
      RTrim2( SendIt, !"\r\n", TRUE )
      SendBuffer = Mid( SendBuffer, cutoff + 1 )
   Else
      RTrim2( SendBuffer, !"\r\n", TRUE )
      SendIt = ""
      swap SendIt, SendBuffer
   endif

   if len_hack( SendIt ) <= 0 then
      LIC_DEBUG( "\\Empty SendIt in PermitTransmission()" )
      Exit sub
   EndIf

#if __FB_DEBUG__
   if Global_IRC.Global_Options.RawIRC <> 0 then
      LIC_Debug( SendIt )
   endif
#endif

   ServerSocket.put_line( SendIt )
   SendTime = Timer
   
   if Global_IRC.Global_Options.ShowRaw <> FALSE and RawRoom <> 0 then
      RawRoom->AddLOT( SendIt, Global_IRC.Global_Options.RawOutputColour )
   EndIf


   If AntiFlood < 2.6 then
      AntiFlood += 0.20 + AntiFlood * 0.10
   else
      AntiFlood = 3
   endif

   cutoff = InStrASM( 1, SendIt, asc(" ") )
   if cutoff = 0 then
      IRC_COMMAND = ucase( SendIt )
   else
      IRC_COMMAND = ucase( left( SendIt, cutoff - 1 ) )
   EndIf

   if len_hack( IRC_COMMAND ) < 4 then Exit Sub

   Dim Param( 2 ) 	As String
   Dim OfSet 			As Integer = 1
   Dim SpacePos      as Integer

   For i As Integer = 0 To 1
      SpacePos = InStrASM( OfSet, SendIt, asc(" ") )
      Param( i ) = Mid( SendIt, OfSet, SpacePos - OfSet )
      OfSet += Len_hack( Param( i ) ) + 1
   Next

   Param(2) = *cptr( zstring ptr, @SendIt[ InStrASM( 1, SendIt, Asc(":") ) ] )

   Var URT = Find( Param(1) )

   Select Case *CPtr( int32_t Ptr, StrPtr( IRC_COMMAND ) )

      case IRC_PRIVMSG

         If len_hack( Param(2) ) > 2 andalso _
            ( ( Param(2)[0] = 1 ) and ( Param(2)[ len_hack( Param(2) ) - 1 ] = 1 ) ) Then

            If URT = 0 Then
               if Global_IRC.CurrentRoom->Server_Ptr = @this then
                  URT = Global_IRC.CurrentRoom
               else
                  URT = Lobby
               EndIf
            EndIf

            Param(2) = Trim( Param(2), chr(1) )
            Var C = Ucase( Param(2) + " " )
            var S = InStrAsm( 1, C, Asc(" ") )

            Select Case Left( C, S - 1 )

               Case "VERSION"
                  URT->AddLOT( _
                     "** Sent CTCP Version Request to " & Param(1) & " ...", _
                     Global_IRC.Global_Options.ServerMessageColour, , , , , TRUE )

               Case "TIME"
                  URT->AddLOT( _
                     "** Sent CTCP Time Request to " & Param(1) & " ...", _
                     Global_IRC.Global_Options.ServerMessageColour, , , , , TRUE )

               Case "PING"
                  URT->AddLOT( _
                     "** Sent CTCP Ping Request to " & Param(1) & " ...", _
                     Global_IRC.Global_Options.ServerMessageColour, , , , , TRUE )

                  LastPingTime = SendTime

               Case "ACTION"
                  URT->AddLOT( _
                     "*" & CurrentNick & " " & Mid( Param(2), S + 1 ), _
                     Global_IRC.Global_Options.YourChatColour, 1, ActionEmote )

               case "DCC"

               case else
                  URT->AddLOT( _
                     "** Sent unknown CTCP to " & Param(1) & ": " & Param(2), _
                     Global_IRC.Global_Options.ServerMessageColour, , , , , TRUE )

            End Select

         else

            UTF8toANSI( Param(2) )

            If URT <> 0 Then
               
               var nick = CurrentNick
               var disablelog = Param(1)[0] = asc("*")
               
               if URT->RoomType = RoomTypes.Channel then
               
                  if Global_IRC.Global_Options.ShowPrivs <> 0 then
                     var UNT = URT->Find( nick )
                     if ( UNT <> 0 ) andalso ( UNT->Privs <> 0 ) then
                        nick = chr( UNT->Privs ) & nick
                     EndIf
                  EndIf
                  
               end if
               
               URT->AddLOT( _
                  "[ " & nick & " ]: " & Param(2), _
                  Global_IRC.Global_Options.YourChatColour, 1, NormalChat,,, disablelog )
               
            Else
               var disablelog = ( StringEqualASM( Ucase_( Param(1) ), UCase_( ServerOptions.IdentifyService ) ) <> 0 )
               Global_IRC.CurrentRoom->AddLOT( _
                  "** PM -> [ " & Param(1) & " ]: " & Param(2), _
                  Global_IRC.Global_Options.YourChatColour, 1, NormalChat,,, disablelog )
            EndIf

         endif

      case IRC_NOTICE

         If ( asc( Param(2) ) <> 1 ) and ( asc( right( Param(2), 1 ) ) <> 1 ) then

            If URT = 0 Then
               URT = Global_IRC.CurrentRoom
            EndIf

            UTF8toANSI( Param(2) )

            URT->AddLOT( _
               "** NOTICE -> [ " & Param(1) & " ]: " & Param(2), _
               Global_IRC.Global_Options.YourChatColour, 1, 0 )

         endif

      case IRC_PING

         const as string lag = "LIC LAG"

         if StringEqualAsm( Param(2), lag ) = 0 then
            Global_IRC.CurrentRoom->AddLOT( "** PING -> " & ServerName, Global_IRC.Global_Options.ServerMessageColour )
            LastPingTime = SendTime
         endif
      
      case TWITCH_USER 'not USERSTATE but just USER, this is ambiguous
         Lobby->AddLOT( "Sending " & SendIt, Global_IRC.Global_Options.ServerMessageColour )
      case IRC_PASS
         Lobby->AddLOT( "Sending PASS ****", Global_IRC.Global_Options.ServerMessageColour )
      
   End Select
   
   if len( SendBuffer ) > 0 AND flush = TRUE then
      PermitTransmission( flush )
   EndIf

End Sub

Function Server_Type.CheckIgnore( ByRef Nick As String ) As Integer

   If ( Len_hack( ServerOptions.IgnoreList ) = 0 ) or ( len_hack( Nick ) = 0 ) Then
      Return FALSE
   EndIf

   If IgnoreListDone = 0 Then
      IgnoreListDone = 1

      var l = UCase_( ServerOptions.IgnoreList )

      IgnoreArray.Build( l )

      for i as integer = 0 to IgnoreArray.Count - 1

         var idnt = InStrASM( 1, IgnoreArray.Array[i], asc("!") )
         var host = InStrASM( 1, IgnoreArray.Array[i], asc("@") )

         if ( idnt = 0 ) and ( host = 0 ) then
            IgnoreArray.Array[i] += "!*"
         EndIf
         if host = 0 then
            IgnoreArray.Array[i] += "@*"
         EndIf

      Next

   EndIf

   var UNick = UCase_( Nick )

   for i as integer = 0 to IgnoreArray.Count - 1

      if MaskCompare( UNick, IgnoreArray.Array[i] ) then
         return TRUE
      EndIf

   Next

   Function = FALSE

End Function

Function Server_Type.Ucase_( ByRef S As String ) As String

   /'
      ASCII maps a-z to A-Z
      STRICT-RFC1459 maps ascii as well as {}| to []\
      RFC1459 maps the two above and also ~ to ^
   '/

   dim as string Ret = S

   For i As Integer = 0 To ( Len_Hack( Ret ) - 1 )

      Select Case Ret[i]

         Case Asc("a") To Asc("z")
            const as integer lcasediff = asc("a") - asc("A")
            Ret[i] -= lcasediff
         case asc("A") to asc("Z")
            'all good
         Case Asc("{")
            If ServerInfo.CMap <> ASCII Then Ret[i] = asc("[")
         Case Asc("}")
            If ServerInfo.CMap <> ASCII Then Ret[i] = asc("]")
         Case Asc("|")
            If ServerInfo.CMap <> ASCII Then Ret[i] = asc("\")
         Case Asc("~")
            If ServerInfo.CMap = RFC1459 Then Ret[i] = asc("^")

      End Select

   Next

   Function = Ret

End Function

Function Server_Type.IS_Channel( ByRef S As String ) As Integer

   if len_hack( S ) <= 0 orelse S[0] = 0 then
      Return FALSE
   end if

   For i As Integer = 0 To UBound( ServerInfo.CHANTYPES )

      If S[0] = ServerInfo.CHANTYPES( i ) Then
         Return TRUE
      EndIf

   Next

   Function = FALSE

End Function

Function Server_Type.LogToFile _
   ( _
      ByRef filename    As String, _
      ByRef _str        As String _
   )  As Integer

   dim as int64_t size

   var sfn = lcase( SafeFileNameEncode( filename ) ) & ".log"
   var FF = FreeFile
   var Ret = Open( ServerOptions.LogFolder & "/" & sfn For Binary As #FF )

   If Ret = 0 Then
      Seek #FF, LOF( FF ) + 1
      #if __FB_DEBUG__
         if right( _str, len( NewLine ) ) <> NewLine then
            Print #FF, _str
            LIC_DEBUG( "\\No Newline '" & _str & "'" )
         else
            Print #FF, _str;
         endif
      #else
         print #FF, _str;
      #endif
      size = LOF( ff )
      Close #FF
      if Global_IRC.LogLength > 0 then
         Global_IRC.LogLength -= len_hack( _str )
      EndIf
      _str = ""
   Else
      LIC_DEBUG( "\\Error writing logfile '" & sfn & "' Err#" & Ret )
   EndIf

   Function = Ret

   ''Max File Size

   with Global_IRC.Global_Options

   if ( .LogMaxFileSize <= 0 ) or ( .LogMaxFileSize > size ) then
      Exit Function
   EndIf

   end with

   select case Global_IRC.Global_Options.LogMaxFileAction

   case LogCopy

      var copyname = ServerOptions.LogFolder & "/" & left( sfn, len( sfn ) - 4 ) & " " & date

      if FileExists( copyname + ".log" ) then
         var i = 1
         while FileExists( copyname & " (" & i & ")" & ".log" )
            i += 1
         Wend
         copyname = copyname & " (" & i & ")"
      EndIf

      name( ServerOptions.LogFolder & "/" & sfn, copyname & ".log" )

   case LogPrune

      const TempLog = "__temp__lic.log"

      FF = FreeFile
      if Open( ServerOptions.LogFolder & "/" & sfn For Binary As #FF ) <> 0 then
         Exit Function
      EndIf

      var FF2 = FreeFile
      if Open( TempLog For Binary Access write As #FF2 ) <> 0 then
         close #FF
         Exit Function
      EndIf

      #define buff_size 1024 * 16
      dim as byte ptr buffer = allocate( buff_size )
      if buffer = 0 then
         close #FF
         close #FF2
         kill TempLog
         Exit Function
      EndIf

      seek #FF, LOF( FF ) - cuint( Global_IRC.Global_Options.LogMaxFileSize * 0.75 )
      var tmp = ""
      Line Input #FF, tmp 'cut any partial line

      dim as ubyte one = 1
      put #FF2, LOF( FF ) - LOC( FF ) - 1, one, 1
      seek #FF2, 1

      dim as uinteger bytes_read = 0

      while not EOF( FF )
         get #FF, , *buffer, buff_size, bytes_read
         if bytes_read = 0 then
            sleep( 1, 1 )
         else
            put #FF2, , *buffer, bytes_read
         EndIf
      Wend

      deallocate( buffer )
      close #FF
      close #FF2

      if kill( ServerOptions.LogFolder & "/" & sfn ) = 0 then
         sleep( 50, 1 )
         name TempLog, ServerOptions.LogFolder & "/" & sfn
      endif

   End Select

End Function


