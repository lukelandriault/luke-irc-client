#undef LIC_Debug
#Macro LIC_Debug( S )
   #If __FB_DEBUG__
      DebugOut( S )
   #endif
#EndMacro

#if __FB_DEBUG__
   Declare Sub DebugOut( ByRef S As String )
   Extern UptimeStart As Double
   #Undef Assert
   #Macro Assert( _A )
      If _A = 0 Then
         LIC_Debug( "\\Assertion Failed! " & __FILE__ & " in " & __FUNCTION__ & "(" & __LINE__ & ") :" & #_A )
         #ifdef WriteLogs
            WriteLogs( )
         #endif
      EndIf
   #EndMacro
#EndIf

#Define debug_gui(_m) Global_IRC.CurrentRoom->AddLOT( _m , Global_IRC.Global_Options.DebugColour, 0, ServerMessage, , , TRUE )


'Print Out Destructor info
#If 0

   #Define LIC_DESTRUCTOR1 Print #1, "DESTRUCTOR " & __FILE__ & " in " & Left( __FUNCTION__, Len( __FUNCTION__ ) - 11 ) & "(" & __LINE__ & ") :" & @This
   #Define LIC_DESTRUCTOR2 Print #1, "OK( " & @This & " )"

#Else

   #Define LIC_DESTRUCTOR1
   #Define LIC_DESTRUCTOR2

#EndIf


