#Define IRC_Options_file "IRC_Options.txt"

Enum OPT_DCCAUTO
   off
   on
   list
End Enum

Enum OPT_LOGMAX
   logcopy
   logprune
End Enum

Enum DS_Render
   fbgfx
   FreeType
   WinAPI
End Enum

Enum KEYBOARD_LAYOUT
   french
End Enum

#undef TRUE
#undef FALSE
Const as integer TRUE = (0 = 0), FALSE = (0 = 1)

Type ChanInfo_Type

   as string _
      ChanNames, _
      Key

   as uinteger _
      Notify : 2, _
      JoinLeave : 2, _
      HostName : 2, _
      Logging : 2


   as ChanInfo_Type ptr next_ptr

   Declare Destructor

End Type

Type Server_Options_type

   As String _
   _
      Server, _
      Password, _
      NickName, _
      UserName, _
      HostName, _
      RealName, _
      AutoJoin, _
      AutoPass, _
      IdentifyService, _
      IgnoreList, _
      LogFolder, _
      DccAutoList, _
      ScriptFile, _
      AutoExec

   as ubyte _
   _
      DccAutoAccept : 2


   As int16_t Port

   ChanInfo as ChanInfo_Type ptr

   Declare Constructor( )
   Declare Destructor( )

End Type

Type IRC_Options_type

   As String _
   _
      BrowserPath, _
      ChatBoxFont, _
      UserListFont, _
      NotifySound, _
      QuitMessage, _
      CTCP_Version, _
      IdentUser, _
      IdentSystem, _
      TimeStampFormat

   As Integer _
   _
      ScreenRes_x, _
      ScreenRes_y, _
      ScreenDriver, _     
      PingTimer
   
   as int32_t _
   _
      MaxBackLog, _
      LogBufferSize, _
      LogLoadHistory, _
      LogMaxFileSize, _
      LogTimeOut
         
   as int16_t _
   _
      AutoRejoinOnKick, _
      AutoRejoinOnBan, _
      BitDepth, _
      ChatBoxFontSize, _
      UserListFontSize, _
      DefaultUserListWidth, _
      DefaultTextBoxWidth, _
      FontRender, _
      LogMaxFileAction
  
   As Byte _ 'Boolean
   _
      AutoReconnect      :LIC_BOOL_BITS, _
      ShowJoinLeave      :LIC_BOOL_BITS, _
      ShowHostnames      :LIC_BOOL_BITS, _
      ShowTimeStamp      :LIC_BOOL_BITS, _
      ShowMOTD           :LIC_BOOL_BITS, _
      ShowCTCP           :LIC_BOOL_BITS, _
      ShowTopicUpdates   :LIC_BOOL_BITS, _
      ShowServerWelcome  :LIC_BOOL_BITS, _
      ShowServerUsers    :LIC_BOOL_BITS, _
      ShowInactive       :LIC_BOOL_BITS, _
      ShowPrivs          :LIC_BOOL_BITS, _
      ShowRaw            :LIC_BOOL_BITS, _
      ShowDateChange     :LIC_BOOL_BITS, _
      SortByPrivs        :LIC_BOOL_BITS, _
      SortTabBySeen      :LIC_BOOL_BITS, _
      NotifyOnChat       :LIC_BOOL_BITS, _
      MinimizeToTray     :LIC_BOOL_BITS, _
      HideTaskbar        :LIC_BOOL_BITS, _
      LogToFile          :LIC_BOOL_BITS, _
      LogMergePM         :LIC_BOOL_BITS, _
      LogJoinLeave       :LIC_BOOL_BITS, _
      LogLobby           :LIC_BOOL_BITS, _
      LogRaw             :LIC_BOOL_BITS, _
      AutoGhost          :LIC_BOOL_BITS, _
      IdentEnable        :LIC_BOOL_BITS, _
      SmoothScroll       :LIC_BOOL_BITS, _
      DCC_Passive        :LIC_BOOL_BITS, _
      DisableQuickCopy   :LIC_BOOL_BITS, _
      AlwaysOnTop        :LIC_BOOL_BITS, _
      TimeStampUseCRT    :LIC_BOOL_BITS

   As uint32_t _ 'COLOURS
   _ ' Make sure to update Convert32to8 in lic-options.bas if BackGround is not the first colour
      BackGroundColour, _
      YourChatColour, _
      TextColour, _
      WhisperColour, _
      JoinColour, _
      LeaveColour, _
      ServerMessageColour, _
      DebugColour, _
      ScrollBarBackgroundColour, _
      ScrollBarForegroundColour, _
      LinkColour, _
      TabColour, _
      TabActiveColour, _
      TabTextColour, _
      TabTextNotifyColour, _
      HiLiteColour, _
      RawInputColour, _
      RawOutputColour, _
      TabFlashColour, _
      SystemTrayColour, _
      ChatHistoryColour
      
   ' Make sure to update Convert32to8 in lic-options.bas if ChatHistory is not the last colour

#if __FB_DEBUG__

   as uinteger _
      DisableSTDOUT :LIC_BOOL_BITS, _
      LogDebug :LIC_BOOL_BITS, _
      RawIRC :LIC_BOOL_BITS 

#endif

   As Single MinPerLine
   As uint16_t DCC_port, IdentPort   

   Declare Sub Load_Options( ByRef FirstRun As Integer = 0 )
   Declare Function Set_Value( byref lhs as string, byref rhs as string ) as integer

   Declare Constructor
   Declare Destructor

End Type

Declare Function Get_RGB( ByRef rhs As ZString Ptr ) As uInt32_t

#ifndef LIC_DEBUG
   #define LIC_DEBUG( DEBUG_ ) REM DEBUG_
#endif
