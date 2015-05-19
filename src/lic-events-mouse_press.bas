#Include "lic.bi"
#undef MAX
#define USE_LIC_MAIN

Extern ChatInput As FBGFX_CHARACTER_INPUT

Using fb

Function fbgfx_GetWidth( byref s as string ) as integer
   return len_hack( s ) * 8
End Function
Function ftype_GetWidth( byref s as string ) as integer
   return Global_IRC.TextInfo.FT_C.GetWidth( s )
End Function

Sub LIC_Event_Mouse_Press( ByRef G As gui_event Ptr )

   #Define CHATLIST_SCROLL 1
   #Define USERLIST_SCROLL 2
   #Define CHATLIST_BOX 4
   #Define USERLIST_BOX 8
   #Define Screen_Y Global_IRC.Global_Options.ScreenRes_Y
   #Define Screen_X Global_IRC.Global_Options.ScreenRes_X

   Dim As Integer Last_Y, SType, c
   Dim as fb.event E

   If G->Y < 21 then 'tab move
      
      if G->button <> BUTTON_RIGHT then exit sub
      
      dim as userroom_type ptr URT = Global_IRC.GetTab( G->X )
      dim as server_type ptr serv = URT->Server_ptr
      dim as integer old_X = G->X
      dim as integer boundary(1), hardlimit(1)
      dim As Integer tabsize = Global_IRC.Global_Options.ScreenRes_x \ Global_IRC.NumVisibleRooms( )
      dim as integer update = 1, rooms
      if tabsize < LIC_MIN_TAB_SIZE Then tabsize = LIC_MIN_TAB_SIZE
      
      scope 'find the hardlimits
         
         dim as integer tmp
         var tmproom = Global_IRC.GetTab( 1 )         
         
         while (tmproom->server_ptr <> serv) or (tmproom->pflags AND Hidden)
            if (tmproom->pflags AND Hidden) = 0 then
               tmp += tabsize
            EndIf
            tmproom = GetNextRoom( tmproom )
         Wend
         hardlimit(0) = tmp
         'LIC_DEBUG( "\\hardlimit0: " & tmp )
         if Global_IRC.NumServers > 1 then
            while tmproom->server_ptr = serv
               if (tmproom->pflags AND Hidden) = 0 then
                  tmp += tabsize
                  rooms += 1
               EndIf
               tmproom = GetNextRoom( tmproom )
            Wend
            hardlimit(1) = tmp
         else
            hardlimit(1) = Global_IRC.Global_Options.ScreenRes_x
            rooms = Global_IRC.NumVisibleRooms( )
         endif
         'LIC_DEBUG( "\\hardlimit1: " & hardlimit(1) )
         
      end scope
      
      if rooms = 1 then exit sub
         
      do
         sleep( 1,1 )
         if update then
            boundary(0) = (G->X \ tabsize) * tabsize
            boundary(1) = boundary(0) + tabsize
            if boundary(0) < hardlimit(0) then boundary(0) = hardlimit(0)
            if boundary(1) > hardlimit(1) then boundary(1) = hardlimit(1)
            Global_IRC.DrawTabs( )
            if Global_IRC.NumServers > 1 then
               line ( hardlimit(0) - 1, 0 )-( hardlimit(0) + 1, 20 ), Global_IRC.Global_Options.LeaveColour, BF
               line ( hardlimit(1) - 1, 0 )-( hardlimit(1) + 1, 20 ), Global_IRC.Global_Options.LeaveColour, BF
            endif
            update = 0
         EndIf

         While ScreenEvent( @E )   
            Select case e.type
            
               case EVENT_MOUSE_MOVE
                  G->X = cshort( e.x )
                  G->Y = cshort( e.y )
   
               case EVENT_MOUSE_BUTTON_RELEASE
                  If e.button = BUTTON_RIGHT Then Exit Do
   
               Case EVENT_WINDOW_LOST_FOCUS
                  ParseScreenEvent( e )
                  Exit sub
   
            End Select   
         Wend
         
         if (G->X < boundary(0)) AND (G->X > hardlimit(0)) then
            if rooms > 2 then
               var tmpprev = URT->PrevRoom->PrevRoom
               var tmpnext = URT->PrevRoom
               if URT = serv->LastRoom then serv->LastRoom = URT->PrevRoom
               if URT->PrevRoom = serv->FirstRoom then serv->FirstRoom = URT
               URT->PrevRoom->PrevRoom->NextRoom = URT
               URT->PrevRoom->PrevRoom = URT
               URT->PrevRoom->NextRoom = URT->NextRoom
               URT->NextRoom->PrevRoom = URT->PrevRoom
               URT->PrevRoom = tmpprev
               URT->NextRoom = tmpnext
            endif
            update = 1
         elseif (G->X > boundary(1)) and (G->X < hardlimit(1)) then
            if rooms > 2 then
               var tmpnext = URT->NextRoom->NextRoom
               var tmpprev = URT->NextRoom
               if URT->NextRoom = serv->LastRoom then serv->LastRoom = URT
               if URT = serv->FirstRoom then serv->FirstRoom = URT->NextRoom
               URT->NextRoom->NextRoom->PrevRoom = URT
               URT->NextRoom->NextRoom = URT
               URT->NextRoom->PrevRoom = URT->PrevRoom
               URT->PrevRoom->NextRoom = URT->NextRoom
               URT->PrevRoom = tmpprev
               URT->NextRoom = tmpnext
            endif
            update = 1
         EndIf
         
         if update = 1 and rooms = 2 then
            if URT = serv->FirstRoom then
               serv->FirstRoom = serv->LastRoom
               serv->LastRoom = URT
            else
               serv->LastRoom = serv->FirstRoom
               serv->FirstRoom = URT               
            EndIf
         EndIf
         
      loop
      
      Global_IRC.DrawTabs( )      

   elseIf ( G->Y < ChatInput.y1 ) Or ( G->X <= Global_IRC.CurrentRoom->UserListWidth ) Then

      Select Case G->X

         Case ( Global_IRC.CurrentRoom->UserListWidth - 7 ) To Global_IRC.CurrentRoom->UserListWidth
            SType = USERLIST_SCROLL

         Case ( Screen_X - 12 ) To Screen_X
            SType = CHATLIST_SCROLL

         Case 0 To ( Global_IRC.CurrentRoom->UserListWidth - 7 )
            SType = USERLIST_BOX

         Case Global_IRC.CurrentRoom->UserListWidth To ( Screen_X - 12 )
            SType = CHATLIST_BOX

      End Select
      
      If ( SType = USERLIST_SCROLL ) Or ( SType = USERLIST_BOX ) Then
         If ( G->button = BUTTON_LEFT ) and ( Global_IRC.CurrentRoom->NumUsers <= Global_IRC.MaxDisp_U ) Then
            Exit Sub
         End If
      Elseif SType = CHATLIST_SCROLL then
         If Global_IRC.CurrentRoom->NumLines <= Global_IRC.MaxDisp_C Then
            Exit Sub
         EndIf
      Endif

   End If

   If G->button = BUTTON_RIGHT Then

      If ( G->X > ( Screen_X - 20 ) ) And ( G->Y > ( Screen_Y - 20 ) ) Then

         'Resize window

         Dim As Integer HalfX, HalfY, Flag
         dim as string msg

         G->X = Screen_X
         G->Y = Screen_Y
         HalfX = Screen_X \ 2
         HalfY = Screen_Y \ 2

         var URT = Global_IRC.CurrentRoom

         ScreenLock

         Do while URT = Global_IRC.CurrentRoom

            ScreenUnlock

            While ScreenEvent( @E )

               Select case e.type

                  case EVENT_MOUSE_MOVE
                     Flag = 0
                     G->X = cshort( e.x )
                     G->Y = cshort( e.y )
                     if G->X < 256 then G->X = 256
                     if G->Y < 128 then G->Y = 128


                  case EVENT_MOUSE_BUTTON_RELEASE
                     If e.button = BUTTON_RIGHT Then Exit Do

                  Case EVENT_WINDOW_LOST_FOCUS
                     ParseScreenEvent( e )
                     Exit sub

               End Select

            Wend

            ScreenLock

            If Flag = 0 Then
               msg = "(" & G->X & "x" & G->Y & ")"
               Line ( HalfX - 32, HalfY - 8 ) - Step( 100, 16 ), Global_IRC.Global_Options.TextColour, BF
               Draw String ( HalfX - 26 + iif( len_hack( msg ) = 9, 8, 0 ), HalfY - 6 ), msg, Global_IRC.Global_Options.BackGroundColour
               Flag = 1
            EndIf

            ScreenUnLock
            MutexUnLock( Global_IRC.Mutex )
            sleep( 26, 1 )
            MutexLock( Global_IRC.Mutex )
            ScreenLock

            c += 1
            if c > 10 then
               c = 0

               #ifdef USE_LIC_MAIN
                  if Pending_Message( ) then Flag = 0
                  LIC_Main( )
               #else
                  if Pending_Message( ) then
                     Flag = 0
                     For i As Integer = 0 To Global_IRC.NumServers - 1
                        Global_IRC.Server[i]->ParseMessage( )
                     Next
                  EndIf
               #endif

            endif

         Loop

         ScreenUnLock

         Line ( HalfX - 30, HalfY - 8 ) - Step( 92, 16 ), Global_IRC.Global_Options.BackGroundColour, BF
         if ( Global_IRC.Global_Options.FontRender = WinAPI ) and ( G->X > LIC_DRAWFONT_X ) then G->X = LIC_DRAWFONT_X

         if ( G->X <> Screen_X ) or ( G->Y <> Screen_Y ) then
            LIC_Resize( G->X, G->Y )
         endif

      elseif SType = USERLIST_SCROLL then

         'Userlist resize
         if Global_IRC.CurrentRoom->RoomType = RoomTypes.List then
            Exit Sub
         EndIf

         dim as integer flag, oldx, oldy
         dim as uInt32_t lcol = Global_IRC.Global_Options.SCROLLBARBACKGROUNDCOLOUR XOR Global_IRC.Global_Options.SCROLLBARFOREGROUNDCOLOUR

         var URT = Global_IRC.CurrentRoom
         var max = Global_IRC.Global_Options.ScreenRes_X - 128

         Do while URT = Global_IRC.CurrentRoom

            #ifdef USE_LIC_MAIN

               if Pending_Message( ) then
                  flag = TRUE
                  LIC_Main( )
                  c = 0
               else
                  c += 1
                  if c > 10 then
                     c = 0
                     LIC_Main( )
                  EndIf
               endif

            #else
               For i As Integer = 0 To Global_IRC.NumServers - 1
                  flag or= Global_IRC.Server[i]->ParseMessage( )
               Next
            #endif

            if flag = TRUE then

               flag = FALSE
               oldx = G->X

               ScreenLock

               URT->PrintUserList( 1 )
               URT->PrintChatBox( 1 )

               line ( oldx, 21 )-( oldx, Global_IRC.Global_Options.ScreenRes_Y - 17 ), lcol

               ScreenUnlock

            endif

            While ScreenEvent( @E )

               Select case e.type

                  case EVENT_MOUSE_MOVE

                     G->X = cshort( e.x )
                     G->Y = cshort( e.y )
                     if G->X < 0 then G->X = 0
                     if G->X > max then G->X = max

                     if oldx <> G->X then
                        Flag = TRUE
                     EndIf


                  case EVENT_MOUSE_BUTTON_RELEASE
                     If e.button = BUTTON_RIGHT Then Exit Do

                  Case EVENT_WINDOW_LOST_FOCUS
                     ParseScreenEvent( e )
                     Exit sub

               End Select

            Wend

            MutexUnLock( Global_IRC.Mutex )
            sleep( 26, 1 )
            MutexLock( Global_IRC.Mutex )

         loop

         if ( URT = Global_IRC.CurrentRoom ) and ( oldx <> URT->UserListWidth ) then

            Global_IRC.Global_Options.DefaultUserListWidth = oldx
            Global_IRC.Global_Options.DefaultTextBoxWidth = Global_IRC.Global_Options.ScreenRes_x - oldx
            LIC_ResizeAllRooms( )

         EndIf

      EndIf

   ElseIf ( G->button = BUTTON_LEFT ) And SType = 0 Then

      ChatInput.MouseDown( G->X )
      ChatInput.Print( )

   ElseIf ( G->Button = BUTTON_LEFT ) And ( SType = CHATLIST_SCROLL ) Or ( SType = USERLIST_SCROLL ) Then

      Var URT = Global_IRC.CurrentRoom

      Do While URT = Global_IRC.CurrentRoom

         While ScreenEvent( @E )
            Select Case e.Type

               Case EVENT_MOUSE_MOVE
                  G->Y = cshort( e.y )
                  G->X = cshort( e.X )

               Case EVENT_MOUSE_BUTTON_RELEASE
                  G->Button = e.button
                  If e.Button = BUTTON_LEFT Then Exit Do

               case EVENT_WINDOW_LOST_FOCUS
                  ParseScreenEvent( e )
                  Exit sub

            End Select
         wend

         If ( G->Y > Screen_Y ) Then 'Mouse out of window

            Select Case Last_Y

               Case Is < ( Screen_Y Shr 3 )
                  G->Y = 0
               Case Is > ( Screen_Y - ( Screen_Y Shr 3 ) )
                  G->Y = Screen_Y
               Case Else
                  G->Y = Last_Y

               'ChatBox Old way
               'Case Is < ( ScreenY \ 7 )
               '	Mouse_Y = 0
               'Case Is > ( ScreenY - ( ScreenY \ 7 ) )
               '	Mouse_Y = ScreenY
               'Case Else
               '	Mouse_Y = Last_Y

            End Select

         EndIf

         If G->Y <> Last_Y Then

            If SType = USERLIST_SCROLL Then
               Global_IRC.CurrentRoom->UpdateUserListScroll( G->Y )
            Else
               Global_IRC.CurrentRoom->flags OR= Backlogging
               Global_IRC.CurrentRoom->UpdateChatListScroll( G->Y )
            EndIf

            Last_Y = G->Y

         EndIf


         #ifdef USE_LIC_MAIN
            if Pending_Message( ) = 0 then
               MutexUnLock( Global_IRC.Mutex )
               sleep( 26, 1 )
               MutexLock( Global_IRC.Mutex )
               c += 1
               if c > 8 then
                  c = 0
                  LIC_Main( )
               EndIf
            else
               c = 0
               LIC_Main( )
            EndIf
         #else
            if Pending_Message( ) then
               For i As Integer = 0 To Global_IRC.NumServers - 1
                  Global_IRC.Server[i]->ParseMessage( )
               Next
            else
               MutexUnLock( Global_IRC.Mutex )
               sleep( 26, 1 )
               MutexLock( Global_IRC.Mutex )
            EndIf
         #endif

      Loop

   ElseIf ( G->Button = BUTTON_MIDDLE ) And ( (SType = CHATLIST_BOX) Or (SType = USERLIST_BOX) ) Then

      Dim Orig_X As Integer = G->X
      Dim Orig_Y As Integer = G->Y
      Dim Passive As Integer 'User released middle mouse button before moving?
      Dim ExitDo As Integer
      Dim Y_Speed As Integer
      Dim Flag As Integer
      Dim TT As Double
      Dim IMG As IMAGE Ptr = ImageCreate( 31, 31, Global_IRC.Global_Options.BackGroundColour )

      Circle IMG, ( 15, 15 ), 15, Global_IRC.Global_Options.YourChatColour, , , , F
      Circle IMG, ( 15, 15 ), 4, Global_IRC.Global_Options.BackGroundColour, , , , F

      'Triangle 1
      Line IMG, ( 11, 6 )-( 19, 6 ), Global_IRC.Global_Options.BackGroundColour
      Line IMG, ( 11, 6 )-( 15, 2 ), Global_IRC.Global_Options.BackGroundColour
      Line IMG, ( 15, 2 )-( 19, 6 ), Global_IRC.Global_Options.BackGroundColour
      Paint IMG, ( 15, 5 ), Global_IRC.Global_Options.BackGroundColour
      'Triangle 2
      Line IMG, ( 11, 24 )-( 19, 24 ), Global_IRC.Global_Options.BackGroundColour
      Line IMG, ( 11, 24 )-( 15, 28 ), Global_IRC.Global_Options.BackGroundColour
      Line IMG, ( 15, 28 )-( 19, 24 ), Global_IRC.Global_Options.BackGroundColour
      Paint IMG, ( 15, 25 ), Global_IRC.Global_Options.BackGroundColour

      If SType = CHATLIST_BOX Then
         Last_Y = Global_IRC.CurrentRoom->ChatScrollBarY
      Else
         Last_Y = Global_IRC.CurrentRoom->UserScrollBarY
      EndIf

      var URT = Global_IRC.CurrentRoom

      Do Until ExitDo <> 0

         While ScreenEvent( @E )
            Select Case e.Type

               Case EVENT_MOUSE_MOVE
                  G->Y = cshort( E.Y )

               Case EVENT_MOUSE_BUTTON_PRESS, EVENT_KEY_PRESS
                  ExitDo = 1

               case EVENT_WINDOW_LOST_FOCUS
                  ExitDo = 1
                  Global_IRC.WindowActive = 0

               Case EVENT_MOUSE_BUTTON_RELEASE
                  If e.Button = BUTTON_MIDDLE Then
                     If G->Y = Orig_Y Then Passive = 1 Else ExitDo = 1
                  EndIf

            End Select
         Wend

         screenlock

         #Define MAX_SCROLL 32

         If ( G->Y <= (Orig_Y - 16) ) Or ( G->Y >= (Orig_Y + 16) ) Then

            Dim As Integer sign = Sgn( Orig_Y - G->Y )
            Y_Speed = ( Orig_Y - G->Y ) \ 16

            If Abs( Y_Speed ) > MAX_SCROLL Then Y_Speed = MAX_SCROLL * sign

            If SType = USERLIST_BOX Then
               Last_Y -= Y_Speed
               If Last_Y < 0 Then Last_Y = 0
               If Last_Y > Screen_Y Then Last_Y = Screen_Y
               Global_IRC.CurrentRoom->UpdateUserListScroll( Last_Y )
               Flag = 0
            Else
               If ( Last_Y <> Y_Speed ) And ( Passive = 0 ) Then
                  Global_IRC.CurrentRoom->LineScroll( -2 * ( sign ) )
                  Last_Y = Y_Speed
                  Flag = 0
               ElseIf Timer > TT Then
                  If Abs( Y_Speed ) = MAX_SCROLL Then
                     Global_IRC.CurrentRoom->LineScroll( Global_IRC.MaxDisp_C * -( sign ) )
                     TT = Timer + 0.08
                  Else
                     Global_IRC.CurrentRoom->LineScroll( -( ( Y_Speed \ 8 ) + sign ) )
                     TT = Timer + 0.3 * ( sign / Y_Speed )
                  EndIf

                  Last_Y = Y_Speed
                  Flag = 0

               EndIf

            EndIf

         EndIf

         #ifdef USE_LIC_MAIN
            if Pending_Message( ) then
               flag = 0
               LIC_Main( )
               c = 0
            else
               c += 1
               if c > 10 then
                  c = 0
                  LIC_Main( )
               EndIf
            endif

         #else
            if Pending_Message( ) then
               flag = 0
               For i As Integer = 0 To Global_IRC.NumServers - 1
                  Global_IRC.Server[i]->ParseMessage( )
               Next
            endif
         #endif

         if URT <> Global_IRC.CurrentRoom then
            Flag = 1
            ExitDo = 1
         EndIf

         If Flag = 0 Then
            Flag = 1

            If SType = USERLIST_BOX Then
               view ( 0, 21 )-( Global_IRC.CurrentRoom->UserListWidth - 8, Screen_Y )
               Put ( Orig_X - 16, Orig_Y - 16 - 21 ), IMG, PSet
            Else
               view ( Global_IRC.CurrentRoom->UserListWidth, 21 )-( Screen_X - 13, Screen_Y - 16 )
               Put ( Orig_X - 16 - Global_IRC.CurrentRoom->UserListWidth, Orig_Y - 16 - 21 ), IMG, PSet
            EndIf
            View

            ScreenUnlock
            MutexUnLock( Global_IRC.Mutex )

            If SType = USERLIST_BOX Then
               sleep( 1 + Global_IRC.CurrentRoom->NumUsers \ 25, 1 )
            Else
               sleep( 1, 1 )
            EndIf

         Else

            ScreenUnlock
            MutexUnLock( Global_IRC.Mutex )

            sleep( 1, 1 )

         EndIf

         MutexLock( Global_IRC.Mutex )

      Loop

      ImageDestroy( IMG )

      If SType = USERLIST_BOX Then
         Global_IRC.CurrentRoom->PrintUserList( 1 )
      Else
         Global_IRC.CurrentRoom->PrintChatBox( 1 )
      EndIf

   ElseIf ( G->Button = BUTTON_LEFT ) And ( SType = CHATLIST_BOX ) Then
      'select text to copy
      
      Dim As UserRoom_Type Ptr URT = Global_IRC.CurrentRoom
      dim as short OrigX = G->X, OrigY = G->Y, LastX, LastY
      Dim As LineOfText Ptr LOT = GetLOT( G->Y )
      dim as LineOfText Ptr LastLOT = LOT, OrigLOT = LOT

      If (LOT = 0) or (Global_IRC.Global_Options.DisableQuickCopy <> 0) Then
         Exit Sub
      EndIf
      
      dim GetWidth as function( byref s as string ) as integer
      dim as integer LineSize
      
      dim as integer OrigOffset
      if Global_IRC.Global_Options.FontRender = fbgfx or URT->RoomType = RawOutput then
         OrigOffset = ( OrigX - Global_IRC.CurrentRoom->UserListWidth + 4 ) \ 8
         if Global_IRC.Global_Options.ShowTimeStamp <> 0 and LOT->MesID < 50 and ( LOT->MesID And 1 ) = 0 then
            OrigOffset -= Len( LOT->TimeStamp )
         elseif (LOT->MesID AND 1) and LOT->MesID < 50 then
            OrigOffset -= 3
         EndIf
         if OrigOffset < 1 then OrigOffset = 1
         GetWidth = @fbgfx_GetWidth
         LineSize = 16
         'LIC_DEBUG( "Orig offset:" & OrigOffset & " ~ " & mid( LOT->Text, OrigOffset, 3 ) )
      else
         dim as integer startX = Global_IRC.CurrentRoom->UserListWidth + 4
         dim as integer w
         GetWidth = @ftype_GetWidth
         LineSize = Global_IRC.TextInfo.ChatBoxCharSizeY
         if Global_IRC.Global_Options.ShowTimeStamp <> 0 and LOT->MesID < 50 and ( LOT->MesID And 1 ) = 0 then
            StartX += GetWidth( LOT->TimeStamp )
         elseif (LOT->MesID AND 1) and LOT->MesID < 50 then
            StartX += 20
         EndIf
         do 
            OrigOffset += 1
            w = GetWidth( left( LOT->Text, OrigOffset ) )
         loop while ( StartX + w < OrigX ) and ( OrigOffset < len_hack( LOT->Text ) )
         'LIC_DEBUG( "Orig offset:" & OrigOffset & " ~ " & mid( LOT->Text, OrigOffset, 3 ) )
      EndIf
      
      dim as string selected
      dim as integer ExitDo, update, lastlen
      dim as double t1 = timer
      
      do until ExitDo
      
         While ScreenEvent( @E )
            Select Case e.Type

               Case EVENT_MOUSE_MOVE
                  G->Y = cshort( E.Y )
                  G->X = cshort( E.X )

               case EVENT_WINDOW_LOST_FOCUS
                  ExitDo = 1
                  Global_IRC.WindowActive = 0

               Case EVENT_MOUSE_BUTTON_RELEASE
                  If e.Button = BUTTON_LEFT Then
                     ExitDo = 1
                  EndIf
                  G->Button = e.Button

            End Select
         wend
         
         if ( GetLOT( G->Y ) <> LastLOT ) then
            update = 1
            LOT = GetLOT( G->Y )
         elseif ( abs( LastX - G->X ) > 4 ) then
            update = 1
         EndIf
         
         if update <> 0 and LOT <> 0 then
                                    
            dim as integer forward = iif( _
               ( OrigLOT <> LOT and G->Y > OrigY ) or ( OrigLOT = LOT and G->X > OrigX ), 1, 0 )
            
            if LOT <> OrigLOT then
               if forward then
                  var tmpy = OrigY + LineSize
                  var tmplot = GetLOT( tmpy )
                  selected = mid( OrigLOT->Text, OrigOffset )
                  while tmplot <> 0 andalso tmplot <> LOT
                     if ( tmplot->MesID and 1 ) = 0 then selected += NEWLINE
                     selected += tmplot->Text
                     tmpy += LineSize
                     tmplot = GetLOT( tmpy )
                  wend
                  if tmplot = 0 then
                     LOT = LastLOT
                  else
                     dim as integer startX = Global_IRC.CurrentRoom->UserListWidth + 4
                     dim as integer w, l
                     if Global_IRC.Global_Options.ShowTimeStamp <> 0 and LOT->MesID < 50 and ( LOT->MesID And 1 ) = 0 then
                        StartX += GetWidth( LOT->TimeStamp )
                     elseif (LOT->MesID AND 1) and LOT->MesID < 50 then
                        StartX += 20
                     EndIf
                     do
                        l += 1
                        w = GetWidth( left( LOT->Text, l ) )
                     loop while ( StartX + w < G->X ) and ( l < len_hack( LOT->Text ) )
                     if ( LOT->MesID and 1 ) = 0 then selected += NEWLINE
                     selected += left( LOT->Text, l )
                  EndIf
               else                  
                  var tmpy = OrigY - LineSize
                  var tmplot = GetLOT( tmpy )
                  var flag = 0
                  selected = left( OrigLOT->Text, OrigOffset )
                  while (tmplot <> 0) and (tmplot <> LOT)
                     if flag = 1 then
                        selected = NEWLINE & selected
                        flag = 0
                     EndIf
                     selected = tmplot->Text & selected
                     if ( tmplot->MesID and 1 ) = 0 then flag = 1
                     tmpy -= LineSize
                     tmplot = GetLOT( tmpy )                     
                  wend
                  if tmplot = 0 then
                     LOT = LastLOT
                  else
                     dim as integer startX = Global_IRC.CurrentRoom->UserListWidth + 4 + GetWidth( LOT->Text )
                     dim as integer w, l
                     if Global_IRC.Global_Options.ShowTimeStamp <> 0 and LOT->MesID < 50 and ( LOT->MesID And 1 ) = 0 then
                        StartX += GetWidth( LOT->TimeStamp )
                     elseif (LOT->MesID AND 1) and LOT->MesID < 50 then
                        StartX += 20
                     EndIf
                     do while ( StartX - w > G->X ) and ( l < len_hack( LOT->Text ) )
                        l += 1
                        w = GetWidth( right( LOT->Text, l ) )
                     loop
                     if flag then selected = NEWLINE & selected
                     selected = right( LOT->Text, l ) & selected
                  EndIf
               end if
            else
               if forward then
                  dim as integer startX = Global_IRC.CurrentRoom->UserListWidth + 4 + GetWidth( Left( LOT->Text, OrigOffset - 1 ) )
                  dim as integer w, l
                  if Global_IRC.Global_Options.ShowTimeStamp <> 0 and LOT->MesID < 50 and ( LOT->MesID And 1 ) = 0 then
                     StartX += GetWidth( LOT->TimeStamp )
                  elseif (LOT->MesID AND 1) and LOT->MesID < 50 then
                     StartX += 20
                  EndIf
                  do
                     l += 1
                     w = GetWidth( mid( LOT->Text, OrigOffset, l ) )
                  loop while ( StartX + w < G->X ) and ( l <= ( len_hack( LOT->Text ) - OrigOffset ) )
                  selected = mid( LOT->Text, OrigOffset, l )
               else
                  dim as integer startX = Global_IRC.CurrentRoom->UserListWidth + 4 + GetWidth( Left( LOT->Text, OrigOffset ) )
                  dim as integer w, l = -1
                  if Global_IRC.Global_Options.ShowTimeStamp <> 0 and LOT->MesID < 50 and ( LOT->MesID And 1 ) = 0 then
                     StartX += GetWidth( LOT->TimeStamp )
                  elseif (LOT->MesID AND 1) and LOT->MesID < 50 then
                     StartX += 20
                  EndIf
                  do
                     l += 1
                     w = GetWidth( mid( LOT->Text, OrigOffset - l, l + 1) )                     
                  loop while ( StartX > G->X + w ) and ( l < OrigOffset - 1 )
                  selected = mid( LOT->Text, OrigOffset - l, l + 1 )
               EndIf
            EndIf
            
            if len_hack( selected ) <> lastlen then
               lastlen = len_hack( selected )
               'LIC_DEBUG( "\\selected:" & selected )
            end if
            
            LastX = G->X
            LastY = G->Y
            LastLOT = LOT
            update = 0
            
         end if
         
         sleep( 1,1 )
      
      Loop
      
      if (len_hack( selected ) > 0) and (t1 + 0.10 < timer) and ( G->X <> OrigX or G->Y <> OrigY ) then
         if multikey( SC_LSHIFT ) or multikey( SC_RSHIFT ) then
            selected = GetClipboardAsString() & selected
         EndIf
         CopyToClipboard( selected )
      else
         G->Button = Button_Left
         G->X = OrigX
         G->Y = OrigY
         LIC_Event_Mouse_Release( G )
      EndIf
   
   EndIf

End Sub
