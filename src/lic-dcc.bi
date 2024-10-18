#undef NoError
#undef Failed

enum DCC_TYPES
   DCC_CHAT
   DCC_SEND
end enum

Enum DCC_STATUS
   Init
   Listening
   Connecting
   Transferring
   Complete
   Failed
End Enum

Enum DCC_ERROR
   NoError
   TimedOut
   Cancelled
   Rejected
   NetworkError
   FileReadError
   FileWriteError
End Enum

Type DCC_TRACKER

   Declare Constructor
   Declare Destructor

   Declare Sub ThreadEnd( )
   Declare Sub SetStatus( ByRef As Integer, ByRef As Integer = 0 )
   Declare Function GetStatus( ) As String
   Declare Function GetError( ) As String

   As Integer           Type_
   As int32_t           status
   As int32_t           SockStatus
   As Integer           error_id
   as integer           token
   As uint16_t          port
   As String            user
   As String            argument
   As uInt32_t          ip
   As UInteger          id
   As chi.socket Ptr    socket
   As Any Ptr           mutex
   As Any Ptr           Thread
   As UInteger          filesize
   As UInteger          bytes_xfer
   As UInteger          speed
   As uinteger          avgspeed
   as int32_t           speedlimit
   As Byte              resumeRequest
   As double            CreationTime
   as any ptr           RoomPtr
   as any ptr           ServerPtr

End Type

Type DCC_LIST_TYPE
   Declare Destructor
   Declare Function Find OVERLOAD ( ByRef As String, ByRef As UShort, ByRef As UInteger, ByRef as Integer = 0 ) As DCC_TRACKER Ptr
   Declare Function Find ( Byref as any ptr ) as DCC_TRACKER ptr
   Declare Sub Add( ByVal As DCC_TRACKER Ptr )
   Declare Sub Remove( ByVal As UInteger )
   Declare Sub Shutdown( )
   Declare Sub FreeZombies( )
   Declare Sub Proc( )
   As UInteger Allocated, Used, Count
   As DCC_TRACKER Ptr Ptr tracker
End Type

Declare Sub DCC_Parse( ByRef In_ As String )
Declare Sub DCC_FILE_ACCEPT_THREAD( ByVal DT As DCC_TRACKER Ptr )
Declare Sub DCC_FILE_SEND_THREAD( ByVal DT As DCC_TRACKER Ptr )
Declare Function DCC_CHAT_Out( Byref as string ) as integer
Declare function DCC_BIND( byval sock as any ptr, byref port as uint16_t ) as integer
