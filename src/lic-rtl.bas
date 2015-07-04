'#define fbc -g -p chisock/lib/win32 -i chisock/ -d __LIC__=-1 -gen gcc
' LIC Run Time module
#ifndef __FB_LINUX__
   #include once "windows.bi"
   #include once "win/commdlg.bi"
#else
   #include once "crt.bi"
   #include once "crt/unistd.bi"    
   #include once "crt/errno.bi"
   #include once "crt/stdio.bi"
   #include once "crt/sys/types.bi"
   #include once "crt/sys/time.bi"
#endif

#Include once "lic-rtl.bi"
#Include once "lic-debug.bi"
#Include once "file.bi"
#if LIC_CHI
   #Include Once "chisock.bi"
#endif
 
#ifdef __FB_LINUX__
declare function waitpid_ cdecl alias "waitpid" (byval pid as integer, byval status as any ptr, byval options as integer) as integer
#define WNOHANG 1
sub forkexec(_command as string)
   
   dim as zstring ptr argv(0 to 3) = { @"sh", @"-c", strptr(_command), NULL }
   
   if fork() = 0 then ' Child
      execvp("sh", @argv(0))
      exit_(1) ' Shouldn't ever get here
   else ' Parent
      ' Nothing
   end if
 
end sub
#endif

Constructor ParamList_Type( byref in as string, byref delimit as ubyte = asc(" ") )

   dim as integer temp, alloc
   dim as integer L = len_hack( in )

   if count > 0 then
      this.Destructor
   EndIf

   copyv = in
   copyz = in

   while temp < L

      count += 1
      if count >= alloc then
         alloc += 8
         z = reallocate( z, sizeof( any ptr ) * alloc )
         s = reallocate( s, sizeof( string ) * alloc )
         start = reallocate( start, sizeof( integer ) * alloc )
         clear s[ count - 1 ], 0, sizeof( string ) * 8
      EndIf

      start[ count - 1 ] = temp
      z[ count - 1 ] = @copyz[ temp ]

      temp = InStrASM( temp + 1, in, delimit )
      if temp <= 0 then
         temp = L + 1
      EndIf

      copyz[ temp - 1 ] = 0
      s[ count - 1 ] = *( z[ count - 1 ] )

   Wend

End Constructor

Destructor ParamList_Type( )

   deallocate( z )
   if s <> 0 then
      for i as integer = 0 to count - 1
         s[i] = ""
      Next
      deallocate( s )
   EndIf
   deallocate( start )

   copyz = ""
   copyv = ""
   z = 0
   s = 0
   start = 0
   count = 0

End Destructor

constructor NonBlockingProc( byval in_proc as any ptr, byval in_param as any ptr = 0 )

   mutex = MutexCreate
   proc = in_proc
   param = in_param

   handle = threadcreate( cptr( any ptr, @execute ), @this )

End Constructor

destructor NonBlockingProc( )
   if handle then
      ThreadWait( handle )
      handle = 0
   EndIf
   mutexdestroy( mutex )
End Destructor

function NonBlockingProc.done( ) as integer

   mutexlock( mutex )
   if flag <> 0 then
      Function = -1
   EndIf
   mutexunlock( mutex )

End Function

static sub NonBlockingProc.execute( byval NBP as NonBlockingProc ptr )

   dim as function( byval as any ptr ) as any ptr myproc = NBP->proc
   dim as any ptr ret

   ret = myproc( NBP->param )

   mutexlock( NBP->mutex )
   NBP->flag = -1
   NBP->return_value = ret
   mutexunlock( NBP->mutex )

End Sub

Function RevLineInput( byref ff as long, byref s as string ) as integer

   dim as integer chunksize = 512
   var ret = 0, p = loc( ff ), bytes = 0

   if p < chunksize then chunksize = p

   dim as ubyte ptr buffer = allocate( chunksize + 1 )

   var t = ""
   s = ""

   while p > 0

      ret = get( #ff, p - chunksize + 1, *buffer, chunksize, bytes )
      buffer[ bytes ] = 0

      if ret <> 0 then exit while

      t = *cptr( zstring ptr, buffer )

      var r = InStrRev( t, !"\n" )

      if r > 0 then
         t = mid( t, r + 1, p - r )
         seek #ff, p - len( t )
         p = 0
      elseif p > chunksize then
         'really long line...
         s = t + s
         p -= chunksize
         if chunksize > p then chunksize = p
      else
         seek #ff, 1
         p = 0
      endif

   wend

   deallocate( buffer )
   if ret = 0 then
      #IFDEF RTrim2
         s = t + s
         RTrim2( s, !"\r\n", TRUE )
      #else
         s = rtrim( t + s, any !"\r\n" )
      #endif
   else
      s = ""
   EndIf

   Function = ret

End Function

Function CalcTime( ByVal t As Uinteger ) As String

   Dim As String R

   if t \ 31556926 = 1 then R &= t \ 31556926 & " year "
   if t \ 31556926 > 1 then R &= t \ 31556926 & " years "
   t mod= 31556926
   if t \ 604800   = 1 then R &= t \ 604800   & " week "
   if t \ 604800   > 1 then R &= t \ 604800   & " weeks "
   t mod= 604800
   if t \ 86400    = 1 then R &= t \ 86400    & " day "
   if t \ 86400    > 1 then R &= t \ 86400    & " days "
   t mod= 86400
   if t \ 3600     = 1 then R &= t \ 3600     & " hour "
   if t \ 3600     > 1 then R &= t \ 3600     & " hours "
   t mod= 3600
   if t \ 60       = 1 then R &= t \ 60       & " minute "
   if t \ 60       > 1 then R &= t \ 60       & " minutes "
   t mod= 60
   if t            = 1 then R &= t            & " second "
   if t            > 1 then R &= t            & " seconds "

   Function = R

End Function

Function CalcSize( ByRef b As uinteger ) As String

   Const as uinteger GB = 2^30, MB = 2^20, KB = 2^10
   Dim As String Ret
   Dim As String * 4 suffix

   Select Case b
      Case Is >= GB
         Ret = Str( b / GB )
         suffix = "GB"
      Case Is >= MB
         Ret = Str( b / MB )
         suffix = "MB"
      Case Is >= KB
         Ret = Str( b / KB )
         suffix = "KB"
      Case Else
         Ret = Str( b )
         suffix = "B"
   End Select

   Var decimal = InStrASM( 1, Ret, asc(".") )

   If decimal > 0 Then
      Function = Left( Ret, decimal + 2 ) + suffix
   Else
      if suffix[0] = asc("B") then
         Function = Ret + suffix
      else
         Function = Ret + ".00" + suffix
      endif
   EndIf

End Function


Function String_Replace _
   ( _
      ByRef SearchFor      As String, _
      ByRef ReplaceWith    As String, _
      ByRef _Input         As String _
   ) As String

   Dim Length_s      As Integer = Len_Hack( SearchFor )
   Dim Length_r      As Integer = Len_Hack( ReplaceWith )
   Dim Start         As Integer = any
   Dim FoundAt       As Integer = InStr( _Input, SearchFor )
   Dim ReturnString  As String

   If FoundAt = 0 Then
      return _Input
   End If

   Start = FoundAt + Length_r
   ReturnString = _Input

   While FoundAt > 0

      if Length_s = Length_r then
         mid( ReturnString, FoundAt, Length_r ) = ReplaceWith
      else
      
         ReturnString = _
            Left( ReturnString, FoundAt - 1 ) & _
            ReplaceWith & _
            Mid( ReturnString, FoundAt + Length_s )
      
      EndIf

      FoundAt = InStr( Start, ReturnString, SearchFor )
      Start = FoundAt + Length_r

   Wend

   Function = ReturnString

End Function

Sub String_Explode( ByRef In_ As String, A() As String )

   Dim As uInteger L = Any
   Dim As UInteger carat = 1
   Dim As UInteger count

   ReDim A(15)

   Do

      L = InStrAsm( Carat, In_, Asc(" ") )

      A( count ) = Mid( In_, Carat, L - Carat )

      If L = 0 Then Exit Do

      Carat += Len_hack( A( count ) ) + 1

      If len_hack( A( count ) ) then

         if count = ubound( A ) then
            ReDim Preserve A( Count + 16 )
         EndIf

         count += 1

      endif

   Loop

   If ( len_hack( A( count ) ) = 0 ) And ( count <> 0 ) Then count -= 1

   ReDim Preserve A( count )

End Sub

Function String_ExplodeZ( ByRef In_ As String, A() As ZString ptr ) as integer

   Dim As Integer carat = 1
   Dim As Integer count = -1
   Dim As Integer I = Any
   Dim As Integer L = len_hack( In_ )
   Dim As Integer nulls( L )

   If L = 0 Then Return 0

   Do

      I = InstrAsm( Carat, In_, Asc(" ") )

      count += 1
      a( count ) = @In_[ carat - 1 ]

      If I Then nulls( count ) = I - 1

      Carat = I + 1

   Loop Until ( I = 0 ) or ( count = ubound( A ) )

   nulls( count ) = L
   For i = 0 To count
      a( 0 )[ nulls( i ) ] = 0
   Next

   Function = count

End Function

Function SafeFileNameEncode( ByRef in As String ) As String

   Dim As Integer bad, cursor

   Var Ret = In
   var l = Len_hack( Ret )

   For i As Integer = 0 To l - 1

      Select Case In[i]

#ifndef __FB_LINUX__
         Case 	1 to 31, Asc("\"), Asc("/"), Asc("|"), Asc("?"), Asc(":"), _
               Asc("*"), Asc("<"), Asc(">"), Asc(""""), Asc("^") ' ^ for fat32, rare but whatever..
#else
         case 1 to 31, Asc("/")
#endif

            bad += 1

         Case Else
            Ret[ cursor ] = In[i]
            cursor += 1

      End Select

   Next

   If bad Then
      len_swap( Ret, l - bad )
      Ret += " " + String( bad, "_" )
   EndIf

#ifndef __FB_LINUX__
   select case left( lcase( ret ), 3 )
      case "com", "lpt" 'com1-9 & lpt1-9 are invalid
         if len( rtrim( ret, "." ) ) = 4 then
            if valint( chr( ret[3] ) ) > 0 then ret = "bad_filename;" & ret
         EndIf
      case  "nul", "con", "prn"
         if len( rtrim( ret, "." ) ) = 3 then ret = "bad_filename;" & ret
   End Select
#endif

   Function = Ret

End Function

#if LIC_USE_ASM_FUNCTIONS = 0

Function SortCreate( ByRef Key As String ) As uint64_t

   dim As ZString * 9 zS
   zS = Key

   /'
      Code reverses the bytes
      That way "Luke" doesn't get sorted as "ekuL"
      0 1 2 3 4 5 6 7
      becomes:
      7 6 5 4 3 2 1 0
   '/

   dim as ubyte ptr b = @zS

   swap b[0], b[7]
   swap b[1], b[6]
   swap b[2], b[5]
   swap b[3], b[4]

   Function = *cptr( uint64_t ptr, b )

End Function

#endif 'LIC_USE_ASM_FUNCTIONS

Function MkDirTree( byref folder as string ) as integer

#ifndef __FB_LINUX__

   var d = trim( folder, any " \/""" )
   var cwd = curdir

   for i as integer = 0 to len( d ) - 1
      if d[i] = asc("/") then d[i] = asc("\")
   Next

   'see if the full path was passed (C:\Folder)
   if asc( d, 2 ) <> asc(":") then
      d = cwd + "\" + d
   endif

   if ChDir( d ) = 0 then 'Already exists?
      ChDir( cwd )
   else
      Function = Shell( "mkdir """ + d + """ 2>NUL" )
   EndIf

#elseif defined( __FB_LINUX__ )

   var d = trim( folder )

   select case asc( d )

   case asc("~")
      d = ENVIRON( "HOME" ) + mid( d, 2 )

   case asc("/")
      'full path, nothing to do

   case else
      d = curdir + "/" + d

   End Select

   'manpage for mkdir:
   '-p, --parents     no error if existing, make parent directories as needed
   Function = Shell( "mkdir -p """ + d + """ 2>/dev/null" )

#endif

End Function

Function MaskCompare( Byref from as String, Byref mask as String ) as Integer

   dim as integer pos1, i, n, L

   var len1 = len_hack( from )
   var len2 = len_hack( mask )

   if len2 = 1 then
      if mask[0] = asc("*") then
         return TRUE
      endif
   EndIf
   if ( len1 = 0 ) or ( len2 = 0 ) then
      if ( len1 OR len2 ) = 0 then
         return TRUE
      else
         return FALSE
      endif
   EndIf

   n = instrasm( 1, mask, asc("*") )
   if n = 0 then
      return StringEqualASM( mask, from )
   EndIf

   do

      if mask[i] = asc("*") then
         i += 1
         if i >= len2 then
            return TRUE
         EndIf
         n = instrasm( i + 1, mask, asc("*") )
         if n = 0 then
            n = len2 + 1
         EndIf
      endif

      L = n - i - 1
      pos1 = instr( pos1 + 1, from, mid( mask, i + 1, L ) )

      if pos1 > 0 then
         pos1 += L - 1
         i += L
      else
         return FALSE
      EndIf

   loop until i >= len2

   if pos1 = len1 then
      Function = TRUE
   else
      Function = FALSE
   endif

End Function

#ifndef __FB_LINUX__

function w32_GetFilename( byval title as zstring ptr = 0 ) as string

   dim filename as zstring ptr = callocate( MAX_PATH + 1 )
	dim ofn as OPENFILENAME

	with ofn
		.lStructSize 		= sizeof( OPENFILENAME )
		.hwndOwner	 		= GetForegroundWindow( ) 'hwnd
		.hInstance	 		= GetModuleHandle( NULL )
		.lpstrFilter 		= @!"All Files, (*.*)\0*.*\0\0"
		.lpstrFile			= filename
		.nMaxFile			= MAX_PATH + 1
		.Flags				= OFN_EXPLORER or OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST
      .lpstrTitle		   = title
	end with

	var cd = curdir( )

	GetOpenFileName( @ofn )

	Function = *filename

	deallocate( filename )
	chdir( cd )

end Function

#else

function lin_GetFilename( byref title as string = "" ) as string

   const as integer GNOME_SESSION = 1, KDE_SESSION = 2 'XFCE uses gnome libs anyway...
   static as integer session_id

   dim as string diag_title, temp
   var ff = freefile

   if session_id = 0 then

      dim as integer kde_c, gnome_c, xfce_c 'counts

      if open pipe( "env | grep -ci gnome" for input as #ff ) = 0 then
         line input #ff, temp
         gnome_c = valint( temp )
         close #ff
      end if

      ff = freefile
      if open pipe( "env | grep -ci kde" for input as #ff ) = 0 then
         line input #ff, temp
         kde_c = valint( temp )
         close #ff
      end if

      ff = freefile
      if open pipe( "env | grep -ci xfce" for input as #ff ) = 0 then
         line input #ff, temp
         xfce_c = valint( temp )
         close #ff
      end if

      if ( kde_c > gnome_c ) and ( kde_c > xfce_c ) then
         session_id = KDE_SESSION
      else
         session_id = GNOME_SESSION
      end if

      temp = ""
      ff = FreeFile

   end if

   if len( title ) > 0 then
      diag_title = " --title """ & title & """"
   end if

   select case session_id

   case KDE_SESSION
      if open pipe( "kdialog --getopenfilename " & ENVIRON( "HOME" ) & diag_title for input as #ff ) = 0 then
         line input #ff, temp
         close #ff
      end if

   case else
      if open pipe( "zenity --file-selection" & diag_title for input as #ff ) = 0 then
         line input #ff, temp
         close #ff
      end if

   end select

   Function = temp

end function

#endif


Constructor ScopeLock_type( ByVal ScopeLock_In As Any Ptr )

   Assert( ScopeLock_In )

   this.Mutex = ScopeLock_In

   MutexLock( this.Mutex )

End Constructor

Destructor ScopeLock_type

   MutexUnLock( this.Mutex )

End Destructor

sub UTF8toANSI( byref in as string )

   dim as integer p, seqlen, bytesleft, char

   if str_len( in ) = 0 then
      exit sub
   EndIf

   for i as integer = 0 to str_len( in ) - 1

      in[p] = in[i]
      p += 1

      select case in[i]
      case 1 to 127 'normal ANSI
      case 128 to 191 'Second, third, or fourth byte of a multi-byte sequence
         select case seqlen
         case 0
            continue for
         case 2
            char OR= ( in[i] AND &b00111111 )
         case 3, 4
            if bytesleft = 2 then
               char = ( in[i] AND &b00000011 ) SHL 6
            else
               char OR= ( in[i] AND &b00111111 )
            endif
         End select
         bytesleft -= 1

         if ( bytesleft = 0 ) and ( seqlen > 0 ) and ( char > 0 ) then
            p -= seqlen
            in[p] = char
            p += 1
            seqlen = 0
         end if

      case 194 to 223 'start of 2byte
         char = ( in[i] AND &b00000011 ) SHL 6
         seqlen = 2
         bytesleft = 1
      case 224 to 239 'start of 3byte
         
         if (in[i] = &hEF) and (str_len( in ) > i + 2) andalso ( (in[i+1] = &hBB) AND (in[i+2] = &hBF) ) then
            'UTF-8 byte order mark
            seqlen = 0
            i += 2
            p -= 1
         else
            seqlen = 3
            bytesleft = 2
         endif
         
#if 1 'hacks, not all utf8 converts to ansi nicely..
         if ( in[i] = 226 ) and ( str_len( in ) > i + 2 ) then
            seqlen = 0
            i += 2
            char = *cptr( ushort ptr, @in[i - 1] )
            select case char
            case 37760 ' emdash
               in[p-1] = asc("-")
            case 39296 ' apostrophe \u2019
               in[p-1] = asc("'")
            case 40064, 40320 ' quotes \u201c \u201d
               in[p-1] = asc("""")
            case 41600 ' bullet char
               in[p-1] = 183
            case 45696 ' minute char
               in[p-1] = asc("'")
            case 45952 ' second char
               in[p-1] = asc("""")
            case else
               'LIC_DEBUG( "\\UTF8:" & char & " \u" & hex( char, 4 ) )
               seqlen = 3
               i -= 2
            end select
         end if
#endif

      case 240 to 244 'start of 4byte
         seqlen = 4
         bytesleft= 3
      case 0
         exit for

      End Select

   Next

   str_len( in ) = p
   in[p] = 0

End sub

Sub RTrim2( Byref in as string, byref match as string = " ", byref any_ as integer = 0 )

   'Edit Inplace RTrim

   dim as integer newlen = str_len( in )
   dim as integer oldlen = newlen
   dim as integer matchlen = str_len( match )

   if ( oldlen = 0 ) or ( matchlen = 0 ) then
      exit sub
   EndIf

   if any_ <> 0 then

      for i as integer = oldlen - 1 to 0 step -1

         for j as integer = 0 to matchlen - 1
            if in[i] = Match[j] then
               newlen -= 1
               Continue For, For
            EndIf
         Next

         exit for

      Next

   elseif matchlen = 1 then

      for i as integer = oldlen - 1 to 0 step -1
         if in[i] = match[0] then
            newlen -= 1
         else
            exit for
         EndIf
      Next

   else

      'compatibility
      in = RTrim( in, match )
      exit sub

   EndIf

   in[ newlen ] = 0
   str_len( in ) = newlen

End Sub

function HSVtoRGB( h As Single, s As Integer, v As Integer ) as uInt32_t

    dim as integer r,g,b
    
    If s = 0 Then
        Return RGB( v, v, v )
    End If
   
    if h > 360 then h MOD= 360
    Dim As Single hue = h

    Select Case h
        Case 0f To 51.5f
            hue = ((hue         ) * (30f / (51.5f          )))
        Case 51.5f To 122f
            hue = ((hue -  51.5f) * (30f / (122f   -  51.5f))) + 30
        Case 122f To 142.5f
            hue = ((hue -   122f) * (30f / (142.5f -   122f))) + 60
        Case 142.5f To 165.5f
            hue = ((hue - 142.5f) * (30f / (165.5f - 142.5f))) + 90
        Case 165.5f To 192f
            hue = ((hue - 165.5f) * (30f / (192f   - 165.5f))) + 120
        Case 192f To 218.5f
            hue = ((hue -   192f) * (30f / (218.5f -   192f))) + 150
        Case 218.5f To 247f
            hue = ((hue - 218.5f) * (30f / (247f   - 218.5f))) + 180
        Case 247f To 275.5f
            hue = ((hue -   247f) * (30f / (275.5f -   247f))) + 210
        Case 275.5f To 302.5f
            hue = ((hue - 275.5f) * (30f / (302.5f - 275.5f))) + 240
        Case 302.5f To 330f
            hue = ((hue - 302.5f) * (30f / (330f   - 302.5f))) + 270
        Case 330f To 344.5f
            hue = ((hue -   330f) * (30f / (344.5f -   330f))) + 300
        Case 344.5f To 360f
            hue = ((hue - 344.5f) * (30f / (360f   - 344.5f))) + 330
    End Select
      
    Dim As Single h1 = hue / 60         
    Dim As Integer i = fix(h1)
    Dim As Single f = h1 - i
    Dim As Integer p = v * (255 - s) shr 8
    Dim As Integer q = v * (255 - f * s) shr 8
    Dim As Integer t = v * (255 - (1 - f) * s) shr 8
   
    Select Case i
        Case 0
            r = v
            g = t
            b = p
        Case 1
            r = q
            g = v
            b = p
        Case 2
            r = p
            g = v
            b = t
        Case 3
            r = p
            g = q
            b = v
        Case 4
            r = t
            g = p
            b = v
        Case 5
            r = v
            g = p
            b = q
    End Select
    
    function = RGB( r, g, b )
    
End Function

function rndColour( byref Dark as integer = 0 ) as uInt32_t 'random colour

#if 1=2 'hsv

   dim as integer v, s
   dim as single h
   
   h = rnd * 360
   s = fix( rnd * 256 )
   v = fix( rnd * 160 )
   
   if dark = 0 then
      v += 96
   EndIf
   
   function = HSVtoRGB( h, s, v )

#else

   dim as integer cmod( 2 ), cleft = 128, start = fix( rnd * 4 )
   for i as integer = 0 to 1
      cmod( i ) = fix( rnd * cleft )
      cleft -= cmod( i )
   Next
   cmod( 2 ) = cleft
   select case start
      case 0: swap cmod( 0 ), cmod( 1 )
      case 1: swap cmod( 0 ), cmod( 2 )
      case 2: swap cmod( 1 ), cmod( 2 )
   end select
   for i as integer = 0 to 2
      cmod( i ) += fix( 128 * rnd )
   Next
   if Dark = 0 then
      function = rgb( cmod(0), cmod(1), cmod(2) )
   else
      function = rgb( cmod(0), cmod(1), cmod(2) ) XOR RGBA( 255, 255, 255, 0 )
   EndIf

#endif

end function

#ifdef fbc
   'test module as standalone executable
   #if __FB_DEBUG__
      #ifndef DebugOut
         Sub DebugOut( ByRef S As String )
            print s
         End Sub
      #endif
   #endif   
   'print GoogleCalc( "((5+52)!)" )

#endif
