#include "lic.bi"

Function DrawString( byval x as integer, byval y as integer, byref s as string, byval c as uInt32_t, byval hint as integer = DS_Hint.CB ) as integer

   select case hint

   'ChatBox
   case DS_Hint.CB

      select case Global_IRC.Global_Options.FontRender

      case fbgfx
         Draw String ( x, y ), s, c
         x += len_hack( s ) * 8

      case else
         x = Global_IRC.TextInfo.FT_C.DrawString( x, y, s, c )

      End Select


   'UserList
   case DS_Hint.UL

      select case Global_IRC.Global_Options.FontRender

      case fbgfx
         Draw String ( x, y ), s, c
         x += len_hack( s ) * 8

      case else
         x = Global_IRC.TextInfo.FT_U.DrawString( x, y, s, c )

      End Select

   End Select

   Function = x

End Function
