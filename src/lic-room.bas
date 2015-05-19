#Include Once "lic.bi"
#Include once "file.bi"
#include once "vbcompat.bi"

Sub UserRoom_Type.SmoothScroll( byref LinesAdded as integer )

   #define SR_X Global_IRC.Global_Options.ScreenRes_X
   #define SR_Y Global_IRC.Global_Options.ScreenRes_Y

   dim as integer ULW = iif( UserListWidth > 0, UserListWidth, 0 )
   dim as integer pixels = LinesAdded * Global_IRC.TextInfo.ChatBoxCharSizeY + 4
   dim as integer X = SR_X - ULW - 13
   dim as integer Y = SR_Y - 20 - 16
   dim as integer VPX1 = ULW, VPX2 = SR_x - 13
   dim as integer VPY1 = 21,  VPY2 = SR_y - 17

   var img = ImageCreate( X, Y, Global_IRC.Global_Options.BackGroundColour )
   var nimg = ImageCreate( X, pixels, Global_IRC.Global_Options.BackGroundColour )

   screenlock

   view
   Get ( ULW, 21 ) - ( SR_x - 14, SR_y - 17 ), img

   UpdateChatListScroll( ChatScrollBarY, 1 )

   view
   get ( ULW, SR_y - 16 - pixels ) - ( SR_x - 13, SR_y - 17 ), nimg

   view ( VPX1, VPY1 )-( VPX2, VPY2 )
   put ( 0, 0 ), img, pset

   screenunlock

   dim as integer flag, pp, pixstep = Global_IRC.TextInfo.ChatBoxCharSizeY \ 4
   dim as fb.event e

   for i as integer = 1 to ( 4 * LinesAdded )

      pp -= pixstep
      screenlock
      view ( VPX1, VPY1 )-( VPX2, VPY2 )
      put ( 0, pp ), img, pset
      put ( 0, Y + pp - 4 ), nimg, pset
      screenunlock
      sleep( 26, 1 )
      while ScreenEvent( @e )
         select case e.type
         case fb.EVENT_MOUSE_MOVE, fb.EVENT_KEY_RELEASE
            ParseScreenEvent( e )
         case fb.EVENT_KEY_REPEAT, fb.EVENT_KEY_PRESS
            Select Case e.ascii
               Case 32 To 126
                  ParseScreenEvent( e )
               Case Else
                  if Parse_Scancode( e.scancode ) then
                     flag = 1
                     exit for
                  endif
            End Select
         case fb.EVENT_MOUSE_ENTER, fb.EVENT_MOUSE_EXIT
         case else
            flag = 1
            exit for
         end select
      Wend

   Next

   view

   ImageDestroy( img )
   ImageDestroy( nimg )

   if flag = 1 then
      ParseScreenEvent( e )
   endif

   if @this = Global_IRC.CurrentRoom then
      PrintChatBox( 1 )
   EndIf

End sub

Sub UserRoom_type.UpdateUserListScroll( ByVal y As Integer )

   If (pflags AND UsersLock) or (UserListWidth = 0) Then Exit Sub

   Dim Y_Res               As Integer = Global_IRC.Global_Options.ScreenRes_y - 21
   Dim ScrollBarLength     As Integer = Y_Res
   Dim UserNumber          As Integer
   Dim UNT                 As UserName_type Ptr

   If NumUsers > Global_IRC.MaxDisp_U Then ScrollBarLength = Y_Res / ( NumUsers / Global_IRC.MaxDisp_U )

   Select Case y
      Case -123456 'GuiUpdate
      Case Is >= ( Global_IRC.Global_Options.ScreenRes_y - ScrollBarLength )
         y = Global_IRC.Global_Options.ScreenRes_y - ScrollBarLength
         UserNumber = NumUsers
      Case Is < 22
         y = 21
      Case Else
         UserNumber = NumUsers * ( ( y - 21 ) / Y_Res )
   End Select

   If y <> -123456 Then
      UserScrollBarY = y
      If NumUsers <= Global_IRC.MaxDisp_U Then
         UNT = FirstUser
      elseIf UserNumber < ( NumUsers shr 1 ) Then
         UNT = FirstUser
         For i As Integer = 1 To UserNumber
            UNT = UNT->NextUser
         Next
      Else
         UNT = LastUser
         If NumUsers - UserNumber < Global_IRC.MaxDisp_U Then UserNumber = NumUsers - Global_IRC.MaxDisp_U + 3
         For i As Integer = UserNumber to NumUsers
            if UNT->PrevUser <> 0 then UNT = UNT->PrevUser
         Next
      EndIf
      If TopDisplayedUser <> UNT Then
         TopDisplayedUser = UNT
         PrintUserList( )
      ElseIf @this <> Global_IRC.CurrentRoom Then 'Hack to update the UserList when switching rooms with tab (UpdateUserList is called before CurrentRoom is set to this room)
         PrintUserList( )
      EndIf
   Else
      PrintUserList( )
      y = UserScrollBarY
   EndIf


   ScreenLock

   Line ( UserListWidth - 7, 21 )-( UserListWidth - 1, Global_IRC.Global_Options.ScreenRes_y ), Global_IRC.Global_Options.ScrollBarBackgroundColour, BF

   If y + ScrollBarLength < Global_IRC.Global_Options.ScreenRes_y then
      Line ( UserListWidth - 7, y )-( UserListWidth - 1, y + ScrollBarLength ), Global_IRC.Global_Options.ScrollBarForegroundColour, BF
   Else
      Line ( UserListWidth - 7, Global_IRC.Global_Options.ScreenRes_y - ScrollBarLength )-( UserListWidth - 1, Global_IRC.Global_Options.ScreenRes_y ), Global_IRC.Global_Options.ScrollBarForegroundColour, BF
   EndIf

   ScreenUnLock

End Sub

Sub UserRoom_Type.LineScroll( ByRef N As Integer )

   var i = CurrentLine
   var y = ChatScrollBarY

   If ( NumLines <= Global_IRC.MaxDisp_C ) Or ( N = 0 ) Then Exit Sub

   i += N

   If i <= Global_IRC.MaxDisp_C Then
      flags OR= BackLogging
      i = Global_IRC.MaxDisp_C
      Y = 1
   elseIf i >= NumLines Then
      flags AND= NOT( BackLogging )
      i = NumLines
      Y = Global_IRC.Global_Options.ScreenRes_y
   Else
      flags OR= BackLogging
      Y = i / NumLines * ( Global_IRC.Global_Options.ScreenRes_y - 37 )
   EndIf

   UpdateChatListScroll( Y, 0 )
   CurrentLine = i
   PrintChatBox( )

End Sub

Sub UserRoom_type.UpdateChatListScroll _
   ( _
      ByVal y           As Integer, _
      ByRef AndPrint    As Integer = 1, _
      ByVal GotoLine    as UInteger = 0 _
   )

   dim as integer OldMax = Global_IRC.MaxDisp_C
   if RoomType = RawOutput then
      Global_IRC.MaxDisp_C = ( Global_IRC.Global_Options.ScreenRes_y - 37 ) \ 16
   EndIf

   dim TextBoxHeight       As Integer = Global_IRC.Global_Options.ScreenRes_y - 37 ' (16 + 21)
   Dim ScrollBarLength     As Integer = TextBoxHeight / ( NumLines / Global_IRC.MaxDisp_C )
   Dim LineNum             As Integer

   If ScrollBarLength > TextBoxHeight Then
      ScrollBarLength = TextBoxHeight
   ElseIf ScrollBarLength < 10 Then
      ScrollBarLength = 10
   EndIf

   If ( ( (flags AND backlogging) = 0 ) Or ( NumLines <= Global_IRC.MaxDisp_C ) ) and GotoLine = 0 Then
      LineNum = NumLines
      flags AND= NOT( BackLogging )
   else
      If y > TextBoxHeight + 20 Then
         y = TextBoxHeight + 20
         flags AND= NOT( BackLogging )
         LineNum = NumLines
      elseif GotoLine > 0 then
         if GotoLine + Global_IRC.MaxDisp_C > NumLines then
            LineNum = NumLines
            y = TextBoxHeight + 20
         else
            LineNum = GotoLine + Global_IRC.MaxDisp_C - 1
            flags or= backlogging
            y = TextBoxHeight * ( LineNum / NumLines ) + 20
         EndIf
      ElseIf y < ScrollBarLength + 21 Then
         y = 21 + ScrollBarLength
         LineNum = Global_IRC.MaxDisp_C
      Else
         LineNum = NumLines * ( ( y - 20 ) / TextBoxHeight )
      EndIf
   EndIf

   ChatScrollBarY = y

   ScreenLock

   Line ( Global_IRC.Global_Options.ScreenRes_x - 12, 20 )-( Global_IRC.Global_Options.ScreenRes_x, Global_IRC.Global_Options.ScreenRes_y - 16), Global_IRC.Global_Options.ScrollBarBackgroundColour, BF

   If (flags AND backlogging) = 0 Then

      CurrentLine = LineNum
      Line ( Global_IRC.Global_Options.ScreenRes_x - 12, TextBoxHeight + 20 - ScrollbarLength )-( Global_IRC.Global_Options.ScreenRes_x, TextBoxHeight + 20 ), Global_IRC.Global_Options.ScrollBarForeGroundColour, BF
      ScreenUnLock

      If AndPrint Then PrintChatBox( )
   Else

      Line ( Global_IRC.Global_Options.ScreenRes_x - 12, y )-( Global_IRC.Global_Options.ScreenRes_x, y - ScrollBarLength ), Global_IRC.Global_Options.ScrollBarForeGroundColour, BF
      ScreenUnLock
      If ( CurrentLine <> LineNum ) Or ( Global_IRC.CurrentRoom <> @this ) Then
         CurrentLine = LineNum
         If AndPrint Then PrintChatBox( )
      EndIf
   EndIf
   
   Global_IRC.MaxDisp_C = OldMax

End Sub

Sub UserRoom_type.Log( ByRef Text As String )

   var msg = date + " "
   if len_hack( Global_IRC.Global_Options.TimeStampFormat ) then
      msg += "(" & time & ") "
   else
      msg += Global_IRC.TimeStamp 
   EndIf

   If ( RoomType = PrivateChat ) And ( Global_IRC.Global_Options.LogMergePM <> 0 ) Then
      Var Str1 = Server_Ptr->uCase_( Mid( Text, 3, InStrASM( 3, Text, Asc(" ") ) - 3 ) )
      Var Str2 = Server_Ptr->uCase_( Server_Ptr->CurrentNick )
      If Global_IRC.Global_Options.LogBufferSize > 0 Then
         If StringEqualASM( Str1, Str2 ) Then
            Dim As ZString Ptr Message = @Text[ 6 + len_hack( Str2 ) ]
            msg += "TO ->[ " & RoomName & " ]: " & *Message & NewLine
         Else
            msg += "FROM ->" & Text & NewLine
         EndIf
         Server_Ptr->LogBuffer += msg
         Global_IRC.LogLength += len_hack( msg )
      Else
         If StringEqualASM( Str1, Str2 ) Then
            Dim As ZString Ptr Message = @Text[ 6 + len_hack( Str2 ) ]
            msg += "TO ->[ " & RoomName & " ]: " & *message & NewLine
         Else
            msg += "FROM ->" & Text & NewLine
         EndIf
         Server_Ptr->LogToFile( "private messages", msg )
      EndIf
   Else
      msg += Text & NewLine
      If Global_IRC.Global_Options.LogBufferSize > 0 Then
         LogBuffer += msg
         Global_IRC.LogLength += len_hack( msg )
      Else
         select case RoomType

         case RoomTypes.Lobby
            Server_Ptr->LogToFile( "server messages", msg )

         case RoomTypes.DccChat
            Server_Ptr->LogToFile( "dcc " + RoomName, msg )
         
         case RoomTypes.RawOutput
            Server_Ptr->LogToFile( "raw log", msg )

         case else
            Server_Ptr->LogToFile( RoomName, msg )

         end select
      EndIf
   EndIf

End Sub

Function UserRoom_type.AddLOT _
   ( _
      ByRef Text           As String, _
      ByRef Colour         As UInt32_t, _
      ByRef PrintNow       As Integer = 1, _
      ByVal MesID          As IRC_MessageID = ServerMessage, _
      ByRef Spawned        As Integer = 0, _
      ByVal MCD            As LOT_MultiColour_Descriptor Ptr = 0, _
      ByRef Disable_Log    As Integer = FALSE _
   ) as LineOfText ptr

   dim as uinteger flags
   if PrintNow = 0 then flags or= LOT_NoPrint
   if Spawned then flags  or= LOT_Spawned
   if Disable_Log then flags or= LOT_NoLog else flags or= LOT_Log
   
   Function = AddLOTEX( text, colour, MesID, MCD, flags )   

end function

function UserRoom_type.AddLOTEX _
   ( _
      byref text as string, _
      byref colour as uint32_t, _
      byval MesID as IRC_MessageID = ServerMessage, _
      byval MCD as LOT_MultiColour_Descriptor ptr = 0, _
      byval LOT_flags as uinteger = 0 _
   ) as LineOfText ptr

   dim as Integer Disable_log, Spawned, PrintNow, TempInt
   
   if LOT_flags and LOT_NoLog then Disable_Log = true
   if LOT_flags and LOT_Spawned then Spawned = 1
   if (LOT_flags and LOT_NoPrint) = 0 then PrintNow = 1

   if ( RoomType = DccChat ) then 'All messages flag
      if (pflags AND Hidden) then
         'Queued for deletion
         Exit Function
      EndIf
      If ( (pflags AND FlashingTab) = 0 ) And ( @this <> Global_IRC.CurrentRoom ) and (LOT_flags AND LOT_NoTab) = 0 Then
         pflags OR= FlashingTab
         If ( Global_IRC.WindowActive or Global_IRC.Global_Options.ShowInactive ) <> 0 Then
            Global_IRC.DrawTabs( )
         EndIf
      EndIf
      If ( Global_IRC.WindowActive = 0 ) and ( (MesID AND 1) = 0 ) and (LOT_flags and LOT_NoNotify) = 0 Then
         LIC_Notify( 1 )
      EndIf
   EndIf

   Dim As LOT_MultiColour Ptr MC_Ptr()
   Dim As Integer MultiColoursAdded, MultiColoursLeft, MCAllocated
   Dim As Integer LinesAdded = 1
     
   var NewLine = New LineOfText
   Function = NewLine

   If ( MesID And 1 ) = 0 Then
      if len_hack( Global_IRC.Global_Options.TimeStampFormat ) > 0 then
         if Global_IRC.Global_Options.TimeStampUseCRT <> 0 then 'strftime method
            var t = time_(0)
            var tmp = localtime(@t)
            if len_hack( Global_IRC.TimeStamp ) < 1 then
               Global_IRC.TimeStamp = space(64)
            EndIf
            str_len( Global_IRC.TimeStamp ) = strftime( Global_IRC.TimeStamp, str_all(Global_IRC.TimeStamp), Global_IRC.Global_Options.TimeStampFormat, tmp )
         else
            Global_IRC.TimeStamp = Format( now, Global_IRC.Global_Options.TimeStampFormat )
         end if
      else
         Global_IRC.TimeStamp = "(" & TIME & ") "
      endif
   EndIf

   Select Case MesID
   Case LineBreak 'to reserved..
      Disable_Log = TRUE
   case NormalChat
      NewLine->Offset = InStrASM( 6, Text, asc(":") )
      '6 is the minimum with a 1 char nick: "[ A ]:"
   End Select

   If ( Disable_Log = FALSE ) And ( (pflags AND ChannelLogging) <> 0 ) Then
      if RoomType = RawOutput then
         if Colour = Global_IRC.Global_Options.RawInputColour then
            this.Log( "<< " & Text )
         elseif Colour = Global_IRC.Global_Options.RawOutputColour then
            this.Log( ">> " & Text )
         EndIf         
      else
         this.Log( Text )
      EndIf      
   EndIf

   if RoomType <> RawOutput then
      if (LOT_flags AND LOT_NoTab) or (LOT_flags and LOT_Tab) then
         pflags AND= NOT( Hidden )
      EndIf
   else
      MCD = 0
   end if

   NewLine->Text = Text
   NewLine->MesID = MesID
   NewLine->Colour = Colour

   'If any escapes exist, escape them.
   'TempInt = InStrASM( 1, Text, MESSAGE_ESCAPE_CHAR )
   'While TempInt > 0

      'NewLine->Text = _
         'Left( NewLine->Text, TempInt ) & _
         'Chr( MESSAGE_ESCAPE_CHAR ) & _
        'Mid( NewLine->Text, TempInt + 1 )

      'TempInt = InStrASM( TempInt + 2, NewLine->Text, MESSAGE_ESCAPE_CHAR )

  ' Wend





   /' This sub does a lot for each line of text,
      so I've split it into 4 sections...

      1st it checks for a MultiColourDescriptor and
      takes care of that (handling more than one if needed)

      2nd splits it into seperate lines depending on the
      length of the text (different method for fbgfx)

      3rd checks if the message should be printed right now

      4th makes sure the number of lines doesn't exceed the
      maximum, also creating more if needed
   '/


   ' 1st
   if MCD <> 0 then

#if 1
      'Split spaces into seperate MCD's (incase they're moved to a new line)

      var MCD2 = MCD

      while MCD2 <> 0

         var in = InStrASM( MCD2->TextStart + 1, Text, asc(" ") )

         if ( in < ( MCD2->TextStart + MCD2->TextLen - 1 ) ) and ( in > 0 ) then

            var N = New LOT_MultiColour_Descriptor

            N->Colour = MCD2->Colour
            N->TextStart = in + 1
            N->TextLen = ( MCD2->TextLen + MCD2->TextStart ) - N->TextStart
            N->NextDesc = MCD2->NextDesc

            MCD2->NextDesc = N
            MCD2->TextLen = in - MCD2->TextStart

         EndIf

         MCD2 = MCD2->NextDesc

      Wend

#endif

      While MCD <> 0

         if MCAllocated = MultiColoursAdded then
            MCAllocated += 16
            ReDim Preserve MC_Ptr( MCAllocated )
         EndIf
         MC_Ptr( MultiColoursAdded ) = New LOT_MultiColour
         If MC_Ptr( MultiColoursAdded ) = 0 Then Exit While

         MC_Ptr( MultiColoursAdded )->Text = Mid( Text, MCD->TextStart, MCD->TextLen )
         if len_hack( MC_Ptr( MultiColoursAdded )->Text ) > 0 Then
            MC_Ptr( MultiColoursAdded )->Colour = MCD->Colour
            MC_Ptr( MultiColoursAdded )->TextStart = MCD->TextStart
   
            if Global_IRC.Global_Options.FontRender = fbgfx then
               MC_Ptr( MultiColoursAdded )->x = MCD->TextStart Shl 3 - 8
            else
               MC_Ptr( MultiColoursAdded )->x = MCD->TextStart
            EndIf
            MultiColoursAdded += 1
         endif
         MCD = MCD->NextDesc
      Wend

      For i As Integer = 1 To MultiColoursAdded - 1
         MC_Ptr( i - 1 )->NextMC = MC_Ptr( i )
      Next
      MultiColoursLeft = MultiColoursAdded

   EndIf



   ' ---------

   ' 2nd
   If Spawned = 0 Then
   
   var FontRender = Global_IRC.Global_Options.FontRender
   if RoomType = RawOutput then Global_IRC.Global_Options.FontRender = fbgfx
   
   If Global_IRC.Global_Options.FontRender <> fbgfx then

      Dim As Integer TargetX, RunningTotalX, RunningTotalChars, DummyX, MCi, MC_count
      Dim As Integer LastSpace, LastSpaceX ', NextSpace, NextSpaceX

      TargetX = TextBoxWidth - 10 - Global_IRC.TextInfo.ChatBoxCharSizeX

      if MesID < 50 then
         'variable targetX ...?
         TargetX -= CWidth( Global_IRC.TimeStamp )
      end if

      For i As Integer = 1 To Len_Hack( Text )
         If ( MultiColoursAdded > 0 ) And ( MCi < MultiColoursAdded ) Then
            If i = MC_Ptr( MCi )->x then
               MC_Ptr( MCi )->x = RunningTotalX
               If LastSpaceX < ( TargetX \ 3 ) Then
                  Var TestForSplit = RunningTotalX
                  For j As Integer = 1 To Len_hack( MC_Ptr( MCi )->Text ) - 1
                     TestForSplit += Global_IRC.TextInfo.CWidth( MC_Ptr( MCi )->Text[j-1] )
                     If TestForSplit > TargetX Then
                        if MCAllocated = MultiColoursAdded then
                           MCAllocated += 16
                           ReDim Preserve MC_Ptr( MCAllocated )
                        EndIf
                        For k As Integer = MultiColoursAdded To ( MCi + 1 ) Step -1
                           MC_Ptr( k ) = MC_Ptr( k - 1 )
                        Next
                        MC_Ptr( MCi + 1 ) = New LOT_MultiColour
                        If MC_Ptr( MCi + 1 ) = 0 Then
                           MC_Ptr( MCi )->Text = Left( MC_Ptr( MCi )->Text, j )
                           Exit For
                        EndIf
                        MC_Ptr( MCi + 1 )->Text = Mid( MC_Ptr( MCi )->Text, j + 1 )
                        MC_Ptr( MCi + 1 )->Colour = MC_Ptr( MCi )->Colour
                        MC_Ptr( MCi + 1 )->TextStart = j + 1
                        MC_Ptr( MCi + 1 )->x = i + j
                        If MultiColoursAdded > MCi + 1 Then MC_Ptr( MCi + 1 )->NextMC = MC_Ptr( MCi + 2 )
                        MultiColoursAdded += 1
                        MultiColoursLeft += 1
                        MC_Ptr( MCi )->Text = Left( MC_Ptr( MCi )->Text, j )
                        MC_Ptr( MCi )->NextMC = MC_Ptr( MCi + 1 )
                        Exit for
                     EndIf
                  Next
               EndIf
               MCi += 1
            endif
         EndIf
         RunningTotalX += Global_IRC.TextInfo.CWidth( Text[i-1] )
         RunningTotalChars += 1
         If Text[ i - 1 ] = 32 Then
            LastSpace = RunningTotalChars
            LastSpaceX = RunningTotalX
         EndIf
         If RunningTotalX >= TargetX Then
            If LastSpaceX < ( TargetX \ 3 ) Then
               LastSpace = RunningTotalChars
               LastSpaceX = RunningTotalX
            EndIf
            If LastSpace < Len_hack( NewLine->Text ) then
               var nl = AddLOTEX( Left( NewLine->Text, LastSpace ), Colour, MesID, 0, LOT_Flags or LOT_Spawned OR LOT_NoLog )
               LinesAdded += 1
               NewLine->Text = Mid( NewLine->Text, LastSpace + 1 )
               If ( MesID And 1 ) = 0 Then
                  Function = nl
                  TargetX -= 24
                  if MesID < 50 then TargetX += CWidth( Global_IRC.TimeStamp )
                  MesID OR= 1
                  NewLine->MesID OR= 1                  
               EndIf
               If MultiColoursAdded Then
                  Dim As Integer QueueToNextLine
                  For j As Integer = MC_count To ( MCi - 1 )
                     If MC_Ptr( j )->x >= LastSpaceX Then
                        MC_Ptr( j )->x -= LastSpaceX
                        QueueToNextLine += 1
                     Else
                        MultiColoursLeft -= 1
                     EndIf
                  Next
                  If ( MCi - QueueToNextLine - MC_count ) > 0 then
                     nl->MultiColour = MC_Ptr( MC_count )
                     MC_Ptr( MCi - 1 - QueueToNextLine )->NextMC = 0
                     MC_count = MCi - QueueToNextLine
                  EndIf
               EndIf
            endif
            RunningTotalX = RunningTotalX - LastSpaceX
            RunningTotalChars = RunningTotalChars - LastSpace
            LastSpace = 0
            LastSpaceX = 0
         EndIf
      Next
   Else ' 2.5
      Dim As Integer CharsPerLine = ( TextBoxWidth \ 8 ) - 1 - iif( MesID < 50, 12, 4 )
      Dim As Integer MCi, Cutoff = CharsPerLine \ 4
      While Len_Hack( NewLine->Text ) > CharsPerLine
         Dim As Integer SpaceInside, MC_Count

         SpaceInside = instrrev( NewLine->Text, " ", CharsPerLine )
         If SpaceInside < Cutoff Then SpaceInside = CharsPerLine
         If SpaceInside >= len_hack( NewLine->Text ) Then Exit while
         var nl = AddLOTEX( Left( NewLine->Text, SpaceInside ), Colour, MesID, 0, LOT_Flags or LOT_Spawned OR LOT_NoLog )
         LinesAdded += 1
         NewLine->Text = Mid( NewLine->Text, SpaceInside + 1 )
         For i As Integer = MCi To MultiColoursAdded - 1
            If MC_Ptr(i)->x >= SpaceInside Shl 3 Then
               MC_Ptr(i)->x -= SpaceInside Shl 3               
            Else
               MC_Count += 1
            EndIf
         Next
         If MC_Count > 0 Then
            MC_Ptr(MCi + MC_Count - 1)->NextMC = 0
            nl->MultiColour = MC_Ptr(MCi)
            MCi += MC_Count
         EndIf
         MultiColoursLeft -= MC_Count
         If ( MesID And 1 ) = 0 Then
            Function = nl
            MesID OR= 1
            NewLine->MesID OR= 1
            if MesID < 50 then CharsPerLine += 8
         EndIf
      Wend
   EndIf
   
   Global_IRC.Global_Options.FontRender = FontRender
   EndIf

   If MultiColoursLeft > 0 Then
      NewLine->MultiColour = MC_Ptr( MultiColoursAdded - MultiColoursLeft )
   EndIf

   TextArray[ NumLines ] = NewLine

   If ( Spawned = 0 ) And ( NewLine->MesID <> LineBreak ) and ( RoomType <> RawOutput ) Then
      DetectLinks( LinesAdded )
   EndIf
   NumLines += 1

   If ( (NewLine->MesID And 1) = 0 ) Then
      NewLine->TimeStamp = Global_IRC.TimeStamp
   EndIf
   ' -------


   ' 3rd
   If (flags AND Backlogging) = 0 Then
      CurrentLine += 1
      If ( @this = Global_IRC.CurrentRoom ) And ( PrintNow = 1 ) and ( Spawned = 0 ) And ( ( Global_IRC.WindowActive or Global_IRC.Global_Options.ShowInactive ) <> 0 ) then
         If ( Global_IRC.LastCL_Print + Global_IRC.Global_Options.MinPerLine ) < Timer Then
            if Global_IRC.Global_Options.SmoothScroll = 0 then
               UpdateChatListScroll( ChatScrollBarY, 1 )
            else
               SmoothScroll( LinesAdded )
            endif
         ElseIf Global_IRC.printQueue_C = 0 then
            Dim As event_Type et
            et.id = Screen_Update_ChatList
            et._ptr = @this
            et.when = Global_IRC.LastCL_Print + Global_IRC.Global_Options.MinPerLine
            Global_IRC.Event_Handler.Add( @et )
            Global_IRC.PrintQueue_C = 1
         endif
      EndIf
   EndIf
   ' ------


   ' 4th

   Dim As LineOfText Ptr ptr NewLocation

   #define ps sizeof( any ptr )
   #define MBL Global_IRC.Global_Options.MaxBackLog
   If NumLines > MBL Then

      Dim As Integer Start
      If ( (flags AND BackLogging) = 0 ) OR ( NumLines > MBL * 2 ) Then
         Start = MBL \ 10 + ( NumLines - MBL )
         NumLines -= Start
         CurrentLine = NumLines
         For i As Integer = 0 To Start - 1
            Delete TextArray[ i ]
         Next
         if NumAllocated > MBL then
            NumAllocated = NumLines + 128
         EndIf
         NewLocation = Allocate( ps * NumAllocated )
         memcpy( NewLocation, @( TextArray[Start] ), ps * NumLines )
         Deallocate( TextArray )
         TextArray = NewLocation
      EndIf

   EndIf

   if NumLines = NumAllocated then
      NumAllocated += 128
      NewLocation = reallocate( TextArray, ps * NumAllocated )
      if NewLocation = 0 then
         NewLocation = Allocate( ps * NumAllocated )
         memcpy( NewLocation, TextArray, ps * NumLines )
         Deallocate( TextArray )
      endif
      TextArray = NewLocation
   EndIf
   ' ------

End Function

Sub UserRoom_type.PrintChatBox( ByRef Forced As Integer = 0 )

   Dim i	As Integer = CurrentLine - 1
   If ( Global_IRC.LastLOT = TextArray[i] ) And ( Forced = 0 ) Then Exit Sub 'No need for an update...

   dim as integer OldRender, OldSize   
   if RoomType = RawOutput then
      OldRender = Global_IRC.Global_Options.FontRender
      OldSize = Global_IRC.TextInfo.ChatBoxCharSizeY
      Global_IRC.Global_Options.FontRender = fbgfx
      Global_IRC.TextInfo.ChatBoxCharSizeY = 16
   EndIf

   Dim Pen_X            As Integer
   Dim Pen_Y            As Integer = Global_IRC.Global_Options.ScreenRes_y - Global_IRC.TextInfo.ChatBoxCharSizeY - 37 ' (16 + 21)
   Dim TimeStampSize    As Integer
   Dim MinClip          As Integer = -( Global_IRC.TextInfo.ChatBoxCharSizeY * 0.45 )

   Global_IRC.LastLOT = TextArray[i]

   ScreenLock
   view ( UserListWidth, 21 )-( Global_IRC.Global_Options.ScreenRes_x - 13, Global_IRC.Global_Options.ScreenRes_y - 16 ), Global_IRC.Global_Options.BackGroundColour
   'line ( UserListWidth, 21 )-( Global_IRC.Global_Options.ScreenRes_x - 13, Global_IRC.Global_Options.ScreenRes_y - 16 ), Global_IRC.Global_Options.BackGroundColour, bf
'  ^ for PrintLOT ^ (disable view)
   
   var tmp = ""
   var TempInt = 0
   
   Do Until ( i < 0 ) Or ( PEN_Y < MinClip )
      #if 0
      PrintLOT( TextArray[ i ], 0, Pen_Y, Global_IRC.Global_Options.TextColour, Global_IRC.Global_Options.BackGroundColour )
      #else
      var LOT = TextArray[ i ]
      var TS = iif( ( LOT->MesID < 50 ) and ( ( LOT->MesID And 1 ) = 0 ) And ( Global_IRC.Global_Options.ShowTimeStamp <> 0 ), TRUE, FALSE )
      Pen_X = 4
      If TS = TRUE then
         TimeStampSize = DrawString( Pen_x, Pen_Y, LOT->TimeStamp, Global_IRC.Global_Options.TextColour ) - Pen_X
         Pen_x += TimeStampSize
      EndIf
      Select case LOT->MesID
         Case NormalChat
            TempInt = LOT->Offset 'InStrASM( 1, LOT->Text, asc(":") )
            if TempInt > 0 then
               tmp = Left( LOT->Text, TempInt )
               Pen_x = DrawString( Pen_X, Pen_Y, tmp, LOT->Colour )
            endif
            tmp = Mid( LOT->Text, TempInt + 1 )
            DrawString( Pen_X, Pen_Y, tmp, Global_IRC.Global_Options.TextColour )

         Case ExNormalChat
            DrawString( 24, Pen_Y, LOT->Text, Global_IRC.Global_Options.TextColour )
         Case LineBreak
            Line ( 40, Pen_Y + Global_IRC.TextInfo.ChatBoxCharSizeY \ 4 )-( TextBoxWidth - 53, Pen_Y + Global_IRC.TextInfo.ChatBoxCharSizeY \ 4 ), LOT->Colour, , &b1111000011110000
            if len_hack( LOT->Text ) then
               TempInt = CWidth( LOT->Text )
               Pen_X = ( TextBoxWidth \ 2 ) - ( TempInt \ 2 ) - 7
               Line ( Pen_X - 4, Pen_Y )-( Pen_X + 4 + TempInt, Pen_Y + Global_IRC.TextInfo.ChatBoxCharSizeY - 1 ), Global_IRC.Global_Options.BackGroundColour, BF
               DrawString( Pen_X, Pen_Y, LOT->Text, LOT->Colour )
            endif
         'Case ServerMessage
            'DrawString( 4, Pen_Y, LOT->Text, LOT->Colour, Global_IRC.Global_Options.ChatBoxFont, Global_IRC.Global_Options.ChatBoxFontSize )
         'Case ExServerMessage
            'DrawString( 24, Pen_Y, LOT->Text, LOT->Colour, Global_IRC.Global_Options.ChatBoxFont, Global_IRC.Global_Options.ChatBoxFontSize )
         case ChatHistory
            DrawString( Pen_X, Pen_Y, LOT->Text, LOT->Colour )
         case ExChatHistory
            DrawString( 24, Pen_Y, LOT->Text, Global_IRC.Global_Options.ChatHistoryColour )
         Case Else
            DrawString( IIf( LOT->MesID And 1, 24, 4 + IIf( TS, TimeStampSize, 0 ) ), Pen_Y, LOT->Text, LOT->Colour )
      End Select

      If LOT->HyperLinks <> 0 Then

         var HLB = LOT->HyperLinks

         While HLB <> 0
            DrawString( HLB->X1 + IIf( LOT->MesID And 1, 24, 4 + IIf( TS, TimeStampSize, 0 ) ), Pen_Y, HLB->AltText, Global_IRC.Global_Options.LinkColour )
            HLB = HLB->NextLink
         Wend

      EndIf

      If LOT->MultiColour <> 0 Then

         var MC = LOT->MultiColour

         While MC <> 0
            DrawString( MC->x + IIf( LOT->MesID And 1, 24, 4 + IIf( TS, TimeStampSize, 0 ) ), Pen_Y, MC->Text, MC->Colour )
            MC = MC->NextMC
         Wend

      EndIf
      #endif
      Pen_Y -= Global_IRC.TextInfo.ChatBoxCharSizeY
      i -= 1
   Loop

   ScreenUnLock
   view

   Global_IRC.LastCL_Print = Timer
   Global_IRC.PrintQueue_C = 0
   
   if RoomType = RawOutput then
      Global_IRC.Global_Options.FontRender = OldRender
      Global_IRC.TextInfo.ChatBoxCharSizeY = OldSize
   end if

End Sub

Sub UserRoom_type.DetectLinks( ByVal NumLinesAdded As Integer )

   Static HyperLinkSearch( 0 to 4 ) As CONST ZString Ptr => _
      { _
         @"HTTP://", _
         @"HTTPS://", _
         @"FTP://", _
         @"WWW.", _
         @"#" _
      }

   static HLS( 0 to 4 ) as string

   if str_len( HLS(0) ) = 0 then
      for i as integer = 0 to ubound( HyperLinkSearch )
         HLS(i) = *HyperLinkSearch(i)
      Next
   EndIf

   if NumLinesAdded > ( NumLines + 1 ) then
      NumLinesAdded = NumLines + 1
   EndIf

   Dim WorkingLine As Integer = NumLines - NumLinesAdded + 1
   Dim LinkID as Integer
   Dim UCaseText as string

   For j As Integer = 1 To NumLinesAdded

      Dim As Integer InStrStart = 1

      UCaseText = UCase( TextArray[ WorkingLine ]->Text )

      var Length = len_hack( UCaseText )

      Do
         var LinkFound = Length

         #if 0
         'Old Method, faster?
         For i As Integer = 0 To ubound( HyperLinkSearch )
            Var TempInStr = InStr( InStrStart, UCaseText, HLS(i) )
            If ( TempInStr > 0 ) And ( TempInStr < LinkFound ) Then
               LinkFound = TempInStr
            EndIf
         Next
         #else

         'New
         dim as integer found( ubound( HyperLinkSearch ) ), char
         for i as integer = ( InStrStart - 1 ) to ( Length - 1 )
            char = UCaseText[i]
            for k as integer = 0 to ubound( HyperLinkSearch )
               if char = HyperLinkSearch(k)[ found( k ) ] then
                  found(k) += 1
                  if HyperLinkSearch(k)[ found( k ) ] = 0 then
                     select case UCaseText[i + 1]
                     case asc("."), asc(",")
                        i += 1
                        continue for, for
                     case asc(" "), 0
                        if k < 4 then
                           i += 1
                           continue for, for
                        EndIf
                     End Select
                     LinkFound = i - found(k) + 2
                     LinkID = iif( k = 4, LinkChannel, LinkWeb )
                     Exit For, For
                  EndIf
               else
                  found(k) = 0
               EndIf
            Next
         Next
         #endif

         If LinkFound <> Length Then

            Dim As Integer SpaceInside = InStrAsm( LinkFound, UCaseText, Asc(" ") )
            If SpaceInside Then
               TextArray[ WorkingLine ]->AddLink( LinkFound, SpaceInside, 0, LinkID )
               InStrStart = SpaceInside
            Else
               Dim As String AltText = *cptr( zstring ptr, @( TextArray[ WorkingLine ]->Text[ LinkFound - 1 ] ) )
               Dim As String HyperLink = AltText
               Dim As Integer Lines = 1
               Do until WorkingLine = NumLines
                  WorkingLine += 1
                  If (TextArray[ WorkingLine ]->MesID AND 1) Then
                     Lines += 1
                     HyperLink += TextArray[ WorkingLine ]->Text
                     SpaceInside = InStrAsm( 1, HyperLink, Asc(" ") )
                     If SpaceInside Then
                        HyperLink = Left( HyperLink, SpaceInside - 1 )
                        Exit Do
                     EndIf
                  Else
                     Exit Do
                  EndIf
               Loop
               For i As Integer = 2 To Lines
                  TextArray[ WorkingLine ]->AddLink( 1, InStrAsm( 1, TextArray[ WorkingLine ]->Text, Asc(" ") ), HyperLink, LinkID )
                  WorkingLine -= 1
               Next
               InStrStart = Len_hack( TextArray[ WorkingLine ]->Text )
               TextArray[ WorkingLine ]->AddLink( LinkFound, InStrStart + 1, HyperLink, LinkID )
            EndIf
         Else
            Exit Do
         EndIf
      Loop
      WorkingLine += 1

   Next

End Sub

Function UserRoom_type.AddUser _
   ( _
      ByRef Username    As ZString Ptr, _
      ByRef Colour      As uInt32_t = 0 _
   ) As UserName_Type Ptr

   Var NewUser	= New Username_type

   If Colour Then
      NewUser->ChatColour = Colour
   Else
      NewUser->ChatColour = rndColour( Global_IRC.DarkUsers )
      While NewUser->ChatColour = Global_IRC.Global_Options.YourChatColour
         NewUser->ChatColour = rndColour( Global_IRC.DarkUsers )
      Wend
   EndIf

   Dim As Integer hit, i, c, PrivCount, LowPriv = &h7FFFFFFF
   dim as integer ub = ubound( Server_Ptr->ServerInfo.VPrefix )
   dim as ubyte ptr vprefix = @( Server_Ptr->ServerInfo.VPrefix(0) )

   c = Username[0][0]
   do until ( c = 0 ) or ( hit = 1 )
      hit = 1
      For j As Integer = 0 To ub
         If c = vprefix[j] Then
            hit = 0
            PrivCount += 1
            If j < LowPriv Then
               LowPriv = j
            EndIf
            exit for
         EndIf
      Next
      i += 1
      c = Username[0][i]
   loop

   'NewUser->Username = Trim( Mid( *Username, PrivCount + 1 ) )
   NewUser->Username = *cptr( zstring ptr, @Username[ PrivCount ] )
   
   If LowPriv <> &h7FFFFFFF Then

      NewUser->Privs = VPrefix[ LowPriv ]
      If Global_IRC.Global_Options.SortByPrivs Then
         NewUser->SortHelper = LowPriv
      EndIf

   ElseIf Global_IRC.Global_Options.SortByPrivs <> 0 Then

      NewUser->SortHelper = 255

   EndIf

   If Global_IRC.Global_Options.SortByPrivs = 0 Then
      NewUser->SortHelper = 255
   EndIf
   
   Var UcaseName = Server_Ptr->UCase_( NewUser->UserName )

   NewUser->Sort = SortCreate( UcaseName )

   if NumUsers = 0 then
      FirstUser = NewUser
      LastUser = NewUser
      TopDisplayedUser = NewUser
       
   #if 1 'quick twitch fix?
   elseif UserListWidth <= 0 then
      
      LastUser->NextUser = NewUser
      NewUser->PrevUser = LastUser
      LastUser = NewUser
   #endif
      
   Else

      var UNT = FirstUser

      If NewUser->SortHelper = 255 Then

         For i = 1 To NumUsers

            If UNT->SortHelper = 255 Then
               If NewUser->Sort <= UNT->Sort then
                  if ( len_hack( UcaseName ) < 9 ) orelse ( UcaseName < Server_Ptr->UCase_( UNT->Username ) ) Then
                     If i = 1 Then
                        FirstUser = NewUser
                     Else
                        NewUser->PrevUser = UNT->PrevUser
                        UNT->PrevUser->NextUser = NewUser
                     EndIf
                     UNT->PrevUser = NewUser
                     NewUser->NextUser = UNT
                     Exit For
                  endif
               endif
            endif
            UNT = UNT->NextUser
            
         Next
         
         If i > NumUsers Then
            NewUser->PrevUser = LastUser
            LastUser->NextUser = NewUser
            LastUser = NewUser
         EndIf

      Else

         For i = 1 To NumUsers
            If ( NewUser->SortHelper < UNT->SortHelper ) Or _
               ( ( NewUser->SortHelper = UNT->SortHelper ) And _
               ( NewUser->Sort <= UNT->Sort ) andalso _
               ( UcaseName < Server_Ptr->UCase_( UNT->Username ) ) ) Then

               If i = 1 Then
                  FirstUser = NewUser
               Else
                  NewUser->PrevUser = UNT->PrevUser
                  UNT->PrevUser->NextUser = NewUser
               EndIf
               UNT->PrevUser = NewUser
               NewUser->NextUser = UNT
               Exit For
            endif

            UNT = UNT->NextUser
         Next
         
         If i > NumUsers Then
            NewUser->PrevUser = LastUser
            LastUser->NextUser = NewUser
            LastUser = NewUser
         EndIf

      endif

      if ( NewUser->NextUser = TopDisplayedUser ) and ( NewUser <> LastUser ) then
         TopDisplayedUser = NewUser
      EndIf

   Endif

   NumUsers += 1

   If (@this = Global_IRC.CurrentRoom) And (Global_IRC.WindowActive = 1) And ((pflags AND UsersLock) = 0) and (UserListWidth > 0) Then
      If Global_IRC.LastUL_Print + Global_IRC.Global_Options.MinPerLine < Timer then
         UpdateWindowTitle( )
         UpdateUserListScroll( -123456 )
      ElseIf Global_IRC.PrintQueue_U = 0 then
         Dim As event_Type et
         et.when = Global_IRC.LastUL_Print + Global_IRC.Global_Options.MinPerLine
         et.id = Screen_Update_UserList
         et._ptr = @this
         Global_IRC.Event_Handler.Add( @et )
         Global_IRC.PrintQueue_U = 1
      endif
   EndIf   

   Function = NewUser

End Function

Sub UserRoom_type.DelUser( ByRef UNT As UserName_type Ptr )
   
   If FirstUser = UNT Then
      FirstUser = UNT->NextUser
      FirstUser->PrevUser = 0
      If UNT = TopDisplayedUser Then TopDisplayedUser = UNT->NextUser
   ElseIf LastUser = UNT Then
      LastUser = UNT->PrevUser
      LastUser->NextUser = 0
      If UNT = TopDisplayedUser Then TopDisplayedUser = UNT->PrevUser
   Else
      UNT->PrevUser->NextUser = UNT->NextUser
      UNT->NextUser->PrevUser = UNT->PrevUser
      If UNT = TopDisplayedUser Then TopDisplayedUser = UNT->PrevUser
   EndIf

   Delete UNT
   NumUsers -= 1

   If ( @this = Global_IRC.CurrentRoom ) And _
      ( ( Global_IRC.WindowActive = 1 ) or ( Global_IRC.Global_Options.ShowInactive <> 0 ) ) and _
      ( (pflags AND UsersLock) = 0 ) and ( UserListWidth > 0 ) Then

      If Global_IRC.LastUL_Print + Global_IRC.Global_Options.MinPerLine < Timer then
         UpdateWindowTitle( )
         UpdateUserListScroll( -123456 )
      ElseIf Global_IRC.PrintQueue_U = 0 then
         Dim As event_Type et
         et.when = Global_IRC.LastUL_Print + Global_IRC.Global_Options.MinPerLine
         et.id = Screen_Update_UserList
         et._ptr = @this
         Global_IRC.Event_Handler.Add( @et )
         Global_IRC.PrintQueue_U = 1
      endif
   EndIf

End Sub

Sub UserRoom_type.DelUser( ByRef Username As string )

   Var UNT = Find( UserName )

   If UNT Then DelUser( UNT )

End Sub

Function UserRoom_type.Find( ByRef user As String ) As UserName_type Ptr

   dim as UserName_Type Ptr UNT
   dim as string fullname
   dim as Integer Rev = FALSE

   Var UcaseName  = Server_Ptr->UCase_( user )
   Var SortFind   = SortCreate( UcaseName )   

   If ( SortFind > 5787213827046133840ULL ) or ( UserListWidth <= 0 ) Then
      Rev = TRUE
      UNT = LastUser
   Else
      UNT = FirstUser
   EndIf

   if Rev = FALSE then

      For i As Integer = 1 To NumUsers

         If SortFind = UNT->Sort Then
            If ( len_hack( UcaseName ) < 9 ) and ( len_hack( UcaseName ) = len_hack( UNT->UserName ) ) Then
               Return UNT
            Else
               fullname = Server_Ptr->UCase_( UNT->Username )
               If StringEqualAsm( fullname, UcaseName ) Then
                  Return UNT
               endif
            endif
         EndIf

         UNT = UNT->NextUser

      Next

   else

      For i As Integer = 1 To NumUsers

         If SortFind = UNT->Sort Then
            If ( len_hack( UcaseName ) < 9 ) and ( len_hack( UcaseName ) = len_hack( UNT->UserName ) ) Then
               Return UNT
            Else
               fullname = Server_Ptr->UCase_( UNT->Username )
               If StringEqualAsm( fullname, UcaseName ) Then
                  Return UNT
               endif
            endif
         EndIf

         UNT = UNT->PrevUser

      Next

   EndIf

   Function = 0

End Function

Sub UserRoom_type.PrintUserList( ByRef Forced As Integer = 0 )

   dim as integer Pen_Y
   dim as string tmp
   var UNT = TopDisplayedUser

   ScreenLock
   view ( 0, 21 )-( UserListWidth - 8, Global_IRC.Global_Options.ScreenRes_y ), Global_IRC.Global_Options.BackGroundColour

   'Line ( 0, 0 )-( UserListWidth - 8, 1 ), Global_IRC.Global_Options.ScrollBarForegroundColour, BF
   if RoomType = RoomTypes.LIST then

      #define chars 50

      do Until ( UNT = 0 ) Or ( Pen_Y > Global_IRC.Global_Options.ScreenRes_y )
         if len_hack( UNT->UserName ) > chars then
            tmp = left( UNT->UserName, chars )
         else
            tmp = UNT->UserName
         EndIf
         DrawString( 2, Pen_Y, tmp, UNT->ChatColour, DS_Hint.UL )
         UNT = UNT->NextUser
         Pen_Y += Global_IRC.TextInfo.UserListCharSizeY
      Loop

   else

      do Until ( UNT = 0 ) Or ( Pen_Y > Global_IRC.Global_Options.ScreenRes_y )
         if UNT->Privs <> 0 then
            tmp = chr( UNT->Privs ) + UNT->UserName
         else
            tmp = UNT->UserName
         EndIf
         DrawString( 2, Pen_Y, tmp, UNT->ChatColour, DS_Hint.UL )
         UNT = UNT->NextUser
         Pen_Y += Global_IRC.TextInfo.UserListCharSizeY
      Loop

   EndIf

   ScreenUnLock
   view

   Global_IRC.LastUL_Print = Timer
   Global_IRC.PrintQueue_U = 0

End Sub

Function GetDateInt( byref s as string ) as integer

'  #channel 02-18-2010.log

   var a = mid( left( s, len( s ) - 4 ), len( s ) - 14 )
   var y = right( a, 4 )
   var m = left( a, 2 )
   var d = mid( a, 4, 2 )

   Function = ValInt( y + m + d )

End Function

#undef max
Function GetRevStrings( byref file as string, msg() as string, byref start as integer, byref max as integer ) as integer

   var c = start
   var ff = freefile
   if Open( file For binary access read As #ff ) <> 0 then
      return c
   EndIf

   Seek #ff, LOF( ff ) + 1

   do until ( loc( ff ) <= 1 ) or ( c = max )

      RevLineInput( ff, msg( c ) )
      if len_hack( msg( c ) ) < 25 then continue do

      select case msg( c )[ 22 ]
         case asc( "[" ) 'Normal Message
         case asc( "*" ) 'Action Emote?
            if msg( c )[ 23 ] = asc( "*" ) then continue do 'Info message
         case else
            continue do
      End Select

      c += 1

   Loop

   Close #ff

   Function = c

End Function

Sub UserRoom_Type.LoadHistory( )

   dim as integer N = Global_IRC.Global_Options.LogLoadHistory

   if N <= 0 then Exit Sub
   If N > Global_IRC.Global_Options.MaxBackLog then N = Global_IRC.Global_Options.MaxBackLog

   var sfn = Server_ptr->ServerOptions.LogFolder + "/" + lcase( SafeFileNameEncode( RoomName ) ) + ".log"

   redim as string msg( N )
   var c = GetRevStrings( sfn, msg(), 0, N )

   if c < n then
      '' Search for other logfiles
      var d = dir( left( sfn, len( sfn ) - 4 ) + " *.log" )

      if len( d ) > 0 then

         redim as string f(32)
         var cnt = -1

         while len( d ) > 0
            cnt += 1
            if cnt > ubound( f ) then
               redim preserve f( ubound( f ) + 32 )
            EndIf
            f( cnt ) = d
            d = dir( )
         Wend

         redim as integer di( cnt )

         for i as integer = 0 to cnt
            di(i) = GetDateInt( f(i) )
         next

         for i as integer = 0 to cnt
            for ii as integer = 0 to cnt
               if i = ii then continue for
               select case di(i)
               case is > di( ii )
                  swap f( i ), f( ii )
                  swap di( i ), di( ii )
               case di( ii )
                  var ddt = FileDateTime( Server_ptr->ServerOptions.LogFolder + "/" + f( i ) )
                  var d2dt = FileDateTime( Server_ptr->ServerOptions.LogFolder + "/" + f( ii ) )
                  if ddt > d2dt then
                     swap f( i ), f( ii )
                     swap di( i ), di( ii )
                  EndIf
               End Select
            Next
         Next

         for i as integer = 0 to cnt
            c = GetRevStrings( Server_ptr->ServerOptions.LogFolder + "/" + f( i ), msg(), c, N )
            if c = N then
               exit for
            EndIf
         Next

      EndIf
   EndIf

   if c = 0 then
      msg( 0 ) = ""
      Exit Sub
   EndIf

   dim as string date1, date2
   dim as username_type ptr UNT

   var MCD1 = New LOT_MultiColour_Descriptor

   MCD1->TextStart = 1
   MCD1->Colour = Global_IRC.Global_Options.TextColour

   var LOT = AddLOT( "* Loading History *", Global_IRC.Global_Options.ChatHistoryColour, 0, LineBreak )

   TopDisplayedUser = FirstUser
   pflags OR= UsersLock
   Global_IRC.SwitchRoom( @this )
   Global_IRC.CurrentRoom = Server_Ptr->Lobby

   LOT->Text = "* History *"

   var d = c 'complete the circle
   var Oset = 0 'User Offset
   var i = 0 'loop flag
   dim user as string 'User nick

   do

      c -= 1
      if c < 0 then c = ubound( msg )
      if d = c then Exit Do

      if len_hack( msg(c) ) <= 25 then
         msg( c ) = ""
         Continue do
      EndIf

      if msg( c )[ 22 ] = asc( "[" ) then
         Oset = 25
      else
         Oset = 24
      EndIf
      
      for i = 0 to ubound( Server_Ptr->ServerInfo.VPrefix )
         if msg(c)[Oset-1] = Server_Ptr->ServerInfo.VPrefix(i) then
            user = mid( msg(c), Oset + 1, InStrASM( Oset, msg(c), asc(" ") ) - Oset - 1 )
            exit for
         EndIf
      Next
      
      if i > ubound( Server_Ptr->ServerInfo.VPrefix ) then
         user = mid( msg(c), Oset, InStrASM( Oset, msg(c), asc(" ") ) - Oset )
      EndIf

      UNT = Find( user )
      if UNT = 0 then
         UNT = AddUser( user )
      EndIf

      date2 = left( msg( c ), 10 )
      if StringEqualASM( date2, date1 ) then
         msg( c ) = mid( msg( c ), 12 )
         MCD1->TextLen = 11
      else
         date1 = date2
         MCD1->TextLen = 22
      EndIf

      var MCD2 = New LOT_MultiColour_Descriptor

      MCD2->Colour = UNT->ChatColour
      MCD2->TextStart = MCD1->TextLen + 1
      MCD2->TextLen = len_hack( user ) + iif( Oset = 25, 5, 1 )
      MCD1->NextDesc = MCD2

      AddLOT( msg( c ), Global_IRC.Global_Options.ChatHistoryColour, 0, ChatHistory, , MCD1, TRUE )
      msg( c ) = ""
      Delete MCD2
      MCD1->NextDesc = 0

   Loop

   Delete MCD1

   pflags AND= NOT( UsersLock )
   Global_IRC.CurrentRoom = @this
   pflags or= FakeUsers

   AddLOT( "* History End *", Global_IRC.Global_Options.ChatHistoryColour, 1, LineBreak )

End Sub

Destructor UserRoom_type

   LIC_DESTRUCTOR1

   If NumUsers > 0 then

      var UNT = FirstUser
      var UNT2 = UNT->NextUser

      For i As Integer = 1 To NumUsers - 1
         Delete UNT
         UNT = UNT2
         UNT2 = UNT2->NextUser
      Next

      delete UNT

   EndIf

#if LIC_DCC
   var DT = Global_IRC.DCC_List.Find( @this )
   if DT <> 0 then
      Global_IRC.DCC_List.Remove( DT->ID )
   EndIf
#endif

   For i As Integer = 0 To ( NumLines - 1 )
      Delete TextArray[i]
   Next
   
   if OldUsers then
      DeAllocate( OldUsers )
   EndIf
   
   DeAllocate( TextArray )

   RoomName = ""
   Topic = ""
   LogBuffer = ""
   LastMODE = ""

   LIC_DESTRUCTOR2

End Destructor
