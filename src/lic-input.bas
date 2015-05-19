#define LIC_WIN_INCLUDE
#Include Once "lic-input.bi"
#Include once "fbgfx.bi"
#ifdef __LIC__
   #include once "lic.bi"
#elseif defined( __FB_WIN32__ )
   #include once "windows.bi"
#endif
#ifndef len_hack
   #define len_hack(s_) cptr( integer ptr, @s_ )[1]
#endif

Using fb

Sub FBGFX_CHARACTER_INPUT.Parse _
   ( _
      ByRef _Input	As long, _
      ByRef ASCII		As long = 0 _
   )

   If MultiKey( SC_CONTROL ) Then
      
      if Multikey( SC_ALT ) then 'ALT-GR
         if this.KeyboardLayout = KB_French then
            select case _Input
               case 3: this &= "~"
               case 4: this &= "#"
               case 5: this &= "{"
               case 6: this &= "["
               case 7: this &= "|"
               case 8: this &= "`"
               case 9: this &= "\"
               case 10: this &= "^"
               case 11: this &= "@"
               case 18: this &= chr( 128 ) 'Euro sign
               case else
                  'LIC_DEBUG( "\\AltGr + " & _input )
            End Select
         endif
         
      elseIf ASCII = 0 then      

         Select Case _Input
            Case SC_V 'Pase
               this &= GetClipboardAsString( )
            case SC_C 'Copy
               if SelectionLength > 0 then
                  CopyToClipboard( mid( _Text, SelectionStart + 1, SelectionLength ) )
               endif
            case SC_X 'Cut
               if SelectionLength > 0 then
                  CopyToClipboard( mid( _Text, SelectionStart + 1, SelectionLength ) )
                  _Text = Left( _Text, SelectionStart ) & Mid( _Text, SelectionStart + SelectionLength + 1 )
                  Carat = SelectionStart
                  SelectionLength = 0
               EndIf
         End Select
         
         if (this.OptionFlags AND Disable_EMAC_Controls) = 0 then

            select case _Input
            
            case 30 'ctrl-a Move cursor to beginning of line
               SelectionLength = 0
               Carat = 0
               
            case 18 'ctrl-e Move cursor to end of line
               SelectionLength = 0
               Carat = Len_hack( _Text )
               
            case 17 'ctrl-w Cut the last word
               Carat = InstrRev( _Text, " " )
               if Carat = Len_Hack( _Text ) and Len_hack( _Text ) > 1 then
                  Carat = InstrRev( _Text, " ", Carat - 1 )
               EndIf
               if Carat >= 0 then
                  CopyToClipBoard( mid( _Text, Carat + 1 ) )
                  _Text = left( _Text, Carat )
               else
                  Carat = 0
               endif
               
            case 22 'ctrl-u Cut everything before the cursor
               CopyToClipBoard( left( _Text, Carat ) )
               _Text = mid( _Text, Carat + 1 )
               Carat = 0
               
            case 37 'ctrl-k Cut everything after the cursor
               CopyToClipBoard( mid( _Text, Carat + 1 ) )
               _Text = left( _Text, Carat )
               Carat = Len_Hack( _Text )
               
            case 21 'ctrl-y Paste the last thing to be cut
               this &= GetClipboardAsString( )                
            
            End Select
         
         EndIf
         
      EndIf

   Else

      If ASCII = 0 then
         Select Case _Input
            Case SC_LEFT
               If Carat > 0 Then
                  If Multikey( SC_LSHIFT ) Or Multikey( SC_RSHIFT ) Then
                     If Carat = SelectionStart Then
                        SelectionLength += 1
                        SelectionStart -= 1
                     ElseIf Carat = SelectionStart + SelectionLength then
                        SelectionLength -= 1
                     Else
                        SelectionStart = Carat - 1
                        SelectionLength = 1
                     EndIf
                  Else
                     SelectionLength = 0
                  EndIf
                  Carat -= 1
               Else
                  If Not( Multikey( SC_LSHIFT ) Or Multikey( SC_RSHIFT ) ) Then
                     SelectionLength = 0
                  endif
               EndIf
            Case SC_RIGHT
               If Carat < Len_hack( _Text ) Then
                  If Multikey( SC_LSHIFT ) Or Multikey( SC_RSHIFT ) Then
                     If Carat = SelectionStart + SelectionLength Then
                        SelectionLength += 1
                     ElseIf Carat = SelectionStart then
                        SelectionStart = Carat + 1
                        SelectionLength -= 1
                     Else
                        SelectionStart = Carat
                        SelectionLength = 1
                     EndIf
                  Else
                     SelectionLength = 0
                  EndIf
                  Carat += 1
               Else
                  If Not( Multikey( SC_LSHIFT ) Or Multikey( SC_RSHIFT ) ) Then
                     SelectionLength = 0
                  endif
               EndIf
            Case SC_UP, SC_DOWN
               For i As Integer = 1 To UBound( InputString ) + 1
                  if _Input = SC_DOWN then
                     If InputCounter = InputBrowser Then
                        Exit For
                     endif
                  else
                     If ( InputCounter = UBound( InputString ) And InputBrowser = 0 ) Or ( InputCounter = InputBrowser - 1 ) Then
                        Exit For
                     EndIf
                  EndIf
                  InputBrowser += IIf( _Input = SC_UP, -1, 1 )
                  If Len( InputString( InputBrowser ) ) > 0 Then Exit For
               Next
               _Text = InputString( InputBrowser )
               Carat = Len_hack( _Text )
               SelectionStart = 0
               SelectionLength = 0
               TextOffset = 0
            Case SC_DELETE
               If SelectionLength Then
                  _Text = Left( _Text, SelectionStart ) & Mid( _Text, SelectionStart + SelectionLength + 1 )
                  Carat = SelectionStart
               Else
                  If Carat < Len_hack( _Text ) Then
                     _Text = Left( _Text, Carat ) & Mid( _Text, Carat + 2 )
                  EndIf
               endif
               SelectionLength = 0
            Case SC_BACKSPACE
               If SelectionLength Then
                  _Text = Left( _Text, SelectionStart ) & Mid( _Text, SelectionStart + SelectionLength + 1 )
                  Carat = SelectionStart
               else
                  If Carat > 0 Then
                     _Text = Left( _Text, Carat - 1 ) & Mid( _Text, Carat + 1 )
                     Carat -= 1
                  EndIf
               endif
               SelectionLength = 0
            Case SC_HOME
               if Multikey( SC_LSHIFT ) Or Multikey( SC_RSHIFT )then
                  SelectionStart = 0
                  SelectionLength = Carat
               else
                  SelectionLength = 0
               endif
               Carat = 0
            Case SC_END
               if Multikey( SC_LSHIFT ) Or Multikey( SC_RSHIFT ) then
                  SelectionStart = Carat
                  SelectionLength = len_hack( _Text ) - Carat
               else
                  SelectionLength = 0
               endif
               Carat = Len_hack( _Text )
            
            End Select

      Else
         If SelectionLength Then
            _Text = Left( _Text, SelectionStart ) & Chr( _Input ) & Mid( _Text, SelectionStart + SelectionLength + 1 )
            Carat = SelectionStart + 1
         Else
            if Carat = len_hack( _Text ) then
               _Text += chr( _Input )
            else
               _Text = Left( _Text, Carat ) & Chr( _Input ) & Mid( _Text, Carat + 1 )
            EndIf
            Carat += 1
         EndIf
         SelectionLength = 0
      EndIf

   EndIf

   If SelectionLength = 0 Then SelectionStart = 0
   CenterCarat( )

End Sub

Sub FBGFX_CHARACTER_INPUT.CenterCarat( )

   dim MaxDisplayedCharacters As Integer = ( x2 - x1 ) \ 8

   if len_hack( _Text ) <= MaxDisplayedCharacters then
      TextOffset = 0
   elseif Carat <= TextOffset then
      TextOffset = Carat - 4
      if TextOffset < 0 then
         TextOffset = 0
      EndIf
   elseif Carat >= ( TextOffset + MaxDisplayedCharacters ) then
      TextOffset = Carat - MaxDisplayedCharacters + 4
      if len_hack( _Text ) < ( TextOffset + MaxDisplayedCharacters ) then
         TextOffset = len_hack( _Text ) - MaxDisplayedCharacters
      EndIf
   EndIf

End Sub

Sub FBGFX_CHARACTER_INPUT.Print

   ScreenLock
   view ( x1, y1 )-( x2, y2 ), BackGroundColour

   Draw String ( 1, 0 ), Mid( _text, TextOffset + 1 ), ForeGroundColour

   If SelectionLength > 0 Then

      dim as string msg
      Dim As Integer StartY = 1 + ( SelectionStart - TextOffset ) * 8
      dim as integer L

      If StartY < 1 Then StartY = 1

      if SelectionStart >= TextOffset then
         L = SelectionLength
         msg = mid( _Text, SelectionStart + 1, L )
      else
         L = SelectionLength - TextOffset
         msg = mid( _Text, TextOffset + 1, L )
      endif

      Line ( StartY, 0 ) - Step( L * 8 - 1, 16 ), ForeGroundColour, BF
      Draw String ( StartY, 0 ), msg, BackGroundColour

   EndIf

   ScreenUnLock
   view

End Sub

Sub FBGFX_CHARACTER_INPUT.MouseDown( ByVal X As Integer )

   Dim as integer oldmouse_x, StartPoint, ShiftMod, nx, ExitDo, c
   Dim as integer max_x = ( Len_hack( _Text ) - TextOffset ) * 8 + x1

   If ( X < x1 ) Or ( X > x2 ) Then Exit Sub

   X -= ( x1 + X ) Mod 8

   If max_x > x2 Then max_x = x2
   If X > max_x  Then X = max_x

   if multikey( SC_LSHIFT ) or multikey( SC_RSHIFT ) then
      if SelectionLength = 0 then
         StartPoint = Carat
      else
         if Carat = SelectionStart then
            StartPoint = Carat + SelectionLength
         else
            StartPoint = SelectionStart
         EndIf
      endif
      ShiftMod = TRUE
      nx = X
   else
      StartPoint = TextOffset + ( X - x1 ) \ 8
      SelectionLength = 0
      nx = X
   EndIf

   dim as fb.event E

   Do until exitdo

      while screenevent( @E )
         select case E.Type
            case EVENT_MOUSE_MOVE
               nx = cshort( e.x )

               If nx < x1 Then
                  nx = x1
               ElseIf nx > max_x Then
                  nx = max_x
               EndIf

            case EVENT_MOUSE_BUTTON_RELEASE

               ExitDo = TRUE

         End Select
      Wend

#ifdef __LIC__
      MutexUnLock( Global_IRC.Mutex )
      sleep( 26, 1 )
      MutexLock( Global_IRC.Mutex )
      c += 1
      if c > 10 then
         c = 0
         LIC_Main( )
      endif
#else
      sleep( 26, 1 )
#endif

      if oldmouse_x <> nx then

         oldmouse_x = nx

         var ss = SelectionStart
         var sl = SelectionLength

         if ShiftMod then

            SelectionStart = StartPoint
            SelectionLength = ( nx - x1 - ( StartPoint - TextOffset ) * 8 ) \ 8

            if SelectionLength < 0 then
               SelectionStart += SelectionLength
               SelectionLength *= -1
               Carat = SelectionStart
            else
               Carat = SelectionStart + SelectionLength
            EndIf
            if SelectionStart + SelectionLength > len_hack( _Text ) then
               SelectionLength = len_hack( _Text ) - SelectionStart
            EndIf

         else

            If nx > X then
               Carat = TextOffset + ( nx - x1 ) \ 8
               SelectionStart = TextOffset + ( X - x1 ) \ 8
               SelectionLength = ( nx - X ) \ 8
            Else
               Carat = TextOffset + ( X - x1 ) \ 8
               SelectionStart = TextOffset + ( nx - x1 ) \ 8
               SelectionLength = Carat - SelectionStart
            endif

            if SelectionLength = 0 then
               Carat = TextOffset + abs( X - x1 + 1 ) \ 8
            elseif oldmouse_x < X then
               Carat = SelectionStart
            EndIf

         EndIf

         if ( ss <> SelectionStart ) or ( sl <> SelectionLength ) then
            this.Print( )
         endif

      endif

   Loop

   If SelectionLength = 0 Then SelectionStart = 0

   If Carat > Len_hack( _Text ) Then Carat = Len_hack( _Text )

End Sub

Sub FBGFX_CHARACTER_INPUT.CursorBlink

   Static As integer s, c
   Static as double t, t2

   t = timer - t2

   if ( t < 0.65 ) or ( c <> Carat ) then

      if ( s = 0 ) or ( c <> Carat ) then
         Line ( x1 + ( Carat - TextOffset ) Shl 3, y1 ) - Step( 0, 16 ), ForeGroundColour
         c = Carat
         s = 1
         t2 = timer
      EndIf

   elseif s = 1 then

      Line ( x1 + ( Carat - TextOffset ) Shl 3, y1 ) - Step( 0, 16 ), BackGroundColour
      s = 0

   elseif t > 1 then

      t2 = timer

   endif

End Sub

Property FBGFX_CHARACTER_INPUT.Length( ) As uInteger
   Property = Len_hack( _Text )
End Property

Operator FBGFX_CHARACTER_INPUT.Cast( ) As String
   Operator = _Text
End Operator

Sub FBGFX_CHARACTER_INPUT.Set( ByRef _RHS As String )

   InputString( InputCounter ) = _Text

   InputCounter += 1

   InputString( InputCounter ) = _RHS

   InputBrowser = InputCounter

   _Text = _RHS

   Carat = Len_hack( _Text )

   SelectionStart = 0
   SelectionLength = 0
   TextOffset = 0

End Sub

Operator FBGFX_CHARACTER_INPUT.&= ( ByRef _RHS As ZString Ptr )

   var OLen = len_hack( _Text )

   If SelectionLength Then

      _Text = _
         Left( _Text, SelectionStart ) & _
         *_RHS & _
         Mid( _Text, SelectionStart + SelectionLength + 1 )

      Carat = SelectionStart + ( len_hack( _Text ) - OLen )

   Else
      _Text = Left( _Text, Carat ) & *_RHS & Mid( _text, Carat + 1 )
      Carat += ( len_hack( _Text ) - OLen )
   EndIf

   SelectionLength = 0
   SelectionStart = 0
   CenterCarat( )

End Operator

Sub FBGFX_CHARACTER_INPUT.Custom_ASCII( ByVal Scancode As Integer )

   Dim EX_ASCII 			As String
   Dim E 					As Event

   Dim Sc_array( 9 ) 	As integer => _
      { _
         SC_INSERT, _
         SC_END, _
         SC_DOWN, _
         SC_PAGEDOWN, _
         SC_LEFT, _
         &h4C, _ 'NumPad 5
         SC_RIGHT, _
         SC_HOME, _
         SC_UP, _
         SC_PAGEUP _
      }

#ifdef __FB_WIN32__
   Sc_array( 5 ) = 0 'fb bug with scancode
#endif

   For i As Integer = 0 To 9
      If Scancode = SC_Array(i) Then
         Ex_ASCII = Str( i )
         Exit For
      EndIf
   Next

   While MultiKey( SC_ALT )

      do while ScreenEvent( @E )
         Select Case e.type
            Case EVENT_KEY_RELEASE
               if e.scancode = SC_ALT then
                  exit while
               EndIf
               For i As Integer = 0 To 9
                  If e.scancode = SC_array(i) Then
                     Ex_ASCII &= i
                     Exit For
                  EndIf
               Next
               
               #if 0 'not sure if i want this or not (also not working)
               if (this.OptionFlags AND Disable_EMAC_Controls) = 0 then
                  var emac = 0
                  select case e.scancode
                  
                  case 48 'meta-b Move cursor back one word
                     Carat = InstrRev( _Text, " ", Carat - 1 )
                     emac = 1
                  
                  case 33 'meta-f Move cursor forward one word
                     Carat = Instr( Carat + 1, _Text, " " )
                     emac = 1
                     
                  end select
                  if emac then
                     SelectionLength = 0
                     SelectionStart = 0
                     CenterCarat( )
                     exit sub
                  EndIf
               endif
               #endif
         End Select
      loop

#ifdef __LIC__
      MutexUnLock( Global_IRC.Mutex )
      sleep( 26, 1 )
      MutexLock( Global_IRC.Mutex )
      LIC_Main( )
#else
      sleep( 1, 1 )
#endif

   Wend

   this &= Chr( valInt( Ex_ASCII ) )

End Sub

Constructor FBGFX_CHARACTER_INPUT _
   ( _
      ByRef inx1 		As Integer	= -1, _
      ByRef iny1 		As Integer	= -1, _
      ByRef inx2 		As Integer	= -1, _
      ByRef iny2 		As Integer	= -1, _
      ByRef BGC 		As uInt32_t	= 1, _
      ByRef FGC 		As uInt32_t	= 1  _
   )

   If inx1 <> -1 Then x1 = inx1
   If iny1 <> -1 Then y1 = iny1
   If inx2 <> -1 Then x2 = inx2
   If iny2 <> -1 Then y2 = iny2

   if x1 > x2 then swap x1, x2
   if y1 > y2 then swap y1, y2

   If BGC <> 1 Then BackGroundColour = BGC
   If FGC <> 1 Then ForeGroundColour = FGC

End Constructor

Destructor FBGFX_CHARACTER_INPUT

   _Text = ""
   For i As Integer = 0 To UBound( InputString )
      InputString(i) = ""
   Next

End Destructor

'Got the two windows clipboard functions from the FreeBASIC forum
'The linux ones pipe xclip

Function GetClipboardAsString( ) As String

#Ifdef __FB_WIN32__

   Dim As ZString ptr 	s_ptr
   Dim As HANDLE 			hglb
   Dim As String 			s = ""

   If( IsClipboardFormatAvailable(CF_TEXT) = 0 ) Then Return s

   If OpenClipboard( NULL ) <> 0 Then
      hglb = GetClipboardData( cf_text )
      s_ptr = GlobalLock( hglb )
      If ( s_ptr <> NULL ) Then
         s = *s_ptr
         GlobalUnlock( hglb )
      End If
      CloseClipboard( )
   End If

   Function = s

#else

   dim s 	as String
   Dim t 	As String
   Dim ff 	As Integer = FreeFile

   if Open pipe ( "xclip -o -selection c" For input As #ff ) = 0 then

      do
         line input #ff, t
         s += t & NewLine
      loop until eof( ff )

      Close #ff

      #ifdef RTrim2
         RTrim2( s, !"\r\n", TRUE )
         Function = s
      #else
         Function = rtrim( s, any !"\r\n" )
      #endif

   EndIf

#endif

End Function

Function CopyToClipboard(ByRef x As String) As Integer

   Function = FALSE

   #Ifdef __FB_WIN32__

   Dim As HANDLE hText = NULL
   Dim As UByte ptr clipmem = NULL
   Dim As Integer n = Len(x)
   If n > 0 Then
     hText = GlobalAlloc(GMEM_MOVEABLE Or GMEM_DDESHARE, n + 1)
     sleep( 15, 1 )
     If (hText) Then
         clipmem = GlobalLock(hText)
         If clipmem Then
             CopyMemory(clipmem, StrPtr(x), n)
         Else
             hText = NULL
         End If
         If GlobalUnlock(hText) Then
             hText = NULL
         End If
     End If
     If (hText) Then
         If OpenClipboard(NULL) Then
             sleep( 15, 1 )
             If EmptyClipboard( ) Then
                 sleep( 15, 1 )
                 If SetClipboardData(CF_TEXT, hText) Then
                     sleep( 15, 1 )
                     Function = TRUE
                 End If
             End If
             CloseClipboard( )
         End If
     End If
   End If

#else

   dim as integer ff = freefile

   if open pipe ( "xclip -selection c" for output as #ff ) = 0 then

      put #ff, ,x
      close #ff
      Function = TRUE

   EndIf

#endif

End Function
