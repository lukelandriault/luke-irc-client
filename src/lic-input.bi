#include once "crt/stdint.bi"

Declare Function GetClipboardAsString( ) As String
Declare Function CopyToClipboard( ByRef As String ) As Integer

#undef TRUE
#undef FALSE
Const as integer TRUE = (0 = 0), FALSE = (0 = 1)

Type FBGFX_CHARACTER_INPUT

   BackGroundColour 	As uInt32_t
   ForeGroundColour 	As uInt32_t
   OptionFlags       As UInteger
   Carat 				As Integer
   x1 					As Integer
   x2 					As Integer
   y1 					As Integer
   y2 					As Integer
   KeyboardLayout    As UByte

   Declare Sub Print
   Declare Sub Parse( ByRef As long, ByRef As long = 0 )
   Declare Sub CursorBlink
   Declare Sub MouseDown( ByVal As Integer )
   Declare Sub Custom_ASCII( ByVal As Integer )
   Declare Sub Set ( ByRef As string )
   Declare Operator Cast( ) As String   
   Declare Operator &= ( ByRef As ZString Ptr )
   Declare Property Length( ) As uinteger

   Declare Constructor _
      ( _
         ByRef inx1 		As Integer = -1, _
         ByRef iny1 		As Integer = -1, _
         ByRef inx2 		As Integer = -1, _
         ByRef iny2 		As Integer = -1, _
         ByRef BGC 		As uInt32_t = 1, _
         ByRef FGC 		As uInt32_t = 1 _
      )
   Declare Destructor

   'Private:

   Declare Sub CenterCarat

   BlinkState        As Integer
   SelectionStart 	As Integer
   SelectionLength 	As Integer
   TextOffset 			As Integer
   Justification 		As Integer
   _Text 				As String
   InputString(31) 	As String
   InputBrowser : 5 	As UByte
   InputCounter : 5 	As UByte

End Type

Enum FBGFX_INPUT_FLAGS
   Disable_EMAC_Controls = 1 shl 0
End Enum

Enum FBGFX_Keyboard_Layouts
   KB_English = 1
   KB_French
End Enum
