#include once "lic.bi"
#include once "file.bi"

#if LIC_DCC

sub DCC_Parse_IRC( byref imsg as irc_message, byref server as Server_Type ptr )

   dim as string msg, Param(), cmd
   dim as integer token
   dim as int32_t TempInt, IP
   Dim As uint16_t Port
   Dim As UInteger FileSize

   dim as string Params = *imsg.Param( imsg.ParamCount )

   String_Explode( Params, Param() )

   if ubound( Param ) < 4 then
      exit sub
   EndIf

   cmd = UCase( Param(1) )

   Select Case cmd

   case "CHAT"

      'DCC CHAT <protocol> <ip> <port> [<token>]

      Port = ValUInt( Param(4) )
      Param(2) = uCase( Param(2) )
      IP = ValInt( Param(3) )
      if ubound( Param ) >= 5 then
         token = valint( Param(5) )
      EndIf

      if ( StringEqualASM( Param(2), "CHAT" ) = 0 ) then exit sub

      var DT = Global_IRC.DCC_List.Find( server->Ucase_( imsg.From ), 0, DCC_STATUS.Init, Token )
      if ( DT <> 0 ) and ( ubound( Param ) >= 3 ) then
         'reverse dcc has been accepted

         Assert( DT->socket = 0 )
         DT->socket = new chi.socket
         DT->port = Port
         DT->IP = ntohl( IP )
         DT->socket->hold = TRUE
         DT->socket->p_send_sleep = 50
         DT->socket->hold = FALSE

         var t = new threadconnect
         *t = type( DT->socket, 0, DT->ip, DT->port, 0, DT->Mutex, @( DT->SockStatus ) )

         DT->thread = threadcreate( cptr( any ptr, @chiconnect ), t, 1024 * 64 )

         DT->status = DCC_STATUS.Connecting
         DT->RoomPtr = cptr( Server_type ptr, DT->ServerPtr )->AddRoom( DT->user, DccChat )

         cptr( UserRoom_type ptr, DT->RoomPtr )->AddLOT( "** Connecting to " + DT->user + " please wait...", Global_IRC.Global_Options.ServerMessageColour, 1, , , , TRUE )
         exit sub
      EndIf

      DT = New DCC_TRACKER

      DT->ip = ntohl( IP )
      DT->port = Port
      DT->user = imsg.From
      DT->ServerPtr = server
      DT->Type_ = DCC_CHAT

      if Port = 0 then
         DT->Token = token
         DT->Port = Global_IRC.Global_Options.DCC_port
      EndIf

      Global_IRC.DCC_list.Add( DT )

      If Global_IRC.CurrentRoom->Server_ptr = server Then
         imsg.URT = Global_IRC.CurrentRoom
      Else
         imsg.URT = server->Lobby
      EndIf

      TempInt = FALSE

      select case server->ServerOptions.DccAutoAccept

      case OPT_DCCAUTO.on

         TempInt = TRUE

      case OPT_DCCAUTO.list

         if len_hack( server->ServerOptions.DccAutoList ) > 0 then

            dim as string a()
            String_Explode( server->ServerOptions.DccAutoList, a() )

            imsg.Prefix = server->UCase_( imsg.Prefix )

            for i as integer = 0 to ubound( a )
               if MaskCompare( imsg.Prefix, server->Ucase_( a(i) ) ) then
                  TempInt = TRUE
                  Exit For
               EndIf
            Next

         endif

      end select

      if TempInt = TRUE then
         DCC_Parse( !"\255A " & DT->id )
         msg = "** DCC Chat from " & imsg.From & " has been auto accepted"
      else

         If ( (imsg.URT->pflags AND FlashingTab) = 0 ) And ( imsg.URT <> Global_IRC.CurrentRoom ) Then
            imsg.URT->pflags OR= FlashingTab
            If ( Global_IRC.WindowActive or Global_IRC.Global_Options.ShowInactive ) <> 0 Then
               Global_IRC.DrawTabs( )
            EndIf
         EndIf

         msg = "** DCC: Incoming DCC CHAT request from " & imsg.From & " - Use '/dcc accept " & DT->id & "' to attempt the connection"

      EndIf

      imsg.URT->AddLot( msg, Global_IRC.Global_Options.ServerMessageColour, , , , , TRUE )

   case else

      Dim As String Filename

      If asc( Param(2) ) = asc("""") Then
         TempInt = InStr( 8 + len( cmd ), Params, """ " ) + 1
         FileName = SafeFileNameEncode( Mid( Params, 8 + len( cmd ), TempInt - 9 - len( cmd ) ) )
      Else
         TempInt = InStrASM( 7 + len( Param(1) ), Params, asc(" ") )
         FileName = SafeFileNameEncode( Mid( Params, 7 + len( cmd ), TempInt - 7 - len( cmd ) ) )
      EndIf

      Params = *( imsg.Param( imsg.ParamCount ) + TempInt )
      erase Param
      String_Explode( Params, Param() )

      select case cmd

      Case "SEND"
         'DCC SEND <filename> <ip> <port> <file size> [<token>]

         if ubound( Param ) < 2 then
            exit sub
         EndIf

         IP = ValInt( Param(0) )
         Port = ValUint( Param(1) )
         FileSize = ValUInt( Param(2) )
         if ubound( Param ) >= 3 then
            Token = ValInt( Param(3) )
         endif

         If ( FileSize = 0 ) or ( len_hack( Filename ) = 0 ) Then
            Exit Sub
         EndIf

         var DT = Global_IRC.DCC_List.Find( server->Ucase_( imsg.From ), 0, DCC_STATUS.Init, Token )
         if ( DT <> 0 ) and ( ubound( Param ) >= 3 ) then
            'reverse dcc has been accepted
            DT->port = Port
            DT->IP = ntohl( IP )
            DT->thread = ThreadCreate( CPtr( any Ptr, ProcPtr( DCC_FILE_SEND_THREAD ) ), DT, 128 )
            exit sub
         EndIf

         If Global_IRC.CurrentRoom->Server_ptr = server Then
            imsg.URT = Global_IRC.CurrentRoom
         Else
            imsg.URT = server->Lobby
         EndIf

         MkDir( "downloads" )
         TempInt = FileLen( "downloads/" & Filename )

         If TempInt >= FileSize Then
            imsg.URT->AddLot( "** DCC: Incoming file from " & imsg.From & " - '" & Filename & "' " & CalcSize( Filesize ) & " - Is already complete. If you want to retry, rename or delete the file in " & curdir & "/downloads first", Global_IRC.Global_Options.ServerMessageColour, , , , , TRUE )
            msg = "PRIVMSG " & imsg.FROM & !" :\1DCC REJECT """ & Filename & """ " & Port & " " & TempInt
            if ubound( Param ) >= 3 then
               msg += " " & Token
            EndIf
            server->SendLine( msg & !"\1" )
            Exit Sub
         endif

         DT = New DCC_TRACKER
         DT->argument = Filename
         DT->ip = ntohl( IP )
         DT->port = Port
         DT->filesize = FileSize
         DT->user = server->Ucase_( imsg.From )
         DT->ServerPtr = server
         DT->Type_ = DCC_SEND
         DT->token = token

         If TempInt > 4096 Then
   ':Mysoft!~se_pah@unaffiliated/mysoft PRIVMSG LukeL :?DCC RESUME "fbc.exe" 13013 114712?
            TempInt -= 4096
            DT->ResumeRequest = 1
            msg = "PRIVMSG " & imsg.From & !" :\1DCC RESUME """ & Filename & """ " & Port & " " & TempInt
            if Port = 0 then
               msg += " " & DT->Token & !"\1"
            else
               msg += !"\1"
            EndIf
            server->SendLine( msg )
         EndIf

         Global_IRC.DCC_list.Add( DT )
         msg = "** DCC: Incoming file from " & imsg.From & " - '" & Filename & "' " & CalcSize( Filesize ) & " - ID#" & DT->ID & " - "

         TempInt = FALSE

         select case server->ServerOptions.DccAutoAccept

         case OPT_DCCAUTO.on

            TempInt = TRUE

         case OPT_DCCAUTO.list

            if len_hack( server->ServerOptions.DccAutoList ) > 0 then

               dim as string a()
               String_Explode( server->ServerOptions.DccAutoList, a() )

               imsg.Prefix = server->UCase_( imsg.Prefix )

               for i as integer = 0 to ubound( a )
                  if MaskCompare( imsg.Prefix, server->Ucase_( a(i) ) ) then
                     TempInt = TRUE
                     Exit For
                  EndIf
               Next

            endif

         end select

         if TempInt = TRUE then
            if DT->ResumeRequest = 0 then
               DCC_Parse( "ACCEPT " & DT->id )
               msg += "Has been auto accepted"
            else
               msg += "requesting resume then auto starting"
               DT->ResumeRequest = 2
            endif
         else
            msg += "Use '/dcc accept " & DT->id & "' to start the download"
         EndIf

         imsg.URT->AddLOT( msg, Global_IRC.Global_Options.ServerMessageColour, ,Notification, , , TRUE )

         If ( (imsg.URT->pflags AND FlashingTab) = 0 ) And ( imsg.URT <> Global_IRC.CurrentRoom ) Then
            imsg.URT->pflags OR= FlashingTab
            If ( Global_IRC.WindowActive or Global_IRC.Global_Options.ShowInactive ) <> 0 Then
               Global_IRC.DrawTabs( )
            EndIf
         EndIf

      Case "RESUME"
         ':LukeT!sfdg@192.168.0.199 PRIVMSG LukeL_ :?DCC RESUME vlc.tar 13001 38928384?

         if ubound( Param ) < 1 then
            exit sub
         EndIf

         Port = ValUint( Param(0) )
         FileSize = ValUint( Param(1) )

         if ubound( Param ) >= 2 then
            Token = ValInt( Param(2) )
         EndIf

         Var DT = Global_IRC.DCC_list.find( server->Ucase_( imsg.From ), Port, iif( ubound( Param ) < 2, Listening, DCC_STATUS.Init ), Token )

         If DT <> 0 Then
            MutexLock( DT->Mutex )
            if DT->Filesize > FileSize then
               DT->bytes_xfer = FileSize
               msg = "ACCEPT "
            else
               msg = "REJECT "
            endif
            MutexUnLock( DT->Mutex )
            server->SendLine( "PRIVMSG " & imsg.From & !" :\1DCC " & msg & *( imsg.Param( imsg.ParamCount ) + 12 ) )
         EndIf

      Case "ACCEPT"
         'DCC ACCEPT <filename> <port> <position> [<token>]

         if ubound( Param ) = 0 then
            exit sub
         end if

         Port = ValUint( Param(0) )
         FileSize = ValUint( Param(1) )
         if ubound( Param ) >= 2 then
            Token = ValInt( Param(2) )
         end if

         Var DT = Global_IRC.DCC_List.Find( server->Ucase_( imsg.From ), Port, DCC_STATUS.Init, Token )

         If DT <> 0 Then

            MutexLock( DT->Mutex )
            var RR = DT->resumeRequest
            If RR <> 0 Then
               DT->bytes_xfer = FileSize
               DT->ResumeRequest = 0
            EndIf
            MutexUnLock( DT->Mutex )

            if RR = 2 then 'Auto Start
               DCC_Parse( "ACCEPT " & DT->id )
            endif

         EndIf

      Case "REJECT"
         'DCC REJECT <filename> <port> <position> [<token>]

         if ubound( Param ) = 0 then
            exit sub
         end if

         Port = ValUint( Param(0) )
         if ubound( Param ) >= 2 then
            Token = ValInt( Param(2) )
         end if

         Var DT = Global_IRC.DCC_List.Find( server->Ucase_( imsg.From ), Port, iif( ubound( Param ) < 2, Listening, DCC_STATUS.Init ), Token )
         If DT <> 0 Then

            select case DT->resumeRequest

            case 0
               DT->SetStatus( DCC_STATUS.Failed, Rejected )
               Notice_Gui( "** DCC: " & DT->GetStatus( ), Global_IRC.Global_Options.ServerMessageColour )

            case 1
               DT->ResumeRequest = 0

            case 2
               DCC_Parse( "ACCEPT " & DT->id )

            End Select

         EndIf

      End Select

   end select

End Sub

#endif