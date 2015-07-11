#Define IRC_Version_name "Luke's IRC Client"
#Define IRC_Version_major "0"
#Define IRC_Version_minor "95"
#Define IRC_Version_build "697"
#Define IRC_Version_http "http://code.google.com/p/luke-irc-client/"

#Include Once "lic-compile-options.bi"
#if LIC_CHI
   #Include Once "chisock.bi"
#endif
#Include Once "fbgfx.bi"

#Ifndef __FB_LINUX__

   '#ifdef LIC_WIN_INCLUDE
      #Include Once "windows.bi"
      #if LIC_CHI = 0
         #include once "win/winsock2.bi"
      #endif
   '#endif
   
   #if sizeof(integer) = 4
      #Define IRC_Build_env "Windows x86_32"
   #else
      #Define IRC_Build_env "Windows x86_64"
   #endif

   Const NewLine = !"\r\n"

#Else
   
   #if sizeof(integer) = 4
      #Define IRC_Build_env "Linux x86_32"
   #else
      #Define IRC_Build_env "Linux x86_64"
   #endif
   
   #if LIC_CHI = 0
      #include once "crt/sys/socket.bi"
   #endif
   
   Const NewLine = !"\n"

#EndIf

#Include Once "lic-options.bi"
#Include Once "lic-input.bi"
#Include Once "lic-debug.bi"
#if LIC_DCC
   #Include Once "lic-dcc.bi"
#endif
#Include Once "lic-rtl.bi"
#include once "lic-font.bi"

#Ifdef LIC_NO_GFX
   #Include Once "lic-nogfx.bi"
#EndIf

#if 0 'use os specific sleep?
   #undef sleep
   #undef sleep
   #macro sleep( l, k )
      #if k = 0
         __sleep( l )
      #else
         #ifndef __FB_LINUX__
            SleepEx( l, k )
         #else
            _sleep( l )
         #endif
      #endif
   #EndMacro
#endif

#undef TRUE
#undef FALSE
Const as integer TRUE = (0 = 0), FALSE = (0 = 1)
Const as integer NO_RETURN = -2

#Define Notice_Gui(_m, _c) Global_IRC.CurrentRoom->AddLOT( _m, _c, , Notification, , , TRUE )

Enum Event_id
   Screen_Update_ChatList
   Screen_Update_UserList
   Server_Output
   Server_Input
   Timeout_Server
   Print_History
   Delete_Room
   Thread_Wait
   Script_Filter
   'make sure filter is first and wordfilter is last for
   'case Script_Filter to Script_WordFilter
   Script_CtcpFilter
   Script_MatchAction
   Script_WordMatch
   Script_WordFilter
End Enum

Enum IRC_MessageID
   NormalChat
   ExNormalChat
   ActionEmote
   ExActionEmote
   ServerMessage
   ExServerMessage
   ChatHistory = 50
   ExChatHistory
   Notification
   ExNotification
   LineBreak = 100
End Enum

Enum IRC_MessageLOTCustomFlags
   LOT_Notify           = 1 shl 0
   LOT_NoNotify         = 1 shl 1
   LOT_TimeStamp        = 1 shl 2
   LOT_NoTimeStamp      = 1 shl 3
   LOT_Log              = 1 shl 4
   LOT_NoLog            = 1 shl 5
   LOT_Print            = 1 shl 6
   LOT_NoPrint          = 1 shl 7
   LOT_Tab              = 1 shl 8
   LOT_NoTab            = 1 shl 9
   LOT_Spawned          = 1 shl 10
End Enum

Enum IRC_MessageFlags
   MF_Filter = 1
   MF_Hilight = 2
   MF_Notify = 4
End Enum

Enum ServerStates
   Disconnected
   Connecting
   Online
   Offline
End Enum

Enum RoomTypes
   Channel
   PrivateChat
   Lobby
   List
   DccChat
   RawOutput
End Enum

Enum DS_Hint
   UL 'Userlist
   CB 'ChatBox
End Enum

enum ChanFlags
   Backlogging = 1 SHL 0
   UserCache   = 1 SHL 1
End Enum

Enum pChanFlags
   synced            = 1 SHL 0
   online            = 1 SHL 1
   FakeUsers         = 1 SHL 2
   UsersLock         = 1 SHL 3
   FlashingTab       = 1 SHL 4
   ChannelJoinLeave  = 1 SHL 5
   ChannelNotify     = 1 SHL 6
   ChannelLogging    = 1 SHL 7
   ChannelHostname   = 1 SHL 8
   Hidden            = 1 SHL 9
   DisableSound      = 1 SHL 10
End Enum

Enum LinkIDs
   LinkChannel
   LinkWeb
   LinkShell
End Enum

Enum TitlePrepends
   PrependNull
   PrependStar
   PrependAt
end enum

Enum ScreenDrivers
   GDI
   DirectX
   OpenGL
End Enum

Enum ListStatus
   ListFinished
   ListSending
   ListCancelled   
End Enum

Enum LIC_Errors
   NoError
   NoOptionsFile
End Enum

type StringArray_Type

   as string ptr array
   as int32_t Count

   Declare sub build( byref as string )
   Declare Destructor( )

End Type

type threadconnect
#if LIC_CHI
   as chi.socket ptr sock
#else
   as socket ptr sock
#endif
   as zstring ptr server
   as uint32_t ip
   as uint16_t port
   as int16_t timeout
   as any ptr mutex
   as int32_t ptr ret
End Type

type gui_event

   as int32_t x, y, button

End Type

Type event_type field = 1 'field = 1 required to avoid alignment
   As Event_id id
   As UInteger unique_id
   As Double When
   As Integer _integer, action
   As Any Ptr _ptr
   As string param(3)
   As String _string
   as string mask
   as string saction
   Declare Destructor
End Type

Type Event_handler_Type

   As UInteger Queued
   As UInteger Allocated
   As UInteger Count
   As event_type Ptr Ptr events

   Declare Sub Add( Byref e_t As event_type Ptr )
   Declare Sub Clean( )
   Declare Sub Check( )
   Declare Constructor
   Declare Destructor

End Type

Type Username_type field = 1

   As String Username
   As uint32_t ChatColour
   as time_t seen
   As uint64_t Sort
   As Username_type Ptr NextUser, PrevUser
   As Ubyte SortHelper, Privs

   Declare Destructor

End Type

Type QuickColour
   as uInt32_t ChatColour
   as uint64_t Sort
   as string rhs
end type

Type LOT_MultiColour
   As int32_t x, TextStart
   As uint32_t Colour
   As String Text
   As LOT_MultiColour Ptr NextMC
   Declare Destructor
End Type

Type LOT_MultiColour_Descriptor
   As int32_t TextStart, TextLen
   As uint32_t Colour
   As LOT_MultiColour_Descriptor Ptr NextDesc
   Declare Destructor
End Type

Type LOT_HyperLinkBox field = 1
   As int16_t x1, x2
   as ubyte id
   as int32_t TextStart
   As String HyperLink, AltText
   As LOT_HyperLinkBox Ptr NextLink
   Declare Destructor
End Type

Type LineOfText field = 1
   As uInt32_t Colour
   As String Text
   'As Byte Ptr Descriptor
   'As UInteger Ptr Shared
   As String TimeStamp

   As uByte MesID
   as uByte Offset

   As LOT_MultiColour Ptr MultiColour
   As LOT_HyperLinkBox Ptr HyperLinks
   Declare Sub AddLink( ByRef As Integer, ByRef As Integer, ByRef As ZString Ptr, ByRef as integer )
   Declare Destructor
End Type

Type Server_Type_ As Server_Type

Type UserRoom_type
   As String RoomName, Topic, LogBuffer, LastMODE
   As uint64_t Sort
   As int16_t RoomType, TextBoxWidth, UserListWidth, UserScrollBarY, ChatScrollBarY
   as uint32_t NumUsers, NumLines, NumAllocated, CurrentLine, flags, pflags
   as double LastModeTime
   As UserRoom_type Ptr NextRoom, PrevRoom
   As UserName_type Ptr FirstUser, LastUser, TopDisplayedUser
   as UserName_type ptr ptr OldUsers
   As LineOfText Ptr Ptr TextArray
   As Server_Type_ Ptr Server_Ptr

   Declare Function AddLOT( _
      ByRef Text As String, _
      ByRef Colour As UInt32_t, _
      ByRef PrintNow As Integer = 1, _
      ByVal MesID As IRC_MessageID = ServerMessage, _
      ByRef Spawned As Integer = 0, _
      ByVal MCD As LOT_MultiColour_Descriptor Ptr = 0, _
      ByRef Disable_Log As Integer = FALSE _
   ) as LineOfText ptr
   
   
   declare function AddLOTEX _
   ( _
      byref text as string, _
      byref colour as uint32_t, _
      byval MesID as IRC_MessageID = ServerMessage, _
      byval MCD as LOT_MultiColour_Descriptor ptr = 0, _
      byval flags as uinteger = 0 _
   ) as LineOfText ptr
   
   declare sub PrintLOT( _
      byval lot as LineOfText ptr, _
      byval Pen_x as int32_t, _
      byval Pen_y as int32_t, _
      byval fg as uInt32_t, _
      byval bg as uInt32_t _
   )

   Declare Sub DelUser OverLoad ( ByRef As String )
   Declare Sub DelUser( ByRef As UserName_type Ptr )
   Declare Sub DetectLinks( ByVal As Integer )
   Declare Sub UpdateUserListScroll( ByVal As Integer )
   Declare Sub PrintUserList( ByRef As Integer = 0 )
   Declare Sub UpdateChatListScroll( ByVal As Integer, ByRef As Integer = 1, Byval as Uinteger = 0 )
   Declare Sub PrintChatBox( ByRef As Integer = 0 )
   Declare Sub LineScroll( ByRef As Integer )
   Declare Sub Log( ByRef As String )
   Declare Sub LoadHistory( )
   Declare Sub SmoothScroll( byref as integer )
   Declare Function Find( ByRef As String ) As UserName_type Ptr
   Declare Function AddUser( ByRef As zString Ptr, ByRef As uInt32_t = 0 ) As UserName_type Ptr

   Declare Destructor

End Type

Type TextInfo_Type

   as int32_t _
      ChatBoxCharSizeX, _
      ChatBoxCharSizeY, _
      UserListCharSizeX, _
      UserListCharSizeY

   as int32_t CWidth( 255 )
   as int32_t UWidth( 255 )

   as font.font_obj FT_U, FT_C

   Declare Sub GetSizes( )

End Type

Type Server_Info_Type

   'The ISUPPORT protocol
   CMap           As Integer
   IPrefix( 15 )  As UByte
   VPrefix( 15 )  As UByte
   CHANTYPES( 7 )	As UByte
   CHANMODES( 3 ) As ZString * 32
   NICKLEN			As Integer
   MODES          as integer

   Flags          As UInteger

End Type

type server_numeric

   'Any descrepencies between servers on a value will be placed in the type so it is dynamic

   as int16_t RPL_ISUPPORT = -1
   as int16_t RPL_MAP = -1
   as int16_t RPL_BOUNCE = -1

   as int16_t RPL_LOGGEDIN = -1
   as int16_t RPL_LOGGEDOUT = -1
   as int16_t ERR_NICKLOCKED = -1

   as int16_t ERR_LAST_ERR_MSG = -1

End Type

type irc_message

   msg              As string
   Raw              As string
   From             As string
   Parameters       As string
   Prefix           As string
   MessageTag       As string
   Command          As zString * 8
   ParamOffset      As int32_t
   ParamCount       As int32_t
   flags            As uint32_t
   URT              As UserRoom_type ptr
   Param(-1 to 63)  As zString ptr = { @"" }

   Declare Destructor( )

End Type

Type Server_type

   As uint32_t _
   _
      NumRooms, _
      ExternalIP, _
      CtcpCount


   As int32_t _
   _
      ReconnectTime, _
      ServerNum, _
      IgnoreListDone, _
      State, _
      Status, _
      Resolved, _
      Network, _
      ListStatus


   As String _
   _
      CurrentNick, _
      UCurrentNick, _
      SendBuffer, _
      LogBuffer, _
      ServerName

   As Double _
   _
      LastPingTime, _
      LastServerTalk, _
      CtcpTimer, _
      AntiFlood, _
      SendTime


   EOL            As ZString * 4
   Numeric        as Server_Numeric
#if LIC_CHI
   ServerSocket   As chi.Socket
#else
   ServerSocket   As SOCKET
#endif
   ServerOptions  As Server_Options_type
   ServerInfo     As Server_Info_type
   Event_Handler  As event_handler_type
   IgnoreArray    As StringArray_Type
   FirstRoom      As UserRoom_type Ptr
   LastRoom       As UserRoom_type Ptr
   Lobby          As UserRoom_type Ptr
   ListRoom       As UserRoom_type Ptr
   RawRoom        As UserRoom_type ptr
   Mutex          As Any Ptr
   ThreadHandle   as any ptr

   Declare Sub SendLine( ByRef message As String, byval BypassAntiFlood as integer = FALSE )
   Declare sub IRC_Connect( )
   Declare Sub DelRoom OverLoad ( ByRef As String )
   Declare Sub DelRoom( ByRef As UserRoom_type Ptr )
   Declare Sub DetachRoom( Byref as UserRoom_Type ptr )
   Declare Sub AttachRoom( Byref as UserRoom_Type ptr )
   Declare Sub PermitTransmission( byval flush as integer = FALSE )
   Declare Sub Parse_Privmsg( byref imsg as irc_message )
   Declare Sub Parse_RPL( byref imsg as irc_message )
   Declare Sub LoadNumerics( byref as string )
   Declare Sub LoadScriptFile( )
   Declare Function AddScript( byref as string ) as integer
   Declare Function ParseMessage( ) as integer
   Declare Function LogToFile( Byref as string, Byref as string ) as integer
   Declare function AddRoom( ByRef As zString Ptr, byref as int16_t ) As UserRoom_type Ptr
   Declare Function ResizeRoom( ByVal as UserRoom_type ptr ) as UserRoom_Type ptr
   Declare Function CheckIgnore( ByRef As String ) As integer
   Declare Function Find( ByRef As zString Ptr ) As UserRoom_type Ptr
   Declare Function RoomCheck( Byref as any ptr ) as UserRoom_Type ptr
   Declare Function UCase_( ByRef As String ) As String
   Declare Function IS_Channel( ByRef As String ) As Integer

   Declare Constructor
   Declare Destructor

End Type

Type Global_IRC_Type

   LastUL_Print   As Double
   LastCL_Print   As Double
   LastLogWrite   As double
   PrintQueue_U   As int32_t
   PrintQueue_C   As int32_t
   LogLength      As integer
   MaxDisp_U      as int32_t
   MaxDisp_C      as int32_t
   NumServers     As uint32_t
   WindowActive   As int32_t
   PrependTitle   as Integer
   HWND           As Integer
   NoServers      as Integer
   DarkUsers      as Integer
   LastError      as integer
   ShutDown       As Integer Ptr
   #if LIC_DCC
      DCC_list       As DCC_LIST_Type
   #endif
   event_handler  As Event_handler_Type
   Server         As Server_type Ptr ptr
   Global_Options As IRC_Options_type
   TextInfo       As TextInfo_Type
   CurrentRoom    As UserRoom_type Ptr
   SwapRoom       as UserRoom_type Ptr   
   LastLOT        As LineOfText Ptr
   Mutex          As Any Ptr
   TimeStamp      as String
   CurrentDay     as zString * 16
   AliasList      as zstring ptr ptr
   AliasCount     as Uinteger

   #If __FB_DEBUG__
   DebugLog       As String
   DebugLock      As Any Ptr
   #endif

   Declare Sub DrawTabs
   Declare Sub ClickTabs( ByVal As Integer )
   Declare Sub SwitchRoom( ByRef As UserRoom_type Ptr )
   Declare Sub AddServer( byref as Server_Options_Type )
   Declare Sub DelServer( byref as integer )
   Declare function GetTab( ByVal X as integer ) as UserRoom_type ptr
   Declare Function NumVisibleRooms( ) As Integer
   Declare Function TotalNumRooms( ) As Integer
   declare Function AliasSet( Byref as string, byval as integer = 0 ) as integer

   Declare Constructor
   Declare Destructor

End Type

Declare Sub LIC_Main( byref as integer = FALSE )
Declare Sub LIC_Main_Events( )
Declare Sub ParseScreenEvent( byref as fb.event )
Declare Sub UpdateWindowTitle( )
Declare Sub LIC_Screen_INIT( )
Declare Sub LIC_Event_Mouse_Release( ByRef g As gui_event Ptr )
Declare Sub LIC_Event_Mouse_Press( ByRef g As gui_event Ptr )
Declare Sub LIC_Notify( ByRef Highlight As Integer = 0 )
Declare Sub LIC_Resize( byval x as integer, byval y as integer )
Declare Sub LIC_ResizeAllRooms( )
Declare Sub WriteLogs( )
Declare Sub chiConnect( byval t as threadconnect ptr )
declare sub chiListen( byval t as threadconnect ptr )
declare sub StripColour( byref as string )
Declare Sub CharKill( byref as string )
#if LIC_DCC
   Declare sub DCC_Parse_IRC( byref imsg as irc_message, byref server as Server_Type ptr )
#endif
Declare sub AddDefaultServer( )
Declare sub RemDefaultServer( )
declare sub Build_IRC_Message( byref as irc_message, byref as string )
declare sub fb_TlsFreeCtxTb alias "fb_TlsFreeCtxTb"() 'fix a crash involving threads
Declare Function Parse_Scancode( ByRef As long ) as integer
Declare Function ServerCheck( byref as any ptr ) as Server_Type ptr
Declare Function DrawString( byval x as integer, byval y as integer, byref s as string, byval c as uInt32_t, byval hint as integer = DS_Hint.CB ) as integer
Declare Function GetPrevRoom( ByVal Room As UserRoom_Type Ptr = 0 ) As UserRoom_Type Ptr
Declare Function GetNextRoom( ByVal Room As UserRoom_Type Ptr = 0 ) As UserRoom_Type Ptr
Declare Function GetLOT( byval as integer ) as LineOfText ptr
Declare Function Pending_Message( ) As Integer
Declare Function UWidth( byref s as string ) as integer
Declare Function CWidth( byref s as string ) as integer

Extern Global_IRC As Global_IRC_Type
