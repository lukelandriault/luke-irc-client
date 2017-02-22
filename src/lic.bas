#define LIC_WIN_INCLUDE
#Include Once "lic.bi"
#Include Once "lic-systray.bi"
#Include Once "file.bi"

Declare Function Options_Emit( byref as string ) as integer
Declare Sub CmdLine_Parse( )

Using fb

Extern Options_File  As string
Extern ChatInput     As FBGFX_CHARACTER_INPUT

Dim ChatInput        As FBGFX_CHARACTER_INPUT
Dim Global_IRC       As Global_IRC_Type
Dim IRC_Shutdown     As Integer

dim shared as double SecondUpdate, FiveSecondUpdate, MinuteUpdate
dim shared as byte timesync
dim shared as uint16_t Minute_Count

#If __FB_DEBUG__   
   Dim UptimeStart As Double
   Dim DebugLevel as integer
   UptimeStart = Timer
   Open Cons For Output As #1
   setbuf(stdout, NULL)
#EndIf

CmdLine_Parse( )

Global_IRC.ShutDown = @IRC_ShutDown
Global_IRC.TimeStamp = "(" & Time & ") "
Global_IRC.LastLogWrite = Timer

Randomize( Timer, 2 ) '2 = fast algorithm, 3 = best but slower
ChDir ExePath

#ifndef __FB_LINUX__
   If FileExists( Environ( "APPDATA" ) & "\lic\" & Options_File ) Then
      ChDir Environ( "APPDATA" ) & "\lic\"
   EndIf
#Else '__FB_LINUX__
   If FileExists( Environ( "HOME" ) + "/.lic/" + Options_File ) Then
      ChDir Environ( "HOME" ) + "/.lic/"
   EndIf
   
   declare function waitpid_ cdecl alias "waitpid" (byval pid as integer, byval status as integer ptr, byval options as integer) as integer
   #define SIGINT 2
   #define SIGPIPE 13   'Broken Pipe
   #define SIGTERM 15
   #define SIG_IGN 1    'Action Ignore
   Declare Function signal Cdecl Alias "signal" ( Byval sig As Integer, Byval action as Integer ) As Any Ptr
   Declare Sub signal_catch( i as integer )
   
   signal( SIGINT, cast( integer, @signal_catch ) )
   signal( SIGTERM, cast( integer, @signal_catch ) )
   
   'if a file is being sent over DCC and is canceled at their end
   'linux kernel will throw a broken pipe signal if send() is called
   'it should be safe to ignore broken pipe signal:   
   signal( SIGPIPE, SIG_IGN )

#EndIf

'tmp screenbuffer
Screenres 32, 32, 4, , fb.GFX_NULL

Global_IRC.Global_Options.Load_Options( 1 ) 'First run to grab the options

If Global_IRC.Global_Options.LogToFile <> 0 Then

   For i As Integer = 0 To Global_IRC.NumServers - 1
      if MkDirTree( Global_IRC.Server[i]->ServerOptions.LogFolder ) <> 0 then
         Global_IRC.Server[i]->ServerOptions.LogFolder = "?" + Global_IRC.Server[i]->ServerOptions.LogFolder
      EndIf
   Next

EndIf

LIC_Debug( NewLine & "\\New Session: " & date & " " & time & NewLine )
LIC_Debug( "\\" IRC_Version_name " v" IRC_Version_major "." IRC_Version_minor "b (build:" IRC_Version_build ") (" IRC_Build_env ")" )
LIC_Debug( "\\Compiled with " __FB_SIGNATURE__ " on " __DATE__ " at " __TIME__ )
LIC_Debug( "\\Using Directory: " & CurDir )


LIC_Screen_INIT( )
LIC_TrayINIT( )

'Init the servers
For i As Integer = 0 To Global_IRC.NumServers - 1

   With *Global_IRC.Server[i]

   if i = 0 then
      Global_IRC.CurrentRoom = .Lobby
      if asc( Global_IRC.Server[i]->ServerOptions.LogFolder ) = asc("?")  then
         LIC_Debug( "\\mkdir fail: " + mid( Global_IRC.Server[i]->ServerOptions.LogFolder, 2 ) )
         .Lobby->AddLOT( "** Error creating log directory '" + mid( Global_IRC.Server[i]->ServerOptions.LogFolder, 2 ) + "' logging will be disabled for this server", Global_IRC.Global_Options.ServerMessageColour, 0, ,1 , , TRUE )
      EndIf
   EndIf

   If ( Global_IRC.Global_Options.LogToFile <> 0 ) and ( (.Lobby->pflags AND ChannelLogging) <> 0 ) then
      var msg =   "==========================================" & NewLine & _
                  "==== New Session: "&Date &" "&Time &" ====" & NewLine & _
                  "==========================================" & NewLine

      if Global_IRC.Global_Options.LogBufferSize > 0 then
         .Lobby->LogBuffer += msg
         Global_IRC.LogLength += len_hack( msg )
      else
         .LogToFile( "server messages", msg )
      EndIf

   EndIf

   End with

Next i

If Global_IRC.NumServers = 0 Then
   AddDefaultServer( )
   if Global_IRC.LastError = NoOptionsFile then      
      notice_gui( "No Options file found!", rgb( 255, 0, 0 ) )
      notice_gui( "Download the example from http://luke-irc-client.googlecode.com/hg/IRC_Options.txt", rgb( 255, 255, 255 ) )
      notice_gui( "Edit this file and place it in the same directory as LIC", rgb( 255, 255, 255 ) )
      notice_gui( "Help for all options available here: http://luke-irc-client.googlecode.com/hg/readme.txt", rgb( 255, 255, 255 ) )
      notice_gui( "To view the readme right now type '/readme' then hit enter", rgb( 128, 255, 128 ) )
   EndIf   
EndIf

#macro LIC_Main_MACRO( )
   If Global_IRC.WindowActive <> 0 Then
      ChatInput.CursorBlink( )
   EndIf

#if LIC_CHI
   For i = 0 To Global_IRC.NumServers - 1

      With *Global_IRC.Server[i]
      
      'FIXME!!!
      

      If ( .State = ServerStates.connecting ) Or ( .ServerSocket.Is_Closed( ) = TRUE ) Then

         .IRC_connect( )
         Continue For

      end if

      if .ServerSocket.length( ) > 0 then

         var TimeOut = timer + 3

         while ( Timer < TimeOut ) and ( .ParseMessage( ) = TRUE )

#Ifndef LIC_NO_GFX
            if events_safe = TRUE then
               LIC_Main_Events( )
            endif
#endif
            if Global_IRC.WindowActive = 0 then
               sleep( 1, 1 )
            EndIf

         Wend

      endif

      If .State = ServerStates.Online then

         var TT = Timer

         If Len_hack( .SendBuffer ) <= 0 Then
            If .AntiFlood <> 0 Then
               If ( .SendTime + .AntiFlood ) < TT Then
                  .AntiFlood = 0
               EndIf
            EndIf
         else
            .PermitTransmission( )
         endif

         If TT > ( .LastServerTalk + Global_IRC.Global_Options.PingTimer ) Then

            .SendLine( "PING :LIC LAG", TRUE )
            .LastPingTime = TT

            Dim As event_Type et, et_to

            'Give the server 30 seconds to respond, or else disconnect
            et.when = 1
            et.id = Timeout_Server

            .Event_handler.Add( @et )

            et_to.id = Timeout_Server
            et_to.When = TT + 30
            et_to.Unique_ID = et.Unique_ID
            et_to._ptr = Global_IRC.Server[i]

            Global_IRC.Event_Handler.Add( @et_to )

            .LastServerTalk = TT - Global_IRC.Global_Options.PingTimer + 35

         EndIf

      EndIf

      End with

   Next
#endif 'LIC_CHI

   If Timer >= SecondUpdate then
      SecondUpdate = Timer + 1

      Global_IRC.Event_Handler.Check( )
      #if LIC_DCC
         Global_IRC.DCC_list.Proc( )
      #endif
      
      if SecondUpdate >= FiveSecondUpdate then

         FiveSecondUpdate = SecondUpdate + 4

         If Global_IRC.LogLength > 0 then
            If ( Global_IRC.LogLength >= Global_IRC.Global_Options.LogBufferSize ) Or _
               ( Global_IRC.LastLogWrite + Global_IRC.Global_Options.LogTimeOut < Timer ) Then

               WriteLogs( )

            EndIf
         EndIf

      EndIf
      
      If SecondUpdate >= MinuteUpdate Then
         
         Minute_Count += 1         
         'LIC_DEBUG( "\\MinUpdate " & time )
         #if LIC_DCC
            Global_IRC.DCC_List.FreeZombies( )
         #endif

         If Global_IRC.Global_Options.MinimizeToTray <> 0 Then
            LIC_TrayRegenerate( )
         EndIf
         
         #ifdef __FB_LINUX__
            'keep the zombie count low!
            #define WNOHANG 1
            dim as integer dummy
            waitpid_( -1, @dummy, WNOHANG )
         #endif
         
         dim as time_t rawtime
         dim as tm ptr timeinfo
         dim as zstring * 16 today
                 
         if (timesync = 0) or (SecondUpdate >= MinuteUpdate + 300) then
            time_( @rawtime )
            timeinfo = localtime( @rawtime )
            strftime( today, 16, "%S", timeinfo )
            MinuteUpdate = SecondUpdate + ( 60 - valint( today ) )
            timesync = 1
         else
            MinuteUpdate += 60
         endif
         
         if Global_IRC.Global_Options.ShowDateChange <> 0 then
         
            'check if the day has changed
            time_( @rawtime )
            timeinfo = localtime( @rawtime )
            strftime( today, 16, "%a %b %d %Y", timeinfo )
            if strcmp( today, Global_IRC.CurrentDay ) then 'if today <> CurrentDay then
               var URT = Global_IRC.CurrentRoom
               do
                  if (URT->pflags AND Hidden) = 0 then
                     URT->AddLOTEX( _
                        "** Day changed to: " & today, _
                        Global_IRC.Global_Options.ServerMessageColour, , ,_
                        LOT_Log OR LOT_NoNotify OR LOT_NoTab )
                  endif
                  URT = GetNextRoom( URT )
               Loop until URT = Global_IRC.CurrentRoom
               swap today, Global_IRC.CurrentDay
               timesync = 0
            EndIf
            
         endif

         if Minute_Count mod 30 = 0 then
         
            var cutoff = time_ - 1800 'delete all 30 minute lurkers
            For i = 0 To Global_IRC.NumServers - 1
               With *Global_IRC.Server[i]               
               
               if .ServerOptions.TwitchHacks <> 0 then
                  var URT = .FirstRoom
                  do
                     if URT->NumUsers > 500 then
                        var UNT = URT->FirstUser
                        var you = URT->Find( .UCurrentNick )
                        do until UNT = 0
                           var UNTNext = UNT->NextUser
                           if (UNT->seen <= cutoff) and (UNT <> you) then                           
                              URT->DelUser( UNT )
                           EndIf
                           UNT = UNTNext
                        Loop
                     endif
                     URT = URT->NextRoom
                  Loop until (URT = .FirstRoom) or (URT = 0)
               EndIf
               
               End With
            next
            
         EndIf

         UpdateWindowTitle( )
         
      EndIf

   EndIf

#endmacro

Do Until IRC_ShutDown

   MutexLock( Global_IRC.Mutex )

   static as integer i, events_safe = TRUE
   LIC_Main_Macro( )

#Ifndef LIC_NO_GFX
   LIC_Main_Events( )
#else
   CheckNOGFX_Events( )
#endif

   MutexUnLock( Global_IRC.Mutex )
#if LIC_CHI
   For i = 0 To Global_IRC.NumServers - 1
      If Global_IRC.Server[i]->ServerSocket.Length( ) Then
         sleep( 1, 1 )
         continue do
      end if
   Next
#endif
   if Global_IRC.WindowActive = 0 then
      sleep( 250, 1 )
   else
      sleep( 50, 1 )
   end if

Loop

Global_IRC.Global_Options.LogBufferSize = 0 'Make further writes direct to file

'Options_Emit( "test.txt" )

LIC_TrayShutdown( )

Screenres 32, 32, iif( Global_IRC.Global_Options.BitDepth <> 0, Global_IRC.Global_Options.BitDepth, 4 ), , fb.GFX_NULL

WriteLogs( )
#if LIC_DCC
   Global_IRC.DCC_LIST.Shutdown( )
#endif

For i As Integer = 0 To Global_IRC.NumServers - 1
   Delete Global_IRC.Server[i]
   Global_IRC.Server[i] = 0
Next

#ifndef __FB_LINUX__
   sleep( 500, 1 )
   WSACleanup( )
#EndIf

LIC_Debug( NewLine )
LIC_Debug( "\\Session End: " & date & " " & time )

'End 0

Sub LIC_Main( byref events_safe as integer = FALSE )

   static as integer i
   LIC_Main_Macro( )

End Sub

Sub LIC_Main_Events( )

   static as fb.event E
   While ScreenEvent(@E)
      ParseScreenEvent( E )
   Wend

End Sub

sub ParseScreenEvent( byref E as fb.event )

   static as gui_event G

   Select Case E.type

      case EVENT_MOUSE_MOVE
         G.x = E.x
         G.y = E.y

      Case EVENT_KEY_RELEASE
         If MultiKey( SC_ALT ) and NOT( Multikey( SC_CONTROL ) ) then
            ChatInput.Custom_ASCII( e.scancode )
            ChatInput.Print( )
         EndIf

      Case EVENT_KEY_PRESS
         Select Case e.ascii
            Case 32 To 126
               ChatInput.Parse( e.Ascii, 1 )
            Case Else
               Parse_Scancode( e.Scancode )
         End Select
         ChatInput.Print( )

      Case EVENT_KEY_REPEAT
         Select Case e.ascii
            Case 32 To 126
               ChatInput.Parse( E.Ascii, 1 )
            Case Else
               Parse_Scancode( e.Scancode )
         End Select
         ChatInput.Print( )

      Case EVENT_WINDOW_LOST_FOCUS
         Global_IRC.WindowActive = 0
         Global_IRC.PrintQueue_U = 1
         Global_IRC.PrintQueue_C = 1
         G.x = -1
         G.y = -1

      Case EVENT_WINDOW_GOT_FOCUS
         Global_IRC.WindowActive = 1
         LIC_TrayFlash_STOP( )
         
         If Global_IRC.CurrentRoom->UserListWidth > 0 Then
            Global_IRC.CurrentRoom->UpdateUserListScroll( -123456 )
         endif
         If (Global_IRC.CurrentRoom->flags AND Backlogging) = 0 Then
            Global_IRC.CurrentRoom->UpdateChatListScroll( Global_IRC.CurrentRoom->ChatScrollBarY, 1 )
         EndIf

         Global_IRC.PrintQueue_U = 0
         Global_IRC.PrintQueue_C = 0
         Global_IRC.DrawTabs( )
         if Global_IRC.PrependTitle <> PrependNull then
            Global_IRC.PrependTitle = PrependNull
            UpdateWindowTitle( )
         end if

      Case EVENT_WINDOW_CLOSE
         *Global_IRC.Shutdown = 1

      Case EVENT_MOUSE_BUTTON_PRESS

         G.Button = E.Button
         if ( G.y >= 0 ) and ( G.x >= 0 ) then LIC_Event_Mouse_Press( @G )

      Case EVENT_MOUSE_BUTTON_RELEASE

         G.Button = E.Button
         if ( G.y >= 0 ) and ( G.x >= 0 ) then LIC_Event_Mouse_Release( @G )

      Case EVENT_MOUSE_WHEEL

         Static As integer OldMouseWheel

         If ( e.w <> OldMouseWheel ) And ( g.x And g.y <> -1 ) Then
            Select Case g.x
               Case 0 To Global_IRC.CurrentRoom->UserListWidth
                  If Global_IRC.CurrentRoom->NumUsers > ( Global_IRC.MaxDisp_U ) Then
                     If ( Global_IRC.CurrentRoom->UserScrollBarY = 0 ) And ( e.w + (-OldMouseWheel) > 0 ) Then Exit Select
                     Dim As Integer Multiplier = ( Global_IRC.Global_Options.ScreenRes_y / Global_IRC.CurrentRoom->NumUsers ) + 1
                     Global_IRC.CurrentRoom->UserScrollBarY -= Multiplier * ( e.w + ( -OldMouseWheel ) )
                     Global_IRC.CurrentRoom->UpdateUserListScroll( Global_IRC.CurrentRoom->UserScrollBarY )
                  endif
               Case Else
                  Global_IRC.CurrentRoom->LineScroll( -( e.w - OldMouseWheel ) )
            End Select
            OldMouseWheel = e.w
         EndIf

   End Select

End Sub

Sub LIC_Resize( byval x as integer, byval y as integer )

   if ( x and 7 ) = 4 then
      'bug with GDI
      x -= 1
   EndIf

   Dim As Integer diffx = Global_IRC.Global_Options.ScreenRes_X - X

   For j As Integer = 0 To Global_IRC.NumServers - 1
      Var URT = Global_IRC.Server[j]->FirstRoom
      For k As Integer = 1 To Global_IRC.Server[j]->NumRooms
         URT->TextBoxWidth -= diffx
         URT = URT->NextRoom
      Next
   Next j

   Global_IRC.Global_Options.ScreenRes_X = X
   Global_IRC.Global_Options.ScreenRes_Y = Y
   Global_IRC.Global_Options.DefaultTextBoxWidth = X - Global_IRC.Global_Options.DefaultUserListWidth

   Dim As String CI = ChatInput

   'LIC_DEBUG( "\\Resizing to:" & X & "x" & Y )

   dim as integer posx, posy
   ScreenControl( fb.GET_WINDOW_POS, posx, posy )
   LIC_Screen_INIT( )
   ScreenControl( fb.SET_WINDOW_POS, posx, posy )

   If Global_IRC.CurrentRoom->UserListWidth > 0 then
      Global_IRC.CurrentRoom->UpdateUserListScroll( -123456 )
   EndIf

   Global_IRC.LastLOT = 0
   Global_IRC.CurrentRoom->UpdateChatListScroll( Global_IRC.CurrentRoom->ChatScrollBarY, 1 )

   Global_IRC.DrawTabs( )

   If Len( CI ) Then
      ChatInput.Set( CI )
      ChatInput.Print
   EndIf

   LIC_ResizeAllRooms( )

End Sub

Sub LIC_ResizeAllRooms( )

   var CurrentRoom = Global_IRC.CurrentRoom

   ScreenLock

   for i as integer = 0 to Global_IRC.NumServers - 1
      var URT = Global_IRC.Server[i]->FirstRoom
      for j as integer = 1 to Global_IRC.Server[i]->NumRooms
         if NOT( ( URT->RoomType = DccChat ) and ( (URT->pflags AND Hidden) <> 0 ) ) then
            'hidden DCC rooms have an event for deletion
            if URT = CurrentRoom then
               URT = URT->Server_Ptr->ResizeRoom( URT )
               CurrentRoom = URT
            else
               URT = URT->Server_Ptr->ResizeRoom( URT )
            EndIf
         EndIf
         URT = URT->NextRoom
      Next
   Next

   if Global_IRC.CurrentRoom <> CurrentRoom then
      Global_IRC.SwitchRoom( CurrentRoom )
   endif

   ScreenUnlock

End Sub

Sub CmdLine_Parse( )

   dim as integer ff = freefile, argc = 1, Terminate
   Open Cons for output as #ff
   
   Do

      Select Case Command( argc )

         Case ""
            Exit Do
            
         case "-h", "-help"
            #define tl 30
            print #ff, "-v   -version            Print LIC version info"
            print #ff, "-o   -optionfile         Set LIC Option filename"
            Terminate = 1
            
         Case "-v", "-version"
            Print #ff, IRC_Version_name " v" IRC_Version_major "." IRC_Version_minor "b build:" IRC_Version_build " (" IRC_Build_env ")"
            Print #ff, "Compiled with " __FB_SIGNATURE__ " (" __FB_BACKEND__ ") on " __DATE__ " at " __TIME__
            Print #ff, "Compile Options: ";
            #If __FB_DEBUG__
               Print #ff, "DEBUG ";
            #EndIf
            #If LIC_USE_STRING_HACKS
               Print #ff, "STRING_HACKS ";
            #endif
            #Ifdef LIC_NO_GFX
               Print #ff, "NO_GFX ";
            #EndIf
            #Ifdef LIC_CHI
               print #ff, "LIBCHISOCK ";
            #endif
            #ifdef LIC_FREETYPE
               print #ff, "LIBFREETYPE ";
            #endif
            print #ff, ""
            Terminate = 1
            
         case "-o", "-optionfile"            
            argc += 1
            if len( command( argc ) ) then
               Options_File = command( argc )
               LIC_DEBUG( "\\Options File set to: " & Options_File )
            EndIf

      End Select

      argc += 1

   Loop
   
   close #ff
   if Terminate <> 0 then
      end 0
   EndIf

End Sub

#ifdef __FB_LINUX__

Sub signal_catch( i as integer )
   
   static as integer force
   LIC_DEBUG( "\\Caught signal: " & i )

   select case i
   case SIGINT, SIGTERM
   
      if force then
         LIC_DEBUG( "\\Forcing termination now" )
         end 1
      EndIf
      force = 1
      
      MutexLock( Global_IRC.Mutex )
      *Global_IRC.Shutdown = TRUE
      MutexunLock( Global_IRC.Mutex )
      
   End Select

   
End Sub

#endif