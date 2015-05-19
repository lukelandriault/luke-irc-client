#Include "lic.bi"

Using fb

Extern ChatInput As FBGFX_CHARACTER_INPUT

Sub LIC_Event_Mouse_Release( ByRef G As gui_event ptr )

if G->y <= 20 then
   
   if G->button = BUTTON_LEFT then
      Global_IRC.ClickTabs( G->X )
   endif

elseif G->X <= Global_IRC.CurrentRoom->UserListWidth - 8 then

   if ( Global_IRC.CurrentRoom->NumUsers = 0 ) then Exit Sub

   var UNT = Global_IRC.CurrentRoom->TopDisplayedUser

   if ( G->Button = BUTTON_LEFT ) or ( Global_IRC.CurrentRoom->RoomType = Channel ) then
      for i as integer = 1 to ( ( G->Y - 21 ) \ Global_IRC.TextInfo.UserListCharSizeY )
         if UNT->NextUser <> 0 then
            UNT = UNT->NextUser
         else
            Exit Sub
         EndIf
      Next
   endif

   if Global_IRC.CurrentRoom->RoomType = RoomTypes.List then

      if G->Button = BUTTON_LEFT then 'Print Room info

         var s = InStrASM( 1, UNT->UserName, asc(" ") )
         var s2 = InStrASM( s + 1, UNT->UserName, asc("]") )

         dim as LOT_MultiColour_Descriptor MCD = ( s + 4, s2 - s, Global_IRC.Global_Options.JoinColour )

         Global_IRC.CurrentRoom->AddLOT( "** " & UNT->UserName, Global_IRC.Global_Options.TextColour, , Notification, , @MCD, TRUE )

      'elseif G->Button = BUTTON_RIGHT then 'Sort the list


      endif

   elseif Global_IRC.CurrentRoom->RoomType = RoomTypes.Channel then

      if G->Button = BUTTON_LEFT then 'Change colour
         var oc = UNT->ChatColour
                     
         UNT->ChatColour = rndColour( Global_IRC.DarkUsers )
         while UNT->ChatColour = Global_IRC.Global_Options.YourChatColour
            UNT->ChatColour = rndColour( Global_IRC.DarkUsers )
         Wend
         Global_IRC.CurrentRoom->PrintUserList( TRUE )
         
         #define RGB_R( c ) ( CUInt( c ) Shr 16 And 255 )
         #define RGB_G( c ) ( CUInt( c ) Shr  8 And 255 )
         #define RGB_B( c ) ( CUInt( c )        And 255 )
         
         #define nc UNT->ChatColour
         LIC_DEBUG( "\\Color1:" & RGB_R(oc) & ":" & RGB_G(oc) & ":" & RGB_B(oc) & " Color2:" & RGB_R(nc) & ":" & RGB_G(nc) & ":" & RGB_B(nc) ) 
      endif

   EndIf

elseif G->Y <= ( Global_IRC.Global_Options.ScreenRes_y - 18 ) then
   
   Dim As UserRoom_Type Ptr URT = Global_IRC.CurrentRoom
   dim as integer CharSizeY = iif( URT->RoomType = RawOutput, 16, Global_IRC.TextInfo.ChatBoxCharSizeY )
   Dim As Integer TextPos_y = ( Global_IRC.Global_Options.ScreenRes_y - G->Y - 16 ) \ CharSizeY
   #if 1=2

   If ( TextPos_y > (URT->CurrentLine+1) ) or (( CInt(URT->CurrentLine) - TextPos_y - 1 ) < 0 ) Then
      Exit Sub
   EndIf

   Dim As LineOfText Ptr LOT = URT->TextArray[ URT->CurrentLine - TextPos_y - 1 ]
   
   #else
      
   Dim As LineOfText Ptr LOT = GetLOT( G->Y )
       
   #endif
   
   
   If LOT = 0 Then Exit Sub

   Dim As LOT_HyperLinkBox Ptr HLB = LOT->HyperLinks
   Dim As Integer DummyX, offsetX = Global_IRC.CurrentRoom->UserListWidth + 4

   If ( LOT->MesID And 1 ) Then
      offsetX += 20
   Else
      If ( Global_IRC.Global_Options.ShowTimeStamp <> 0 ) and ( LOT->MesID < 50 ) Then
         offsetX += CWidth( LOT->TimeStamp )
      endif
   EndIf
   If G->Button = BUTTON_LEFT Then
      while HLB <> 0
         If ( HLB->X1 + offsetX <= G->X ) And ( HLB->X2 + offsetX >= G->X ) Then
            select case HLB->ID

            case LinkChannel
               Global_IRC.CurrentRoom->Server_Ptr->SendLine( "JOIN " & HLB->HyperLink )

            case LinkWeb, LinkShell

               var link_ = HLB->HyperLink

               #Ifdef __FB_WIN32__

                  'The ampersand (&), pipe (|), and parentheses ( ) are special characters
                  'that must be preceded by the escape character (^)

                  link_ = String_Replace( "^", "^^", link_ )
                  link_ = String_Replace( "&", "^&", link_ )
                  link_ = String_Replace( "|", "^|", link_ )
                  link_ = String_Replace( "(", "^(", link_ )
                  link_ = String_Replace( ")", "^)", link_ )

                  link_ = "Start /B " & link_
                  Shell( link_ )

               #Else

                  'characters ", $, `, and \ are still interpreted by the shell,
                  'even when they're in double quotes.

                  link_ = String_Replace( "\",  "\\",  link_ )
                  link_ = String_Replace( """", "\""", link_ )
                  link_ = String_Replace( "$",  "\$",  link_ )
                  link_ = String_Replace( "`",  "\`",  link_ )

                  if ucase( left( HLB->HyperLink, 3 ) ) = "WWW" then
                     'xdg-open doesn't like www without http://
                     link_ = "http://" + link_
                  end if

                  'link_ = Global_IRC.Global_Options.BrowserPath & " """ & link_ & """ > /dev/null 2>&1 &"
                  'get rid of BrowserPath ?
                  link_ = "xdg-open """ & link_ & """ > /dev/null 2>&1"
                  forkexec( link_ )

               #EndIf

            End Select

            Exit while

         EndIf
         HLB = HLB->NextLink
      Wend
   ElseIf G->Button = BUTTON_RIGHT then
      Dim As String ToClipBoard
      If MultiKey( SC_LSHIFT ) Or MultiKey( SC_RSHIFT ) Then
         ToClipBoard = GetClipboardAsString( ) & NewLine
      endif
      While ( (URT->TextArray[ URT->CurrentLine - TextPos_y - 1 ]->MesID And 1) <> 0 ) and ( URT->CurrentLine - TextPos_y > 1 )
         TextPos_y += 1
      Wend
      If ( Global_IRC.Global_Options.ShowTimeStamp <> 0 ) and ( URT->TextArray[ URT->CurrentLine - TextPos_y - 1 ]->MesID < 50 ) then
         ToClipBoard &= URT->TextArray[ URT->CurrentLine - TextPos_y - 1 ]->TimeStamp
      endif
      Do
         ToClipBoard &= URT->TextArray[ URT->CurrentLine - TextPos_y - 1 ]->Text
         If URT->CurrentLine - TextPos_y = URT->NumLines Then Exit Do
         TextPos_y -= 1
         if ( URT->TextArray[ URT->CurrentLine - TextPos_y - 1 ]->MesID and 1 ) = 0 then
            Exit Do
         EndIf
      Loop
      if len_hack( ToClipBoard ) > 0 then
         CopyToClipboard( ToClipBoard )
      EndIf
   endif

#ifdef __FB_LINUX__ 
else 'input box
   
      if ( G->button = BUTTON_MIDDLE ) then
         'primary selection paste
         dim as String s, t
         Dim As Integer ff = FreeFile
         
         if Open pipe ( "xclip -o" For input As #ff ) = 0 then
         
            do
               line input #ff, t
               s += t & NewLine
            loop until eof( ff )
         
            Close #ff
         
            #ifdef RTrim2
               RTrim2( s, !"\r\n", TRUE )
            #else
               s = rtrim( s, any !"\r\n" )
            #endif
            
            if len_hack( s ) > 0 then
               ChatInput &= s
               ChatInput.Print( )
            endif
         
         EndIf
      
      endif
   
#endif

endif

End Sub
