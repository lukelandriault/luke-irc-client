#include once "lic.bi"
#Include Once "lic-server.bi"
#include once "crt/string.bi"

Sub Server_Type.Parse_Privmsg( byref imsg as irc_message )

':LukeL!n=Luke@unaffiliated/lukel PRIVMSG ##FreeBASIC :hello

   dim as int32_t action, TempInt
   dim as LOT_MultiColour_Descriptor MCD
   
   'CTCP :
   If ( len_hack( imsg.msg ) > 2 ) andalso ( ( imsg.msg[0] = 1 ) and ( imsg.msg[ len_hack( imsg.msg ) - 1 ] = 1 ) ) Then
      dim as string IRC_Reply
      TempInt = InStrAsm( 2, imsg.msg, Asc(" ") )
      If TempInt = 0 Then TempInt = len_hack( imsg.msg )
      dim as zstring * 8 CTCP_CMD = UCase( mid( imsg.msg, 2, TempInt - 2 ) )
      TempInt = *cptr( int32_t ptr, @CTCP_CMD[0] )
      
      Select Case TempInt
         case *cptr( int32_t ptr, @"ACTI" ) 'ACTION
            action = 1
         Case *cptr( int32_t ptr, @"VERS" ) 'VERSION
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
         case *cptr( int32_t ptr, @"TIME" )
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
         case *cptr( int32_t ptr, @"PING" )
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
         Case *cptr( int32_t ptr, @"DCC" )

            DCC_Parse_IRC( imsg, @this )
#endif

         case else

            exit sub 'unknown

      End Select

      if action = 0 then
      
         if Global_IRC.Global_Options.CTCPIgnoreMulti <> 0 then 'Ignore multi-target CTCP?
            If StringEqualASM( Ucase_( *imsg.Param( 0 ) ), UCurrentNick ) = 0 Then
               Exit Sub
            EndIf
         endif    
     
         CtcpCount += 1 '15 CTCP in 30 seconds or less will automatically add a filter script
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

      If len_hack( IRC_Reply ) then
         If Global_IRC.Global_Options.ShowCTCP <> 0 then
            imsg.URT->AddLOT( "CTCP Reply to " & imsg.From & ": " & Trim( mid( IRC_Reply, InStrAsm( 1, IRC_Reply, Asc(":") ) + 1 ), Chr(1) ), Global_IRC.Global_Options.ServerMessageColour )
         endif
         SendLine( IRC_Reply )
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
      
      var UNT = imsg.URT->Find( imsg.From )
      if ServerOptions.TwitchHacks <> 0 then
         
         if ServerOptions.TwitchKillEmotes <> 0 then 'destroy any emote only messages
            if instr( imsg.MessageTag, "emote-only=1" ) then
               Exit Sub 'peace out spammers
            EndIf
         EndIf
         
         if (UNT = 0) orelse (UNT->seen = 0) then 'new subscribers will not show badges
            dim as uint32_t twcolor
            TempInt = instr( imsg.MessageTag, "color=#" )
            if TempInt > 0 then
               dim as ubyte r,g,b
               dim as ubyte ptr index = cptr( ubyte ptr, @twcolor )
               twcolor = valuint( "&h" & mid( imsg.MessageTag, TempInt + 7, 6 ) )           
               while (Global_IRC.DarkUsers = 0) and (index[0]+index[1]+index[2] <= 96)
                  index[0] += index[0]+8: index[1] += index[1]+8: index[2] += index[2]+8
               Wend
               if (index[0]=255) and (index[2]=255) then index[1] or=8 'protect the pink
            else
               twcolor = rndColour( Global_IRC.DarkUsers )
            end if
            if UNT = 0 then
               UNT = imsg.URT->AddUser( imsg.From, twcolor )
            else
               UNT->ChatColour = twcolor
            EndIf
            TempInt = instr( imsg.MessageTag, "display-name=" )
            if (TempInt > 0) andalso (imsg.MessageTag[TempInt+12] <> asc(";")) then 
               var dispName = mid( imsg.MessageTag, TempInt + 13, InStrASM( TempInt+1, imsg.MessageTag, asc(";") ) - TempInt - 13 )
               UTF8toANSI( dispName )
               if( ucase_( dispName ) = ucase_( UNT->Username ) ) then
                  UNT->Username = dispName
               EndIf
            end if
            if (instr( imsg.MessageTag, "user-type=mod" ) > 0) or (imsg.From = *( imsg.Param(0)+1 )) then
               UNT->Privs = ServerInfo.VPrefix(0)
            elseif instr( imsg.MessageTag, "subscriber=1" ) > 0 then
               UNT->Privs = ServerInfo.VPrefix(1)
            EndIf
         end if
         memcpy( strptr( imsg.From ), strptr( UNT->Username ), len_hack( imsg.From ) )
         
      EndIf
      
      dim as integer l, p = 1 'p[osition] l[inebreak]
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
         LIC_Notify( iif( (imsg.URT->pflags AND DisableSound) = 0, 2, 1 ) )
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
