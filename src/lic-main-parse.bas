#Include Once "lic.bi"

#if __FB_DEBUG__
Declare Sub TestInput( )
declare sub LIC_TrayFlash_STOP
#endif

Using fb

Extern ChatInput As FBGFX_CHARACTER_INPUT

dim shared TabResults as ubyte ptr

sub ClearTabResults( ) destructor
   Deallocate TabResults
   TabResults = 0
End Sub

Function Parse_Scancode( ByRef Scancode As long ) as integer

Function = TRUE

Dim TMP As String

Select Case scancode

   case SC_LEFT, SC_RIGHT, SC_LSHIFT

      if not Multikey( SC_CONTROL ) then
         ChatInput.Parse( scanCode )
         Function = FALSE
      else

         var URT = Global_IRC.CurrentRoom

         select case scancode
         case SC_RIGHT

            URT = GetNextRoom( )
            while ( URT <> Global_IRC.CurrentRoom ) and ( (URT->pflags AND FlashingTab) = 0 )
               URT = GetNextRoom( URT )
            Wend

         case SC_LEFT

            URT = GetPrevRoom( )
            while ( URT <> Global_IRC.CurrentRoom ) and ( (URT->pflags AND FlashingTab) = 0 )
               URT = GetPrevRoom( URT )
            Wend

         case SC_LSHIFT

            if Global_IRC.SwapRoom <> 0 then
               'URT = Global_IRC.SwapRoom
            EndIf

         End Select

         if URT <> Global_IRC.CurrentRoom then Global_IRC.SwitchRoom( URT )

      endif

   Case SC_PAGEDOWN, SC_PAGEUP 'Scroll Up/Down

      If ( MultiKey( SC_CONTROL ) ) Then
         If scancode = SC_PAGEDOWN Then
            Global_IRC.CurrentRoom->UpdateChatListScroll( Global_IRC.Global_Options.ScreenRes_Y, 1 )
         Else
            Global_IRC.CurrentRoom->flags OR= Backlogging
            Global_IRC.CurrentRoom->UpdateChatListScroll( 1, 1 )
         endif
      Else
         Global_IRC.CurrentRoom->LineScroll( ( Global_IRC.MaxDisp_C - 1 ) * IIf( scancode = SC_PAGEDOWN, 1, -1 ) )
      EndIf

   Case SC_ESCAPE 'Close Windows

      var URT = Global_IRC.CurrentRoom

      If URT->RoomType = RoomTypes.Channel then
         If (URT->pflags AND pChanFlags.online) then
            URT->Server_Ptr->SendLine( "PART " & URT->RoomName )
         Else
            URT->Server_Ptr->DelRoom( URT )
         endif

#if LIC_DCC
      Elseif URT->RoomType = DccChat then

         var tracker = Global_IRC.DCC_List.Find( URT )

         if tracker <> 0 then
            if tracker->SockStatus <> NO_RETURN then
               URT->Server_Ptr->DelRoom( URT )
               Exit Function
            EndIf
            tracker->socket->Close( )
         EndIf

         Dim As event_Type et
         et.when = Timer + 60
         et.id = Delete_Room
         et._ptr = URT->Server_Ptr
         et._integer = cint( URT )
         Global_IRC.Event_handler.Add( @et )

         URT->pflags OR= Hidden

         URT = GetPrevRoom
         While (URT->pflags AND Hidden)
            URT = GetPrevRoom( URT )
         Wend
         ChatInput.x1 = URT->UserListWidth + 12
         Global_IRC.SwitchRoom( URT )

      else
#endif
         URT->Server_Ptr->DelRoom( URT )
      Endif

   Case SC_TAB 'Switch rooms / Auto Complete Nick
      If MultiKey( SC_CONTROL ) Or MultiKey( SC_LSHIFT ) Then
         If Global_IRC.NumVisibleRooms > 1 Then
            Dim As UserRoom_Type Ptr SwitchRoom
            If MultiKey( SC_LSHIFT ) Then
               SwitchRoom = GetPrevRoom
               While (SwitchRoom->pflags AND Hidden)
                  SwitchRoom = GetPrevRoom( SwitchRoom )
               Wend

            Else
               SwitchRoom = GetNextRoom
               While (SwitchRoom->pflags AND Hidden)
                  SwitchRoom = GetNextRoom( SwitchRoom )
               Wend
            EndIf
            Global_IRC.SwitchRoom( SwitchRoom )
         EndIf
      Elseif lcase( ChatInput ) = "/topic " then

         ChatInput.Set( "/topic " + Global_IRC.CurrentRoom->Topic )
         Function = FALSE

      else

         static as string LastSearch
         static as integer Count, TabCarat
         dim as integer Allocated
         Var SpaceInside = InStrRev( ChatInput, " ", ChatInput.Carat ) + 1
         Var Search = LCase( Mid( ChatInput, SpaceInside, InStr( SpaceInside, ChatInput & " ", " " ) - SpaceInside  ) )

         Const as integer MaxResultLen = 64

         If ( len( LastSearch ) = 0 ) Or ( NOT StringEqualASM( Search, LastSearch ) ) Then

            TabCarat = -1
            Count = 0

            dim as integer L = len( search )

            If ( L > 0 ) andalso ( Global_IRC.CurrentRoom->Server_Ptr->Is_Channel( Search ) = TRUE ) Then
               Var URT = Global_IRC.CurrentRoom
               For i As Integer = 1 To Global_IRC.TotalNumRooms( )
                  If StringEqualASM( LCase( Left( URT->RoomName, L ) ), Search ) Then

                     if Count = Allocated then

                        Allocated += 32
                        var tmp = reallocate( TabResults, MaxResultLen * Allocated )

                        if tmp = 0 then
                           exit for
                        EndIf

                        TabResults = tmp

                     EndIf

                     if len_hack( URT->RoomName ) < MaxResultLen then
                        *cptr( zstring ptr, @TabResults[ count * MaxResultLen ] ) = URT->RoomName
                     else
                        *cptr( zstring ptr, @TabResults[ count * MaxResultLen ] ) = left( URT->RoomName, MaxResultLen - 1 )
                     endif
                     count += 1

                  EndIf
                  URT = GetNextRoom( URT )
               Next
            else
               redim as Username_Type ptr UNTArray(0)
               Var UNT = Global_IRC.CurrentRoom->FirstUser
               For i As Integer = 1 To Global_IRC.CurrentRoom->NumUsers
                  If StringEqualASM( LCase( Left( UNT->UserName, L ) ), Search ) Then

                     if Count = Allocated then

                        Allocated += 32
                        var tmp = reallocate( TabResults, MaxResultLen * Allocated )

                        if tmp = 0 then
                           exit for
                        EndIf
                        
                        redim preserve UNTArray( Allocated )
                        TabResults = tmp

                     EndIf
                     
                     if Global_IRC.Global_Options.SortTabBySeen <> 0 then
                        
                        UNTArray( count ) = UNT
                        
                     else
                     
                        if len_hack( UNT->UserName ) < MaxResultLen then
                           *cptr( zstring ptr, @TabResults[ count * MaxResultLen ] ) = UNT->UserName
                        else
                           *cptr( zstring ptr, @TabResults[ count * MaxResultLen ] ) = left( UNT->UserName, MaxResultLen - 1 )
                        endif
                        
                     endif
                     count += 1

                  EndIf
                  UNT = UNT->NextUser
                  if Allocated >= 128 then
                     exit for
                  EndIf
               Next
               if Global_IRC.Global_Options.SortTabBySeen <> 0 then
                  for i as integer = 0 to count - 2
                     if UNTArray( i + 1 )->seen > UNTArray( i )->seen then
                        swap UNTArray( i + 1 ), UNTArray( i )
                        i = -1
                     EndIf
                  Next
                  for i as integer = 0 to count - 1
                     if len_hack( UNTArray(i)->UserName ) <= MaxResultLen then
                        *cptr( zstring ptr, @TabResults[ i * MaxResultLen ] ) = UNTArray(i)->UserName
                      else
                        *cptr( zstring ptr, @TabResults[ i * MaxResultLen ] ) = left( UNTArray(i)->UserName, MaxResultLen - 1 )
                     endif
                  Next
               EndIf
            endif

         EndIf
         
         if TabResults = 0 then
            Return FALSE
         EndIf
       
         TabCarat += 1
         If TabCarat >= count Then TabCarat = 0
         If count > 0 Then
            LastSearch = lcase( *cptr( zstring ptr, @TabResults[ TabCarat * MaxResultLen ] ) )
            ChatInput.Set( _
               Left( cast( string, ChatInput ), SpaceInside - 1 ) & _
               *cptr( zstring ptr, @TabResults[ TabCarat * MaxResultLen ] ) & _
               Mid( cast( string, ChatInput ), ChatInput.Carat + 1 ) _
            )
         endif
         Function = FALSE

      EndIf
   Case SC_ENTER 'Evaluate text input

      If ChatInput.Length = 0 Then
         Return FALSE
      EndIf

      ClearTabResults( )

      If ( asc( ChatInput ) = asc("/") ) And ( MultiKey( SC_CONTROL ) = 0 ) Then
         
         dim as string Response, cmd = Mid( ChatInput, 2 )
         
         'Handle any Aliases
         with Global_IRC
         if .AliasList <> 0 then
            dim as integer i, sp = instrasm( 1, cmd, asc(" ") )
            dim as string p1 = ucase( mid( cmd, 1, sp - 1 ) )
            while i < .AliasCount
               if .AliasList[i] <> 0 then
                  if *.AliasList[i] = p1 then
                     LIC_DEBUG( "\\Alias remap '" & p1 & "' -> '" & *.AliasList[i+1] & "'" )                    
                     cmd = *.AliasList[i+1] & mid( cmd, sp )
                     exit while
                  EndIf
               Endif
               i += 2
            Wend
         endif
         end with
         
         dim as ParamList_Type PL = cmd
         #define LHS PL.s[0]
         #define EnteredCommand PL.copyv

         LHS = ucase( LHS )

         Var FirstSpace = iif( PL.count > 1, PL.start[1], len_hack( LHS ) )
         Var RHS = RTrim( *cptr( zstring ptr, @EnteredCommand[ FirstSpace ] ) )

#if LIC_DCC
         if Global_IRC.CurrentRoom->RoomType = DccChat then

            select case LHS
            case "ME", "EMOTE", "ACTION", "EM"
               response = !"\1ACTION " & RHS & !"\1"
            case "CYCLE", "HOP"
               'invalid for dcc chat
               exit function
            end select

            if len_hack( response ) > 0 then
               DCC_CHAT_Out( response )
               ChatInput.Set( "" )
               exit function
            end if

            response = ""
         end if
#endif

         Select Case LHS

            Case "ME", "EMOTE", "ACTION", "EM"
               Response = "PRIVMSG " & Global_IRC.CurrentRoom->RoomName & !" :\1ACTION " & RHS & !"\1"

            Case "PING", "P"
               If Len( RHS ) = 0 Then
                  Response = "PING :"
               else
                  Response = "PRIVMSG " & RHS & !" :\1PING "
               EndIf

               if len_hack( Global_IRC.CurrentRoom->Server_Ptr->SendBuffer ) = 0 then
                  Response &= Timer & !"\1"
               else
                  'PING 0 will use LastPingTimer for the calculation
                  Response &= !"0\1"
               EndIf

            Case "TIME", "T"
               If Len( RHS ) = 0 Then
                  Response = "TIME"
               else
                  Response = "PRIVMSG " & RHS & !" :\1TIME\1"
               EndIf

            Case "VER", "VERSION", "V"
               If Len( RHS ) = 0 Then
                  Response = "VERSION"
               else
                  Response = "PRIVMSG " & RHS & !" :\1VERSION\1"
               EndIf

            Case "PART"
               If Len( RHS ) = 0 Then
                  Response = EnteredCommand + " " + Global_IRC.CurrentRoom->RoomName
               ElseIf Global_IRC.CurrentRoom->Server_Ptr->IS_CHANNEL( RHS ) = FALSE Then
                  Response = "PART " & Global_IRC.CurrentRoom->RoomName & " :" & RHS
               EndIf

            Case "QUIT", "Q"
               If Len( RHS ) Then
                  for i as integer = 0 to Global_IRC.NumServers - 1
                     #if LIC_CHI
                     if Global_IRC.Server[i]->ServerSocket.IS_Closed = FALSE then
                        Global_IRC.Server[i]->SendLine( "QUIT :" & RHS, TRUE )
                        Global_IRC.Server[i]->ServerSocket.Close( )
                        sleep( 100, 1 )
                     EndIf
                     #else
                        Global_IRC.Server[i]->SendLine( "QUIT :" & RHS, TRUE )
                        closesocket( Global_IRC.Server[i]->ServerSocket )
                     #endif
                  Next
               EndIf
               *Global_IRC.ShutDown = 1

            Case "MSG", "W", "MESSAGE", "WHISPER", "M", "PM", "PRIVMSG", "QUERY"

               #define target PL.s[1]
               #undef msg
               #define msg *cptr( zstring ptr, @PL.copyv[ PL.start[2] ] )

               If Len( target ) = 0 Then
                  Return FALSE
               EndIf

               with *( Global_IRC.CurrentRoom->Server_Ptr )

               var URT = Global_IRC.CurrentRoom->Server_Ptr->Find( target )

               If .IS_CHANNEL( target ) = FALSE then
                  If URT = 0 Then
                     If StringEqualASM( .UCase_( target ), .UCurrentNick ) Then
                        Response = "PRIVMSG " & target & " :" & msg
                        TMP = !"\nPRIVMSG " & target & " :"
                        Response = String_Replace( !"\n", TMP, Response )
                        exit select
                     else
                        URT = .AddRoom( target, PrivateChat )
                     endif
                  EndIf
               elseif URT = 0 then
                  Response = "PRIVMSG " & target & " :" & msg
                  TMP = !"\nPRIVMSG " & target & " :"
                  Response = String_Replace( !"\n", TMP, Response )
                  exit select
               EndIf            

               If URT <> 0 then
                  if URT <> Global_IRC.CurrentRoom Then
                     Global_IRC.SwitchRoom( URT )
                  EndIf
                  if PL.count > 2 then
                     ChatInput.Set( msg )
                     Parse_Scancode( SC_ENTER )
                  endif
               EndIf
               
               End With

            Case "NOTICE", "N"
               #define target PL.s[1]
               #define msg *cptr( zstring ptr, @PL.copyv[ PL.start[2] ] )

               If PL.Count > 2 Then
                  Response = "NOTICE " & target & " :" & msg
               endif

            Case "NAMES"
               Response = EnteredCommand
               If Len( RHS ) = 0 Then
                  Response += Global_IRC.CurrentRoom->RoomName
               EndIf

            Case "IGNORE", "SQUELCH", "UNIGNORE", "UNSQUELCH"

               With *Global_IRC.CurrentRoom

               var u = ( LHS[0] = asc("U") )

               if PL.count >= 3 then
                  for i as integer = 1 to PL.count - 2
                     ChatInput.Set( "/" & LHS & " " & PL.s[i] )
                     Parse_Scancode( SC_ENTER )
                  Next
                  RHS = PL.s[PL.count - 1]
               EndIf

               Var IName = Trim( RHS )
               var SName = " " + .Server_Ptr->UCase_( IName )
               var i = InStr( .Server_Ptr->UCase_( .Server_Ptr->ServerOptions.IgnoreList ), SName )

               if len( IName ) = 0 then i = 0

               If ( (i > 0) and (u <> 0) ) or ( (u = 0) and (i = 0) and (len(IName) > 0)) Then

                  if u <> 0 then

                     .Server_Ptr->ServerOptions.IgnoreList = _
                        left( .Server_Ptr->ServerOptions.IgnoreList, i - 1 ) + mid( .Server_Ptr->ServerOptions.IgnoreList, i + len_hack( SName ) )

                     SName = "** Removed '" & IName & "' from the ignore list"

                  else

                     .Server_Ptr->ServerOptions.IgnoreList += " " + IName

                     SName = "** Added '" & IName & "' to the ignore list"

                  endif

                  Notice_Gui( SName, Global_IRC.Global_Options.ServerMessageColour )
                  .Server_Ptr->IgnoreListDone = 0

               Else

                  if ( u <> 0 ) and ( len( IName ) > 0 ) then
                     Notice_Gui( "** '" & IName & "' was not found on the ignore list", Global_IRC.Global_Options.ServerMessageColour )
                  EndIf
                  Notice_Gui( "** Current Ignore List:" & .Server_Ptr->ServerOptions.IgnoreList, Global_IRC.Global_Options.ServerMessageColour )

               Endif

               End with

            Case "ID", "IDENTIFY"
               Response = "PRIVMSG " & Global_IRC.CurrentRoom->Server_Ptr->ServerOptions.IdentifyService & " :IDENTIFY " & RHS

            Case "NS", "NICKSERV"
               Response = "PRIVMSG " & Global_IRC.CurrentRoom->Server_Ptr->ServerOptions.IdentifyService & " :" & RHS

            Case "CS", "CHANSERV"
               Response = "PRIVMSG CHANSERV :" & RHS

            Case "TOPIC"

               with *Global_IRC.CurrentRoom

               If Len( RHS ) = 0 Then
                  Response = EnteredCommand + " " + .RoomName
               Elseif _
                  ( InStrASM( 1, RHS, asc(" ") ) = 0 ) and _
                  ( .Server_Ptr->IS_Channel( RHS ) = TRUE ) then
                     Response = EnteredCommand
               else
                  Response = "TOPIC " & .RoomName & " :" & RHS
               EndIf

               end with

            case "TOPICA"
               'Topic append

               if len( RHS ) > 0 then
                  Response = "TOPIC " & Global_IRC.CurrentRoom->RoomName & " :" & Global_IRC.CurrentRoom->Topic & RHS
               EndIf

            Case "JOIN", "J"
               Response = "JOIN " & RHS

            case "WHOIS"
               Response = EnteredCommand

            Case "CONNECT"

               if Global_IRC.NoServers = TRUE then
                  Exit Function
               EndIf
               
               var snum = valint( rhs )
               
               'FIXME!!!
               #if LIC_CHI
               if snum = 0 then
                  For i As Integer = 0 To Global_IRC.NumServers - 1
                     With *Global_IRC.Server[i]
                        If .ServerSocket.Is_Closed( ) = TRUE Then
                           .State = ServerStates.disconnected
                           .IRC_Connect( )
                        EndIf
                     End With
                  Next
               else
                  if Global_IRC.NumServers >= snum then
                     With *Global_IRC.Server[ snum - 1 ]
                        If .ServerSocket.Is_Closed( ) = TRUE Then
                           .State = ServerStates.disconnected
                           .IRC_Connect( )
                        EndIf
                     End with
                  end if
               End if
               #endif
               
            Case "KICK", "KICKBAN"
               'Var Victim = Left( RHS, InStr( RHS & " ", " " ) - 1 )
               'Var Reason = LTrim( Mid( RHS, InStr( RHS, " " ) ) )
               if PL.count < 2 then
                  return FALSE
               EndIf
               Response = "KICK " & Global_IRC.CurrentRoom->RoomName & " " & PL.s[1]
               if PL.count > 2 then
                  Response &= " :" & *cptr( zstring ptr, @PL.copyv[ PL.start[2] ] )
               EndIf
               If Len( LHS ) > 4 Then ' = "KICKBAN" Then
                  ChatInput.Set( "/BAN " & PL.s[1] )
                  Parse_Scancode( SC_ENTER )
               EndIf

            Case "BAN"
               Response = "MODE " & Global_IRC.CurrentRoom->RoomName & " +b " & RHS & "!*@*"

            Case "VOICE", "+", "OP", "@", "HALF", "%", "DEVOICE", "DEOP", "DEHALF"
               if len_hack( RHS ) = 0 then
                  return FALSE
               EndIf

               dim as zstring ptr minus = iif( LHS[0] = asc("D"), @"-", @"+" )
               dim as ubyte mode

               select case LHS[0]
               case asc("V"), asc("+")
                  mode = asc("v")
               case asc("H"), asc("%")
                  mode = asc("h")
               case asc("D")
                  mode = LHS[2] + 32 'o:h:v respectively
               case else
                  mode = asc("o")
               End Select

               with *( Global_IRC.CurrentRoom )

               if PL.s[1] = "*" then
                  #define UC .Server_Ptr->Ucase_
                  #define you .Server_Ptr->UCurrentNick
                  Var UNT = .FirstUser
                  Response = "D" 'Dummy param 0
                  for i as integer = 1 to .NumUsers
                     if (LHS[0] <> asc("D")) and (UNT->Privs <> 0) then
                        dim as integer hasmode
                        for j as integer = 0 to ubound( .Server_Ptr->ServerInfo.IPrefix )
                           if .Server_Ptr->ServerInfo.IPrefix(j) = 0 then
                              exit for
                           EndIf
                           if UNT->Privs = .Server_Ptr->ServerInfo.VPrefix(j) then
                              hasmode = 1
                           endif
                           if mode = .Server_Ptr->ServerInfo.IPrefix(j) then
                              if hasmode then
                                 UNT = UNT->NextUser
                                 continue for, for
                              EndIf
                           EndIf
                        Next
                     EndIf
                     if ( StringEqualASM( UC( UNT->UserName ), you ) = 0 ) then
                        Response += " " + UNT->UserName
                     end if
                     UNT = UNT->NextUser                 
                  Next
                  PL.Constructor( Response )
                  if PL.Count <= 1 then
                     ChatInput.Set( "" )
                     ChatInput.Print( )
                     return FALSE
                  EndIf
               endif

               Response = "MODE " & .RoomName & " " & *minus

               dim as string orig = Response
               dim as integer c = 1
               for i as integer = 1 to ( PL.Count - 2 ) \ .Server_Ptr->ServerInfo.Modes
                  Response += String( .Server_Ptr->ServerInfo.Modes, mode )
                  for j as integer = 1 to .Server_Ptr->ServerInfo.Modes
                     Response += " " + PL.s[c]
                     c += 1
                  Next
                  Response += !"\n" + orig
               Next
               Response += String( PL.count - c, mode ) & mid( PL.copyv, PL.start[c] )

               end with

            Case "INVITE", "I"
               If InStrASM( 1, RHS, asc(" ") ) = 0 Then
                  RHS &= " " & Global_IRC.CurrentRoom->RoomName
               EndIf
               Response = "INVITE " + RHS

#if LIC_DCC
            Case "DCC"
               DCC_Parse( RHS )
#endif

            Case "FIXSCREEN"
               LIC_Screen_INIT( )
               If Global_IRC.CurrentRoom->UserListWidth > 0 then
                  Global_IRC.CurrentRoom->PrintUserList( )
               endif
               Global_IRC.LastLOT = 0
               Global_IRC.CurrentRoom->PrintChatBox( )
               Global_IRC.PrintQueue_U = 0
               Global_IRC.PrintQueue_C = 0

            case "RECONNECT"

               if Global_IRC.NoServers = TRUE then
                  Return FALSE
               EndIf

               var start = Global_IRC.CurrentRoom->Server_ptr->ServerNum
               var finish = start
               var current = start

               if ( ucase( left( rhs, 3 ) ) = "ALL" ) and ( Global_IRC.NumServers > 1 ) then
                  if start = 0 then
                     finish = Global_IRC.NumServers - 1
                  else
                     finish = start - 1
                  EndIf
               EndIf

               do

                  with *( Global_IRC.Server[ current ] )

                     MutexLock( .Mutex )
                     'FIXME!!!
                     #if LIC_CHI
                     if .ServerSocket.Is_Closed( ) = FALSE then
                        .SendLine("QUIT :Reconnecting", TRUE )
                     EndIf
                     .ServerSocket.Close( )
                     #else
                     closesocket( .ServerSocket )
                     #endif
                     .ReconnectTime = 0
                     .State = ServerStates.disconnected
                     MutexUnlock( .Mutex )

                     Notice_Gui( "** Reconnecting to " & .ServerOptions.Server, Global_IRC.Global_Options.ServerMessageColour )

                  End With

                  if current = finish then Exit Do

                  current += 1
                  if current = Global_IRC.NumServers then current = 0

               loop

            case "COLOUR", "COLOR"
               ' /colour [ <user> [ <colour> ] ]

               if Global_IRC.CurrentRoom->NumUsers = 0 then Return FALSE

               var UNT = Global_IRC.CurrentRoom->FirstUser

               if len( RHS ) = 0 then

                  for i as integer = 0 to ( Global_IRC.CurrentRoom->NumUsers - 1 )

                     UNT->ChatColour = rndColour( Global_IRC.DarkUsers )
                     While UNT->ChatColour = Global_IRC.Global_Options.YourChatColour
                        UNT->ChatColour = rndColour( Global_IRC.DarkUsers )
                     Wend
                     UNT = UNT->NextUser

                  Next

               else

                  Var S = InStrASM( 1, RHS, asc(" ") )

                  if S = 0 then
                     UNT = Global_IRC.CurrentRoom->Find( RHS )
                     if UNT = 0 then Return FALSE
                                          
                     UNT->ChatColour = rndColour( Global_IRC.DarkUsers )
                     While UNT->ChatColour = Global_IRC.Global_Options.YourChatColour
                        UNT->ChatColour = rndColour( Global_IRC.DarkUsers )
                     Wend

                  else
                     UNT = Global_IRC.CurrentRoom->Find( left( RHS, S - 1 ) )
                     if UNT = 0 then Return FALSE

                     UNT->ChatColour = Get_RGB( mid( RHS, S + 1 ) )

                  endif

               EndIf

               Global_IRC.CurrentRoom->PrintUserList( TRUE )

            case "SET"
               If PL.count < 3 Then Return FALSE

               lhs = UCase( Trim( PL.s[1], any !" \t" ) )
               rhs = LTrim( *cptr( zstring ptr, @PL.copyv[ PL.start[2] ] ), any !" \t" )

               TMP = "** "

               if Global_IRC.Global_Options.Set_Value( lhs, rhs ) then
                  TMP += "SET: " & lhs & " = " & rhs
               else
                  TMP += "Could not find " & lhs
               EndIf

               Notice_Gui( TMP, Global_IRC.Global_Options.ServerMessageColour )

            case "SERVER"

               enum cmds
                  s_add
                  s_rem
                  s_list
                  s_help
               End Enum

               rhs = Trim( rhs ) + " "

               var cmd = s_add
               var S1 = InStrAsm( 1, rhs, Asc(" ") )

               select case ucase( PL.s[1] )
               case "", "HELP"
                  Global_IRC.CurrentRoom->AddLOT( "** Server commands:", Global_IRC.Global_Options.ServerMessageColour, 0, Notification, , , TRUE )
                  Global_IRC.CurrentRoom->AddLOT( "  list : list current servers", Global_IRC.Global_Options.ServerMessageColour, 0, Notification, , , TRUE )
                  Global_IRC.CurrentRoom->AddLOT( "  remove <ID> : remove server with matching ID", Global_IRC.Global_Options.ServerMessageColour, 0, Notification, , , TRUE )
                  Global_IRC.CurrentRoom->AddLOT( "  To add a server do /server <server> [<port>] [<pass>]", Global_IRC.Global_Options.ServerMessageColour, 0, Notification, , , TRUE )
                  Global_IRC.CurrentRoom->AddLOT( "  The default port is 6667", Global_IRC.Global_Options.ServerMessageColour, 1, Notification, , , TRUE )
                  cmd = s_help
               case "REMOVE", "-"
                  cmd = s_rem
               case "LIST"
                  if Global_IRC.NoServers = TRUE then
                     Return FALSE
                  EndIf
                  Global_IRC.CurrentRoom->AddLOT( "* Server List: *", Global_IRC.Global_Options.ServerMessageColour, 0, LineBreak, 1 )
                  for i as integer = 0 to Global_IRC.NumServers - 1
                     TMP = "   #" & i+1 & " " & Global_IRC.Server[i]->ServerOptions.Server & " [ " & Global_IRC.Server[i]->ServerName & " ] " & Global_IRC.Server[i]->CurrentNick
                     Global_IRC.CurrentRoom->AddLOT( TMP, Global_IRC.Global_Options.ServerMessageColour, 0, Notification, , , TRUE )
                  Next
                  Global_IRC.CurrentRoom->AddLOT( "", Global_IRC.Global_Options.ServerMessageColour, 1, LineBreak, 1 )
                  cmd = s_list
               case else
                  if asc( rhs ) = asc("-") then
                     cmd = s_rem
                     S1 = 1
                  else
                     S1 = 0
                  EndIf
               end select

               S1 += 1
               var S2 = InStrASM( S1, rhs, asc(" ") )

               select case cmd

               case s_add

                  dim as string param()

                  rhs = mid( rhs, S1 )
                  String_Explode( rhs, param() )

                  if ( len_hack( param(0) ) = 0 ) then
                     Return FALSE
                  EndIf

                  dim as Server_Options_Type addition

                  swap addition.Server, param(0)

                  if ubound( param ) >= 1 then
                     addition.Port = ValUint( param(1) )
                  EndIf
                  if ubound( param ) >= 2 then
                     swap addition.Password, param(2)
                  EndIf

                  with ( Global_IRC.CurrentRoom->Server_Ptr->ServerOptions )

                  addition.NickName = .NickName
                  'addition->ServerOptions.UserName = .Username
                  'addition->ServerOptions.Hostname = .Hostname
                  'addition->ServerOptions.RealName = .Realname

                  end with

                  Global_IRC.AddServer( addition )

               case s_rem

                  Global_IRC.DelServer( valint( mid( rhs, S1, S2 - S1 ) ) )

               end select

               Global_IRC.DrawTabs( )

            case "HELP"
               Parse_Scancode( SC_F1 )

            case "CLEAR"
               Parse_Scancode( SC_F8 )

            case "CYCLE", "HOP"
               Global_IRC.CurrentRoom->Server_Ptr->SendLine( _
                  "PART " & Global_IRC.CurrentRoom->RoomName & !"\nJOIN " & Global_IRC.CurrentRoom->RoomName )

            case "SCRIPT"

               enum cmds
                  scripthelp
                  scriptadd
                  scriptdel
                  scriptlist
               End Enum

               dim as integer cmd = scripthelp

               if PL.count > 1 then
                  select case lcase( PL.s[1] )
                  case "add"
                     if PL.count > 2 then
                        cmd = scriptadd
                     endif
                  case "del", "delete", "remove"
                     if PL.count > 2 then
                        cmd = scriptdel
                     endif
                  case "list"
                     cmd = scriptlist
                  End Select
               EndIf

               select case cmd
               case scripthelp
                  Global_IRC.CurrentRoom->AddLOT( "** Script commands :", Global_IRC.Global_Options.ServerMessageColour, 0, Notification, , , TRUE )
                  Global_IRC.CurrentRoom->AddLOT( "  add <script> : Add a script", Global_IRC.Global_Options.ServerMessageColour, 0, Notification, , , TRUE )
                  Global_IRC.CurrentRoom->AddLOT( "  del <ID> : Delete script with ID", Global_IRC.Global_Options.ServerMessageColour, 0, Notification, , , TRUE )
                  Global_IRC.CurrentRoom->AddLOT( "  list : List scripts for this server", Global_IRC.Global_Options.ServerMessageColour, 1, Notification, , , TRUE )
               case scriptadd
                  PL.s[0] = *cptr( zstring ptr, @PL.copyv[ PL.start[2] ] )
                  if Global_IRC.CurrentRoom->Server_Ptr->AddScript( PL.s[0] ) = TRUE then
                     Global_IRC.CurrentRoom->AddLOT( "** Script '" & PL.s[0] & "' was added", Global_IRC.Global_Options.ServerMessageColour, 1, Notification, , , TRUE )
                  else
                     Global_IRC.CurrentRoom->AddLOT( "** Script add failed", Global_IRC.Global_Options.ServerMessageColour, 1, Notification, , , TRUE )
                  EndIf
               case scriptdel
                  var id = valint( PL.s[ 2 ] ) - 1
                  with Global_IRC.CurrentRoom->Server_Ptr->Event_handler

                  if ( ( id < .allocated ) and ( id >= 0 ) ) andalso ( .events[id] <> 0 ) then
                     select case .events[id]->ID
                     case Script_Filter to Script_WordFilter
                        Global_IRC.CurrentRoom->AddLOT( "** Script '" & .events[id]->_string & "' was deleted", Global_IRC.Global_Options.ServerMessageColour, 1, Notification, , , TRUE )
                        Delete .events[id]
                        .events[id] = 0
                        .queued -= 1
                        exit select, select
                     End Select
                  EndIf

                  End With
                  Global_IRC.CurrentRoom->AddLOT( "** Script delete failed", Global_IRC.Global_Options.ServerMessageColour, 1, Notification, , , TRUE )
               case scriptlist
                  var LB = Global_IRC.CurrentRoom->AddLOT( "* Scripts: *", Global_IRC.Global_Options.ServerMessageColour, 0, LineBreak, 1 )
                  var LastLine = LB
                  with Global_IRC.CurrentRoom->Server_Ptr->Event_handler
                  for i as integer = 0 to .allocated - 1
                     if .events[i] = 0 then
                        continue for
                     endif
                     select case .events[i]->ID
                     case Script_Filter to Script_WordFilter
                        LastLine = Global_IRC.CurrentRoom->AddLOT( "  ID:" & i + 1 & " | " & .events[i]->_string, Global_IRC.Global_Options.ServerMessageColour, 0, Notification, , , TRUE )
                     End Select
                  Next
                  end with
                  if LB = LastLine then
                     Global_IRC.CurrentRoom->AddLOT( "No scripts found", Global_IRC.Global_Options.ServerMessageColour, 0, LineBreak, 1 )
                  else
                     Global_IRC.CurrentRoom->AddLOT( "", Global_IRC.Global_Options.ServerMessageColour, 0, LineBreak, 1 )
                  end if
                  Global_IRC.CurrentRoom->PrintChatBox( 1 )
               End Select

            case "CTCP"
               if ( PL.count < 3 ) orelse ( len( PL.s[2] ) <= 0 ) then
                  return FALSE
               EndIf

               response = "PRIVMSG " & PL.s[1] & !" :\1" & *cptr( zstring ptr, @PL.copyv[ PL.start[2] ] ) & !"\1"

            case "LIST"
               if Global_IRC.CurrentRoom->Server_Ptr->ListRoom <> 0 then
                  Global_IRC.CurrentRoom->Server_Ptr->DelRoom( Global_IRC.CurrentRoom->Server_Ptr->ListRoom )
                  Global_IRC.CurrentRoom->Server_Ptr->ListRoom = 0
               EndIf

               swap response, PL.copyv

            case "SLAP"

               if PL.count = 1 then
                  return FALSE
               end if

               dim as string ircobject

               if PL.count = 2 then
                  ircobject = "a large trout"
               else
                  ircobject = *cptr( zstring ptr, @PL.copyv[ PL.start[2] ] )
               end if

               var msg = !"\1ACTION slaps " & PL.s[1] & " around a bit with " & ircobject & !"\1"

               if Global_IRC.CurrentRoom->RoomType = DccChat then
                  #if LIC_DCC
                     DCC_CHAT_OUT( msg )
                  #endif
               else
                  response = "PRIVMSG " & Global_IRC.CurrentRoom->RoomName & " :" & msg
               end if

            case "LAST"

               if ( PL.count = 1 ) then ' or ( Global_IRC.CurrentRoom->RoomType <> Channel ) then
                  return FALSE
               end if

               dim as integer found, currentline, i
               redim as string results( 31 )

               var sp = instrrev( PL.copyv, " " )
               var amount = iif( sp <= 5, 1, valint( mid( PL.copyv, sp + 1 ) ) )          
               var osearch = mid( PL.copyv, 6, sp - 6 )               
               
               if amount <= 0 then
                  amount = 1
                  osearch &= mid( PL.copyv, sp )
               EndIf
               
               var search = ucase( osearch )
               
               'LIC_DEBUG( "\\searching for: """ & search & """ amount:" & amount )
               with *( Global_IRC.CurrentRoom )

               currentline = .NumLines - 1

               do until ( found = amount ) or ( currentline = 0 )
                  if ( .TextArray[ currentline ]->MesID < 50 ) then
                     i = InStr( ucase( .TextArray[ currentline ]->Text ), search )                     
                     if i <> 0 then
                        if found > ubound( results ) then
                           redim Preserve results( ubound( results ) + 32 )
                        end if
                        while (.TextArray[ currentline ]->MesID AND 1) <> 0
                           currentline -= 1
                        Wend
                        results( found ) = .TextArray[ currentline ]->TimeStamp & .TextArray[ currentline ]->Text
                        for i = 1 to .NumLines - currentline - 1
                           if (.TextArray[ currentline + i ]->MesID AND 1) = 0 then
                              exit for
                           else
                              results( found ) += .TextArray[ currentline + i ]->Text
                           EndIf
                        Next
                        found += 1
                     end if
                  end if
                  currentline -= 1
               loop

               if found = 0 then
                  .AddLOT( "** Error could not find any history for " & osearch, Global_IRC.Global_Options.ServerMessageColour, 1, Notification, , , TRUE )
               else
                  .AddLOT( "* " & osearch & " | History *", Global_IRC.Global_Options.ChatHistoryColour, 0, LineBreak )
                  dim as string msg
                  currentline = .NumLines - 1
                  for i = found - 1 to 0 step -1
                     .AddLOT( results(i), Global_IRC.Global_Options.ChatHistoryColour, 0, ChatHistory, , , TRUE )
                  next
                  .AddLOT( "* End History *", Global_IRC.Global_Options.ChatHistoryColour, 1, LineBreak )
               end if

               end with
                       
            case "ABOUT"
               Global_IRC.CurrentRoom->AddLOTEX( _
                  "** " IRC_Version_name " v" IRC_Version_major & "." IRC_Version_minor "b (build:" IRC_Version_build & _ 
                  ") (" IRC_Build_env ")", Global_IRC.Global_Options.ServerMessageColour, Notification, 0, LOT_NoLog or LOT_NoPrint )
               
               Notice_Gui( "** Compiled with " __FB_SIGNATURE__ " on " __DATE__ " at " __TIME__, Global_IRC.Global_Options.ServerMessageColour )

            Case "?"
               Dim As ZString ptr HelpMessage(48)
               Dim As LOT_MultiColour_Descriptor MCD = ( 1, 0, Global_IRC.Global_Options.TabColour )

               HelpMessage(4) = @"* : May require elevated status to perform these commands"
               HelpMessage(5) = @"/server <cmd> : Add/Del servers. Use /server for available commands"
               HelpMessage(6) = @"/raw <message> : Sends message unmodified to the server (careful)"
               HelpMessage(7) = @"/reconnect [all] : Reconnects to the server, use all to apply to all servers"
               HelpMessage(8) = @"/ping <user> : [CTCP] Request a response from user to judge latency [/p]"
               HelpMessage(9) = @"/time <user> : [CTCP] Request user's current local time [/t]"
               HelpMessage(10)= @"/version <user> : [CTCP] Request info about user's IRC client [/v /ver]"
               HelpMessage(18)= @"/part [<message>] : Leave the current room (optional part message)"
               HelpMessage(19)= @"/notice <target> <message> : Send a NOTICE to target"
               HelpMessage(20)= @"/id <password> : Send IDENTIFY message to NickServ with password"
               HelpMessage(21)= @"/ns <message> : Send message to NickServ"
               HelpMessage(22)= @"/topic <message> : *Set current channel's topic"
               HelpMessage(23)= @"/kick <user> [<message>] : *Kick user from the channel with optional message"
               HelpMessage(24)= @"/kickban <user> [<message>] : *Ban user's nick from the channel & then kick"
               HelpMessage(25)= @"/voice <users> : *Grant voice (+v) status to users [/+]"
               HelpMessage(26)= @"/op <users> : *Grant operator (+o) status to users [/@]"
               HelpMessage(27)= @"/invite <user> : *Invite user to a private channel [/i]"
               HelpMessage(28)= @"/topica <message> : *Append message to current channel's topic"
               HelpMessage(30)= @"/colour [<user> [<value>]] : Use a new colour for user(s). Value is in format r,g,b [/color]"
               HelpMessage(31)= @"/script <cmd> : Add/Del scripts. Use /script for available commands"
               HelpMessage(32)= @"/fixscreen : Attempt to fix any display problems"
               HelpMessage(33)= @"/about : Display your current LIC version"
               HelpMessage(34)= @"/alias : Set an alias, leave empty to display aliases"

               Global_IRC.CurrentRoom->AddLOT( "*[ / commands ]*", Global_IRC.Global_Options.ServerMessageColour, 0, LineBreak, 1 )
               dim as string msg

               For i As Integer = UBound( HelpMessage ) to 0 step -1
                  If HelpMessage(i) <> 0 Then
                     var MCD2 = new LOT_MultiColour_Descriptor
                     msg = *HelpMessage(i)
                     MCD2->TextStart = InStr( msg, "[/" )
                     if MCD2->TextStart > 0 then
                        MCD.NextDesc = MCD2
                        MCD2->TextLen = len_hack( msg ) - MCD2->TextStart + 1
                        MCD2->Colour = MCD.Colour
                     else
                        delete MCD2
                     EndIf
                     MCD.TextLen = InStrASM( 1, msg, asc(":") )
                     Global_IRC.CurrentRoom->AddLOT( msg, Global_IRC.Global_Options.TextColour, 0, Notification, 0, @MCD, TRUE )
                     if MCD.NextDesc <> 0 then
                        Delete MCD.NextDesc
                        MCD.NextDesc = 0
                     EndIf
                  EndIf
               Next
               Global_IRC.CurrentRoom->AddLOT( "", Global_IRC.Global_Options.ServerMessageColour, 1, LineBreak, 0 )
            
            case "AWAY"
               Response = "AWAY :" & RHS
               
            case "README"
               
               #define readme_url "https://raw.githubusercontent.com/lukelandriault/luke-irc-client/master/readme.txt"
               dim as curl_obj cobj
               var curl = curlget( readme_url, cobj, TRUE, FALSE )
               if ( curl <> CURLE_OK ) or ( cobj.size = 0 ) then
                  notice_gui( "error connecting to github : " & *iif( cobj.size, curl_easy_strerror(curl), @"404 not found" ), rgb( 192, 0, 0 ) )
                  return 0
               EndIf
               
               cobj.p[cobj.size] = 0
               dim as string response = *cptr( zstring ptr, cobj.p )
               deallocate( cobj.p )
                              
               with Global_IRC
               .CurrentRoom->AddLOT( "*[ LIC readme.txt ]*", .Global_Options.ServerMessageColour, 0, LineBreak, 1 )
               dim as integer n, numlines = Global_IRC.CurrentRoom->NumLines
               
               do
                  n = InStrASM( 1, response, asc(!"\n") )
                  .CurrentRoom->AddLOT( rtrim( left( response, n - 1 ), !"\r" ), .Global_Options.YourChatColour, 0, notification, , , 1 )
                  response = mid( response, n + 1 )
               loop while len( response )
               
               .CurrentRoom->AddLOT( "*[ EOF readme.txt ]*", .Global_Options.ServerMessageColour, 0, LineBreak, 1 )
               .CurrentRoom->UpdateChatListScroll( 0, 1, numlines )
               
               end with
            
            case "ALIAS"
               if len( rhs ) = 0 then
                  dim as integer showed
                  if Global_IRC.AliasList <> 0 then
                     for i as integer = 0 to Global_IRC.AliasCount - 1 step 2
                        if Global_IRC.AliasList[i] <> 0 then
                           Notice_Gui( "Alias: " & *Global_IRC.AliasList[i] & " = " & *Global_IRC.AliasList[i+1], Global_IRC.Global_Options.ServerMessageColour )
                           showed += 1
                        EndIf
                     Next
                  endif
                  if showed = 0 then
                     Notice_Gui( "There are no set aliases", Global_IRC.Global_Options.ServerMessageColour )
                  elseif showed > 1 then
                     Global_IRC.CurrentRoom->PrintChatBox( 1 )
                  EndIf
               else
                  Global_IRC.AliasSet( rhs, 1 )
               EndIf               

            #If __FB_DEBUG__
            
            case "CRASH" 'initiate a seg fault
               dim as integer i = *cptr( integer ptr, 0 )
               print "seg fault.." & i
            
            case "GOTO"
               
               dim as uinteger i = valuint( RHS )
               Global_IRC.CurrentRoom->UpdateChatListScroll( 0, 1, i )

            case "B", "BENCHMARK"

               dim as string msg(1)
               dim as double t1, t2
               
               msg(0) = "LOOO L ADSF SPAMM MMMSPAM !! SMAPPPEEWMA AD FMERHA AMDF ASHDFJ ASKDKFKEFHASD WF SPAM!SDF JF ASDF JADFJ AJSDJF JFDF JDFJ"
               msg(1) = "ADF HAHA DF E www.google.com WHAT!! LOL Www.yahoo.ca ASDF ASD ASDFEE #ASDF asdfj #freenode asdfjl #LIC ahdflj #FREEBASIC ashkdfhasjdf #DAF Fasdfhkjash www.lool.in"

               var URT2 = Global_IRC.CurrentRoom->Server_Ptr->Find( "LIC:TEST:ROOM" )
               'Global_IRC.CurrentRoom->Server_Ptr->ServerOptions.TwitchHacks = 1

               if URT2 <> 0 then
                  Global_IRC.CurrentRoom->Server_Ptr->DelRoom( URT2 )
               EndIf

               var URT = Global_IRC.CurrentRoom
               var LogToFile = Global_IRC.Global_Options.LogToFile
               Global_IRC.Global_Options.LogToFile = FALSE

               URT2 = URT->Server_Ptr->AddRoom( "LIC:TEST:ROOM", Channel )

               Global_IRC.SwitchRoom( URT )
               
               t1 = timer
               for i as integer = 1 to valint( RHS ) ' URT2->NumLines <= Global_IRC.Global_Options.MaxBackLog
                  URT2->AddLOT( msg( iif( (i and 31) = 0, 1, 0 ) ), Global_IRC.Global_Options.ServerMessageColour,0,,,,TRUE )
               next
               t1 = timer - t1
               
               LIC_DEBUG( "done adding lines, timer: " & t1 )
               
               dim as zstring * 9 user
               dim as integer userlen = 1
               
               t2 = timer
               for i as integer = 1 to valint( RHS )
                  for j as integer = 0 to 7
                     user[j] = int( rnd * 26 ) + 65
                  Next
                  URT2->AddUser( @user )
               Next
               t2 = timer - t2
               
               LIC_DEBUG( "done adding users, timer: " & t2 & " (twitch hacks o" & *iif( Global_IRC.CurrentRoom->Server_Ptr->ServerOptions.TwitchHacks, @"n)", @"ff)" ) )
               
               URT2->AddLOT( "Adding " & valint( RHS ) & " lines took " & t1, Global_IRC.Global_Options.ServerMessageColour,0,,,,TRUE )
               URT2->AddLOT( "Adding " & valint( RHS ) & " users took " & t2, Global_IRC.Global_Options.ServerMessageColour,0,,,,TRUE )
               
               Global_IRC.Global_Options.LogToFile = LogToFile
               
               'URT->Server_Ptr->DelRoom( URT2 )

            Case "D", "DEBUG"               
               
               select case ucase( RHS )
               case "THREAD"
                  LIC_DEBUG( "spawning thread" )
                  LIC_NOTIFY( 0 )
                  LIC_DEBUG( "sending stop signal" )
                  LIC_TrayFlash_STOP
                  return 0
               case "HILITE", "D"
                  dim as irc_message ircm
                  ircm.URT = Global_IRC.CurrentRoom
                  var msg = ":FakeMessage!fake@message PRIVMSG " & ircm.URT->RoomName & " :" & string( 200, "a" ) & " hello " & ircm.URT->Server_Ptr->CurrentNick
                  Build_IRC_Message( ircm, msg )
                  lic_debug( "\\faking message:" & msg )
                  ircm.URT->Server_Ptr->Parse_Privmsg( ircm )
                  return 0
               end select
               
               Dim As UInteger dt = Timer - UptimeStart
               Dim As Integer IRC_Total_Users, IRC_Total_Rooms, IRC_Hidden_Rooms, IRC_Total_Lines, IRC_Server_Events
               var URT = Global_IRC.Server[0]->FirstRoom

               Do
                  IRC_Total_Users += URT->NumUsers
                  IRC_Total_Rooms += 1
                  If (URT->pflags AND Hidden) Then IRC_Hidden_Rooms += 1
                  IRC_Total_Lines += URT->NumLines
                  URT = GetNextRoom( URT )
               Loop Until URT = Global_IRC.Server[0]->FirstRoom

               IRC_Server_Events = Global_IRC.CurrentRoom->Server_Ptr->Event_Handler.Queued

               Dim As String CHANMODES, PREFIX = "("
               For i As Integer = 0 To 3
                  CHANMODES += Global_IRC.CurrentRoom->Server_Ptr->ServerInfo.CHANMODES( i ) & ","
               Next

               For i As Integer = 0 To UBound( Global_IRC.CurrentRoom->Server_Ptr->ServerInfo.IPrefix )
                  If Global_IRC.CurrentRoom->Server_Ptr->ServerInfo.IPrefix(i) <> 0 Then
                     PREFIX += Chr( Global_IRC.CurrentRoom->Server_Ptr->ServerInfo.IPrefix(i) )
                  EndIf
               Next
               PREFIX += ")"
               For i As Integer = 0 To UBound( Global_IRC.CurrentRoom->Server_Ptr->ServerInfo.VPrefix )
                  If Global_IRC.CurrentRoom->Server_Ptr->ServerInfo.VPrefix(i) <> 0 Then
                     PREFIX += Chr( Global_IRC.CurrentRoom->Server_Ptr->ServerInfo.VPrefix(i) )
                  EndIf
               Next

               Global_IRC.CurrentRoom->AddLOT( "Debug Info", Global_IRC.Global_Options.DebugColour, 0, LineBreak )
               debug_gui( "Total Rooms: " & IRC_Total_Rooms & " Hidden Rooms: " & IRC_Hidden_Rooms )
               debug_gui( "Total Users: " & IRC_Total_Users )
               debug_gui( "Total Lines: " & IRC_Total_Lines )
               debug_gui( "Total IRC messages: " & Global_IRC.msgCount )
               If ( Global_IRC.Global_Options.LogToFile <> 0 ) And ( Global_IRC.Global_Options.LogBufferSize > 0 ) Then
                  debug_gui( "Log Buffer: " & Global_IRC.LogLength & " / " & Global_IRC.Global_Options.LogBufferSize )
               EndIf
               debug_gui( "Events: " & Global_IRC.Event_Handler.Queued & " Server Events: " & IRC_Server_Events )

               debug_gui( "ServerInfo CaseMap: " & Global_IRC.CurrentRoom->Server_Ptr->ServerInfo.CMap & " PREFIX: " & PREFIX )
               debug_gui( "   CHANMODES: " & CHANMODES & " NICKLEN: " & Global_IRC.CurrentRoom->Server_Ptr->ServerInfo.NICKLEN )
               debug_gui( "Uptime: " & CalcTime( dt ) )
               Global_IRC.CurrentRoom->AddLOT( "", Global_IRC.Global_Options.DebugColour, 1, LineBreak )

            case "TEST"
               TestInput( )

            #EndIf

            case else

               if ( LHS <> "RAW" ) and ( LHS <> "QUOTE" ) then
                  rhs = EnteredCommand
               EndIf

               if Global_IRC.CurrentRoom->Server_ptr->State = ServerStates.Online then
                  Global_IRC.CurrentRoom->Server_ptr->SendLine( rhs, TRUE )
                  Global_IRC.CurrentRoom->AddLOT( "** RAW -> [ " & Global_IRC.CurrentRoom->Server_ptr->ServerName & " ]: " & rhs, Global_IRC.Global_Options.ServerMessageColour )
               else
                  Global_IRC.CurrentRoom->AddLOT( "** ERROR: You are not connected", Global_IRC.Global_Options.ServerMessageColour, , , , , TRUE )
               endif

         End Select

         If len_hack( Response ) then
            Global_IRC.CurrentRoom->Server_Ptr->SendLine( Response )
         EndIf

      #If __FB_DEBUG__

      ElseIf ( Left( cast( string, ChatInput ), 1 ) = "\" ) And ( MultiKey( SC_CONTROL ) ) Then
         Global_IRC.CurrentRoom->Server_Ptr->SendLine( Mid( ChatInput, 2 ) )
         Function = FALSE

      #endif

#if LIC_DCC
      Elseif Global_IRC.CurrentRoom->RoomType = DccChat then

         if NOT DCC_CHAT_Out( ChatInput ) then
            Global_IRC.CurrentRoom->AddLOT( "** Error: Connection not established", Global_IRC.Global_Options.LeaveColour, , Notification )
         end if
#endif

      elseif Global_IRC.CurrentRoom->RoomType = RawOutput then
         Global_IRC.CurrentRoom->Server_Ptr->SendLine( ChatInput, TRUE )

      else

         const as integer TargetLen = 400 'No real way of knowing the cutoff length? 400 seems safe

         dim as string SendBuffer = ChatInput 'do not use var
         dim as string SendIt

         var ten = InStrASM( 1, Sendbuffer, 10 )

         while ( ten > 0 ) OR ( len_hack( SendBuffer ) > TargetLen )

            if ( ten > 0 ) and ( ten <= TargetLen ) then

               SendIt = Left( SendBuffer, ten - 1 )
               RTrim2( SendIt, !"\r" )
               SendBuffer = mid( SendBuffer, ten + 1 )

            else

               var i = InStrRev( SendBuffer, " ", TargetLen )

               if i <= 6 then '6 = len("[...] ") ; must be used to prevent recursion
                  i = TargetLen
               endif
               
               if len_hack( SendBuffer ) - i <= 10 then 'little bit of forgiveness
                  SendIt = ""
                  swap SendIt, SendBuffer
               else
                  Sendit = left( SendBuffer, i ) & "[...]"
                  SendBuffer = "[...] " & mid( SendBuffer, i + 1 )
               EndIf               

            EndIf

            if len_hack( SendIt ) = 0 then SendIt = " "
            if ( Global_IRC.CurrentRoom->Server_Ptr->ServerOptions.TwitchHacks <> 0 ) and ( Global_IRC.CurrentRoom->RoomType = PrivateChat ) then
               Global_IRC.CurrentRoom->Server_Ptr->SendLine( "PRIVMSG " & Global_IRC.CurrentRoom->RoomName & " :.w " & Global_IRC.CurrentRoom->RoomName & " " & SendIt & !"\n" )
            else
               Global_IRC.CurrentRoom->Server_Ptr->SendLine( "PRIVMSG " & Global_IRC.CurrentRoom->RoomName & " :" & SendIt & !"\n" )
            EndIf            

            ten = InStrASM( 1, Sendbuffer, 10 )
            
         wend

         RTrim2( SendBuffer, !"\r\n", TRUE )
         if len_hack( SendBuffer ) > 0 then
            if ( Global_IRC.CurrentRoom->Server_Ptr->ServerOptions.TwitchHacks <> 0 ) and ( Global_IRC.CurrentRoom->RoomType = PrivateChat ) then
               Global_IRC.CurrentRoom->Server_Ptr->SendLine( "PRIVMSG " & Global_IRC.CurrentRoom->RoomName & " :.w " & Global_IRC.CurrentRoom->RoomName & " " & SendBuffer & !"\n" )
            else
               Global_IRC.CurrentRoom->Server_Ptr->SendLine( "PRIVMSG " & Global_IRC.CurrentRoom->RoomName & " :" & SendBuffer & !"\n" )
            endif
         endif

         Function = FALSE

      EndIf

      ChatInput.Set( "" )
      ChatInput.Print( )

   Case SC_F1 'Print Help

      Dim As ZString ptr HelpMessage(64)
      Dim As LOT_MultiColour_Descriptor MCD = ( 1, 0, Global_IRC.Global_Options.TabColour )

      'HelpMessage(0) = @"Luke's IRC Client Help"
      'HelpMessage(1) = @"F1: Display this help message"
      HelpMessage(2) = @"F2: Toggle channel's notification"
      HelpMessage(3) = @"F3: Toggle time stamp display"
      HelpMessage(4) = @"F4: Clear the outbound message queue"
      HelpMessage(5) = @"F5: Toggle channel's user join/leave messages"
      HelpMessage(6) = @"F6: Toggle hostname display on user join messages"
      HelpMessage(7) = @"F7: Reload the IRC Options file for new option values"
      HelpMessage(8) = @"F8: Clear the current room's chat"
      HelpMessage(12)= @"F12: Show all hidden windows"
      HelpMessage(13)= @"Esc: Close the current room (part if channel)"
      HelpMessage(14)= @"CTRL-V: Paste text from the clipboard"
      HelpMessage(15)= @"PgUp/Down: Scroll up/down one page"
      HelpMessage(16)= @"CTRL-PgUp/Down: Go to top/bottom of the scrollback"
      HelpMessage(22)= @"CTRL-Tab: Switch to the next visible room"
      HelpMessage(23)= @"SHIFT-Tab: Switch to the previous visible room"
      HelpMessage(24)= @"TAB: Auto-complete nick/room"
      HelpMessage(30)= @"/me <msg> : Send a CTCP ACTION message to the channel [/em /action /emote]"
      HelpMessage(31)= @"/msg <user> <msg> : Send a Private Message to <user> [/m /pm /w /message /privmsg /whisper]"
      HelpMessage(34)= @"/join <channel> : Join another channel [/j]"
      HelpMessage(35)= @"/quit <message> : Exit IRC with an optional message [/q]"
      HelpMessage(36)= @"/ignore : Display your ignore list [/squelch]"
      HelpMessage(37)= @"/ignore <user> : Add someone to the ignore list [/squelch]"
      HelpMessage(38)= @"/unignore <user> : Remove someone from the ignore list [/unsquelch]"
      HelpMessage(38)= @"/dcc : Show DCC help info"
      HelpMessage(49)= @"/? : Show all other '/' commands (that are not listed here)"
      HelpMessage(50)= @"Right Click: Copy the message under the mouse to the clipboard"
      HelpMessage(51)= @"Shift + RClick: Save the current clipboard and add a message to it (used to copy more than 1 message)"
      HelpMessage(52)= @"Mouse Wheel Up/Down: Scroll Up/Down"
      HelpMessage(53)= @"Middle Mouse Button: Activate mouse scroller"


      Global_IRC.CurrentRoom->AddLOT( "*[ LIC Help ]*", Global_IRC.Global_Options.ServerMessageColour, 0, LineBreak, 1 )

      var msg = space( 160 )
      var MCD2 = New LOT_MultiColour_Descriptor
      For i As Integer = UBound( HelpMessage ) to 0 step -1
         If HelpMessage(i) <> 0 Then
            msg = *HelpMessage(i)
            MCD.TextLen = InStrASM( 1, msg, asc(":") )
            MCD2->Colour = MCD.Colour
            MCD2->TextStart = InStr( msg, "[/" )
            if MCD2->TextStart > 0 then
               MCD2->TextLen = len_hack( msg ) - MCD2->TextStart + 1
               MCD.NextDesc = MCD2
               if MCD2->NextDesc <> 0 then
                  'clean any splits from the last AddLOT call
                  delete MCD2->NextDesc
                  MCD2->NextDesc = 0
               EndIf
            else
               MCD.NextDesc = 0
            endif
            Global_IRC.CurrentRoom->AddLOT( msg, Global_IRC.Global_Options.TextColour, 0, Notification, 0, @MCD, TRUE )
         EndIf
      Next
      'let the scope destructor clean up
      MCD.NextDesc = MCD2

      Global_IRC.CurrentRoom->AddLOT( "", Global_IRC.Global_Options.ServerMessageColour, 1, LineBreak, 0 )

   Case SC_F2 'Toggle Notifications
      if Multikey( SC_CONTROL ) then
         Global_IRC.CurrentRoom->pflags XOR= DisableSound
         If (Global_IRC.CurrentRoom->pflags AND DisableSound) Then TMP = "dis" Else TMP = "en"
         Notice_Gui( "** " & Global_IRC.CurrentRoom->RoomName & " Sound notification " & TMP & "abled", Global_IRC.Global_Options.ServerMessageColour )
      else
         Global_IRC.CurrentRoom->pflags XOR= ChannelNotify
         If (Global_IRC.CurrentRoom->pflags AND ChannelNotify) Then TMP = "en" Else TMP = "dis"
         Notice_Gui( "** " & Global_IRC.CurrentRoom->RoomName & " Show notifications " & TMP & "abled", Global_IRC.Global_Options.ServerMessageColour )
      EndIf

   Case SC_F3 'Toggle Time Stamps
      Global_IRC.Global_Options.ShowTimeStamp Xor= 1
      If Global_IRC.Global_Options.ShowTimeStamp Then TMP = "en" Else TMP = "dis"
      Notice_Gui( "** Time stamps " & TMP & "abled", Global_IRC.Global_Options.ServerMessageColour )
   Case SC_F4 'Clear Outbound buffer
      If Len( Global_IRC.CurrentRoom->Server_Ptr->SendBuffer ) Then
         Global_IRC.CurrentRoom->Server_Ptr->SendBuffer = ""
         Notice_Gui( "** Outbound message queue has been cleared", Global_IRC.Global_Options.ServerMessageColour )
      EndIf
   Case SC_F5 'Toggle Join/Leave
      Global_IRC.CurrentRoom->pflags XOR= ChannelJoinLeave
      If (Global_IRC.CurrentRoom->pflags AND ChannelJoinLeave) Then TMP = "en" Else TMP = "dis"
      Notice_Gui( "** " & Global_IRC.CurrentRoom->RoomName & " show join/leave messages " & TMP & "abled", Global_IRC.Global_Options.ServerMessageColour )
   Case SC_F6 'Toggle Hostnames
      Global_IRC.CurrentRoom->pflags XOR= ChannelHostName
      If (Global_IRC.CurrentRoom->pflags AND ChannelHostName) Then TMP = "en" Else TMP = "dis"
      Notice_Gui( "** " & Global_IRC.CurrentRoom->RoomName & " Hostname display " & TMP & "abled", Global_IRC.Global_Options.ServerMessageColour )
   Case SC_F7 'Reload the Options File
      Global_IRC.Global_Options.Load_Options( )
      Global_IRC.TextInfo.GetSizes( )
      LIC_Resize( Global_IRC.Global_Options.ScreenRes_X, Global_IRC.Global_Options.ScreenRes_Y )
      Notice_Gui( "** Updated IRC Options", Global_IRC.Global_Options.ServerMessageColour )
   Case SC_F8 'Clear Current Room Chat
      If Global_IRC.CurrentRoom->NumLines > 1 then
         For i As Integer = 0 To ( Global_IRC.CurrentRoom->NumLines - 1 )
            Delete Global_IRC.CurrentRoom->TextArray[i]
         Next
         deallocate( Global_IRC.CurrentRoom->TextArray )
         Global_IRC.CurrentRoom->TextArray = Allocate( 128 * sizeof( any ptr ) )
         Global_IRC.CurrentRoom->NumAllocated = 128
         Global_IRC.CurrentRoom->NumLines = 0
         Global_IRC.CurrentRoom->CurrentLine = 0
         Global_IRC.CurrentRoom->flags AND= NOT( BackLogging )
         Notice_Gui( "** Chat cleared", Global_IRC.Global_Options.ServerMessageColour )
      EndIf
   Case SC_F12 'Reveal all hidden windows
      var URT = Global_IRC.CurrentRoom
      For i As Integer = 1 To Global_IRC.TotalNumRooms
         if URT->RoomType <> DccChat then URT->pflags AND= NOT( Hidden )
         URT = GetNextRoom( URT )
      Next
      Global_IRC.DrawTabs( )

   ''' Testing Stuff

   #if __FB_DEBUG__

   Case SC_F11
      'Global_IRC.CurrentRoom->Server_Ptr->SendBuffer = ""
      #if LIC_CHI
         Global_IRC.CurrentRoom->Server_Ptr->ServerSocket.Close()
      #else
         closesocket( Global_IRC.CurrentRoom->Server_Ptr->ServerSocket )
      #endif
      LIC_Debug( "\\Forced Disconnect" )

   Case SC_F9
      BSave "LIC SS " & Date & ".bmp", 0
      debug_gui( "Screenshot Saved" )

   #endif
   
   case SC_B, SC_C, SC_F
      if MultiKey( SC_CONTROL ) then
         if ScanCode = SC_F then
            ChatInput &= Chr(15)
         elseif ScanCode = SC_C then
            if ChatInput.SelectionLength > 0 then
               'let Copy Function take it
               goto ScanCodeElse
            else
               ChatInput &= Chr(3)
            EndIf
         else
            ChatInput &= Chr(2)
         EndIf
      else
         goto ScanCodeElse
      EndIf

#if LIC_FREETYPE

   case SC_PLUS, SC_MINUS 'Resize font for chat window
      Global_IRC.Global_Options.ChatBoxFontSize += iif( scanCode = SC_PLUS, 1, -1 )
      Notice_Gui( "Font Size Changed: " & Global_IRC.Global_Options.ChatBoxFontSize, Global_IRC.Global_Options.ServerMessageColour )
      if Global_IRC.Global_Options.FontRender = FreeType then
      
         with Global_IRC.TextInfo

         dim as integer freetype_cleanup = 0
         if font.ttf_init() <> font.no_error then
            LIC_DEBUG( "\\FreeType error on init:" & font.geterror( ) )
            freetype_cleanup = 1
         elseif .FT_C.Load_TTFont( Global_IRC.Global_Options.ChatBoxFont, Global_IRC.Global_Options.ChatBoxFontSize, 32, 126 ) <> font.no_error then
            LIC_DEBUG( "\\FreeType error in ChatBoxFont:" & font.geterror( ) )
            freetype_cleanup = 1
         end if

         if freetype_cleanup then
            .FT_C.Destructor( )
            .FT_U.Destructor( )
            Global_IRC.Global_Options.FontRender = fbgfx
         end if

         end with
         
         Global_IRC.TextInfo.GetSizes( )
         LIC_ResizeAllRooms( 1 )
         font.ttf_deinit()

      endif

#endif

   Case Else
ScanCodeElse:

      ChatInput.Parse( scanCode )
      Function = FALSE

End Select

End Function

#if __FB_DEBUG__
Sub TestInput( )

   'FIXME!!!
   'Need a sub that will test fuzzing / every possible input for bugs

End Sub
#endif
