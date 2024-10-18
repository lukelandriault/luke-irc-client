#define LIC_WIN_INCLUDE
#Include Once "lic.bi"
#ifdef __FB_WIN32__
   #Include Once "win/shellapi.bi"
   #Include Once "win/mmsystem.bi"
#else
   #undef font
   #include Once "X11/Xutil.bi"
#EndIf
#include Once "lic-systray.bi"

#ifdef __FB_WIN32__
   Dim Shared As WNDPROC OldWindowProc
   dim Shared As NOTIFYICONDATA NID
   Dim Shared As hIcon Tray_Icon(3)
   Dim Shared As hIcon Tray_Swap
   Dim Shared As Byte Swapped_Icon
   Dim Shared As Byte Tray_Flash_ON
   Dim Shared As Byte Tray_Flash_STOP
   Dim Shared As Byte Tray_Flash_Visible
   Dim Shared As Any Ptr TrayMutex
   Dim Shared As Any Ptr TrayThread
   TrayMutex = MutexCreate( )
#else
   type X11DRIVER 'incomplete type but just what i need to hack some gfxlib internals
      as any ptr display, visual
      as int32_t screen
      as Window window_, wmwindow, fswindow    
   End Type
   Extern fb_x11 alias "fb_x11" as X11DRIVER 'located in fb gfxlib module
#EndIf

Extern ChatInput As FBGFX_CHARACTER_INPUT

using fb

Sub LIC_TrayINIT( )

   Static As Integer ran
   If ran = 1 Then Exit Sub

#ifdef __FB_WIN32__

   /'
      1000 ICON "lic_1.ico"
      2000 ICON "lic_2.ico"
      3000 ICON "lic_3.ico"
      4000 ICON "lic_4.ico"
      5000 ICON "lic_5blue.ico"
      6000 ICON "lic_5green.ico"
      7000 ICON "lic_5red.ico"

      case "SYSTEMTRAYCOLOUR"
         rhs = ucase( rhs )
         if rhs = "RED" then SystemTrayColour = 1
         if rhs = "GREEN" then SystemTrayColour = 2
   '/

   If Global_IRC.Global_Options.MinimizeToTray <> 0 Then
      Dim hMod As HMODULE = GetModuleHandle( null )
      Dim hPopupMenu As HMenu = CreatePopupMenu
      Tray_Icon(0) = LoadIcon( hMod, MAKEINTRESOURCEA(1000) )
      Tray_Icon(1) = LoadIcon( hMod, MAKEINTRESOURCEA(2000) )
      Tray_Icon(2) = LoadIcon( hMod, MAKEINTRESOURCEA(3000) )
      Tray_Icon(3) = LoadIcon( hMod, MAKEINTRESOURCEA(4000) )
      select case Global_IRC.Global_Options.SystemTrayColour
         case 1:     Tray_Swap = LoadIcon( hMod, MAKEINTRESOURCEA(7000) )
         case 2:     Tray_Swap = LoadIcon( hMod, MAKEINTRESOURCEA(6000) )
         case else:  Tray_Swap = LoadIcon( hMod, MAKEINTRESOURCEA(5000) )
      end select

      With NID
        .cbSize           = SizeOf(NOTIFYICONDATA)
        .hIcon            = Tray_Icon(0)
        .uFlags           = NIF_MESSAGE Or NIF_ICON Or NIF_TIP 'Or NIF_INFO
        .uCallbackMessage = WM_USER + 1
        .szTip            = "Luke's IRC Client"
        '.szInfoTitle      = ""
        '.szInfo           = ""
      End With
      ran = 1
   EndIf

#EndIf

End Sub

Sub LIC_Screen_INIT( )

#Ifdef LIC_NO_GFX
   ScreenRes Global_IRC.Global_Options.ScreenRes_x, Global_IRC.Global_Options.Screenres_y, 8, , fb.GFX_NULL
   Screen 0, 8
   Exit Sub
#EndIf

#Ifdef __FB_WIN32__
   If ( Global_IRC.Global_Options.MinimizeToTray <> 0 ) and ( Global_IRC.HWND <> 0 ) then
      Shell_NotifyIcon( NIM_DELETE, @NID )
   EndIf
   select case Global_IRC.Global_Options.ScreenDriver
   case ScreenDrivers.DirectX
      ScreenControl( fb.SET_DRIVER_NAME, "DirectX" )
   case ScreenDrivers.OpenGL
      '!!!FIXME!!!
   case else
      'default
      ScreenControl( fb.SET_DRIVER_NAME, "GDI" )      
   End Select   
#EndIf

   ScreenRes Global_IRC.Global_Options.ScreenRes_x, Global_IRC.Global_Options.Screenres_y, Global_IRC.Global_Options.BitDepth, , fb.GFX_NO_SWITCH or iif( Global_IRC.Global_Options.AlwaysOnTop <> 0, fb.GFX_ALWAYS_ON_TOP, 0 )
   Width Global_IRC.Global_Options.ScreenRes_x \ 8, Global_IRC.Global_Options.ScreenRes_y \ 16
   ScreenControl( GET_WINDOW_HANDLE, Global_IRC.HWND )

   if Global_IRC.Global_Options.BitDepth = 8 then

     dim as integer R, G, B, CNT, RR, GG, BB

     for R = 0 to 7
       for G = 0 to 7
         for B = 0 to 3
           RR = cint(R*36.43):GG = cint(G*36.43):BB = cint(B*75)
           Palette CNT,RR, GG, BB
           CNT += 1
         next B
       Next G
     next R

   EndIf

#Ifdef __FB_WIN32__
   'This is a Mix of D.J Peters' and Zippy's code from the forum ( and help from Mysoft )
   'I had to take a bit of each to finally figure out a way to do what I wanted
   'It allows you to minimize to tray without having it on the taskbar when active =]
   #define _Hwnd Cast( HWND, Global_IRC.HWND )
   If ( Global_IRC.Global_Options.HideTaskbar <> 0 ) and ( Global_IRC.Global_Options.MinimizeToTray <> 0 ) then
      SetWindowLongPtr(_Hwnd,GWLP_HWNDPARENT, cptr( LONG_PTR, GetDesktopWindow())) ' Mysoft Magic, this hides it from the taskbar
      SetWindowPos(_Hwnd,0,0,0,0,0,SWP_NOSIZE Or SWP_NOMOVE)
   EndIf

   If Global_IRC.Global_Options.MinimizeToTray <> 0 Then
      OldWindowProc = cptr(WNDPROC,SetWindowLongPtr(_Hwnd,GWLP_WNDPROC,cptr(LONG_PTR,@NewWindowProc)))
      LIC_TrayRegenerate( )
   EndIf
#else
   dim as XClassHint xch = ( @IRC_Version_name, @"LIC" )
   XSetClassHint( fb_x11.display, fb_x11.wmwindow, @xch )
#EndIf

   dim as integer ULW = iif( Global_IRC.CurrentRoom = 0, Global_IRC.Global_Options.DefaultUserListWidth, Global_IRC.CurrentRoom->UserListWidth )

   ChatInput.x1 = ULW + 12
   ChatInput.y1 = Global_IRC.Global_Options.ScreenRes_Y - 16
   ChatInput.x2 = Global_IRC.Global_Options.ScreenRes_X
   ChatInput.y2 = Global_IRC.Global_Options.ScreenRes_Y
   ChatInput.BackGroundColour = Global_IRC.Global_Options.BackGroundColour
   ChatInput.ForeGroundColour = Global_IRC.Global_Options.YourChatColour
   
   Draw String ( ULW + 2, Global_IRC.Global_Options.ScreenRes_y - 16 ), ">", Global_IRC.Global_Options.YourChatColour

   Global_IRC.TextInfo.GetSizes( )

End Sub

#ifdef __FB_WIN32__

Function NewWindowProc _
   ( _
      Byval hWin     As HWND, _
      Byval Msg      As Uinteger, _
      Byval wParam   As WPARAM, _
      Byval lParam   As LPARAM _
   ) As LRESULT

   Select Case Msg

      Case WM_SYSCOMMAND

         if wParam = SC_MINIMIZE then
            If Global_IRC.Global_Options.HideTaskbar <> 0 Then
               SetWindowLongPtr( hWin,GWLP_HWNDPARENT, NULL )
            endif
            ShowWindow(hWin, SW_HIDE)
            Return FALSE
         End if

      Case WM_USER + 1

         if lParam = WM_LBUTTONDOWN then
            If IsWindowVisible(hWin) = FALSE then
               ShowWindow (hWin, SW_SHOW)
               If Global_IRC.Global_Options.HideTaskbar <> 0 Then
                  SetWindowLongPtr( hWin,GWLP_HWNDPARENT, cptr( LONG_PTR, GetDesktopWindow( ) ))
               EndIf
               SetForegroundWindow( hWin )
            Else
               If Global_IRC.Global_Options.HideTaskbar <> 0 Then
                  SetWindowLongPtr( hWin,GWLP_HWNDPARENT, NULL )
               EndIf
               ShowWindow(hWin, SW_HIDE)
            EndIf
         End If

#if 0 'Not Working?

      Case WM_QUERYENDSESSION
         beep
         LIC_DEBUG( "WM_QUERYENDSESSION" )
         return 1

      case WM_ENDSESSION
         
         LIC_DEBUG( "WM_ENDSESSION" )
         
         If wParam <> 0 Then
            LIC_DEBUG( "WM_ENDSESSION2" )
            'MutexLock( Global_IRC.Mutex )
            *Global_IRC.Shutdown = 1
            'MutexunLock( Global_IRC.Mutex )
            sleep( 1000, 1 )
         EndIf
         return 1
         
#endif

  End Select

  Function = OldWindowProc(hWin, Msg, wParam, lParam)

End Function

#EndIf

Sub LIC_Notify( ByRef Highlight As Integer = 0 )

   #ifdef __FB_WIN32__

   With Global_IRC.Global_Options

   If ( .HideTaskbar = 0 ) Or ( .MinimizeToTray = 0 ) then
      Dim As FLASHWINFO fwinfo = ( sizeof(FLASHWINFO), Cast( HWND, Global_IRC.HWND ), 2, 3 )
      FlashWindowEx( @fwinfo )
   EndIf

   If ( Highlight = 2 ) Then
      if len_hack( .NotifySound ) > 0 then PlaySound( .NotifySound, NULL, SND_FILENAME Or SND_NODEFAULT )
   EndIf

   If .MinimizeToTray = 1 Then

      MutexLock( TrayMutex )

      If ( Tray_Flash_ON <> 0 ) And ( HighLight <> 0 ) And ( Swapped_Icon = 0 ) Then
         Tray_Flash_STOP = 1
         if TrayThread <> 0 then
            MutexUnLock( TrayMutex )
            ThreadWait( TrayThread )
            TrayThread = 0
            MutexLock( TrayMutex )
         end if         
         Swap Tray_Icon(3), Tray_Swap
         Swapped_Icon = 1
         Tray_Flash_Visible = 0
      ElseIf ( HighLight <> 0 ) And ( Swapped_Icon = 0 ) Then
         Swap Tray_Icon(3), Tray_Swap
         Swapped_Icon = 1
         Tray_Flash_Visible = 0
      EndIf

      If Tray_Flash_Visible = 0 Then
         Tray_Flash_Visible = 1
         Tray_Flash_STOP = 0
         if TrayThread <> 0 then
            MutexUnLock( TrayMutex )
            ThreadWait( TrayThread )            
            MutexLock( TrayMutex )
         EndIf
#if 0 
         TrayThread = ThreadCreate( CPtr( Any Ptr, ProcPtr( TrayFlashThread ) ), ,4 * 1024 )
#else
   'fb's threadcreate crashes beginning with fbc 0.24, I think it's something to do with the TLS
   'i'm not quite sure whats going on but this seems to fix it, or atleast be a suitable workaround
         dim as FBTHREAD ptr thread = allocate( sizeof( FBTHREAD ) )
         thread->proc = ProcPtr( TrayFlashThread )
         thread->id = CreateThread( NULL, 4 * 1024, cast( LPTHREAD_START_ROUTINE, @TrayFlashThread ), NULL, 0, NULL )
         TrayThread = thread
#endif
      EndIf
      
      MutexUnLock( TrayMutex )

   EndIf

   End with

   #Else
   
   if Highlight = 0 then
      Global_IRC.PrependTitle or= PrependStar
   else
      Global_IRC.PrependTitle or= PrependAt
   end if

   Dim As String WinTitle
   ScreenControl( GET_WINDOW_TITLE, WinTitle )

   For i As Integer = 1 To 5
      If ( ScreenEvent <> 0 ) Or ( Pending_Message <> 0 ) Then Exit For
      WindowTitle WinTitle
      sleep( 500, 1 )
      If ( ScreenEvent <> 0 ) Or ( Pending_Message <> 0 ) Then Exit For
      WindowTitle "@ @@ @@@ @@@@ @@@ @@ @"
      sleep( 500, 1 )
   Next

   UpdateWindowTitle( )

   #EndIf

End Sub

#ifdef __FB_WIN32__

Sub TrayFlashThread( )
   Dim As Integer c
   MutexLock( TrayMutex )
   Tray_Flash_ON = 1
   While c < 25
      For i As Integer = -2 To 3
         NID.hIcon = Tray_Icon( Abs( i ) )
         Shell_NotifyIcon( NIM_MODIFY, @nid )
         If Tray_Flash_STOP = 1 Then Exit While
         MutexUnLock( TrayMutex )
         SleepEx(100,1)
         MutexLock( TrayMutex )
      Next
      c += 1
   Wend
   Tray_Flash_ON = 0
   MutexUnLock( TrayMutex )
   fb_TlsFreeCtxTb() 'this fixes a crash with the trayflash thread
End Sub

#EndIf

Sub LIC_TrayFlash_STOP( )

#ifdef __FB_WIN32__
   If Global_IRC.Global_Options.MinimizeToTray <> 0 Then
      MutexLock( TrayMutex )
      If Tray_Flash_ON = 1 Then
         Tray_Flash_STOP = 1
         MutexUnLock( TrayMutex )
         ThreadWait( TrayThread )
         TrayThread = 0
         MutexLock( TrayMutex )
      EndIf
      NID.hIcon = Tray_Icon(0)
      Shell_NotifyIcon( NIM_MODIFY, @nid )
      If Swapped_Icon = 1 Then
         Swap Tray_Icon(3), Tray_Swap
         Swapped_Icon = 0
      EndIf
      Tray_Flash_Visible = 0
      MutexUnLock( TrayMutex )
   EndIf
#EndIf

End Sub

Sub LIC_TrayShutdown( )

#ifdef __FB_WIN32__
   MutexLock( TrayMutex )
   If Tray_Flash_ON = 1 Then
      Tray_Flash_STOP = 1
      MutexUnLock( TrayMutex )
      ThreadWait( TrayThread )
      TrayThread = 0
   Else
      MutexUnLock( TrayMutex )
   EndIf
   MutexDestroy( TrayMutex )
   If Global_IRC.Global_Options.MinimizeToTray <> 0 then
      Shell_NotifyIcon( NIM_DELETE, @NID )
   EndIf
#EndIf

End Sub

Sub LIC_TrayRegenerate( )

#ifdef __FB_WIN32__
   
   MutexLock( TrayMutex )
   NID.hWnd = Cast( HWND, Global_IRC.HWND )
   Shell_NotifyIcon( NIM_ADD, @NID )
   MutexUnLock( TrayMutex )
   
#endif

End Sub