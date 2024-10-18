#include once "lic.bi"
#Include Once "lic-server.bi"
#Include Once "lic-numeric.bi"
#Include Once "crt/time.bi"

sub Server_Type.Parse_RPL( byref imsg as irc_message )

static as integer TempInt

Select Case valInt( imsg.Command )

   Case /' Do nothings '/ RPL_ENDOFMOTD, RPL_ENDOFWHO, RPL_ENDOFWHOIS, RPL_ENDOFWHOWAS, RPL_ENDOFBANLIST, RPL_ENDOFLINKS
   case RPL_WELCOME
':holmes.freenode.net 001 LukeL :Welcome to the freenode IRC Network LukeL

      If Global_IRC.Global_Options.ShowServerWelcome <> 0 then
         Lobby->AddLOT( "<Welcome>: " & *imsg.Param( imsg.ParamCount ), Global_IRC.Global_Options.ServerMessageColour, 0 )
      endif
      CurrentNick = *imsg.Param(0)
      UCurrentNick = Ucase_( CurrentNick )
      ReconnectTime = 0
      ExternalIP = 0
      if ServerOptions.TwitchHacks <> 0 then
         SendLine( "CAP REQ :twitch.tv/commands", TRUE )
         SendLine( "CAP REQ :twitch.tv/tags", TRUE )
      else
         SendLine( "USERHOST " + CurrentNick, TRUE )
      end if
      If ( Len( ServerOptions.AutoPass ) > 0 ) And ( UCase_( ServerOptions.NickName ) = UCurrentNick ) Then
         SendLine( "PRIVMSG " + ServerOptions.IdentifyService + " :IDENTIFY " + ServerOptions.AutoPass )
      EndIf
      If Len( ServerOptions.AutoJoin ) Then
         Dim As Integer i = 1, NextSpace = any
         Dim As event_type Join_event, Join_event_timeout

         var Join = !"\nJOIN "
         Join_event._string = Join

         Do
            NextSpace = InStrAsm( i, ServerOptions.AutoJoin, Asc(" ") )
            var Channel = Mid( ServerOptions.AutoJoin, i, NextSpace - i )
            var CIT = ServerOptions.ChanInfo
            var LastN = InStrRev( Join_event._string, !"\n" )
            i = NextSpace + 1
            if ( len_hack( Join_event._string ) - LastN ) > 400 then
               Join_event._string += Join
            EndIf
            While CIT <> 0
               if ( InStr( CIT->ChanNames, ucase( Channel + " " ) ) > 0 ) and ( len_hack( CIT->Key ) > 0 ) then
                  if InStrASM( LastN + 1, Join_event._string, asc(",") ) > 0 then
                     Join_event._string += Join
                  EndIf
                  Join_event._string += Channel + " " + CIT->Key + Join
                  Continue Do
               EndIf
               CIT = CIT->next_ptr
            Wend
            Join_event._string += Channel & ","
         Loop Until i = 1
         Join_event._string = LTrim( RTrim( Join_event._string, "," ), !"\n" )

         If Len( ServerOptions.AutoPass ) Then
            Join_event._integer = IRC_NOTICE
            Join_Event._ptr = StrPtr( ServerOptions.IdentifyService )
            Join_Event.Param(1) = "identified"
            If ( Global_IRC.Global_Options.AutoGhost <> 0 ) And ( UCurrentNick <> Ucase_( ServerOptions.NickName ) ) Then
               Join_event_timeout.When = Timer + 9
            Else
               Join_event_timeout.When = Timer + 7
            endif
         Else
            Join_event_timeout.When = Timer
            Join_event._Integer = 002
         EndIf

         Join_event.when = 1
         Join_event.id = Server_Input

         Event_handler.Add( @Join_event )

         Join_event_timeout.Unique_ID = Join_Event.Unique_ID
         Join_event_timeout._ptr = @this
         Join_Event_Timeout.Id = Timeout_Server

         Global_IRC.Event_Handler.Add( @Join_event_timeout )

      EndIf
   case RPL_YOURHOST, RPL_CREATED
':holmes.freenode.net 002 LukeL :Your host is holmes.freenode.net[shakermaker.preshweb.co.uk/6667], running version hyperion-1.0.2b
':holmes.freenode.net 003 LukeL :This server was created Fri Mar  6 12:03:17 UTC 2009

      If Global_IRC.Global_Options.ShowServerWelcome <> 0 then
         Lobby->AddLOT( "<Welcome>: " & *imsg.Param( imsg.ParamCount ), Global_IRC.Global_Options.ServerMessageColour, 0 )
      endif

   Case RPL_MYINFO
':zelazny.freenode.net 004 LukeL zelazny.freenode.net hyperion-1.0.2b aAbBcCdDeEfFGhHiIjkKlLmMnNopPQrRsStTuUvVwWxXyYzZ01234569*@ bcdefFhiIklmnoPqstv

      ServerName = *imsg.Param( 1 )
      Lobby->RoomName = ServerName
      Global_IRC.DrawTabs( )

   Case Numeric.RPL_ISUPPORT
':farmer.freenode.net 005 LukeL CHANTYPES=# EXCEPTS INVEX CHANMODES=eIbq,k,flj,CFLMPQScgimnprstz CHANLIMIT=#:120 PREFIX=(ov)@+ MAXLIST=bqeI:100 MODES=4 NETWORK=freenode KNOCK STATUSMSG=@+ CALLERID=g :are supported by this server
':farmer.freenode.net 005 LukeL SAFELIST ELIST=U CASEMAPPING=rfc1459 CHARSET=ascii NICKLEN=16 CHANNELLEN=50 TOPICLEN=390 ETRACE CPRIVMSG CNOTICE DEAF=D MONITOR=100 :are supported by this server
':farmer.freenode.net 005 LukeL FNC TARGMAX=NAMES:1,LIST:1,KICK:1,WHOIS:1,PRIVMSG:4,NOTICE:4,ACCEPT:,MONITOR: EXTBAN=$,arx WHOX CLIENTVER=3.0 :are supported by this server

      /'
      The ISUPPORT protocol

      CMap        Case mapping when comparing upper/lower case nicks & channels
      IPrefix     Internal prefix ( o v etc )
      VPrefix     Visible prefix ( @ + etc )
      CHANTYPES  	Channel prefixes ( #&!+ etc )
      CHANMODES   All server MODES, which use a param, which don't
      NICKLEN     Maximum nick length
      MODES       Maximum modesets per line
      '/
      Dim As String LHS, RHS

      LHS = mid( imsg.raw, imsg.ParamOffset + len_hack( CurrentNick ) + 2 )
      LHS = "<Supported>: " + left( LHS, len_hack( imsg.Parameters ) - len_hack( CurrentNick ) - 1 )
      Lobby->AddLOT( LHS, Global_IRC.Global_Options.ServerMessageColour )

      For j As Integer = 1 To imsg.ParamCount - 1

         RHS = *imsg.Param( j ) 'Temp String
         TempInt = InStrASM( 1, RHS, Asc("=") )
         If TempInt > 0 Then
            LHS = UCase( Left( RHS, TempInt - 1 ) )
            RHS = Mid( RHS, TempInt + 1 )
         Else
            LHS = UCase( RHS )
         EndIf

         Select Case LHS

            Case "NICKLEN"
               ServerInfo.Flags Or= S_INFO_FLAG_NICKLEN
               ServerInfo.NickLen = ValInt( RHS )

            Case "CASEMAPPING"
               ServerInfo.Flags Or= S_INFO_FLAG_CASEMAPPING
               Select Case LCase( RHS )
                  Case "ascii": ServerInfo.CMap = ASCII
                  Case "strict-rfc1459": ServerInfo.CMap = STRICT_RFC1459
                  Case Else: ServerInfo.CMap = RFC1459
               End Select
               UCurrentNick = Ucase_( CurrentNick )

            Case "PREFIX"
               'PREFIX=(ov)@+
               ServerInfo.Flags Or= S_INFO_FLAG_PREFIX
               Dim As Integer icount, vcount
               TempInt = 0
               For i As Integer = 0 To Len_Hack( RHS ) - 1
                  If RHS[i] = Asc( "(" ) Then
                     Continue For
                  elseIf RHS[i] = Asc( ")" ) Then
                     TempInt = 1
                     icount = 0
                     Continue For
                  EndIf
                  if ( icount > ubound( ServerInfo.IPrefix ) ) or ( vcount > ubound( ServerInfo.VPrefix ) ) then
                     continue for
                  EndIf
                  If TempInt = 0 Then
                     ServerInfo.IPrefix( icount ) = RHS[i]
                     icount += 1
                  Else
                     ServerInfo.VPrefix( vcount ) = RHS[i]
                     vcount += 1
                  EndIf
               Next

            Case "CHANMODES"
               ServerInfo.Flags Or= S_INFO_FLAG_CHANMODES
               Dim As Integer start = 1
               For i As Integer = 0 To 3
                  TempInt = InStrASM( start, RHS, Asc(",") )
                  ServerInfo.CHANMODES( i ) = Mid( RHS, start, TempInt - Start )
                  start = TempInt + 1
               Next

            Case "CHANTYPES"
               ServerInfo.Flags Or= S_INFO_FLAG_CHANTYPES
               Dim As Integer ub = UBound( ServerInfo.CHANTYPES )
               For i As Integer = 0 To ub
                  ServerInfo.CHANTYPES( i ) = 0
               Next
               TempInt = IIf( Len_Hack( RHS ) - 1 > ub, ub, Len_Hack( RHS ) - 1 )
               For i As Integer = 0 To TempInt
                  ServerInfo.CHANTYPES( i ) = RHS[i]
               Next

            case "KNOCK"
               ServerInfo.Flags Or= S_INFO_FLAG_KNOCK

            case "MODES"
               ServerInfo.Modes = valint( RHS )

            case "NETWORK"
               LoadNumerics( RHS )

         End Select

      Next

   Case RPL_STATSCONN To RPL_LUSERME,  RPL_LOCALUSERS, RPL_GLOBALUSERS
':brown.freenode.net 266 LukeL :Current global users: 43824  Max: 45360
':heinlein.freenode.net 252 LukeIRC 36 :flagged staff members

      If Global_IRC.Global_Options.ShowServerUsers <> 0 Then
         Dim As ZString Ptr Z = @imsg.raw[ imsg.ParamOffset + Len( *imsg.Param(0) ) + 1 ]
         If imsg.ParamCount = 1 Then Z += 1
         Lobby->AddLOT( "<Users>: " & *Z, Global_IRC.Global_Options.ServerMessageColour )
      EndIf

   Case RPL_AWAY
      imsg.URT->AddLOT( "** NOTICE: " & *imsg.Param(1) & " is marked as away: " & *imsg.Param( imsg.ParamCount ), Global_IRC.Global_Options.ServerMessageColour, , , , , TRUE )

   case RPL_UMODEIS
':xs4all.nl.quakenet.org 221 jim405 +i

      Lobby->AddLOT( "** " & ServerName & " sets your user MODE " & *imsg.Param(1), Global_IRC.Global_Options.ServerMessageColour, , , , , TRUE )

   case RPL_USERHOST
':holmes.freenode.net 302 LukeL :LukeL=+n=Luke@255.255.255.255

      var msg = *imsg.Param( imsg.ParamCount )
      
      If ( ExternalIP = 0 ) And ( StringEqualASM( Ucase_( *imsg.Param( 0 ) ), UCurrentNick ) ) Then
         'Auto generated         
         if len( msg ) then
            TempInt = InStrRev( msg, "@" )
            ExternalIP = chi.resolve( mid( msg, TempInt + 1 ) )
            if ExternalIP = chi.NOT_AN_IP then ExternalIP = 0
         end if
      Else
         imsg.URT->AddLOT( "** USERHOST " & msg, Global_IRC.Global_Options.ServerMessageColour, , , , , TRUE )
      endif

   Case RPL_UNAWAY, RPL_NOWAWAY
      imsg.URT->AddLOT( "** NOTICE: " & *imsg.Param( imsg.ParamCount ), Global_IRC.Global_Options.ServerMessageColour )

   Case RPL_WHOISUSER
':adams.freenode.net 311 LukeL LukeL unknown unaffiliated/lukel * :Luke
      
      Global_IRC.CurrentRoom->AddLOT( _ 
         "** WHOIS " & *imsg.Param(1) & " ** ident:" & *imsg.Param(2) & " hostmask:" & *imsg.Param(3) & " realname:" & *imsg.Param(imsg.ParamCount), _
         Global_IRC.Global_Options.ServerMessageColour _
      )
      
   case RPL_WHOISSERVER
':card.freenode.net 312 LukeLC LukeL irc.freenode.net :http://freenode.net/
      
      Global_IRC.CurrentRoom->AddLOT( "** WHOIS " & *imsg.Param(1) & " ** using server:" & *imsg.Param(2) & " - " & *imsg.Param(imsg.ParamCount), Global_IRC.Global_Options.ServerMessageColour )
      
   case RPL_WHOISOPERATOR, RPL_WHOISCHANNELS, RPL_WHOISSPECIAL, RPL_WHOISACTUALLY
':card.freenode.net 319 LukeLC LukeL :#ubuntu
':card.freenode.net 320 LukeLC LukeL :is identified to services
':irc.mzima.net 338 LukeLC user xx.180.83.xxx :actually using host

      Dim As ZString Ptr Z = @imsg.raw[ imsg.ParamOffset + len_hack( CurrentNick ) + Len( *imsg.Param(1) ) + 2 ]
      If imsg.ParamCount = 2 Then Z += 1
      Global_IRC.CurrentRoom->AddLOT( "** WHOIS " & *imsg.Param(1) & " ** " & *Z, Global_IRC.Global_Options.ServerMessageColour )

   case RPL_WHOISLOGGEDIN
':card.freenode.net 330 LukeLC LukeL LukeL :is logged in as

      Global_IRC.CurrentRoom->AddLOT( "** WHOIS " & *imsg.Param(1) & " ** " & *imsg.Param(3) & " " & *imsg.Param(2), Global_IRC.Global_Options.ServerMessageColour )

   Case RPL_WHOISIDLE
':holmes.freenode.net 317 LukeL Mysoft 16 1261725510 :seconds idle, signon time

      Dim As String S = "** WHOIS " & *imsg.Param(1) & " ** Idle for: "
      TempInt = valint( *imsg.Param( 2 ) )
      S &= CalcTime( TempInt )
      if imsg.ParamCount >= 4 then
         TempInt = valint( *imsg.Param( 3 ) )
         RTrim2( S )
         S &= ", Sign on time: " & RTrim( *ctime( CPtr( time_t Ptr, @TempInt ) ), Any NewLine )
      EndIf

      Global_IRC.CurrentRoom->AddLOT( S, Global_IRC.Global_Options.ServerMessageColour )
   
   case RPL_WHOISHOST, RPL_WHOISSECURE
':adams.freenode.net 378 LukeL LukeL :is connecting from *@CPEbcbe7c-CM185937.cpe.net.cable.rogers.com 99.242.140.73
':adams.freenode.net 671 LukeL LukeL :is using a secure connection
      Global_IRC.CurrentRoom->AddLOT( "** WHOIS " & *imsg.Param(1) & " ** " & *imsg.Param(2), Global_IRC.Global_Options.ServerMessageColour )

   case RPL_LISTSTART
':lindbohm.freenode.net 321 LukeL Channel :Users  Name

      if ListRoom <> 0 then DelRoom( ListRoom )
      ListRoom = AddRoom( "List", RoomTypes.List )
      ListStatus = ListSending

   Case RPL_LIST
':lindbohm.freenode.net 322 LukeL #ubuntu 1479 :Official Ubuntu Support Channel
      '<channel> <users> :<topic>

      if (ListRoom = 0) and (ListStatus <> ListCancelled) then
         ListRoom = AddRoom( "List", RoomTypes.List )
      elseif (ListStatus = ListCancelled) then
         exit sub
      EndIf

      CharKill( imsg.msg )
      ListRoom->AddUser( *imsg.Param(1) & " [" & ValInt( *imsg.Param(2) ) & "]: " & imsg.msg, Global_IRC.Global_Options.ServerMessageColour )

   case RPL_LISTEND
':lindbohm.freenode.net 323 LukeL :End of /LIST

      if ListRoom <> 0 then
         Global_IRC.SwitchRoom( ListRoom )

         if ListRoom->NumUsers = 0 then
            Notice_GUI( "** Server returned 0 visible channels", Global_IRC.Global_Options.ServerMessageColour )

         elseif ListRoom->NumUsers = 1 then

            var UNT = ListRoom->FirstUser

            var s = InStrASM( 1, UNT->UserName, asc(" ") )
            var s2 = InStrASM( s + 1, UNT->UserName, asc("]") )

            dim as LOT_MultiColour_Descriptor MCD = ( s + 4, s2 - s, Global_IRC.Global_Options.JoinColour )

            ListRoom->AddLOT( "** " & UNT->UserName, Global_IRC.Global_Options.TextColour, , Notification, , @MCD, TRUE )

         endif
      EndIf
      ListStatus = ListFinished

   case RPL_LOAD2HI
':niven.freenode.net 263 LukeL LIST :Server load is temporarily too heavy. Please wait a while and try again.

      imsg.URT->AddLOT( "** " & *imsg.Param( imsg.ParamCount ) & " [ " & *imsg.Param(1) & " ]", Global_IRC.Global_Options.ServerMessageColour, , , , , TRUE )

   Case RPL_CHANNELMODEIS
':verne.freenode.net 324 LukeL #LukeL +tnc

      imsg.URT->AddLOT( "** " & *imsg.Param(1) & " channel modes: " & *imsg.Param(2), Global_IRC.Global_Options.ServerMessageColour )

   Case RPL_CHANNELURL
':holmes.freenode.net 328 LukeL ##freebasic :http://freebasic.net/

      imsg.URT->AddLOT( "Channel Website: " & *imsg.Param( imsg.ParamCount ), Global_IRC.Global_Options.JoinColour )

   Case RPL_CREATIONTIME
':holmes.freenode.net 333 LukeL ##FreeBASIC cha0s 1253221658

      var URT = Find( imsg.Param(1) )

      if URT = 0 then
         URT = Global_IRC.CurrentRoom
      EndIf

      imsg.msg = *imsg.Param(1) & " was created"

      if imsg.ParamCount > 2 then
         imsg.msg += " by " & *imsg.Param(2)
         TempInt = valInt( *imsg.Param(3) )
      else
         TempInt = valInt( *imsg.Param(2) )
      EndIf

      imsg.msg += " on " & RTrim( *ctime( CPtr( time_t Ptr, @TempInt ) ), Any NewLine )

      URT->AddLOT( imsg.msg, Global_IRC.Global_Options.ServerMessageColour )

   Case RPL_TOPIC
':card.freenode.net 332 LukeL #ubuntu :Official Ubuntu Support Channel

      CharKill( imsg.msg )

      var URT = Find( imsg.Param(1) )

      if URT = 0 then
         Global_IRC.CurrentRoom->AddLOT( *imsg.Param(1) & " Channel Topic: " & imsg.msg, Global_IRC.Global_Options.JoinColour )
      else
         URT->AddLOT( "Channel Topic: " & imsg.msg, Global_IRC.Global_Options.JoinColour )
         swap URT->Topic, imsg.msg
      EndIf

   Case RPL_TOPICWHOTIME
':kubrick.freenode.net 333 LukeLC #ubuntu LjL 1202394365

      TempInt = valInt( *imsg.Param(3) )
      imsg.msg = "Topic set by " & *imsg.Param(2) & " on " & RTrim( *ctime( CPtr( time_t Ptr, @TempInt ) ), Any NewLine )      
      
      imsg.URT = Find( imsg.Param(1) )
      if imsg.URT = 0 then
         imsg.URT = iif( Global_IRC.CurrentRoom->Server_Ptr = @this, Global_IRC.CurrentRoom, Lobby )
         imsg.msg = *imsg.Param(1) & " " & imsg.msg
      EndIf

      imsg.URT->AddLot( imsg.msg, Global_IRC.Global_Options.JoinColour )

   Case RPL_INVITING
':zelazny.freenode.net 341 LukeL LukeL_ #LIC

      imsg.URT->AddLOT( "** " & *imsg.Param(0) & " has invited " & *imsg.Param(1) & " to join " & *imsg.Param(2), Global_IRC.Global_Options.ServerMessageColour )

   case RPL_VERSION
':zelazny.freenode.net 351 LukeL ircd-seven-1.0.1(20100130-d3139a423e1f, Charybdis 3.2-dev). zelazny.freenode.net :eHIKMpSZ6 TS6ow 15S

      imsg.URT->AddLOT( "<Version>:" & mid( imsg.raw, imsg.ParamOffset + len_hack( CurrentNick ) + 1 ), Global_IRC.Global_Options.ServerMessageColour )

   Case RPL_WHOREPLY
':kornbluth.freenode.net 352 LukeL #channel ~ident hostname server.freenode.net Nick H@ :0 Real Name

      imsg.msg = "** WHO **" & *( @imsg.raw[ imsg.ParamOffset + len_hack( CurrentNick ) ] )
      imsg.URT->AddLOT( imsg.msg, Global_IRC.Global_Options.ServerMessageColour )

   Case RPL_NAMREPLY
':calvino.freenode.net 353 LukeL = ##c :user1 user2

      If (imsg.URT->pflags AND pChanFlags.synced) = 0 Then
         Dim As Integer i, s

         if (imsg.URT->pflags AND pChanFlags.FakeUsers) = 0 then
            Do
               Select Case imsg.Param( imsg.ParamCount )[0][i]
                  Case asc(" ")
                     imsg.Param( imsg.ParamCount )[0][i] = 0
                     imsg.URT->AddUser( @( imsg.Param( imsg.ParamCount )[s] ) )
                     s = i + 1
                  Case 0
                     If imsg.Param( imsg.ParamCount )[0][i-1] <> 0 Then
                        imsg.URT->AddUser( @( imsg.Param( imsg.ParamCount )[s] ) )
                     EndIf
                     Exit Do
               End Select
               i += 1
            Loop
         else

            dim as username_type ptr UNT
            dim as integer ub = ubound( ServerInfo.VPrefix )
            dim as ubyte ptr vprefix = @( ServerInfo.VPrefix(0) )
            dim as zstring ptr Username

            if imsg.URT->OldUsers = 0 then
               imsg.URT->pflags OR= UsersLock
               imsg.URT->OldUsers = allocate( ( imsg.URT->NumUsers + 1 ) * sizeof( any ptr ) )
               UNT = imsg.URT->FirstUser
               for i = 0 to imsg.URT->NumUsers - 1
                  imsg.URT->OldUsers[ i ] = UNT
                  UNT = UNT->NextUser
               next
               'null terminator
               imsg.URT->OldUsers[ i ] = 0
            end if

            i = 0
            do
               Select Case imsg.Param( imsg.ParamCount )[0][i]
                  Case asc(" ")
                     imsg.Param( imsg.ParamCount )[0][i] = 0
                     Username = @( imsg.Param( imsg.ParamCount )[s] )
                     s = i + 1
                  Case 0
                     If imsg.Param( imsg.ParamCount )[0][i-1] <> 0 Then
                        Username = @( imsg.Param( imsg.ParamCount )[s] )
                     else
                        Username = 0
                     End If
                     s = -1
                  case else
                     Username = 0
               End Select

               if Username <> 0 then
                  dim as integer c, hit, privcount
                  do until ( Username[0][c] = 0 ) or ( hit = 1 )
                     hit = 1
                     For j As Integer = 0 To ub
                        If Username[0][c] = vprefix[j] Then
                           hit = 0
                           PrivCount += 1
                           exit for
                        EndIf
                     Next
                     c += 1
                  loop
                  UNT = imsg.URT->Find( *( Username + PrivCount ) )
                  if UNT then
                     imsg.URT->AddUser( Username, UNT->ChatColour )
                  else
                     imsg.URT->AddUser( Username, 0 )
                  EndIf
                  
               end if

               i += 1
            Loop until s = -1

         end if

      Else
         notice_gui( "** [ " & *imsg.Param( imsg.ParamCount - 1 ) & " ] : " & *imsg.Param( imsg.ParamCount ), Global_IRC.Global_Options.ServerMessageColour )
      endif

   Case RPL_ENDOFNAMES
':kubrick.freenode.net 366 LukeL #ubuntu :End of /NAMES list.

      if ( (imsg.URT->pflags AND pChanFlags.FakeUsers) <> 0 ) and ( imsg.URT->OldUsers <> 0 ) then
         dim i as integer
         do until imsg.URT->OldUsers[ i ] = 0
            imsg.URT->DelUser( imsg.URT->OldUsers[ i ] )
            i += 1
         loop

         deallocate( imsg.URT->OldUsers )
         imsg.URT->OldUsers = 0
         imsg.URT->pflags AND= NOT( pChanFlags.FakeUsers )

      end if

      If (imsg.URT->pflags AND pChanFlags.synced) = 0 Then

         imsg.URT->pflags OR= pChanFlags.synced

         'If imsg.URT->UsersLock <> 0 Then
            imsg.URT->TopDisplayedUser = imsg.URT->FirstUser
         'End If

         var UNT = imsg.URT->Find( CurrentNick )
         if UNT <> 0 then
            UNT->ChatColour = Global_IRC.Global_Options.YourChatColour
         EndIf

         'Global_IRC.SwitchRoom( imsg.URT )
         imsg.URT->pflags AND= NOT( UsersLock )
         'imsg.URT->UserScrollBarY = 0

         if imsg.URT = Global_IRC.CurrentRoom then
            Global_IRC.SwitchRoom( imsg.URT )
            imsg.URT->UpdateUserListScroll( -123456 )
         end if

      Else
         notice_gui( "** [ " & *imsg.Param(1) & " ] : " & *imsg.Param( imsg.ParamCount ), Global_IRC.Global_Options.ServerMessageColour )
      end if

   Case RPL_BANLIST
':wolfe.freenode.net 367 LukeL #codename4 ljrbot!*@* sagan.freenode.net 1226577305

      TempInt = valInt( *imsg.Param( imsg.ParamCount ) )
      Var T = RTrim( *ctime( Cptr( time_t ptr, @TempInt ) ), Any NewLine )

      imsg.URT->AddLOT( "** " & *imsg.Param(1) & " Ban List: " & *imsg.Param(2) & " set by " & *imsg.Param(3) & " on " & T, Global_IRC.Global_Options.ServerMessageColour )

   Case RPL_MOTDSTART, RPL_MOTD
':card.freenode.net 372 LukeL :- information.  Thank you for using freenode!

      If Global_IRC.Global_Options.ShowMOTD <> 0 Then
         Lobby->AddLOT( "<MOTD>: " & *imsg.Param( imsg.ParamCount ), Global_IRC.Global_Options.ServerMessageColour )
      EndIf

   case RPL_TIME
':verne.freenode.net 391 LukeL verne.freenode.net :Tuesday January 5 2010 -- 15:48:17 -05:00

      imsg.URT->AddLOT( "** " & *imsg.Param( 1 ) & " time: " & *imsg.Param( imsg.ParamCount ), Global_IRC.Global_Options.ServerMessageColour )

   case RPL_YOUREOPER
':Lukenet 381 LukeL :You are now an IRC Operator

      imsg.URT->AddLOT( "** [ " & ServerName & " ]: " & *imsg.Param( imsg.ParamCount ), Global_IRC.Global_Options.ServerMessageColour )

   case RPL_HOSTHIDDEN
':bartol.freenode.net 396 LukeL_ unaffiliated/lukel :is now your hidden host (set by services.)

      imsg.URT->AddLOT( "** " & *imsg.Param( 1 ) & " " & *imsg.Param( imsg.ParamCount ), Global_IRC.Global_Options.ServerMessageColour )

   Case ERR_NICKNAMEINUSE
':kubrick.freenode.net 433 * LukeL :Nickname is already in use.

      dim as string NewNick

      If ( Ucase_( *imsg.Param(0) ) <> UCurrentNick ) Or ( len_hack( CurrentNick ) = 0 ) Then
         If ( Global_IRC.Global_Options.AutoGhost <> 0 ) And ( Len( ServerOptions.AutoPass ) > 0 ) Then

            NewNick = space( ServerInfo.NICKLEN )
            For i As Integer = 0 To len_hack( NewNick ) - 1
               NewNick[i] = Fix( Rnd * 26 ) + 65
            Next

            imsg.URT->AddLOT( "** Auto Ghosting " & ServerOptions.NickName, Global_IRC.Global_Options.ServerMessageColour, , , , , TRUE )

            SendLine( "NICK " & NewNick )
            SendLine( "PRIVMSG " & ServerOptions.IdentifyService & " :GHOST " & ServerOptions.NickName & " " & ServerOptions.AutoPass )

            Dim As event_Type et
            et.id = Server_Output
            et._string = "NICK " & ServerOptions.NickName
            et.when = 1
            et._integer = IRC_NOTICE
            et.Param(1) = "GHOST"
            et._ptr = StrPtr( ServerOptions.IdentifyService )
            Event_Handler.Add( @et )
            et._string = "PRIVMSG " & ServerOptions.IdentifyService & " :IDENTIFY " & ServerOptions.AutoPass
            Event_Handler.Add( @et )

         Else

            NewNick = *imsg.Param(1)

            If ( Len( NewNick ) < ServerInfo.NickLen ) then
               NewNick += "_"
            ElseIf Len( ServerOptions.NickName ) >= ServerInfo.NickLen Then
               TempInt = Len( RTrim( NewNick, "_" ) )
               If TempInt = 0 Then
                  NewNick = ServerOptions.NickName
               Else
                  NewNick = Left( NewNick, TempInt - 1 ) + "_" + Mid( NewNick, TempInt + 1 )
               EndIf
            Else
               NewNick = ServerOptions.NickName
            EndIf

            imsg.URT->AddLOT( "** NOTICE: " & *imsg.Param(1) & " is already in use. Trying auto-gen nick " & NewNick, Global_IRC.Global_Options.ServerMessageColour, , , , , TRUE )

            SendLine( "NICK " & NewNick )

         EndIf
      Else
         if @this = Global_IRC.CurrentRoom->Server_Ptr then
            imsg.URT = Global_IRC.CurrentRoom
         else
            imsg.URT = Lobby
         EndIf
         imsg.URT->AddLOT( "** ERROR: " & *imsg.Param( imsg.ParamCount ), Global_IRC.Global_Options.ServerMessageColour )
      EndIf

   Case ERR_LINKCHANNEL
':leguin.freenode.net 470 LukeL #freebasic ##freebasic :Forwarding to another channel

      imsg.URT->AddLOT( "** NOTICE: " & *imsg.Param(1) & ": " & *imsg.Param( imsg.ParamCount ) & ": " & *imsg.Param(2), Global_IRC.Global_Options.ServerMessageColour )
      var CIT = ServerOptions.ChanInfo
      while CIT <> 0
         if CIT->ChanNames = ucase( *imsg.Param(1) ) then
            CIT->ChanNames = ucase( *imsg.Param(2) )
         EndIf
         CIT = CIT->next_ptr
      Wend

   Case 400 to 599 'Various Errors
':calvino.freenode.net 480 LukeL #perl :Cannot join channel (throttled)

      var msg = "** ERROR:"

      for i as integer = 0 to imsg.ParamCount
         msg += " " + *imsg.Param( i )
      Next

      imsg.URT->AddLOT( msg, Global_IRC.Global_Options.ServerMessageColour )
      If ( (imsg.URT->pflags AND FlashingTab) = 0 ) And ( imsg.URT <> Global_IRC.CurrentRoom ) Then
         imsg.URT->pflags OR= FlashingTab
         If ( Global_IRC.WindowActive or Global_IRC.Global_Options.ShowInactive ) <> 0 Then
            Global_IRC.DrawTabs( )
         EndIf
      EndIf

      Select Case valInt( imsg.Command )

         case ERR_BANNEDFROMCHAN
':calvino.freenode.net 474 LukeL___ #LukeL :Cannot join channel (+b)

            If ( Global_IRC.Global_Options.AutoRejoinOnBan > 0 ) And ( Ucase_( imsg.URT->RoomName ) = Ucase_( *imsg.Param(1) ) ) Then
               Dim As event_type e
               e.when = Timer + Global_IRC.Global_Options.AutoRejoinOnBan
               e.id = Server_Output
               e._ptr = @this
               e._string = "JOIN " & *imsg.Param(1)
               Global_IRC.Event_Handler.Add( @e )
            EndIf

         case ERR_INVITEONLYCHAN
':leguin.freenode.net 473 LukeL #codename4 :You need to be invited to that channel

            'if ( ServerInfo.Flags and S_INFO_FLAG_KNOCK ) <> 0 then
            '   msg = "** [ Server KNOCK is enabled, use /knock " + *imsg.Param(1) + " to ask the ops for an invite ]"
            '   imsg.URT->AddLOT( msg, Global_IRC.Global_Options.TextColour, , , , , TRUE )
            'EndIf

      End Select

   Case Numeric.RPL_LOGGEDIN
':zelazny.freenode.net 901 LukeL LukeL n=Luke unaffiliated/lukel :You are now logged in. (id LukeL, username n=Luke, hostname unaffiliated/lukel)

      Lobby->AddLOT( "** " + *imsg.Param( imsg.ParamCount ), Global_IRC.Global_Options.ServerMessageColour )

   case else
':irc.mzima.net 711 LukeL #channel :Your KNOCK has been delivered.
      
      var msg = "** [" + imsg.Command + "] " + ServerName + " :" & imsg.MessageTag
      for i as integer = 0 to imsg.ParamCount
         msg += " " + *imsg.Param( i )
      Next

      if Global_IRC.CurrentRoom->Server_Ptr = @this then
         imsg.URT = Global_IRC.CurrentRoom
      else
         imsg.URT = Lobby
      EndIf

      #if __FB_DEBUG__
         imsg.URT->AddLOT( msg, Global_IRC.Global_Options.DebugColour )
         if valint( imsg.Command ) = 0 then
            LIC_DEBUG( "\\ERROR:Unknown message[" & ServerNum & "]:" & imsg.MessageTag & " " & imsg.raw & "\\" )
         end if
      #else
         imsg.URT->AddLOT( msg, Global_IRC.Global_Options.ServerMessageColour )
      #endif

End Select


End Sub
