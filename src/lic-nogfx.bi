#If 1=2
Sub CheckNOGFX_Events( )
End Sub
#EndIf

#Macro CheckNOGFX_Events( )
   Var In_Key = LCase( InKey )
   If InStrAsm( 1, In_Key, Asc("q") ) Then IRC_SHUTDOWN = 1
   If InStrAsm( 1, In_Key, Asc("d") ) Then
      'while Multikey( fb.SC_D ): Sleep 25: Wend
      var URT = Global_IRC.Server[0]->FirstRoom
      dim as integer T_Lines, T_Users, NonChannels, IRC_Server_Events
      For i as integer = 1 to Global_IRC.TotalNumRooms
         if URT->Server_Ptr->IS_CHANNEL( URT->RoomName ) then
            color 15: print "| ";
            Color IIf( URT->flags AND ChanFlags.online, 15, 8)
            Print URT->RoomName;
            Color 15: Print "( ";
            color 6 : print URT->NumUsers & " ";
            color 2 : print URT->NumLines;
            color 15: print " ) ";
         else
            NonChannels += 1
         end if
         T_Lines += URT->NumLines
         T_Users += URT->NumUsers
         URT = GetNextRoom( URT )
      Next
      For i As Integer = 0 To Global_IRC.NumServers - 1
         IRC_Server_Events += Global_IRC.Server[i]->Event_Handler.Queued
      Next

      print "|"
      color 15: print "Rooms: " & Global_IRC.TotalNumRooms & " NonChannels: " & NonChannels
      color 6 : print "Users: " & T_Users;
      color 2 : Print " Lines: " & T_Lines
      color 10: print "Uptime: " & CalcTime( Cuint( Timer - UptimeStart ) )
      Print "Events: " & Global_IRC.Event_Handler.Queued & " Server Events: " & IRC_Server_Events
      Print "DCC Used: " & Global_IRC.DCC_LIST.Used & " Allocated: " & Global_IRC.DCC_LIST.Allocated & " Count: " & Global_IRC.DCC_LIST.Count
      If ( Global_IRC.Global_Options.LogToFile <> 0 ) And ( Global_IRC.Global_Options.LogBufferSize > 0 ) Then
         Print "Log Buffer: " & Global_IRC.LogLength & " / " & Global_IRC.Global_Options.LogBufferSize
      EndIf
      color 7
      sleep 10000
   End If
#EndMacro
