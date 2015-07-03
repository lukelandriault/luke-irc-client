#include once "crt/string.bi"
#Include Once "lic.bi"
#Include Once "lic-server.bi"
#Include Once "lic-numeric.bi"

dim shared as uinteger MaxMessageSize

#Macro CheckEvents( )

   If event_handler.queued > 0 then
      For i As Integer = 0 To event_handler.allocated - 1

         If event_handler.events[i] = 0 Then Continue For

         With *event_handler.events[i]

         Select Case ._Integer
         Case 0, *CommandPtr
         Case Else
            if valInt( imsg.Command ) <> ._Integer then
               Continue For
            endif
         End Select

         if len_hack( .mask ) > 0 then
            if MaskCompare( Ucase_( imsg.Prefix ), Ucase_( .mask ) ) = 0 then
               Continue For
            endif
         endif

         dim as integer success = TRUE
         For ii As Integer = 0 To 3
            If len_hack( .param(ii) ) > 0 Then
               select case .id
               case Script_Filter, Script_MatchAction
                  success AND= StringEqualASM( uCase( *imsg.Param(ii) ), .param(ii) )
               case Script_WordFilter, Script_WordMatch
                  success AND= ( 0 < InStr( uCase( imsg.msg ), .param(0) ) )
               case else
                  success AND= ( 0 < InStr( uCase( *imsg.Param(ii) ), .param(ii) ) )
               End Select
               If success = FALSE Then
                  Continue For, For
               EndIf
            EndIf
         Next

         If ._ptr <> 0 Then
            if StringEqualASM( Ucase_( imsg.From ), Ucase_( *CPtr( ZString Ptr, ._ptr ) ) ) = 0 then
               Continue For
            EndIf
         EndIf

         Select Case .id
            Case Server_Input, Server_Output
               SendLine( ._string )
            case Print_History
               imsg.URT = Find( .Param(1) )
               if imsg.URT <> 0 then imsg.URT->LoadHistory( )
            case Script_WordMatch
               imsg.flags or= .action
            case Script_Filter, Script_WordFilter
               imsg.flags or= MF_Filter
            case Script_CtcpFilter
               if ( asc( imsg.msg ) = 1 ) and ( asc( imsg.msg, len_hack( imsg.msg ) ) = 1 ) then
                  if len_hack( imsg.msg ) > 7 then
                     var d = *cptr( double ptr, @imsg.msg[0] )
                     select case d
                     case *cptr( double ptr, @!"\1ACTION " ), *cptr( double ptr, @!"\1action " )
                        success = FALSE
                     end select
                  end if
                  if success = TRUE then
                     imsg.flags or= MF_Filter
                  end if
               end if
            case Script_MatchAction
               SendLine( .saction, TRUE )
         End Select

         select case .When
         case 0
            continue for
         case 1
            Delete event_handler.events[i]
            event_handler.events[i] = 0
            event_handler.queued -= 1
         case else
            .When -= 1
         End Select

         End with

      Next
   EndIf

#EndMacro

Function Server_type.ParseMessage( ) as integer

   static as int32_t TempInt
   static as irc_message imsg

   #define CommandPtr CPtr( int32_t Ptr, @imsg.Command )

   'imsg.raw = ServerSocket.get_until( EOL )

   TempInt = ServerSocket.Length( )

   if TempInt > 0 then
      
      if MaxMessageSize = 0 then
         MaxMessageSize = IRC_MAX_MESSAGE_SIZE
         imsg.raw = space( IRC_MAX_MESSAGE_SIZE )
         imsg.msg = space( IRC_MAX_MESSAGE_SIZE )
      endif

      if TempInt > MaxMessageSize then TempInt = MaxMessageSize
      
      TempInt = ServerSocket.get_data( strptr( imsg.raw ), TempInt, TRUE )

      str_len( imsg.raw ) = TempInt
      imsg.raw[ TempInt ] = 0

      var n = InStrASM( 1, imsg.raw, asc( !"\n" ) )

      if n > 0 then
         'imsg.raw = Left( imsg.raw, N - len( EOL ) ) 'removes the EOL

         If EOL[1] <> 0 then
            imsg.raw[ n - 2 ] = 0
            str_len( imsg.raw ) = n - 2
         else
            str_len( imsg.raw ) = n - 1
         EndIf
         *cptr( ushort ptr, @imsg.raw[ n - 1 ] ) = 0

         ServerSocket.dump_data( n )

      else
         if TempInt = MaxMessageSize then
            MaxMessageSize *= 2
            imsg.raw = space( MaxMessageSize )
            imsg.msg = space( MaxMessageSize )
            LIC_DEBUG( "\\MaxMessageSize reached with no EOL. Expanding to " & MaxMessageSize )
         else
            'LIC_DEBUG( "\\" & TempInt & " len message no EOL" )
            'server having issues delivering messages?
            if ( len_hack( SendBuffer ) = 0 ) and ( SendTime + 3 < Timer ) and ( ServerSocket.Is_Closed( ) = FALSE ) Then
               SendLine( "PING :LIC LAG" )
            EndIf
         endif
         sleep( 1, 1 )
         exit function
      endif

   else
      sleep( 1, 1 )
      Exit function
   EndIf

   If len_hack( imsg.raw ) <= 4 Then
      LIC_DEBUG( "\\INFO: Bad packet (too small) from " & ServerOptions.Server )
      Exit Function
   EndIf
   
#if __FB_DEBUG__
   if Global_IRC.Global_Options.RawIRC <> 0 then
      LIC_Debug( imsg.raw )
   endif
#endif
   LastServerTalk = Timer
   imsg.flags = 0
   Function = TRUE
   
   if Global_IRC.Global_Options.ShowRaw <> FALSE and RawRoom <> 0 then
      RawRoom->AddLOT( imsg.raw, Global_IRC.Global_Options.RawInputColour )
   EndIf

   Build_IRC_Message( imsg, imsg.raw )

   'Macro at the top
   CheckEvents( )

   ' Remove IRC Colour data
   if ( len_hack( imsg.msg ) > 0 ) and ( (imsg.flags AND MF_Filter) = 0 ) then
      UTF8toANSI( imsg.msg )
      StripColour( imsg.msg )
   else
      'no need to alter a filtered message
      TempInt = 0
   endif

   'Pre process to find the UserRoom Type
   Select Case *CommandPtr

      Case IRC_PRIVMSG

         imsg.URT = Find( imsg.Param(0) )
         If imsg.URT = 0 Then
            imsg.URT = Find( imsg.From )
         EndIf

      Case IRC_NOTICE

         imsg.URT = Find( imsg.Param(0) )

         If imsg.URT = 0 Then

            If StringEqualASM( UCase( imsg.From ), "CHANSERV" ) Then
               'ChanServ Notices
               ':ChanServ!ChanServ@services. NOTICE LukeL :[#channel] Hi welcome to #channel!

               Var FirstWord = Trim( Left( imsg.msg, InStr( imsg.msg, " " ) - 1 ), Any "][()" )
               imsg.URT = Find( FirstWord )
               If imsg.URT Then Exit Select

            elseif len_hack( imsg.From ) = 0 then
               if StringEqualASM( ucase( *imsg.Param(0) ), "AUTH" ) then
                  imsg.URT = Lobby
               endif
            EndIf

         EndIf


         'Search for the user.. ??
         'If Global_IRC.CurrentRoom->Server_Ptr = @this Then
         '   imsg.URT = Find( imsg.From )
         '   If imsg.URT <> Global_IRC.CurrentRoom then
         '      imsg.URT = Global_IRC.CurrentRoom
         '      For i As Integer = 1 To NumRooms
         '         if imsg.URT->Find( imsg.From ) Then Exit For
         '         imsg.URT = imsg.URT->NextRoom
         '      Next
         '   endif
         'Else
         '   imsg.URT = Lobby->NextRoom
         '   For i As Integer = 1 To NumRooms - 1
         '      If imsg.URT->Find( imsg.From ) Then Exit For
         '      imsg.URT = imsg.URT->NextRoom
         '   Next
         'EndIf

         'Default to lobby/current Room

         If imsg.URT = 0 Then
            If Global_IRC.CurrentRoom->Server_Ptr = @this Then
               imsg.URT = Global_IRC.CurrentRoom
            Else
               imsg.URT = Lobby
            EndIf
         EndIf

      Case IRC_QUIT, IRC_NICK, IRC_INVITE, IRC_PING
         'Handled in their respective switch below

      case IRC_JOIN, IRC_PART, IRC_MODE, IRC_TOPIC
         'Can have URT = 0
         imsg.URT = Find( imsg.Param(0) )

      case IRC_KICK, IRC_PONG
         'Cannot have URT = 0

         imsg.URT = Find( imsg.Param(0) )

         if imsg.URT = 0 then
            if Global_IRC.CurrentRoom->Server_Ptr = @this Then
               imsg.URT = Global_IRC.CurrentRoom
            else
               imsg.URT = Lobby
            EndIf
         EndIf

      Case Else

         For i As Integer = 1 To imsg.ParamCount
            imsg.URT = Find( imsg.Param(i) )
            If imsg.URT Then Exit Select
         Next

         If Global_IRC.CurrentRoom->Server_Ptr = @this Then
            imsg.URT = Global_IRC.CurrentRoom
         Else
            imsg.URT = Lobby
         endif

   End Select

   Select Case *CommandPtr

      Case IRC_JOIN
':LukeL!n=Luke@unaffiliated/lukel JOIN :##FreeBASIC         
         
         Var UCase_From = Ucase_( imsg.From )
         Var DisableLog = ( Global_IRC.Global_Options.LogJoinLeave = 0 )

         If StringEqualAsm( UCase_From, UCurrentNick ) Then
            If imsg.URT = 0 Then
               if len( *imsg.Param(0) ) > 0 then
                  imsg.URT = AddRoom( imsg.Param(0), Channel )
                  Global_IRC.SwitchRoom( imsg.URT )
               else
                  'LIC_DEBUG( "\\Empty Join" )
                  return 0
               end if
            Else
               imsg.URT->pflags or= pChanFlags.FakeUsers
               imsg.URT->AddLOT( "** You have rejoined the channel", Global_IRC.Global_Options.JoinColour, , , , , DisableLog )
            EndIf
            imsg.URT->pflags AND= NOT( pChanFlags.synced )
            imsg.URT->pflags OR= pChanFlags.online
         Else
         
            If imsg.URT = 0 Then
               Assert( imsg.URT )
               Exit Function
            EndIf

            var UNT = imsg.URT->AddUser( imsg.From )

            If ( (imsg.URT->pflags AND ChannelJoinLeave) <> 0 ) and ( (imsg.flags AND MF_Filter) = 0 ) Then

               dim as LOT_MultiColour_Descriptor MCD = Type( 4, Len_hack( imsg.From ), UNT->ChatColour )
               dim as string msg

               const jmsg = " has joined the channel"

               If (imsg.URT->pflags AND ChannelHostname) <> 0 Then
                  TempInt = InStrAsm( 1, imsg.Prefix, Asc("!") )
                  msg = "** " & imsg.From & " " + "(" & *cptr( zstring ptr, @( imsg.Prefix[ TempInt ] ) ) & ")" + jmsg
               else
                  msg = "** " & imsg.From & jmsg
               endif

               imsg.URT->AddLOT( msg, Global_IRC.Global_Options.JoinColour, , , , @MCD, DisableLog )

            EndIf
            
            UNT->seen = time_

         EndIf

      Case IRC_QUIT
':someguy!someguy@someip.net QUIT :good bye

         dim as string msg

         imsg.URT = FirstRoom

         For i As Integer = 1 To NumRooms
            If (imsg.URT->pflags AND pChanFlags.online) then
               Var UNT = imsg.URT->Find( imsg.From )
               If UNT <> 0 Then
                  If ( (imsg.URT->pflags AND ChannelJoinLeave) <> 0 ) and ( (imsg.flags AND MF_Filter) = 0 ) Then

                     if len_hack( msg ) = 0 then
                        if imsg.Param(0)[0] = 0 then
                           msg = "** " & imsg.From & " has left the server"
                        else
                           msg = "** " & imsg.From & " has left the server" & " | " & imsg.msg
                        EndIf
                     EndIf

                     imsg.URT->AddLOT( msg, Global_IRC.Global_Options.LeaveColour, , , , , (Global_IRC.Global_Options.LogJoinLeave = 0) )

                  EndIf
                  imsg.URT->DelUser( UNT )
               EndIf
            endif
            imsg.URT = imsg.URT->NextRoom
         Next

      Case IRC_PRIVMSG

         If (imsg.flags AND MF_Filter) = 0 then
            if CheckIgnore( imsg.Prefix ) = 0 then
               Parse_Privmsg( imsg )
            endif
         endif

      Case IRC_PING
'PING :irc.freenode.net

         imsg.Parameters = "PONG :" & *imsg.Param( imsg.ParamCount )         
         SendLine( imsg.Parameters, TRUE )

      Case IRC_PART
'someuser!someuser@someip.net PART #somechannel :some reason...

'seen this...
':somebody!nobody@cable.rogers.com QUIT :Quit: Bye!
':somebody!nobody@cable.rogers.com PART #SomeChan

         Var Ucase_From = Ucase_( imsg.From )

         If imsg.URT = 0 Then
            Assert( imsg.URT )
            Exit Function
         EndIf

         If StringEqualAsm( UCase_From, UCurrentNick ) Then
            DelRoom( imsg.URT )
         Else
            If ( (imsg.URT->pflags AND ChannelJoinLeave) <> 0 ) and ( (imsg.flags AND MF_Filter) = 0 ) Then

               Var DisableLog = ( Global_IRC.Global_Options.LogJoinLeave = 0 )
               var msg = "** " & imsg.From & " has left the channel"

               If imsg.Param(1)[0] <> 0 Then
                  msg += " | " & imsg.msg
               EndIf
               imsg.URT->AddLOT( msg, Global_IRC.Global_Options.LeaveColour, , , , , DisableLog )

            EndIf
            imsg.URT->DelUser( imsg.From )
         EndIf

      Case IRC_NOTICE
':NickServ!NickServ@services. NOTICE LukeL :This nickname is owned by someone else

         If ( CheckIgnore( imsg.Prefix ) <> 0 ) or ( (imsg.flags AND MF_Filter) <> 0 ) Then
            Exit Function
         EndIf

         var msg = ""

         If ( len_hack( imsg.msg ) > 2 ) andalso ( imsg.msg[0] = 1 ) and ( imsg.msg[ len_hack( imsg.msg ) - 1 ] = 1 ) Then
':JimBob42!n=Username@rogers.com NOTICE LukeL :?VERSION Luke's IRC Client:0.65b542:Linux:http://code.google.com/p/luke-irc-client/?

            var Param = Trim( imsg.msg, Chr(1) )
            Var S = UCase( Param ) + " "
            S = Left( S, InStrAsm( 1, S, Asc(" ") ) - 1 )

            if Global_IRC.CurrentRoom->Server_Ptr = @this then imsg.URT = Global_IRC.CurrentRoom else imsg.URT = Lobby

            Select Case S
               Case "PING", "PONG"
                  var t = val( *imsg.Param( imsg.ParamCount ) )
                  if t <= 0 then t = LastPingTime

                  msg = "** PING Reply from " & imsg.From & " took " & Cint( ( Timer - t ) * 1000 ) & " ms"

               Case "VERSION"
                  msg = "** Version Reply from " & imsg.From & ":" & Mid( Param, 8 )
               Case "TIME"
                  msg = "** Time Reply from " & imsg.From & ":" & Mid( Param, 5 )
               case else
                  msg = "** Unknown CTCP Reply from " & imsg.From & ":" & Param
            End Select

            imsg.URT->AddLOT( msg, Global_IRC.Global_Options.ServerMessageColour, , , , , TRUE )

         Else
            CharKill( imsg.msg )
            If Len( imsg.From ) then
               if IS_CHANNEL( imsg.URT->RoomName ) then
                  msg = "**NOTICE** [ " & imsg.From & " > " & *imsg.Param(0) & " ]: " & imsg.msg
               else
                  msg = "[ " & imsg.From & " ]:NOTICE: " & imsg.msg
               EndIf
               imsg.URT->AddLOT( msg, Global_IRC.Global_Options.ServerMessageColour )
            Else
               imsg.URT->AddLOT( imsg.msg, Global_IRC.Global_Options.ServerMessageColour )
            EndIf
            If ( (imsg.URT->pflags AND FlashingTab) = 0 ) And ( imsg.URT <> Global_IRC.CurrentRoom ) Then
               imsg.URT->pflags OR= FlashingTab
               If ( Global_IRC.WindowActive or Global_IRC.Global_Options.ShowInactive ) <> 0 Then
                  Global_IRC.DrawTabs( )
               EndIf
            EndIf
         EndIf

      Case IRC_NICK
'someuser!someuser@someip.net NICK newnick

         dim as string msg
         dim as integer flag

         imsg.URT = FirstRoom
         For i As Integer = 1 To NumRooms
            If (imsg.URT->pflags AND pChanFlags.online) then
               var UNT = imsg.URT->Find( imsg.From )
               If UNT <> 0 Then
                  dim as LOT_MultiColour_Descriptor MCD = ( 3, len_hack( UNT->UserName ), UNT->ChatColour )

                  UNT->UserName = *imsg.Param( imsg.ParamCount )

                  if (imsg.flags AND MF_Filter) = 0 then

                     if len_hack( msg ) = 0 then
                        msg = "< " & imsg.From & " is now known as: " & UNT->UserName & " >"
                     EndIf

                     imsg.URT->AddLOT( msg, Global_IRC.Global_Options.ServerMessageColour, , , , @MCD )
                     flag = TRUE

                  endif

                  if UNT->Privs <> 0 then
                     UNT->UserName = chr( UNT->Privs ) + UNT->UserName
                  EndIf

                  var tmpflags = imsg.URT->pflags
                  imsg.URT->pflags OR= UsersLock
                  imsg.URT->AddUser( UNT->UserName, UNT->ChatColour )
                  imsg.URT->pflags = tmpflags
                  imsg.URT->DelUser( UNT )

               EndIf
            endif
            imsg.URT = imsg.URT->NextRoom
         Next
         If StringEqualASM( UCurrentNick, Ucase_( imsg.From ) ) Then
            CurrentNick = *imsg.Param( imsg.ParamCount )
            UCurrentNick = Ucase_( CurrentNick )
            if flag = FALSE then
               Lobby->AddLOT( "<You are now known as: " & CurrentNick & ">", Global_IRC.Global_Options.ServerMessageColour )
            end if
         End If

      Case IRC_MODE
':LukeL!n=luke@cable.rogers.com MODE #LukeL +v-m+v Luke2 LukeLM
':services. MODE LukeL :+e

         var Param0 = *imsg.Param(0)
         var Param1 = *imsg.Param(1)

         If IS_Channel( Param0 ) then

            if imsg.URT = 0 then
               Assert( imsg.URT )
               Exit Function
            EndIf

            dim as integer C, UserPriv, ModeNegative, ModeOffset = 1
            var tmpflags = imsg.URT->pflags

            For i As Integer = 0 To len_hack( Param1 ) - 1

               C = Param1[i]

               Select Case C

                  Case Asc("-")
                     ModeNegative = 1
                  Case Asc("+")
                     ModeNegative = 0
                  Case Else

                     For j As Integer = 0 To UBound( ServerInfo.IPrefix )
                        If C <> ServerInfo.IPrefix( j ) Then Continue For

                        ModeOffset += 1
                        Assert( ModeOffset <= imsg.ParamCount )

                        var UNT = imsg.URT->Find( *imsg.Param( ModeOffset ) )

                        /' Server delay can cause this to happen
                        :joe!@network.org KICK #channel victim
                        :bob!@someisp.org MODE #channel +o victim
                        So if no UNT, just continue '/
                        If UNT = 0 Then Continue For

                        TempInt = ubound( ServerInfo.VPrefix ) + 1

                        for k as integer = 0 to ubound( ServerInfo.VPrefix )
                           if UNT->Privs = ServerInfo.VPrefix( k ) then
                              TempInt = k
                           EndIf
                        Next

                        If ( ModeNegative = 1 ) And ( UNT->Privs = ServerInfo.VPrefix( j ) ) Then
                           UNT->Privs = 0
                        ElseIf ( ModeNegative = 0 ) And ( j < TempInt ) Then
                           UNT->Privs = ServerInfo.VPrefix( j )
                        Else
                           Continue For
                        EndIf

                        if UNT->Privs <> 0 then UNT->UserName = chr( UNT->Privs ) + UNT->UserName

                        imsg.URT->pflags OR= UsersLock
                        imsg.URT->AddUser( UNT->UserName, UNT->ChatColour )
                        imsg.URT->pflags = tmpflags
                        imsg.URT->DelUser( UNT )

                     Next

                     If ( ServerInfo.Flags AND S_INFO_FLAG_CHANMODES ) <> 0 then
                        For j As Integer = 0 To 3
                           If InStr( ServerInfo.CHANMODES( j ), Chr( C ) ) Then
                              If ( j <= 1 ) or ( ( j = 2 ) And ( ModeNegative = 0 ) ) Then
                                 ModeOffset += 1
                              EndIf
                              Exit For
                           EndIf
                        Next
                     Else

                        Select Case C
                           Case asc("b"), asc("k")
                              ModeOffset += 1
                           Case asc("l")
                              If ModeNegative = 0 Then ModeOffset += 1
                        End Select

                     EndIf

               End Select

            Next

            if ( imsg.flags and MF_Filter ) then
               exit function
            EndIf

            var ModeSet = *cptr( zstring ptr, @imsg.raw[ imsg.ParamOffset + len_hack( Param0 ) + 1 ] )
            var msg = "** " & imsg.From & " sets MODE " & ModeSet

            TempInt = abs( Timer - imsg.URT->LastModeTime )

            if StringEqualASM( imsg.URT->LastMODE, ModeSet ) and ( TempInt < 5 ) then
               if (imsg.URT->pflags AND ChannelLogging) <> 0 then imsg.URT->Log( msg )
            else
               imsg.URT->AddLOT( msg, Global_IRC.Global_Options.ServerMessageColour )
               imsg.URT->LastMODE = ModeSet
               imsg.URT->LastModeTime = Timer
            EndIf

         Else
            if ( imsg.Flags and MF_Filter ) = 0 then
               Lobby->AddLot( "** " & ServerName & " sets MODE " & Param0 & " " & *imsg.Param( imsg.ParamCount ), Global_IRC.Global_Options.ServerMessageColour )
            endif
         EndIf

      Case IRC_KICK
':someop!someop@someip.net KICK #somechannel somejerk :get out of here jerk!

         var msg = "** "
         var user = *imsg.Param(1)

         If StringEqualASM( Ucase_( user ), UCurrentNick ) Then
            msg += "You were kicked out of the channel by " & imsg.From
            If imsg.Param(2)[0] <> 0 then
               msg += " (" & *imsg.Param(2) & ")"
            endif
            imsg.URT->pflags AND= NOT( pChanFlags.online OR pChanFlags.synced )

            select case Global_IRC.Global_Options.AutoRejoinOnKick
            case 0
               'do nothing
            case is > 0
               Dim As event_type et

               et.id = Server_Output
               et.when = Timer + Global_IRC.Global_Options.AutoRejoinOnKick
               et._string = "JOIN " & *imsg.Param(0)
               et._ptr = @this

               Global_IRC.Event_Handler.Add( @et )

            case else
               SendLine( "JOIN " & *imsg.Param(0) )

            End Select
            If ( (imsg.URT->pflags AND FlashingTab) = 0 ) And ( imsg.URT <> Global_IRC.CurrentRoom ) Then
               imsg.URT->pflags OR= FlashingTab
               If ( Global_IRC.WindowActive or Global_IRC.Global_Options.ShowInactive ) <> 0 Then
                  Global_IRC.DrawTabs( )
               EndIf
            EndIf
         else
            msg += user & " has been kicked by " & imsg.From
            If imsg.Param(2)[0] <> 0 then
               msg += " (" & *imsg.Param(2) & ")"
            endif
            imsg.URT->DelUser( user )
         Endif

         if ( imsg.Flags and MF_Filter ) = 0 then
            imsg.URT->AddLOT( msg, Global_IRC.Global_Options.LeaveColour )
         end if

      Case IRC_TOPIC
':someop!someop@someip.net TOPIC #somechannel :new channel topic

         if imsg.URT = 0 then
            Assert( imsg.URT )
            Exit Function
         EndIf

         CharKill( imsg.msg )
         imsg.URT->Topic = imsg.msg
         If imsg.URT = Global_IRC.CurrentRoom Then UpdateWindowTitle( )
         If Global_IRC.Global_Options.ShowTopicUpdates <> 0 then
            imsg.URT->AddLOT( "** " & imsg.From & " has updated the channel topic: " & imsg.msg, Global_IRC.Global_Options.ServerMessageColour )
         Endif

      Case IRC_INVITE
':someop!someop@someip.net INVITE someuser :#somechannel

         if @this = Global_IRC.CurrentRoom->Server_Ptr then
            imsg.URT = Global_IRC.CurrentRoom
         else
            imsg.URT = Lobby
         EndIf

         imsg.URT->AddLOT( "** " & imsg.From & " has invited you to join " & *imsg.Param( imsg.ParamCount ), Global_IRC.Global_Options.ServerMessageColour )
         If ( (imsg.URT->pflags AND FlashingTab) = 0 ) And ( imsg.URT <> Global_IRC.CurrentRoom ) Then
            imsg.URT->pflags OR= FlashingTab
            If ( Global_IRC.WindowActive or Global_IRC.Global_Options.ShowInactive ) <> 0 Then
               Global_IRC.DrawTabs( )
            EndIf
         EndIf

      Case IRC_ERROR
         ReconnectTime += 30

      Case IRC_PONG

         TempInt = fix( ( Timer - LastPingTime ) * 1000 )
         var msg = Ucase( imsg.msg )

         select case msg

         case "LIC LAG"

         case "LIC CONNECTION CHECK"
            LIC_Debug( "\\" & ServerOptions.Server & " PING reply took " & TempInt & " ms" )

         case "ZNC" 'ZNC plays PING PONG

         case else
            imsg.URT->AddLOT( "** Server responded in " & TempInt & " ms", Global_IRC.Global_Options.ServerMessageColour )

         end select
      
      case IRC_CAP
      
         imsg.URT->AddLOT( " ** Server enables: " & *imsg.Param( imsg.ParamCount ), Global_IRC.Global_Options.ServerMessageColour )
      
      case IRC_USER
         
         'twitch.tv USERSTATE... can be ignored

      Case Else

         Parse_RPL( imsg )

   End Select

End Function

Sub CharKill( ByRef StringIN As String )

   dim as integer i, p, l = len_hack( StringIn )

   do

      Select Case StringIn[i]

         case asc(!"\t"), 32 to 145, 149 to 255

            StringIn[p] = StringIn[i]
            p += 1

         case 146
         
            StringIn[p] = asc("'")
            p += 1
         
         case 147, 148
         
            StringIn[p] = asc("""")
            p += 1
            
         Case 0
            Exit Do

      End Select

      i += 1

   loop until i >= l

   if p <> i then
      StringIn[p] = 0
      str_len( StringIn ) = p
   EndIf

End Sub

sub Build_IRC_Message( byref m as irc_message, byref s as string )
   
   dim as integer TempInt
   
   if str_all( m.msg ) <= MaxMessageSize then
      m.msg = space( MaxMessageSize )
   EndIf
   if str_all( m.raw ) <= MaxMessageSize then
      m.raw = space( MaxMessageSize )
   EndIf
   if strptr( m.raw ) <> strptr( s ) then
      memcpy( @m.raw[0], @s[0], len_hack( s ) )
      m.raw[ len_hack( S ) ] = 0
      str_len( m.raw ) = len_hack( s )
   endif   
   
   if m.raw[0] = Asc( "@" ) then
      'The message pseudo-BNF, as defined in RFC 1459, section 2.3.1 is extended to look as follows:
   
      '<message>       ::= ['@' <tags> <SPACE>] [':' <prefix> <SPACE> ] <command> <params> <crlf>
      '<tags>          ::= <tag> [';' <tag>]*
      '<tag>           ::= <key> ['=' <escaped value>]
      '<key>           ::= [ <vendor> '/' ] <sequence of letters, digits, hyphens (`-`)>
      '<escaped value> ::= <sequence of any characters except NUL, CR, LF, semicolon (`;`) and SPACE>
      '<vendor>        ::= <host>
      
      'Just gonna strip these and deal with them later to maintain compatibility
      TempInt = InStrAsm( 1, m.raw, asc(" ") )
      m.MessageTag = mid( m.raw, 2, TempInt - 2 )
      str_len( m.raw ) -= len_hack( m.MessageTag ) + 2
      memmove( @m.raw[0], @m.raw[TempInt], str_len( m.raw ) + 1 )
      'LIC_DEBUG( "\\Set Message tag: [" & m.MessageTag & "]" )
      'LIC_DEBUG( "\\Set Message raw: [" & m.raw & "]" )
   else
      m.MessageTag = ""
   end if
   
   ' a ':' denotes the message begins with who it's from ( m.Prefix )
   If m.raw[0] = Asc( ":" ) Then
      m.Prefix = mid( m.raw, 2, InStrAsm( 2, m.raw, Asc(" ") ) - 2 )
      TempInt = Len_Hack( m.Prefix ) + 1
      m.Command = UCase( Mid( m.raw, TempInt + 2, InStrAsm( TempInt + 2, m.raw, Asc(" ") ) - TempInt - 2 ) )
      m.ParamOffset = InStrAsm( TempInt + 2, m.raw, asc(" ") )
      m.Parameters = *cptr( zstring ptr, @m.raw[ m.ParamOffset ] )
      TempInt = InStrAsm( 1, m.Prefix, Asc("!") ) - 1
      if TempInt > 0 then
         m.From = Left( m.Prefix, TempInt )
      else
         m.From = m.Prefix
      EndIf
   Else
      m.From = ""
      m.Prefix = ""

      TempInt = InStrAsm( 1, m.raw, Asc(" ") )
      m.Command = UCase( Left( m.raw, TempInt - 1 ) )
      m.ParamOffset = TempInt
      m.Parameters = *cptr( zstring ptr, @m.raw[ m.ParamOffset ] )

   EndIf

   m.ParamCount = -1

   if len_hack( m.Parameters ) = 0 then
      'no params
   elseif m.Parameters[0] = Asc( ":" ) Then

      m.ParamCount = 0
      m.Param( 0 ) = @m.Parameters[1]

      if len_hack( m.Parameters ) > 1 then
         memcpy( @m.msg[0], m.Param( 0 ), len_hack( m.Parameters ) )
      else
         m.msg[0] = 0
      endif

      str_len( m.msg ) = len_hack( m.Parameters ) - 1

   Else 'Multiple Params
':NickServ!NickServ@services. NOTICE LukeL :hi

      TempInt = 1
      do
         TempInt = InStrASM( TempInt, m.Parameters, asc( ":" ) )
         if TempInt > 0 then
            if m.Parameters[TempInt - 2] = asc( " " ) then
               'the space insures parameters like '#a:b' are added properly
               'and not taken as the final param
               exit do
            else
               TempInt += 1
            EndIf
         EndIf
      loop while TempInt > 0

      If TempInt > 0 Then

         str_len( m.msg ) = len_hack( m.Parameters ) - TempInt
         memcpy( @m.msg[0], @m.Parameters[ TempInt ], str_len( m.msg ) + 1 )

         m.Parameters[ TempInt - 1 ] = 0
         Len_Swap( m.Parameters, TempInt - 2 )

         m.ParamCount = String_ExplodeZ( m.Parameters, m.Param() )

         m.ParamCount += 1
         m.Param( m.ParamCount ) = @m.raw[ m.ParamOffset + TempInt ]

      Else

         m.ParamCount = String_ExplodeZ( m.Parameters, m.Param() )

         m.msg[0] = 0
         str_len( m.msg ) = 0

      endif

   EndIf

   'for safety
   static nothing as zstring ptr = @""
   for TempInt = ( m.ParamCount + 1 ) to ubound( m.Param )
      if m.Param( TempInt ) = nothing then
         exit for
      EndIf
      m.Param( TempInt ) = nothing
   Next

End Sub
