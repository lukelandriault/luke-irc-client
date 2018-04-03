#if __LIC__
   #include once "lic.bi"
   Extern ChatInput As FBGFX_CHARACTER_INPUT
#else
   #Include Once "lic-options.bi"
#endif

#define _BOOL(B) abs( ValInt( B ) <> 0 )

Declare Sub Options_Sub_ChanInfo( byref CI as ChanInfo_Type ptr )

Extern As String Options_File
Dim As String Options_File
Options_File = IRC_Options_File

Dim shared as long ff
dim shared as string tmp_opts

Function IRC_Options_Type.Set_Value( byref lhs as string, byref rhs as string ) as integer

   var ret = TRUE

   '' Strings
   Select Case lhs
      Case "QUITMESSAGE"
         QuitMessage = rhs
      Case "BROWSERPATH"
         BrowserPath = rhs
      Case "CTCPVERSION"
         CTCP_Version = rhs
      Case "CHATBOXFONT"
         ChatBoxFont = rhs
      Case "USERLISTFONT"
         UserListFont = rhs
      Case "NOTIFYSOUND"
         NotifySound = rhs
      case "IDENTUSER"
         IdentUser = rhs
      case "IDENTSYSTEM"
         IdentSystem = rhs
      case "TIMESTAMPFORMAT"
         TimeStampFormat = rhs
      case "KBLAYOUT"
         select case ucase( rhs )
         case "FRENCH"
            ChatInput.KeyboardLayout = KB_French
         End Select
      case "FONTRENDER"

         select case ucase( rhs )
         case "FREETYPE"
            FontRender = FreeType
         #ifndef __FB_LINUX__
         case "WINAPI"
            FontRender = WinAPI
         #endif
         case else
            FontRender = fbgfx

         end select
      case "SCREENDRIVER"
         
         select case ucase( rhs )
         case "DIRECTX"
            ScreenDriver = DirectX
         case "OPENGL"
            ScreenDriver = OpenGL
         case else
            ScreenDriver = GDI
         End Select
         
      case "CHANNEL"
         dim as ChanInfo_Type CIT
         Options_Sub_ChanInfo( @CIT )
         'Discard for now         
      
      case else
         ret = FALSE

   End Select

   if ret = TRUE then Return ret else ret = TRUE

   if ucase( left( rhs, 1 ) ) = "Y" then
      rhs[0] = asc("1")
   EndIf

   select case lhs
      Case "AUTOREJOINONKICK"
         AutoRejoinOnKick = val( rhs )
      Case "MINPERLINE"
         MinPerLine = val( rhs )
      Case "USERLISTFONTSIZE"
         UserListFontSize = valInt( rhs )
      Case "CHATBOXFONTSIZE"
         ChatBoxFontSize = valInt( rhs )
      Case "SCREENRESX"
         ScreenRes_x = valInt( rhs )
      Case "SCREENRESY"
         ScreenRes_y = valInt( rhs )
      Case "MAXBACKLOG"
         MaxBackLog = valInt( rhs )
      Case "USERLISTWIDTH"
         DefaultUserListWidth = valInt( rhs )
   	Case "PINGTIMER"
         PingTimer = valInt( rhs )
      Case "DCCPORT"
         DCC_port = ValUInt( rhs )
      case "IDENTPORT"
         IdentPort = ValUInt( rhs )
      Case "AUTOREJOINONBAN"
         AutoRejoinOnBan = valInt( rhs )
      Case "AUTORECONNECT"
         AutoReconnect = valInt( rhs )
      Case "LOGBUFFERSIZE"
         LogBufferSize = valInt( rhs ) * 1024
      Case "LOGTIMEOUT"
         LogTimeOut = valInt( rhs )
      case "LOGLOADHISTORY"
   		LogLoadHistory = ValInt( rhs )
      case "LOGMAXFILESIZE"
         LogMaxFileSize = ValInt( rhs ) * 1024
      case "LOGMAXFILEACTION"
         select case ucase( rhs )
         case "PRUNE"
            LogMaxFileAction = LogPrune
         case else
            LogMaxFileAction = LogCopy
         End Select

''''  BOOL

      Case "LOGTOFILE"
         LogToFile = _BOOL( rhs )
      Case "LOGMERGEPM"
         LogMergePM = _BOOL( rhs )
   	Case "LOGJOINLEAVE"
         LogJoinLeave = _BOOL( rhs )
      case "LOGLOBBY"
         LogLobby = _BOOL( rhs )
      case "LOGRAW"
         LogRaw = _BOOL( rhs )
      Case "SHOWCTCP"
         ShowCTCP = _BOOL( rhs )
      Case "SHOWMOTD"
         ShowMOTD = _BOOL( rhs )
   	Case "SHOWJOINLEAVE"
         ShowJoinLeave = _BOOL( rhs )
   	Case "SHOWTIMESTAMP"
         ShowTimeStamp = _BOOL( rhs )
   	Case "SHOWSERVERWELCOME"
         ShowServerWelcome = _BOOL( rhs )
   	Case "SHOWSERVERUSERS"
         ShowServerUsers = _BOOL( rhs )
      case "SHOWPRIVS"
         ShowPrivs = _BOOL( rhs )
      case "SHOWRAW"
         ShowRaw = _BOOL( rhs )
      case "SHOWDATECHANGE"
         ShowDateChange = _BOOL( rhs )
   	Case "SORTBYPRIVS"
         SortByPrivs = _BOOL( rhs )
      case "SORTTABBYACTIVITY"
         SortTabBySeen = _BOOL( rhs )
      Case "MINIMIZETOTRAY"
         MinimizeToTray = _BOOL( rhs )
   	Case "SHOWHOSTNAMES"
         ShowHostnames = _BOOL( rhs )
   	Case "HIDETASKBAR"
         HideTaskbar = _BOOL( rhs )
   	Case "AUTOGHOST"
         AutoGhost = _BOOL( rhs )
      case "SHOWINACTIVE"
         ShowInactive = _BOOL( rhs )
      Case "NOTIFYONCHAT"
         NotifyOnChat = _BOOL( rhs )
   	Case "SHOWTOPICUPDATES"
         ShowTopicUpdates = _BOOL( rhs )
      case "IDENTENABLE"
         IdentEnable = _BOOL( rhs )
      case "SMOOTHSCROLL"
         SmoothScroll = _BOOL( rhs )
      case "DCCPASSIVE"
         DCC_Passive = _BOOL( rhs )
      case "DISABLEQUICKCOPY"
         DisableQuickCopy = _BOOL( rhs )
      case "DISABLEEMACCONTROLS"
         if _BOOL( rhs ) then
            ChatInput.OptionFlags or= Disable_EMAC_Controls
         else
            ChatInput.OptionFlags and= NOT( Disable_EMAC_Controls )
         endif
      case "ALWAYSONTOP"
         AlwaysOnTop = _BOOL( rhs )
      case "TIMESTAMPUSECRT"
         TimeStampUseCRT = _BOOL( rhs )
      case "TWITCHKILLEMOTES"
         Global_IRC.CurrentRoom->Server_Ptr->ServerOptions.TwitchKillEmotes = _BOOL( rhs )
         
         
''''  COLOURS
         
      Case "WHISPERCOLOUR"
         WhisperColour = Get_RGB( rhs )
      Case "JOINCOLOUR"
         JoinColour = Get_RGB( rhs )
      Case "LEAVECOLOUR"
         LeaveColour = Get_RGB( rhs )
      Case "SERVERMESSAGECOLOUR"
         ServerMessageColour = Get_RGB( rhs )
      Case "DEBUGCOLOUR"
         DebugColour = Get_RGB( rhs )
      Case "SCROLLBARBACKGROUNDCOLOUR"
         ScrollBarBackgroundColour = Get_RGB( rhs )
      Case "SCROLLBARFOREGROUNDCOLOUR"
         ScrollBarForegroundColour = Get_RGB( rhs )
      Case "LINKCOLOUR"
         LinkColour = Get_RGB( rhs )
      Case "BACKGROUNDCOLOUR"
         BackgroundColour = Get_RGB( rhs )
         Dim As UInt32_t Ptr _c = @(Global_IRC.Global_Options.BackGroundColour)
         If ( CUByte( *_c Shr 16 ) + CUByte( *_c Shr 8 ) + CUByte( *_c ) ) > 378 Then
            Global_IRC.DarkUsers = TRUE
         end if
      Case "YOURCHATCOLOUR"
         YourChatColour = Get_RGB( rhs )
      Case "TEXTCOLOUR"
         TextColour = Get_RGB( rhs )
      Case "TABACTIVECOLOUR"
         TabActiveColour = Get_RGB( rhs )
      Case "TABCOLOUR"
         TabColour = Get_RGB( rhs )
      Case "TABTEXTNOTIFYCOLOUR"
         TabTextNotifyColour = Get_RGB( rhs )
      Case "TABTEXTCOLOUR"
         TabTextColour = Get_RGB( rhs )
      case "TABFLASHCOLOUR"
         TabFlashColour = Get_RGB( rhs )
      Case "HILITECOLOUR"
         HiLiteColour = Get_RGB( rhs )
      case "CHATHISTORYCOLOUR"
         ChatHistoryColour = Get_RGB( rhs )
      case "RAWINPUTCOLOUR"
         RawInputColour = Get_RGB( rhs )
      case "RAWOUTPUTCOLOUR"
         RawOutputColour = Get_RGB( rhs )         

#if __FB_DEBUG__

      case "DISABLESTDOUT"
         DisableSTDOUT = _BOOL( rhs )
      case "LOGDEBUG"
         LogDebug = _BOOL( rhs )
      case "RAWIRC"
         RawIRC = _BOOL( rhs )
         
#endif

      case else
         ret = FALSE

   End Select

   Function = ret

End Function

Sub IRC_Options_Type.Load_Options( ByRef FirstRun As Integer = 0 )

   Dim As String LineInput, lhs, rhs
   Dim As Integer SplitLoc
   Dim As Integer Servers
   dim as Integer BPP
   dim as integer skip

   reDim As Server_Options_Type Server(8)
   var ServerAllo = ubound( Server )

   ff = FreeFile
   If Open( Options_File For binary access read As #ff ) <> 0 Then
      LIC_DEBUG( "\\Failed to load options from " & Options_File )
      FontRender = fbgfx
      Global_IRC.LastError = NoOptionsFile
   EndIf

   Do Until Eof( ff )

      Line Input #ff, LineInput
      If Len_Hack( LineInput ) = 0 Then Continue Do
      SplitLoc = InStrAsm( 1, LineInput, Asc("=") )
      lhs = UCase( Trim( Left( LineInput, SplitLoc - 1 ), any !" \t" ) )
      rhs = LTrim( Mid( LineInput, SplitLoc + 1 ), any !" \t" )
      if asc( lhs ) = asc("'") then continue do

      lhs = String_Replace( " ", "", lhs )
      lhs = String_Replace( "_", "", lhs )
      
      if SplitLoc = 0 then
         select case ucase( RTrim( rhs, any !" \t" ) )
#ifndef __FB_WIN32__
            case "[WINDOWS]": skip = 1
            case "[LINUX]": skip = 0
#else
            case "[WINDOWS]": skip = 0
            case "[LINUX]": skip = 1
#endif
         End Select
      EndIf
      
      if skip = 1 then
         if lhs = "[CONFIG" then
            skip = 0
         else
            continue do
         endif
      EndIf
      
      if left( lhs, 5 ) = "ALIAS" then
         'alias s = set
         Global_IRC.AliasSet( mid( lhs, 6 ) & " " & rhs )
         Continue do
      elseif SplitLoc = 0 then
         if ucase( left( rhs, 6 ) ) = "ALIAS " then
            'alias s set
            Global_IRC.AliasSet( mid( rhs, 7 ) )
            continue do
         EndIf         
      EndIf 

      With Server( Servers )
         Select Case lhs
            Case "SERVER"
               .Server = rhs
            Case "PORT"
               .Port = valInt( rhs )
            Case "PASSWORD"
               .Password = rhs
            Case "NICKNAME", "NICK"
               .NickName = rhs
            Case "USERNAME", "USER"
               .UserName = rhs
            Case "HOSTNAME"
               .HostName = rhs
            Case "REALNAME"
               .RealName = rhs
            case "AUTOEXEC"
               .AutoExec += rhs + !"\n"
            Case "AUTOJOIN"
               .AutoJoin = rhs
            Case "AUTOPASS"
               .AutoPass = rhs
            Case "IDSERVICE"
               .IdentifyService = rhs
            Case "IGNORELIST"
               .IgnoreList = " " + rhs                        
            case "TWITCHHACKS"
               .TwitchHacks = _BOOL( rhs )
            case "TWITCHKILLEMOTES"
               .TwitchKillEmotes = _BOOL( rhs )
            case "CHANNEL"

               rhs = ucase( rhs ) + " "

               if len( rhs ) > 1 then

                  var CIT = @( .ChanInfo )
                  while *CIT <> 0
                     CIT = @( CIT[0]->next_ptr )
                  Wend

                  *CIT = New ChanInfo_Type

                  CIT[0]->ChanNames = rhs
                  CIT[0]->Notify = &b11
                  CIT[0]->JoinLeave = &b11
                  CIT[0]->HostName = &b11
                  CIT[0]->Logging = &b11

                  Options_Sub_ChanInfo( *CIT )
               endif

            case "SYSTEMTRAYCOLOUR"
               rhs = ucase( rhs )
               if rhs = "RED" then SystemTrayColour = 1
               if rhs = "GREEN" then SystemTrayColour = 2

            case "LOGFOLDER"

#ifndef __FB_LINUX__
               .LogFolder = rtrim( rhs, any "/\ " )
               if instr( rhs, ":\" ) = 0 then
                  .LogFolder = ExePath + "/log/" + .LogFolder
               EndIf
#else
               .LogFolder = rtrim( rhs, any "/ " )
               if left( rhs, 1 ) = "~" then
                  .LogFolder = ENVIRON( "HOME" ) + mid( .LogFolder, 2 )
               elseif left( rhs, 1 ) <> "/" then
                  .LogFolder = ExePath + "/log/" + .LogFolder
               EndIf
#endif

            case "DCCAUTOACCEPT"

               rhs = trim( ucase( rhs ) )

               if asc( rhs ) = asc("Y") then
                  rhs[0] = asc("1")
               EndIf

               if rhs = "LIST" then
                  .DccAutoAccept = OPT_DCCAUTO.list
               else
                  .DccAutoAccept = _BOOL( rhs )
               EndIf

            case "DCCAUTOLIST"
               .DccAutoList = rhs

            case "SCRIPTFILE"
               .ScriptFile = rhs

            Case "[CONFIG"
               Servers += 1
               if Servers = ServerAllo then
                  ServerAllo += 8
                  ReDim Preserve Server( ServerAllo )
               EndIf
            
            case "BITDEPTH"
               BPP = valint( rhs )

            case else
               SplitLoc = 0
         End Select
      End with

      If SplitLoc <> 0 then Continue Do

      Set_Value( lhs, rhs )

   Loop

   Close #ff

   if ( ScreenRes_x and 7 ) = 4 then
      'bug with GDI
      ScreenRes_x -= 1
   EndIf
   if ( ScreenRes_x > LIC_DRAWFONT_X ) and ( FontRender = WinAPI ) then ScreenRes_x = LIC_DRAWFONT_X
   DefaultTextBoxWidth = ScreenRes_x - DefaultUserListWidth

   If FirstRun <> 0 Then

      Select case BPP
      case 1 to 8
         BPP = 8
      case 24 to 32
         BPP = 32
      case else
         BPP = 16
      End Select

      if BPP <> 0 then BitDepth = BPP
      if BPP = 8 then '32 to 8
         var colptr = @BackGroundColour
         for i as integer = 0 to ( offsetof( IRC_Options_type, ChatHistoryColour ) - offsetof( IRC_Options_type, BackGroundColour ) ) \ 4 - 1
            colptr[ i ] = rgb32to8( colptr[ i ] )
         next
      EndIf

      For i As Integer = 0 To UBound( Server )
         Global_IRC.AddServer( Server(i) )
      Next
   EndIf
   
   
   if FontRender = FreeType then
#if LIC_FREETYPE
      with Global_IRC.TextInfo

      dim as integer freetype_cleanup = 0
      if font.ttf_init() <> font.no_error then
         LIC_DEBUG( "\\FreeType error on init:" & font.geterror( ) )
         freetype_cleanup = 1
      elseif .FT_U.Load_TTFont( UserListFont, UserListFontSize, 32, 126 ) <> font.no_error then
         LIC_DEBUG( "\\FreeType error on UserListFont:" & font.geterror( ) )
         freetype_cleanup = 1         
      elseif .FT_C.Load_TTFont( ChatBoxFont, ChatBoxFontSize, 32, 126 ) <> font.no_error then
         LIC_DEBUG( "\\FreeType error in ChatBoxFont:" & font.geterror( ) )
         freetype_cleanup = 1
      end if

      if freetype_cleanup then
         .FT_C.Destructor( )
         .FT_U.Destructor( )
         FontRender = fbgfx
      end if

      end with
#else
      FontRender = fbgfx
#endif

#ifndef __FB_LINUX__
   elseif FontRender = WinAPI then

      with Global_IRC.TextInfo

      if .FT_U.Load_W32Font( UserListFont, UserListFontSize, 32 ) or .FT_C.Load_W32Font( ChatBoxFont, ChatBoxFontSize, 32 ) then
         LIC_DEBUG( "\\W32 Font error:" & font.geterror( ) )
         .FT_C.Destructor( )
         .FT_U.Destructor( )
         FontRender = fbgfx
      EndIf

      End With
#endif

   else

      Global_IRC.TextInfo.FT_C.Destructor( )
      Global_IRC.TextInfo.FT_U.Destructor( )
   EndIf

   font.ttf_deinit( )
   
End Sub

Sub Options_Sub_ChanInfo( byref CI as ChanInfo_Type ptr )

   Dim as string LineInput

   do until eof( ff )

      Line Input #ff, LineInput
      If Len_Hack( LineInput ) = 0 Then Continue Do

      var SplitLoc = InStrAsm( 1, LineInput, Asc("=") )
      var lhs = UCase( Trim( Left( LineInput, SplitLoc - 1 ), any !" \t" ) )
      var rhs = Trim( Mid( LineInput, SplitLoc + 1 ), any !" \t" )

      if asc( lhs ) = asc("'") then continue do

      lhs = String_Replace( " ", "", lhs )

      if SplitLoc = 0 then
         if ( ucase( left( rhs, 3 ) ) = "END" ) then
            if ucase( right( rhs, 7 ) ) = "CHANNEL" then Exit Sub
         endif
      EndIf

      select case lhs
         case "KEY"
            CI->Key = rhs
         case else
            SplitLoc = 0
      end select

      if SplitLoc <> 0 then Continue Do

      if ucase( left( rhs, 1 ) ) = "Y" then
         rhs[0] = asc("1")
      EndIf

      select case lhs

         case "NOTIFYONCHAT"
            CI->Notify = _BOOL( rhs )

         case "SHOWJOINLEAVE"
            CI->JoinLeave = _BOOL( rhs )

         case "SHOWHOSTNAMES"
            CI->HostName = _BOOL( rhs )

         case "LOGTOFILE"
            CI->Logging = _BOOL( rhs )

      End Select

   Loop

End Sub

Function Get_RGB( ByRef rhs As ZString Ptr ) As uInt32_t

   Dim As Integer r, g, b, comma(1)

   comma(0) = InStr( *rhs, "," )
   comma(1) = InStr( comma(0) + 1, *rhs, "," )

   r = valInt( *rhs )
   g = valInt( Mid( *rhs, comma(0) + 1 ) )
   b = valInt( Mid( *rhs, comma(1) + 1 ) )

   if Global_IRC.Global_Options.BitDepth = 8 then
      Function = RGB8( r, g, b )
   else
      Function = RGB( r, g, b )
   EndIf

End Function

Sub TextInfo_type.GetSizes( )

   Dim As Integer TempX, TempY

   ChatBoxCharSizeX   = 0
   ChatBoxCharSizeY   = 0
   UserListCharSizeX  = 0
   UserListCharSizeY  = 0

   with Global_IRC

   if .Global_Options.FontRender <> fbgfx then

      For i As Integer = 0 To 255

         CWidth( i ) = FT_C.glyph( i ).advance_x
         if CWidth( i ) > ChatBoxCharSizeX then
            ChatBoxCharSizeX = CWidth( i )
         EndIf

         UWidth( i ) = FT_U.glyph( i ).advance_x
         If UWidth( i ) > UserListCharSizeX Then
            UserListCharSizeX = UWidth( i )
         EndIf

      Next

      ChatBoxCharSizeY = FT_C.size_ + FT_C.size_ \ 2 + 2
      UserListCharSizeY = FT_U.size_ + FT_U.size_ \ 2 + 2

   else 'fbgfx

      ChatBoxCharSizeX   = 8
      ChatBoxCharSizeY   = 16
      UserListCharSizeX  = 8
      UserListCharSizeY  = 16

      for i as integer = 0 to 255
         CWidth( i ) = 8
         UWidth( i ) = 8
      Next

   EndIf

   .MaxDisp_C = ( .Global_Options.ScreenRes_y - 37 ) \ ChatBoxCharSizeY
   .MaxDisp_U = ( .Global_Options.ScreenRes_y - 21 ) \ UserListCharSizeY

   end with

End Sub

Constructor IRC_Options_Type

   '' Strings ''

      BrowserPath             = "firefox"
      ChatBoxFont             = "System"
      UserListFont            = "System"
      NotifySound             = ""
      QuitMessage             = ""
      CTCP_Version            = ""
      IdentUser               = "LICUser"
      IdentSystem             = "UNIX"
      TimeStampFormat         = ""


   '' Integers ''

      ScreenRes_x             = 800
      ScreenRes_y             = 600
      BitDepth                = 16
      ChatBoxFontSize         = 8
      UserListFontSize        = 8
      DefaultUserListWidth    = 90
      MaxBackLog              = 2000
      DefaultTextBoxWidth     = 0
      LogBufferSize           = 0
      LogTimeOut              = 300
      LogLoadHistory          = 0
      AutoRejoinOnKick        = 3
      AutoRejoinOnBan         = 0
      PingTimer               = 305
      LogMaxFileSize          = 0
      LogMaxFileAction        = LogCopy

#ifndef __FB_LINUX__
      FontRender            = WinAPI
#else
      FontRender            = FreeType
#endif

   '' BOOLEAN ''

      AutoReconnect         = 1
      ShowTimeStamp         = 1
      ShowJoinLeave         = 1
      ShowHostnames         = 0
      ShowMOTD              = 1
      ShowCTCP              = 0
      ShowTopicUpdates      = 1
      ShowServerWelcome     = 0
      ShowServerUsers       = 0
      ShowInactive          = 0
      ShowPrivs             = 0
      ShowRaw               = 0
      ShowDateChange        = 1
      SortByPrivs           = 1
      SortTabBySeen         = 1
      NotifyOnChat          = 1
      MinimizeToTray        = 0
      HideTaskbar           = 0
      LogToFile             = 0
      LogMergePM            = 0
      LogJoinLeave          = 1
      LogLobby              = 1
      LogRaw                = 1
      AutoGhost             = 0
      IdentEnable           = 0
      DisableQuickCopy      = 0
      AlwaysOnTop           = 0
      TimeStampUseCRT       = 0


   '' COLOURS ''

      BackGroundColour           = RGB( 0, 0, 0 )
      YourChatColour             = RGB( 218, 218, 218 )
      TextColour                 = RGB( 200, 200, 200 )
      WhisperColour              = RGB( 210, 84, 142 )
      JoinColour                 = RGB( 16, 255, 16 )
      LeaveColour                = RGB( 160, 32, 32 )
      ServerMessageColour        = RGB( 0, 128, 234 )
      DebugColour                = RGB( 16, 243, 253 )
      ScrollBarBackgroundColour  = RGB( 32, 16, 48 )
      ScrollBarForegroundColour  = RGB( 192, 192, 192 )
      LinkColour                 = RGB( 64, 96, 200 )
      TabColour                  = RGB( 128, 128, 128 )
      TabActiveColour            = RGB( 192, 192, 192 )
      TabTextColour              = RGB( 0, 0, 200 )
      TabTextNotifyColour        = RGB( 200, 0, 0 )
      TabFlashColour             = RGB( 255, 255, 255 )
      HiLiteColour               = RGB( 64, 255, 64 )
      ChatHistoryColour          = RGB( 128, 128, 128 )
      RawInputColour             = RGB( 48, 212, 48 )
      RawOutputColour            = RGB( 212, 48, 48 )


   '' MISC ''

   MinPerLine = 0.5
   DCC_port = DCC_DEFAULT_LISTEN_PORT
   IdentPort = 113


End Constructor

Destructor IRC_Options_type

   LIC_DESTRUCTOR1

   BrowserPath = ""
   ChatBoxFont = ""
   UserListFont = ""
   NotifySound = ""
   QuitMessage = ""
   CTCP_Version = ""
   IdentUser = ""
   IdentSystem = ""

   LIC_DESTRUCTOR2

End Destructor

Constructor Server_Options_Type

   Server            = ""
   Password          = ""
   NickName          = "Guest"
   UserName          = "Guest"
   HostName          = "*"
   RealName          = "*"
   AutoJoin          = ""
   AutoPass          = ""
   IdentifyService   = "NickServ"
   IgnoreList        = ""
   LogFolder         = ""
   DccAutoList       = ""
   ScriptFile        = ""

   DccAutoAccept     = 0
   TwitchHacks       = 0
   TwitchKillEmotes  = 0

   Port              = 6667

End Constructor

Destructor Server_Options_Type

   LIC_DESTRUCTOR1

   Server            = ""
   Password          = ""
   NickName          = ""
   UserName          = ""
   HostName          = ""
   RealName          = ""
   AutoJoin          = ""
   AutoPass          = ""
   IdentifyService   = ""
   IgnoreList        = ""
   LogFolder         = ""
   DccAutoList       = ""
   ScriptFile        = ""

   LIC_DESTRUCTOR2

End Destructor

Destructor ChanInfo_Type

   LIC_DESTRUCTOR1

   ChanNames = ""
   Key = ""

   if next_ptr <> 0 then delete next_ptr

   LIC_DESTRUCTOR2

End Destructor

