#include once "crt/stdint.bi"
#ifndef __FB_LINUX__
declare function w32_GetFilename( byval title as zstring ptr = 0 ) as string
#else
declare function lin_GetFilename( byref title as string = "" ) as string
declare sub forkexec(_command as string)
#endif

#undef TRUE
#undef FALSE
Const as integer TRUE = (0 = 0), FALSE = (0 = 1)

#include once "lic-compile-options.bi"

#if LIC_USE_ASM_FUNCTIONS
Declare Function InstrAsm_( ByVal Start As Integer, ByRef TEXT as string, ByVal CHAR as integer) as Integer
Declare Function StringEqualAsm_ ( ByRef Str1 As String, ByRef Str2 As String ) As Integer
#endif

Declare Function String_Replace( ByRef As String, ByRef As String, ByRef As String ) As String
Declare Function CalcTime( ByVal t As Uinteger ) As String
Declare Function CalcSize( ByRef b As uinteger ) As String
Declare Function SafeFileNameEncode( ByRef in As String ) As String
Declare Function SortCreate( ByRef Key As String ) As uint64_t
Declare function String_ExplodeZ( ByRef In_ As String, A() As ZString ptr ) as integer
Declare Function RevLineInput( byref ff as long, byref s as string ) as integer
Declare Function MkDirTree( byref folder as string ) as integer
Declare Function MaskCompare( Byref as String, Byref as String ) as Integer
Declare function rndColour( byref Dark as integer = 0 ) as uInt32_t
declare function HSVtoRGB( h As Single, s As Integer, v As Integer ) as uInt32_t
Declare Sub String_Explode( ByRef In_ As String, A() As String )
declare Sub UTF8toANSI( byref as string )
declare Sub RTrim2( Byref in as string, byref match as string = " ", byref any_ as integer = 0 )


type ParamList_Type

   Declare Constructor ( byref as string, byref as ubyte = asc(" ") )
   Declare Destructor ( )

   as zstring ptr ptr z
   as string ptr s
   as integer ptr start
   as integer count

   as string copyv   'verbatim copy
   as string copyz   'null mangled copy

End Type

type NonBlockingProc

   declare constructor( byval as any ptr, byval as any ptr = 0 )
   declare destructor( )

   declare function done( ) as integer
   as any ptr return_value

   private:

   as any ptr mutex, proc, param, handle
   as integer flag

   declare static sub execute( byval as NonBlockingProc ptr )

End Type

Type ScopeLock_type

   Declare Constructor( Byval As Any Ptr )
   Declare Destructor

   As Any Ptr Mutex

End Type

#Macro ScopeLock2( _PTR, __SL_ID )
   Dim As ScopeLock_type _ScopleLock_##__SL_ID = _PTR
#EndMacro

#Macro ScopeLock( _PTR )
   ScopeLock2( _PTR, __LINE__ )
#EndMacro


