#include once "lic.bi"
#Include Once "lic-server.bi"
#include once "crt/string.bi"

Sub Server_Type.Parse_Privmsg( byref imsg as irc_message )

':LukeL!n=Luke@unaffiliated/lukel PRIVMSG ##FreeBASIC :hello

   dim as integer action, unknown, TempInt
   dim as LOT_MultiColour_Descriptor MCD
   
   'CTCP :

   If ( len_hack( imsg.msg ) > 2 ) andalso ( ( imsg.msg[0] = 1 ) and ( imsg.msg[ len_hack( imsg.msg ) - 1 ] = 1 ) ) Then
      dim as string IRC_Reply
      TempInt = InStrAsm( 2, imsg.msg, Asc(" ") )
      If TempInt = 0 Then TempInt = len_hack( imsg.msg )
      var CTCP_CMD = UCase( mid( imsg.msg, 2, TempInt - 2 ) )
      if StringEqualASM( CTCP_CMD, "ACTION" ) then
         action = 1
      else
      
         #if 0 'Ignore multi-target CTCP?
         If StringEqualASM( Ucase_( *imsg.Param( 0 ) ), UCurrentNick ) = 0 Then
            Exit Sub
         EndIf
         #endif

         '15 CTCP in 30 seconds or less will automatically add a filter script
         CtcpCount += 1
         if Timer > CtcpTimer then
            CtcpTimer = Timer + 30
            CtcpCount = 1
         elseif CtcpCount >= 15 then
            AddScript( "ctcpfilter" )
            Lobby->AddLOT( "** Some jerk is sending a lot of CTCP spam, a filter script has been added to ignore CTCP. Use /script to view or remove it", Global_IRC.Global_Options.ServerMessageColour, , , , , TRUE )
            Lobby->pflags OR= FlashingTab
            CtcpTimer = 0
            exit sub
         end if

      EndIf
      TempInt = *cptr( integer ptr, @CTCP_CMD[0] )
      Select Case TempInt
         Case *cptr( integer ptr, @"VERS" ) 'VERSION
            If Global_IRC.Global_Options.ShowCTCP <> 0 then
               MCD = Type( 10, 12, Global_IRC.Global_Options.WhisperColour )
               if Global_IRC.CurrentRoom->Server_Ptr = @this then
                  imsg.URT = Global_IRC.CurrentRoom
               else
                  imsg.URT = Lobby
               EndIf
               imsg.URT->AddLOT( "Received CTCP Version Request from " & imsg.From, Global_IRC.Global_Options.ServerMessageColour, , , , @MCD, TRUE )
            endif
            IRC_Reply = "NOTICE " & imsg.From & !" :\1VERSION "
            if len( Global_IRC.Global_Options.CTCP_Version ) <> 0 then
               IRC_Reply += Global_IRC.Global_Options.CTCP_Version & chr(1)
            else
               IRC_Reply += _
                  IRC_Version_name ":" _
                  IRC_Version_major "." _
                  IRC_Version_minor "b" _
                  IRC_Version_build ":" _
                  IRC_Build_env ":" _
                  IRC_Version_http & chr(1)
            EndIf
         case *cptr( integer ptr, @"TIME" )
            If Global_IRC.Global_Options.ShowCTCP <> 0 Then
               MCD = Type( 10, 9, Global_IRC.Global_Options.WhisperColour )
               if Global_IRC.CurrentRoom->Server_Ptr = @this then
                  imsg.URT = Global_IRC.CurrentRoom
               else
                  imsg.URT = Lobby
               EndIf
               imsg.URT->AddLOT( "Received CTCP Time Request from " & imsg.From, Global_IRC.Global_Options.ServerMessageColour, , , , @MCD, TRUE )
            EndIf
            Var T = time_
            IRC_Reply = "NOTICE " & imsg.From & !" :\1TIME " & RTrim( *ctime( @T ), Any NewLine ) & chr(1)
         case *cptr( integer ptr, @"PING" )
            If Global_IRC.Global_Options.ShowCTCP <> 0 Then
               MCD = Type( 10, 9, Global_IRC.Global_Options.WhisperColour )
               if Global_IRC.CurrentRoom->Server_Ptr = @this then
                  imsg.URT = Global_IRC.CurrentRoom
               else
                  imsg.URT = Lobby
               EndIf
               imsg.URT->AddLOT( "Received CTCP Ping Request from " & imsg.From, Global_IRC.Global_Options.ServerMessageColour, , , , @MCD, TRUE )
            endif
            IRC_Reply = "NOTICE " & imsg.From & " :" & imsg.msg

#if LIC_DCC
         Case *cptr( integer ptr, @"DCC" )

            DCC_Parse_IRC( imsg, @this )
#endif

         case else

            unknown = 1

      End Select

      If len_hack( IRC_Reply ) then
         If Global_IRC.Global_Options.ShowCTCP <> 0 then
            imsg.URT->AddLOT( "CTCP Reply to " & imsg.From & ": " & Trim( mid( IRC_Reply, InStrAsm( 1, IRC_Reply, Asc(":") ) + 1 ), Chr(1) ), Global_IRC.Global_Options.ServerMessageColour )
         endif
         SendLine( IRC_Reply )
      EndIf

      if ( action = 0 ) or ( unknown = 1 ) then
         Exit Sub
      EndIf

   EndIf
   
   dim as integer hilite
   var MCD_ptr = @MCD
   var disable_log = iif( imsg.from[0] = asc( "*" ), TRUE, FALSE )
   'ZNC will prefix messages with *

   CharKill( imsg.msg )

   If IS_Channel( *imsg.Param(0) ) then

      If imsg.URT = 0 Then
         Assert( imsg.URT )
         Exit Sub
      EndIf
      
      dim as integer l, p = 1 'p[osition] l[inebreak]
      var UNT = imsg.URT->Find( imsg.From )
      var ColourToUse = iif( UNT, UNT->ChatColour, Global_IRC.Global_Options.WhisperColour )
      var UCaseMsg = Ucase_( imsg.msg )
      
      if ( action = 0 ) and ( Global_IRC.Global_Options.ShowPrivs <> 0 ) and ( UNT <> 0 ) then
         if UNT->Privs <> 0 then imsg.From = chr( UNT->Privs ) & imsg.From
      EndIf
      
      do 'CurrentNick Search
         p = InStr( p, UCaseMsg, UCurrentNick )

         if p > 0 then

            p += len_hack( UCurrentNick )

            select case asc( UCaseMsg, p )
               case asc("A") to asc("Z")
                  continue do
            End Select
            select case asc( UCaseMsg, p - len_hack( UCurrentNick ) - 1 )
               case asc("A") to asc("Z")
                  continue do
            End Select

            l = iif( action = 0, 6, -5 )

            MCD_ptr->TextStart = p + Len_hack( imsg.From ) + l - len_hack( UCurrentNick )
            MCD_ptr->TextLen = len_hack( UCurrentNick )
            MCD_ptr->Colour = Global_IRC.Global_Options.HiliteColour
            MCD_ptr->NextDesc = New LOT_MultiColour_Descriptor
            'LIC_DEBUG( "added MCD start:" & MCD_ptr->TextStart & " len:" & MCD_ptr->TextLen )
            MCD_ptr = MCD_ptr->NextDesc
            
            hilite = 1

         EndIf

      Loop until p = 0

      if (imsg.flags AND MF_hilight) <> 0 then
         hilite = 1
      EndIf
      
      if hilite <> 0 then
         with *( imsg.URT->TextArray[ imsg.URT->NumLines - 1 ] )
         If ( .MesID = LineBreak ) and ( len_hack( .Text ) = 0 ) Then
            imsg.URT->NumLines -= 1
            Delete imsg.URT->TextArray[ imsg.URT->NumLines ]
            imsg.URT->TextArray[ imsg.URT->NumLines ] = 0
            If (imsg.URT->flags AND BackLogging) Then imsg.URT->CurrentLine -= 1
         Else
            imsg.URT->AddLOT( "", Global_IRC.Global_Options.YourChatColour, 0, LineBreak, 1 )
         EndIf
         end with
         MCD_ptr = @MCD
      else
         MCD_ptr = 0
      EndIf
      
      if UNT <> 0 then
         UNT->seen = time_
      endif
      
      if action = 0 then
         imsg.URT->AddLOT( "[ " & imsg.From & " ]: " & imsg.msg, ColourToUse, l xor 1, NormalChat, 0, MCD_Ptr, disable_log )
      else
         imsg.URT->AddLOT( "*" & imsg.From & " " & *cptr( zstring ptr, @imsg.msg[7] ), ColourToUse, l xor 1, ActionEmote, 0, MCD_Ptr, disable_log )
      EndIf

      if hilite <> 0 then
         Global_IRC.LastLOT = 0 'Fixes double hilites that delete the previous linebreak
         imsg.URT->AddLOT( "", Global_IRC.Global_Options.YourChatColour, 1, LineBreak )
         If Global_IRC.WindowActive = 0 Then
            if Global_IRC.CurrentRoom <> imsg.URT then Global_IRC.SwitchRoom( imsg.URT )
            LIC_Notify( iif( (imsg.URT->pflags AND DisableSound) = 0, 2, 1 ) )
         endif
      else
         If Global_IRC.WindowActive = 0 Then
            If ( (imsg.URT->pflags AND ChannelNotify) <> 0 ) or ( (imsg.flags AND MF_Notify) <> 0 ) Then
               LIC_Notify( )
            EndIf
         EndIf
      EndIf

   Else ' IS_Channel( *imsg.Param(0) ) = FALSE

      If imsg.URT = 0 Then
         If StringEqualAsm( Ucase_( imsg.From ), UCurrentNick ) then
            Global_IRC.CurrentRoom->AddLOT( "** From yourself: " & imsg.msg, Global_IRC.Global_Options.YourChatColour )
            Exit Sub
         else
            imsg.URT = AddRoom( imsg.From, PrivateChat )
         endif
      EndIf

      if action = 0 then
         imsg.URT->AddLOT( "[ " & imsg.From & " ]: " & imsg.msg, Global_IRC.Global_Options.WhisperColour, 1, NormalChat, , , disable_log )
      else
         imsg.URT->AddLOT( "*" & imsg.From & " " & *cptr( zstring ptr, @imsg.msg[7] ), Global_IRC.Global_Options.WhisperColour, 1, ActionEmote, , , disable_log )
      EndIf

      If Global_IRC.WindowActive = 0 Then
         TempInt = iif( (imsg.URT->pflags AND DisableSound) = 0, 2, 1 )
         LIC_Notify( TempInt )
      EndIf
      
      hilite = 1

   EndIf

   If ( (imsg.URT->pflags AND FlashingTab) = 0 ) And ( imsg.URT <> Global_IRC.CurrentRoom ) Then
      imsg.URT->pflags OR= FlashingTab
      If ( Global_IRC.WindowActive or Global_IRC.Global_Options.ShowInactive ) <> 0 Then
         Global_IRC.DrawTabs( )
      EndIf
   EndIf

End Sub
