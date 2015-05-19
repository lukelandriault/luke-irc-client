#Include once "lic.bi"

Sub LineOfText.AddLink _
   ( _
      ByRef StartPos    As Integer, _
      ByRef EndPos      As Integer, _
      ByRef TheLink     As ZString Ptr, _
      ByRef LinkID      as Integer _
   )
   
   dim as ubyte swapchar
   dim as integer Length = EndPos - StartPos

   if TheLink = 0 then
      if Length < 2 then exit sub
   else
      if TheLink[1] = 0 then exit sub
   EndIf

   var HLB = New LOT_HyperLinkBox
   If HLB = 0 Then Exit Sub

   if Length <= 0 then
      Length = len_hack( Text ) - StartPos
   EndIf

   'swap a null in to grab a fast zstring
   'HLB->AltText = mid( Text, StartPos, Length )
   swap swapchar, Text[ StartPos + Length ]
   HLB->AltText = *cptr( zstring ptr, @Text[ StartPos - 1 ] )
   swap swapchar, Text[ StartPos + Length ]

   HLB->ID = LinkID

   If TheLink = 0 Then
      HLB->HyperLink = HLB->AltText
   else
      HLB->HyperLink = *TheLink
   EndIf

   If HLB->id = LinkWeb then
      const as string MatchChars = " ,<>[]{}\|`^#%"".;"
      Length = len_hack( HLB->HyperLink )
      RTrim2( HLB->HyperLink, MatchChars, TRUE )
      If ( Length <> len_hack( HLB->HyperLink ) ) and ( Length = len_hack( HLB->AltText ) ) Then
         'found unwanted chars & not a multi-line link
         RTrim2( HLB->AltText, MatchChars, TRUE )
      EndIf
   EndIf

   Length = str_len( Text )
   str_len( Text ) = StartPos - 1
   
   swapchar or= 0 'temp fix for 0.22 bug?
   swap swapchar, Text[ str_len( Text ) ]
   HLB->X1 = CWidth( Text )
   swap swapchar, Text[ str_len( Text ) ]
   str_len( Text ) = Length
   HLB->X2 = CWidth( HLB->AltText ) + HLB->X1
   HLB->TextStart = StartPos

   If HyperLinks = 0 Then
      HyperLinks = HLB
   Else
      Var HLB2 = HyperLinks
      while HLB2->NextLink <> 0
         HLB2 = HLB2->NextLink
      wend
      HLB2->NextLink = HLB
   EndIf

End Sub

Destructor LOT_HyperLinkBox

   LIC_DESTRUCTOR1

   AltText = ""
   HyperLink = ""
   If NextLink <> 0 Then Delete NextLink

   LIC_DESTRUCTOR2

End Destructor

Destructor LOT_MultiColour_Descriptor

   LIC_DESTRUCTOR1

   If NextDesc <> 0 Then Delete NextDesc

   LIC_DESTRUCTOR2

End Destructor

Destructor LOT_MultiColour

   LIC_DESTRUCTOR1

   Text = ""
   If NextMC <> 0 Then Delete NextMC

   LIC_DESTRUCTOR2

End Destructor

Destructor LineOfText

   LIC_DESTRUCTOR1

   Text = ""
   If HyperLinks <> 0 Then Delete Hyperlinks
   If MultiColour <> 0 Then Delete MultiColour

   LIC_DESTRUCTOR2

End Destructor

Destructor UserName_type

   LIC_DESTRUCTOR1

   UserName = ""

   LIC_DESTRUCTOR2

End Destructor

#If __FB_DEBUG__
   Sub DebugOut( ByRef S As String )

      MutexLock( Global_IRC.DebugLock )

      If Global_IRC.Global_Options.LogDebug <> 0 Then

         If Global_IRC.Global_Options.LogBufferSize > 0 Then

            Global_IRC.DebugLog += S + NewLine
            Global_IRC.LogLength += Len_hack( S ) + len( NewLine )

         Else

            var FF = FreeFile

            If Open( "log/LIC_Debug.log" For Binary As #FF ) = 0 Then
               Seek #FF, LOF( FF ) + 1
               Print #FF, S
               Close #FF
            endif

         endif

      EndIf

      if ( Global_IRC.Global_Options.DisableSTDOUT <> FALSE ) _
         and ( (len_hack( S ) < 2) orelse ( *cptr( short ptr, @S[0] ) <> *cptr( short ptr, @"\\" ) ) ) then
      
      else
         'damn system bell, DIE!
         var bell = instrASM( 1, S, 7 )
         while bell >= 1
            S[ bell - 1 ] = asc(" ")
            bell = instrASM( bell + 1, S, 7 )
         Wend
   
         Print #1, S
      
      end if

      MutexUnlock( Global_IRC.DebugLock )

   End Sub
#endif


Sub UpdateWindowTitle( )
   
   static as string title
   
   if str_all( title ) <= 1 then
      title = space( 64 )
   EndIf
   
   if Global_IRC.PrependTitle AND PrependAt then
      title[0] = asc("@")
      str_len( title ) = 1
   elseif Global_IRC.PrependTitle AND PrependStar then
      title[0] = asc("*")
      str_len( title ) = 1
   else
      str_len( title ) = 0
   end if

   With *Global_IRC.CurrentRoom

      select case .RoomType
      case RoomTypes.Channel
         title += "LIC | " & .RoomName & "(" & .NumUsers & ") | " & .Topic
      case RoomTypes.List
         title += "LIC | " & .Server_Ptr->ServerName & " List (" & .NumUsers & ")"
      case else
         title += "LIC | " & .RoomName
      end select

   End With

   WindowTitle( title )

End Sub

Function Pending_Message( ) As Integer

   For i As Integer = 0 To Global_IRC.NumServers - 1

      'FIXME!!!
      #if LIC_CHI
         If Global_IRC.Server[i]->ServerSocket.Length( ) Then Return -1
      #else
      #endif

   Next
   
   return 0

End Function

Sub WriteLogs( )

   'Var forced = ( Global_IRC.LogLength >= Global_IRC.Global_Options.LogBufferSize )
   var WriteFailed = 0

   For i As Integer = 0 To Global_IRC.NumServers - 1

      With *Global_IRC.Server[i]

      If len_hack( .LogBuffer ) Then

         WriteFailed or= .LogToFile( "private messages", .LogBuffer )

      EndIf

      Var URT = .FirstRoom

      For j As Integer = 1 To .NumRooms

         If Len_Hack( URT->LogBuffer ) Then

            select case URT->RoomType

            case RoomTypes.Lobby
               WriteFailed or= .LogToFile( "server messages", URT->LogBuffer )

            case RoomTypes.DccChat
               WriteFailed or= .LogToFile( "dcc " + URT->RoomName, URT->LogBuffer )
            
            case RoomTypes.RawOutput
               WriteFailed or= .LogToFile( "raw log", URT->LogBuffer )

            case else
               WriteFailed or= .LogToFile( URT->RoomName, URT->LogBuffer )

            End Select

         EndIf
         URT = URT->NextRoom

      Next

      End with

   Next

   #If __FB_DEBUG__

   'LIC_DEBUG( "\\Wrote Logfile [" & *IIf( forced, @"Full]", @"Timed]" )  )
   If Len_hack( Global_IRC.DebugLog ) Then

      var FF = FreeFile
      Var Ret = Open( "log/LIC_Debug.log" For Binary As #FF )

      If Ret = 0 Then
         Seek #FF, LOF( FF ) + 1
         Print #FF, Global_IRC.DebugLog;
         Close #FF
         Global_IRC.LogLength -= len_hack( Global_IRC.DebugLog )
         Global_IRC.DebugLog = ""
      Else
         LIC_DEBUG( "\\Error writing Debug logfile, Err#" & Ret )
      EndIf

      WriteFailed Or= Ret

   EndIf

   #EndIf

   If ( WriteFailed = 0 ) And ( Global_IRC.LogLength <> 0 ) Then
      LIC_DEBUG( "\\Log size check failed! Reported size: " & Global_IRC.LogLength )
      Global_IRC.LogLength = 0
   EndIf

   Global_IRC.LastLogWrite = Timer

End Sub

Function UWidth( byref s as string ) as integer

#if LIC_NUKE_ASM OR sizeof(integer) = 8
   dim as integer ret
   
   with Global_IRC.TextInfo   
   
   for i as integer = 0 to len_hack( s ) - 1
      ret += .UWidth( s[i] )
   Next
   
   End With

   function = ret
   
#else 'asm

   static as int32_t ptr p
   if p = 0 then p = @Global_IRC.TextInfo.UWidth(0)
   
   asm

      mov edx, [s]
      mov ecx, [edx+4]
      cmp ecx, 0
      jle exitu
      
      mov edi, [edx]
      mov esi, [p]
      
      xor eax, eax
      xor ebx, ebx
      
      addcharu:

      mov bl, byte ptr [edi+ecx-1]
      add eax, dword ptr [esi+ebx*4]
      
      dec ecx
      jnz addcharu
            
      mov [ Function ], eax
      
      exitu:
      
   End Asm

#endif

End Function

Function CWidth( byref s as string ) as integer

#if LIC_NUKE_ASM OR sizeof(integer) = 8
   dim as integer ret
   
   with Global_IRC.TextInfo   
   
   for i as integer = 0 to len_hack( s ) - 1
      ret += .CWidth( s[i] )
   Next
   
   End With

   function = ret
   
#else 'asm

   static as int32_t ptr p
   if p = 0 then p = @Global_IRC.TextInfo.CWidth(0)
   
   asm

      mov edx, [s]
      mov ecx, [edx+4]
      cmp ecx, 0
      jle exitc
      
      mov edi, [edx]
      mov esi, [p]
      
      xor eax, eax
      xor ebx, ebx
      
      addcharc:

      mov bl, byte ptr [edi+ecx-1]
      add eax, dword ptr [esi+ebx*4]
      
      dec ecx
      jnz addcharc
            
      mov [ Function ], eax
      
      exitc:
      
   End Asm

#endif

End Function


'FIXME!!!
#if LIC_CHI
sub chiConnect( byval t as threadconnect ptr )

   var orig = 0

   if t->ret then orig = *t->ret
   if ( t->ip = 0 ) and ( t->server <> 0 ) then
      t->ip = chi.resolve( *t->server )
   EndIf

   var status = t->sock->client( t->ip, t->port )

   if t->mutex then mutexlock( t->mutex )
   if t->ret then
      if *t->ret = orig then *t->ret = status
   EndIf
   if t->mutex then mutexunlock( t->mutex )

   delete t

End Sub

sub chiListen( byval t as threadconnect ptr )

   var status = t->sock->listen( cdbl( t->timeout ) )

   if t->mutex then mutexlock( t->mutex )
   if t->ret then *t->ret = status
   if t->mutex then mutexunlock( t->mutex )

   delete t

End Sub
#endif

sub StringArray_Type.build( byref s as string )

   this.Destructor( )

   if len_hack( s ) = 0 then
      Count = 0
      Exit Sub
   EndIf

   redim as string a()
   String_Explode( s, a() )

   Count = ubound( a ) + 1
   Array = callocate( Count * Sizeof( String ) )

   for i as integer = 0 to ubound( a )

      Array[i] = a(i)

   Next

End Sub

Destructor StringArray_Type( )

   if array <> 0 then
      for i as integer = 0 to Count - 1
         array[i] = ""
      Next
      Deallocate( array )
      array = 0
   EndIf
   
   Count = 0

End Destructor

sub StripColour( byref in as string )
   
   dim as integer TempInt = InStrAsm( 1, in, 3 )
   
   if TempInt > 0 then

      dim as integer LHS_Count, RHS_Count, foreground, background
      var tmpstring = in

      While TempInt > 0

         var LHS_Count = TempInt - 1
         var RHS_Count = TempInt + 1

         For i As Integer = 1 To 2
            Select Case Asc( tmpstring, TempInt + i )
               Case 3
                  RHS_Count += 1
                  i -= 1
                  TempInt += 1
               case asc("0") To asc("9")
                  RHS_Count += 1
               case else
                  exit for
            End Select
         Next

         If asc( tmpstring, RHS_Count ) = asc(",") Then

            foreground = valint( mid( tmpstring, TempInt + 1, 2 ) )
            background = valint( mid( tmpstring, RHS_Count + 1, 2 ) )

            TempInt = RHS_Count + 1

            if ( asc( tmpstring, TempInt ) >= asc("0") ) and ( asc( tmpstring, TempInt ) <= asc("9") ) then
               RHS_Count += 1
               TempInt += 1
               if ( asc( tmpstring, TempInt ) >= asc("0") ) and ( asc( tmpstring, TempInt ) <= asc("9") ) then
                  RHS_Count += 1
               EndIf
            EndIf

            if background = foreground then
               for i as integer = RHS_Count to len_hack( tmpstring ) - 1
                  if tmpstring[i] = 3 then exit for
                  tmpstring[i] = asc(" ")
               Next
            EndIf

            RHS_Count += 1
         EndIf
         
         
         tmpstring = Left( tmpstring, LHS_Count ) + Mid( tmpstring, RHS_Count )
         TempInt = InStrASM( LHS_Count + 1, tmpstring, 3 )

      Wend

      if len_hack( tmpstring ) > 0 then
         memcpy( @in[0], @tmpstring[0], len_hack( tmpstring ) + 1 )
         str_len( in ) = len_hack( tmpstring )
      else
         in[0] = 0
         str_len( in ) = 0
      endif

   endif

End Sub

