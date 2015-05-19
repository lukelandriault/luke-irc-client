#include "lic.bi"
#include "lic-server.bi"

sub Server_Type.LoadNumerics( byref N as string )

   select case ucase( N )

   case "FREENODE"
      Network = freenode

      Numeric.RPL_LOGGEDIN	= 901

   case "EFNET"
      Network = efnet

      Numeric.ERR_LAST_ERR_MSG = 999

   case "QUAKENET"
      Network = quakenet

   case "UNDERNET"
      Network = undernet

   case "DALNET"
      Network = dalnet

   End Select

   /'
      Ratbox:
      Numeric.RPL_LOGGEDIN	      = 900
      Numeric.RPL_LOGGEDOUT      = 901
      Numeric.ERR_NICKLOCKED     = 902

      Numeric.ERR_LAST_ERR_MSG   = 999
   '/

End Sub
