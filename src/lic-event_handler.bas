#Include "lic.bi"
#Include "crt/string.bi"

Sub Event_Handler_Type.Add( Byref e_t As event_type Ptr  )

   If Queued = Allocated Then
      Var new_space = Callocate( ( Allocated + 4 ) * SizeOf( Any Ptr ) )
      If New_space = 0 Then Exit Sub
      If Queued Then
         memcpy( new_space, events, Allocated * SizeOf( Any Ptr ) )
      EndIf
      DeAllocate( events )
      events = new_space
      Allocated += 4
   EndIf

   Dim As Integer Free_Space

   While events[ Free_Space ] <> 0
      Free_Space += 1
   Wend

   events[ Free_Space ] = New event_Type

   If events[ Free_Space ] = 0 Then Exit Sub

   memcpy( events[ Free_Space ], e_t, SizeOf( event_type ) - ( ( ubound( e_t->Param ) + 4 ) * SizeOf( String ) ) )

   for i as integer = 0 to ubound( e_t->Param )
      events[ Free_Space ]->Param(i) = ucase( e_t->Param(i) )
   Next
   
   events[ Free_Space ]->_String = e_t->_String   
   events[ Free_Space ]->mask = e_t->mask
   events[ Free_Space ]->saction = e_t->saction

   queued += 1
   Count += 1

   If e_t->Unique_Id = 0 Then
      events[ Free_Space ]->Unique_Id = Count
      e_t->Unique_Id = Count
   EndIf

End Sub

Sub Event_Handler_Type.Clean( )
   For i As Integer = 0 To Queued - 1
      Delete events[i]
   Next
   DeAllocate( events )
   Queued = 0
   Allocated = 0
End Sub

Sub Event_Handler_Type.Check( )

   If Queued = 0 Then
      If Allocated > 4 Then
         Var new_spot = Reallocate( events, 4 * SizeOf( Any Ptr ) )
         If new_spot then
            Allocated = 4
            events = new_spot
         endif
      EndIf
      Exit Sub
   EndIf

   With Global_IRC

   Var T = timer
   For i As Integer = 0 To Allocated - 1

      If events[i] = 0 Then Continue For
      If T < events[i]->when Then Continue For

      Select Case events[i]->id

         Case Screen_Update_ChatList
            If ( ( .WindowActive <> 0 ) or ( .Global_Options.ShowInactive <> 0 ) ) And ( .CurrentRoom = events[i]->_ptr ) And ( (.CurrentRoom->flags AND Backlogging) = 0 ) Then
               'if Global_IRC.Global_Options.SmoothScroll = 0 then
                  .CurrentRoom->UpdateChatListScroll( .CurrentRoom->ChatScrollBarY, 1 )
               'else
                  '.CurrentRoom->SmoothScroll(
               'endif
            EndIf

         Case Screen_Update_UserList
            If ( ( .WindowActive <> 0 ) or ( .Global_Options.ShowInactive <> 0 ) ) And ( .CurrentRoom = events[i]->_ptr ) And ( .CurrentRoom->UserListWidth > 0 ) then
               .CurrentRoom->UpdateUserListScroll( -123456 )
            EndIf

         Case Server_Output
            var S = ServerCheck( events[i]->_ptr )

            if S <> 0 then
               S->SendLine( events[i]->_string )
            EndIf

         Case Timeout_Server
            var S = ServerCheck( events[i]->_ptr )

            If S = 0 orelse S->Event_Handler.Queued = 0 Then
               Exit Select
            EndIf

            For ii As Integer = 0 To S->Event_Handler.Allocated - 1
               If S->Event_Handler.events[ii] = 0 Then Continue For

               With *S->Event_Handler.events[ii]

               If events[i]->Unique_ID = .Unique_ID Then

                  Select Case .id
                     Case Server_Input, Server_Output
                        S->SendLine( ._string )
                     Case Timeout_Server
                        #if LIC_CHI
                           S->ServerSocket.Close( )
                        #else
                           closesocket( S->ServerSocket )
                        #endif
                        LIC_DEBUG( "\\No Server PONG from " & S->ServerOptions.Server )
                  End Select

                  Delete S->Event_Handler.events[ii]
                  S->Event_Handler.events[ii] = 0
                  S->Event_Handler.queued -= 1

               EndIf

               End with

            Next

         case Delete_Room
            var Server = ServerCheck( events[i]->_ptr )

            if Server <> 0 then

               var URT = server->RoomCheck( cast( any ptr, events[i]->_integer ) )

               if URT <> 0 then
                  server->DelRoom( URT )
               End If

            End If

         case Thread_Wait
            MutexUnlock( Global_IRC.Mutex )
            ThreadWait( events[i]->_ptr )
            MutexLock( Global_IRC.Mutex )

      End Select

      Delete events[i]
      Queued -= 1
      events[i] = 0

   Next

   End with

End Sub

Constructor Event_Handler_Type

   Allocated = 4
   events = cAllocate( Allocated * SizeOf( Any Ptr ) )

End Constructor

Destructor Event_Handler_Type

   LIC_DESTRUCTOR1

   this.Clean( )

   LIC_DESTRUCTOR2

End Destructor

Destructor event_type

   LIC_DESTRUCTOR1

   _string = ""
   mask = ""
   for i as integer = 0 to ubound( param )
      param( i ) = ""
   Next

   LIC_DESTRUCTOR2

End Destructor
