#define rgb8(RR,GG,BB) cast( ubyte, ((RR)And 224)Or((((GG)shr 5))shl 2)Or(((BB)shr 6)) )
#define rgba8(RR,GG,BB,AA) cast( ubyte, ((RR)and 224)or((((GG)shr 5))shl 2)or(((BB)shr 6)) )
#define rgb32to8(RGB32) cast( ubyte, ((((RGB32) shr 16)and 224)or(((((RGB32)shr 13)and 7))shl 2)or((((RGB32) and 255)shr 6))) )
#define rgb8to32(RGB8) cast( uint32_t, ((((RGB8)and 224)shl 16)or(((RGB8)and 28)shl 11)or(((RGB8)and 3)shl 6)or &hFF000000) )

'string hacks
#define str_loc( _s ) cptr( integer ptr, @_s )[0]
#define str_len( _s ) cptr( integer ptr, @_s )[1]
#define str_all( _s ) cptr( integer ptr, @_s )[2]

#if __LIC__

   'no graphics window for testing purposes
   '#Define LIC_NO_GFX

  
   #if __FB_BACKEND__ = "gcc"
       'Replace all asm code with native fb
      #define LIC_NUKE_ASM 1
      'Use faster ASM runtime functions written by Mysoft
      #define LIC_USE_ASM_FUNCTIONS 0
   #else
      #define LIC_NUKE_ASM 0
      #define LIC_USE_ASM_FUNCTIONS 1
   #endif
   
   'Use faster pointer hacks for fb strings instead of len() etc
   #Define LIC_USE_STRING_HACKS 1

   'default value for buffer creation, will grow if needed
   #define IRC_MAX_MESSAGE_SIZE 512

   'Minimum tab size width in pixels (tabs on the top)
   #Define LIC_MIN_TAB_SIZE 40

   'WinAPI buffer width for drawfont( )
   #define LIC_DRAWFONT_X 2048

   'enable dcc?
   #define LIC_DCC 1
   
   'link chisock? wip
   #define LIC_CHI 1
   
   'use freetype lib?
   #define LIC_FREETYPE 0
   
   'DCC starting listen port. min 1025, max 65535, recommended 10000 to 50000
   #Define DCC_DEFAULT_LISTEN_PORT 13000

   'DCC file transfer memory buffer size
   #Define DCC_BUFFER_SIZE 512 * 1024

#endif

#If LIC_USE_STRING_HACKS
   #Define len_hack(_s) str_len(_s)
   #Define len_swap(_s,_n) str_len(_s) = _n
#Else
   #Define len_hack(_s) Len(_s)
   #Define len_swap(_s,_n ) _s = Left(_s,_n)
#EndIf

#if LIC_USE_ASM_FUNCTIONS
   #Define StringEqualAsm StringEqualAsm_
   #Define InstrASM InstrASM_
#else
   #Define StringEqualAsm( _S1, _S2 ) ( _S1 = _S2 )
   #Define InstrASM( _S, _T, _C ) InStr( _S, _T, Chr( _C ) )
#endif

#if __LIC_GCC__ 'bitmasks not working in gcc
   #Define LIC_BOOL_BITS 1
#else
   #Define LIC_BOOL_BITS 1
#endif
