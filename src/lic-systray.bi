#Ifdef __FB_WIN32__

   Declare Function NewWindowProc( Byval hWin As HWND, _
                                   Byval Msg As Uinteger, _
                                   Byval wParam As WPARAM, _
                                   Byval lParam As LPARAM ) _
                                   As LRESULT

type FBTHREAD
   as HANDLE id
   as any ptr proc
   as any ptr param
   as any ptr op
end type

#EndIf

Declare Sub LIC_TrayFlash_STOP( )
Declare Sub LIC_TrayShutdown( )
Declare Sub LIC_TrayInit( )
Declare Sub LIC_TrayRegenerate( )
declare Sub TrayFlashThread( )


