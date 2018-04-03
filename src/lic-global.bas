#Include Once "lic.bi"

Extern ChatInput As FBGFX_CHARACTER_INPUT

Sub Global_IRC_Type.DelServer( Byref server_num as integer )

   if ( server_num <= 0 ) or ( server_num > NumServers ) or ( NoServers = TRUE ) then
      Exit Sub
   EndIf

   WriteLogs( )

   redim as UserRoom_Type ptr orphans()
   dim as integer orphan_count

   '' Check for any DCC rooms
   var URT = Server[ server_num - 1 ]->FirstRoom
   for i as integer = 1 to Server[ server_num - 1 ]->NumRooms
      if ( URT->RoomType = DccChat ) and ( (URT->pflags AND Hidden) = 0 ) then
         if orphan_count >= ubound( orphans ) then
            redim preserve orphans( ubound( orphans ) + 8 )
         EndIf
         orphans( orphan_count ) = URT
         orphan_count += 1
      EndIf
      URT = URT->NextRoom
   Next

   for i as integer = 1 to orphan_count
      Server[ server_num - 1 ]->DetachRoom( orphans( i - 1 ) )
   Next

   if NumServers = 1 then

      delete server[ 0 ]
      AddDefaultServer( )

   else

      dim as server_type ptr ptr new_spot = Allocate( ( NumServers - 1 ) * sizeof( Any ptr ) )

      URT = CurrentRoom
      while URT->Server_Ptr = Server[ server_num - 1 ]
         URT = GetPrevRoom( URT )
      Wend
      if URT <> CurrentRoom then
         SwitchRoom( URT )
      EndIf

      for i as integer = 1 to server_num - 1
         new_spot[i - 1] = server[i - 1]
      Next
      for i as integer = server_num + 1 to NumServers
         new_spot[i - 2] = server[i - 1]
         new_spot[i - 2]->ServerNum -= 1
      Next

      delete server[ server_num - 1 ]
      Deallocate( server )
      server = new_spot
      NumServers -= 1

   EndIf

   for i as integer = 1 to orphan_count
      CurrentRoom->Server_Ptr->AttachRoom( orphans( i - 1 ) )
   next

End Sub

Sub Global_IRC_Type.AddServer( byref S as Server_Options_Type )

   If len_hack( S.Server ) = 0 Then
      if S.ChanInfo <> 0 then
         Delete S.ChanInfo
         S.ChanInfo = 0
      EndIf
      Exit Sub
   Endif

   redim as UserRoom_Type ptr orphans()
   dim as integer orphan_count

   var NoS = NoServers

   if NoServers <> FALSE then
      var URT = Server[0]->FirstRoom->NextRoom
      for i as integer = 2 to Server[0]->NumRooms
         if ( URT->RoomType = DccChat ) and ( (URT->pflags AND Hidden) = 0 ) then
            if orphan_count >= ubound( orphans ) then
               redim preserve orphans( ubound( orphans ) + 8 )
            EndIf
            orphans( orphan_count ) = URT
            orphan_count += 1
         endif
         URT = URT->NextRoom
      Next
      for i as integer = 1 to orphan_count
         Server[0]->DetachRoom( orphans( i - 1 ) )
      Next
      RemDefaultServer( )
   EndIf

   var ServerNum = Global_IRC.NumServers

   NumServers += 1

   var NewSpot = reAllocate( Server, NumServers * SizeOf( Any Ptr ) )

   if NewSpot = 0 then
      NewSpot = Allocate( NumServers * SizeOf( Any Ptr ) )
      memcpy( NewSpot, Server, ServerNum * SizeOf( Any Ptr ) )
      Deallocate( Server )
   endif

   Server = NewSpot
   Server[ServerNum] = New Server_Type

   With Server[ServerNum]->ServerOptions

   .Port = S.Port
   .Server = S.Server
   .Password = S.Password
   .Nickname = S.Nickname
   .Username = S.Username
   .Hostname = S.Hostname
   .Realname = S.Realname
   .AutoExec = S.AutoExec
   .AutoJoin = S.Autojoin
   .AutoPass = S.Autopass
   .ChanInfo = S.ChanInfo
   .IgnoreList = S.IgnoreList
   .IdentifyService = S.IdentifyService
   .LogFolder = S.LogFolder
   .DccAutoAccept = S.DccAutoAccept
   .DccAutoList = S.DccAutoList
   .TwitchHacks = S.TwitchHacks
   .TwitchKillEmotes = S.TwitchKillEmotes
   .ScriptFile = S.ScriptFile

   if len_hack( .LogFolder ) = 0 then
      .LogFolder = exepath + "/log/" + .Server
   EndIf

   if len_hack( .ScriptFile ) > 0 then
      Server[ServerNum]->LoadScriptFile( )
   EndIf

   End With

   with *( Server[ServerNum] )

   .Lobby = .AddRoom( .ServerOptions.Server, Lobby )
   .ServerName = .ServerOptions.Server
   .ServerNum = ServerNum
   #if LIC_CHI
      .ServerSocket.p_send_sleep = 50
   #endif
   
   if Global_IRC.Global_Options.ShowRaw <> FALSE then
      .RawRoom = .AddRoom( "+" & .ServerOptions.Server & "+", RawOutput )  
   EndIf

   if NoS <> FALSE then
      SwitchRoom( .Lobby )
      for i as integer = 1 to orphan_count
         .AttachRoom( orphans( i - 1 ) )
      Next
   EndIf

   end with

   S.ChanInfo = 0 'insures the destructor doesn't delete

End Sub

Sub AddDefaultServer( )

   with Global_IRC

   if .Server = 0 then
      .Server = Allocate( sizeof( any ptr ) )
   EndIf

   .NumServers = 1
   .NoServers = TRUE

   .Server[0] = New Server_Type

   'Disable connecting
   .Server[0]->State = ServerStates.offline

   'Disable logging
   .Server[0]->ServerOptions.LogFolder = "?"

   ScreenLock

   .Server[0]->Lobby = .Server[0]->AddRoom( "LIC", Lobby )
   .CurrentRoom = .Server[0]->Lobby

   for i as integer = 0 to (.CurrentRoom->NumLines - 1)
      delete .CurrentRoom->TextArray[i]
   Next
   .CurrentRoom->NumLines = 0
   .CurrentRoom->CurrentLine = 0

   .CurrentRoom->AddLOT( "There are currently no servers",    RGB( 255, 0, 0 ), 0, Notification )
   .CurrentRoom->AddLOT( "Use '/server <server>' to add one", RGB( 0, 255, 0 ), 0, Notification )
   .CurrentRoom->AddLOT( "Use '/help' for more help",         RGB( 0, 255, 0 ), 1, Notification )

   ChatInput.X1 = 12
   Draw String ( 2, Global_IRC.Global_Options.ScreenRes_y - 16 ), ">", Global_IRC.Global_Options.YourChatColour

   ScreenUnlock

   End With

End Sub

Sub RemDefaultServer( )

   Delete Global_IRC.Server[0]

   Global_IRC.NumServers = 0
   Global_IRC.NoServers = FALSE

End Sub

Function ServerCheck( byref S as any ptr ) as Server_Type ptr

   for i as integer = 0 to Global_IRC.NumServers - 1
      if cptr( any ptr, Global_IRC.Server[i] ) = S then
         return Global_IRC.Server[i]
      EndIf
   Next

End Function

Sub Global_IRC_type.SwitchRoom( ByRef Room_Ptr As UserRoom_type Ptr )

   Global_IRC.SwapRoom = Global_IRC.CurrentRoom

   If Room_Ptr->UserListWidth > 0 Then
      Room_Ptr->UpdateUserListScroll( Room_Ptr->UserScrollBarY )
   EndIf

   Room_Ptr->UpdateChatListScroll( 0, 1, iif( Room_Ptr->CurrentLine < MaxDisp_C, 1, Room_Ptr->CurrentLine - MaxDisp_C + 1 ) )
   Room_Ptr->pflags AND= Not( FlashingTab )

   Global_IRC.CurrentRoom = Room_Ptr

   Global_IRC.DrawTabs( )

   screenlock
   line ( Room_Ptr->UserListWidth, Global_IRC.Global_Options.ScreenRes_y - 16 )-( Room_Ptr->UserListWidth + 12, Global_IRC.Global_Options.ScreenRes_y ), Global_IRC.Global_Options.BackGroundColour, BF
   Draw String ( Room_Ptr->UserListWidth + 2, Global_IRC.Global_Options.ScreenRes_y - 16 ), ">", Global_IRC.Global_Options.YourChatColour
   screenunlock

   UpdateWindowTitle( )

   ChatInput.x1 = Room_Ptr->UserListWidth + 12
   ChatInput.Print( )

End Sub

Function Global_IRC_type.NumVisibleRooms( ) As Integer

   Dim As Integer Ret

   For i As Integer = 0 To NumServers - 1

      Var URT = Server[i]->FirstRoom

      For j As Integer = 1 To Server[i]->NumRooms

         If (URT->pflags AND Hidden) = 0 Then Ret += 1
         URT = URT->NextRoom

      Next j

   Next
   
   Function = Ret

End Function

Function Global_IRC_type.TotalNumRooms( ) As Integer

   Dim As Integer Ret

   For i As Integer = 0 To NumServers - 1

      Ret += Server[i]->NumRooms

   Next

   Function = Ret

End Function

Sub Global_IRC_type.DrawTabs( )

   Dim TabString        As String
   Dim TabColour        As uInt32_t = any
   Dim TabTextColour    As uInt32_t = any
   Dim X_Size           As Integer = Global_IRC.Global_Options.ScreenRes_x \ NumVisibleRooms
   Dim i                As Integer

   If X_Size < LIC_MIN_TAB_SIZE Then X_Size = LIC_MIN_TAB_SIZE

   ScreenLock

   view ( 0, 0 )-( Global_IRC.Global_Options.ScreenRes_x, 20 ), Global_IRC.Global_Options.BackGroundColour

   For j As Integer = 0 To NumServers - 1

      Var URT = Server[j]->FirstRoom

      For k As Integer = 1 To Server[j]->NumRooms

         If (URT->pflags AND Hidden) = 0 then

            TabColour = IIf( URT = CurrentRoom, Global_IRC.Global_Options.TabActiveColour, Global_IRC.Global_Options.TabColour )
            TabTextColour = IIf( (URT->pflags AND FlashingTab), Global_IRC.Global_Options.TabTextNotifyColour, Global_IRC.Global_Options.TabTextColour )

            Circle ( i * X_Size + 9, 10 ), 8, TabColour, , , , F
            Circle ( ( i + 1 ) * X_Size - 11, 10 ), 8, TabColour, , , , F

            Line ( i * X_Size + 10, 2 ) - Step( X_Size - 20, 16 ), TabColour, BF

            TabString = Left( URT->RoomName, X_Size \ 8 - 1 )

            Draw String ( i * X_Size + X_Size \ 2 - Len_hack( TabString ) * 4, 3 ), TabString, TabTextColour

            i += 1

         EndIf

         URT = URT->NextRoom

      Next

   Next

   'Line ( 0, 20 )-( Global_IRC.Global_Options.ScreenRes_x, 20 ), Global_IRC.Global_Options.TabActiveColour

   ScreenUnlock

   view

End Sub

function Global_IRC_type.GetTab( ByVal X as integer ) as UserRoom_type ptr
   Dim WhichRoom  As Integer = Any
   Dim numrooms   As Integer = NumVisibleRooms( )
   Dim X_Size     As Integer = Global_IRC.Global_Options.ScreenRes_x \ numrooms

   var URT = Server[0]->FirstRoom

   If X_Size < LIC_MIN_TAB_SIZE Then X_Size = LIC_MIN_TAB_SIZE

   WhichRoom = X \ X_Size
   If WhichRoom >= numrooms Then WhichRoom = numrooms - 1

   While (URT->pflags AND Hidden)
      URT = GetNextRoom( URT )
   Wend

   For i As Integer = 1 To WhichRoom
      URT = GetNextRoom( URT )
      If (URT->pflags AND Hidden) Then i -= 1
   Next
   
   Function = URT
End Function

Sub GLobal_IRC_type.ClickTabs( ByVal X As Integer )

   var URT = GetTab( X )
   If URT <> CurrentRoom Then SwitchRoom( URT )

End Sub

Function GetPrevRoom( ByVal Room As UserRoom_Type Ptr = 0 ) As UserRoom_Type Ptr

   If Room = 0 Then Room = Global_IRC.CurrentRoom

   If ( Room->Server_Ptr->NumRooms > 1 ) And ( Room <> Room->Server_Ptr->FirstRoom ) Then

      Function = Room->PrevRoom

   ElseIf Global_IRC.TotalNumRooms = 1 Then

      Function = Room

   ElseIf Global_IRC.NumServers = 1 Then

      Function = Room->Server_Ptr->LastRoom

   else

      Dim As Integer S
      For i As Integer = 0 To Global_IRC.NumServers - 1

         If Global_IRC.Server[i] = Room->Server_Ptr Then

            Select Case i
               Case 0: S = Global_IRC.NumServers - 1
               Case Else: S = i - 1
            End Select

            Exit For

         EndIf

      Next

      Function = Global_IRC.Server[S]->LastRoom

   EndIf

End Function

Function GetNextRoom( ByVal Room As UserRoom_Type Ptr = 0 ) As UserRoom_Type Ptr

   If Room = 0 Then Room = Global_IRC.CurrentRoom

   If ( Room->Server_Ptr->NumRooms > 1 ) And ( Room <> Room->Server_Ptr->LastRoom ) Then

      Function = Room->NextRoom

   ElseIf Global_IRC.TotalNumRooms = 1 Then

      Function = Room

   ElseIf Global_IRC.NumServers = 1 Then

      Function = Room->Server_Ptr->FirstRoom

   else

      Dim As Integer S

      For i As Integer = 0 To Global_IRC.NumServers - 1

         If Global_IRC.Server[i] = Room->Server_Ptr Then

            Select Case i
               Case Global_IRC.NumServers - 1: S = 0
               Case Else: S = i + 1
            End Select

            Exit For

         EndIf

      Next

      Function = Global_IRC.Server[S]->FirstRoom

   EndIf

End Function

Function GetLOT( byval Y as integer ) as LineOfText ptr
   
   Dim As UserRoom_Type Ptr URT = Global_IRC.CurrentRoom
   dim as integer CharSizeY = iif( URT->RoomType = RawOutput, 16, Global_IRC.TextInfo.ChatBoxCharSizeY )
   Dim As Integer TextPos_y = ( Global_IRC.Global_Options.ScreenRes_y - Y - 16 ) \ CharSizeY

   If ( TextPos_y > (URT->CurrentLine+1) ) or (( CInt(URT->CurrentLine) - TextPos_y - 1 ) < 0 ) Then
      return 0
   EndIf

   Function = URT->TextArray[ URT->CurrentLine - TextPos_y - 1 ]
   
End Function

Function Global_IRC_Type.AliasSet( byref in as string, byval notify as integer = 0 ) as integer
   
   dim as integer sp = instr( in, " " )     
   dim as string a1 = ucase( left( in, sp - 1 ) )
   dim as string a2 = mid( in, sp + 1 )
   
   if len( a1 ) = 0 then
      a1 = ucase( in )
      a2 = ""
   EndIf
   
   dim as integer location = -1
   if AliasList = 0 then
      AliasCount = 32
      AliasList = Callocate( 32 * sizeof( zstring ptr ) )
      location = 0
   else
      dim as integer i
      while i < AliasCount
         if AliasList[i] <> 0 then
            if *AliasList[i] = a1 then
               if len( a2 ) > 0 then
                  AliasList[i+1] = reallocate( AliasList[i+1], len( a2 ) )
                  *AliasList[i+1] = a2
                  if notify then
                     Notice_Gui( "Set alias: " & a1 & " = " & a2, Global_Options.ServerMessageColour )
                  EndIf
               else
                  deallocate( AliasList[i] )
                  deallocate( AliasList[i+1] )
                  AliasList[i] = 0
                  AliasList[i+1] = 0
                  if notify then
                     Notice_Gui( "Deleted alias: " & a1, Global_Options.ServerMessageColour )
                  EndIf
               endif
               return TRUE
            EndIf
         else
            location = i
         Endif
         i += 2
      Wend
   EndIf
      
   if location = -1 then
      dim as integer NewAliasCount = AliasCount + 32
      dim as zstring ptr ptr NewAliasList = CAllocate( NewAliasCount * sizeof( zstring ptr ) )
      if NewAliasList <> 0 then
         memcpy( NewAliasList, AliasList, AliasCount * sizeof( zstring ptr ) )
         location = AliasCount
         AliasList = NewAliasList
         AliasCount = NewAliasCount         
      else
         return FALSE
      EndIf
   EndIf

   if len( a2 ) then
      AliasList[location] = allocate( len( a1 ) + 1 )
      *AliasList[location] = a1
      AliasList[location+1] = allocate( len( a2 ) + 1 )
      *AliasList[location+1] = a2
      
      if notify then
         Notice_Gui( "Set alias: " & a1 & " = " & a2, Global_Options.ServerMessageColour )
      EndIf
   endif
   
   Function = TRUE
   
End Function

Constructor Global_IRC_Type( )
  
   dim as time_t rawtime
   dim as tm ptr timeinfo
    
   time_( @rawtime )
   timeinfo = localtime( @rawtime )
   strftime( CurrentDay, 16, "%a %b %d %Y", timeinfo )

   Mutex = MutexCreate( )
   
   #If __FB_DEBUG__
      DebugLock = MutexCreate( )
   #EndIf

End Constructor

Destructor Global_IRC_Type( )

   LIC_DESTRUCTOR1

   For i As Integer = 0 To NumServers - 1

      if Server[i] <> 0 then
         Delete Server[i]
      EndIf

   Next

   DeAllocate( Server )
   TimeStamp = ""
   if AliasList <> 0 then
      for i as integer = 0 to AliasCount - 1
         Deallocate( AliasList[i] )
         AliasList[i] = 0
      next
      Deallocate( AliasList )
      AliasList = 0
      AliasCount = 0
   EndIf
   
   MutexDestroy( Mutex )

   #If __FB_DEBUG__
      DebugLog = ""
      MutexDestroy( DebugLock )
   #EndIf

   LIC_DESTRUCTOR2

End Destructor
