#include once "lic.bi"

#if LIC_DCC

private function DCC_FILE_ACCEPT( byval DT as DCC_TRACKER ptr ) as integer

   MutexLock( DT->Mutex )

   Var filename = "downloads/" & DT->argument
   Var totalrecv = DT->bytes_xfer
   Var sock = DT->Socket
   Var filesize = DT->filesize
   var limit = DT->speedlimit
   sock->recv_limit = DT->speedlimit
   DT->Status = DCC_STATUS.Transferring

   MutexUnLock( DT->Mutex )

   Var ff = FreeFile
   If Open( filename For Binary As #ff ) <> 0 Then
      LIC_DEBUG( "\\DCC: Error opening file for write:" & filename )
      Sock->Close( )
      DT->SetStatus( DCC_STATUS.Failed, DCC_ERROR.FileWriteError )
      MutexLock( Global_IRC.Mutex )
      If *Global_IRC.Shutdown = 0 Then
         Notice_Gui( "** DCC: " & DT->GetStatus( ), Global_IRC.Global_Options.ServerMessageColour )
      EndIf
      MutexUnLock( Global_IRC.Mutex )
      sleep( 2000, 1 )
      DT->ThreadEnd( )
      return FALSE
   EndIf

   Dim As UInteger BUFFER_SIZE = DCC_BUFFER_SIZE
   Dim As UByte Ptr buffer = Allocate( DCC_BUFFER_SIZE )

   While Buffer = 0
      sleep( 26, 1 )
      If BUFFER_SIZE >= 1024 Then BUFFER_SIZE \= 2
      buffer = Allocate( BUFFER_SIZE )
   Wend

   LIC_DEBUG( "\\DCC: Starting file xfer" )

   MutexLock( Global_IRC.Mutex )
   Notice_Gui( _
      "** DCC: Starting file transfer " & DT->Argument & _
      " from " & DT->User & ". Use '/dcc list' to provide updates", _
      Global_IRC.Global_Options.ServerMessageColour )
   MutexUnLock( Global_IRC.Mutex )

   Var TT = CUInt( Timer )
   Var StatsUpdate = TT
   Var StartSize = TotalRecv
   Var StartTime = TT
   var TimeOut = Timer + 30

   Dim As UInteger TotalGot, Got30, Got30T = TT + 30
   Dim As Integer Amount

   Seek #ff, StartSize + 1

   Do

      if sock->is_closed( ) = TRUE then
         MutexLock( DT->Mutex )
         If TotalRecv >= FileSize Then
            DT->Status = DCC_STATUS.Complete
         else
            DT->Status = DCC_STATUS.Failed
            DT->Error_ID = DCC_ERROR.Cancelled
         EndIf
         MutexUnlock( DT->Mutex )
         Exit Do
      EndIf

      Amount = sock->length( )
      if Amount > BUFFER_SIZE then Amount = BUFFER_SIZE
      if Amount > 0 then Amount = sock->get_data( buffer, Amount )

      If Amount > 0 Then

         Put #ff, , *buffer, Amount

         TotalRecv += Amount
         TotalGot += Amount
         Got30 += Amount

         sock->Put( Cast( Integer, htonl( TotalRecv ) ) )

         TimeOut = Timer + 30

         If TotalRecv >= FileSize Then
            MutexLock( DT->Mutex )
            DT->bytes_xfer = FileSize
            DT->avgspeed = ( totalrecv - StartSize ) / ( TT - StartTime )
            DT->Status = DCC_STATUS.Complete
            MutexUnLock( DT->Mutex )
            LIC_DEBUG( "\\DCC: DCC Complete" )
            Exit Do
         EndIf

      else

         sleep( 1, 1 )

         TT = Timer

         If TT > StatsUpdate Then

            MutexLock( DT->Mutex )
            DT->bytes_xfer = totalrecv
            DT->speed = sock->recv_rate
            #if __FB_DEBUG__
               'print #1, "\\DCC: Speed: " & CalcSize( DT->speed )
            #endif
            if limit <> DT->speedlimit then
               limit = DT->speedlimit
               sock->recv_limit = limit * 1.1
            EndIf

            StatsUpdate += 1

            if TT > Got30T then
               Got30T = TT + 30
               DT->avgspeed = Got30 \ 30
               Got30 = 0
            endif

            MutexUnLock( DT->Mutex )

         EndIf

         If Timer > TimeOut Then
            DT->SetStatus( DCC_STATUS.Failed, DCC_ERROR.TimedOut )
            LIC_DEBUG( "\\DCC: DCC Timed Out" )
            Exit Do
         EndIf

      EndIf

   Loop

   Close #ff
   DeAllocate( buffer )

   MutexLock( DT->Mutex )
   DT->speed = 0
   sock->close
   MutexUnLock( DT->Mutex )

   sleep( 2000, 1 )

   Function = TRUE

End Function

Sub DCC_FILE_ACCEPT_THREAD( ByVal DT As DCC_TRACKER Ptr )

   DT->Socket = New chi.socket
   dim as integer status = TRUE

   if DT->Token = 0 then

      DT->SetStatus( DCC_STATUS.Connecting )
      LIC_DEBUG( "\\DCC: Connecting..." )

      if DT->Socket->client( DT->ip, DT->port ) <> chi.socket_OK Then
         LIC_DEBUG( "\\DCC: Could not connect" )
         DT->SetStatus( DCC_STATUS.Failed, DCC_ERROR.NetworkError )
         MutexLock( Global_IRC.Mutex )
         If *Global_IRC.Shutdown = 0 Then
            Notice_Gui( "** DCC: " & DT->GetStatus( ), Global_IRC.Global_Options.ServerMessageColour )
         EndIf
         MutexUnLock( Global_IRC.Mutex )
         status = FALSE
      EndIf

   else
      'reverse DCC

      DT->Port = Global_IRC.Global_Options.DCC_port
      status = DCC_BIND( DT->Socket, DT->Port )

      if status = chi.SOCKET_OK then

         DT->SetStatus( DCC_STATUS.Listening )
         status = DT->socket->listen( 45 )
         if status <> TRUE then
            DT->socket->Close( )
            MutexLock( DT->Mutex )
            If DT->Status = DCC_STATUS.Listening Then
               LIC_DEBUG( "\\DCC: Timed Out" )
               DT->Status = DCC_STATUS.Failed
               DT->Error_ID = DCC_ERROR.TimedOut
               MutexUnLock( DT->Mutex )
               MutexLock( Global_IRC.Mutex )
               If *Global_IRC.Shutdown = 0 Then
                  Notice_Gui( "** DCC: " & DT->GetStatus( ), Global_IRC.Global_Options.ServerMessageColour )
               EndIf
               MutexUnLock( Global_IRC.Mutex )
            Else
               MutexUnLock( DT->Mutex )
            EndIf
         endif

      else

         DT->SetStatus( DCC_STATUS.Failed, DCC_ERROR.NetworkError )
         MutexLock( Global_IRC.Mutex )
         If *Global_IRC.Shutdown = 0 Then
            Notice_Gui( "** DCC: " & DT->GetStatus( ) & " could not bind to address", Global_IRC.Global_Options.ServerMessageColour )
         EndIf
         MutexUnLock( Global_IRC.Mutex )
         status = FALSE

      endif

   endif

   if status <> TRUE then
      sleep( 2000, 1 )
      DT->ThreadEnd( )
      Exit Sub
   EndIf

   if DCC_FILE_ACCEPT( DT ) = FALSE then
      exit sub
   EndIf

   MutexLock( Global_IRC.Mutex )
   If *Global_IRC.Shutdown = 0 Then
      Notice_Gui( "** DCC: " & DT->GetStatus( ), Global_IRC.Global_Options.ServerMessageColour )

      if DT->Status = DCC_STATUS.Complete then
         Notice_Gui( "** To view the file in it's folder click here", Global_IRC.Global_Options.ServerMessageColour )
         with *( Global_IRC.CurrentRoom->TextArray[ Global_IRC.CurrentRoom->NumLines - 1 ] )
            .AddLink( len_hack( .Text ) - 3, len_hack( .Text ) + 1, 0, LinkShell )
#ifndef __FB_LINUX__
            .HyperLinks->HyperLink = "explorer /e,/select," & curdir & "\downloads\" & String_Replace( "/", "\", DT->argument )
#else
            .HyperLinks->HyperLink = curdir & "/downloads/"
#endif
         end with
      endif

   EndIf
   MutexUnLock( Global_IRC.Mutex )

   DT->ThreadEnd( )

End Sub

private function DCC_FILE_SEND( Byval DT as DCC_TRACKER ptr ) as integer

   MutexLock( DT->Mutex )

   var sock = DT->socket
   Var filename = DT->argument
   Var totalsent = DT->bytes_xfer
   var limit = DT->speedlimit
   sock->send_limit = limit
   DT->Status = DCC_STATUS.Transferring

   MutexUnLock( DT->Mutex )

   Var ff = FreeFile
   If Open( filename For Binary Access Read As #ff ) <> 0 Then
      LIC_DEBUG( "\\DCC: Error opening file:" & filename )
      Sock->Close( )
      DT->SetStatus( DCC_STATUS.Failed, DCC_ERROR.FileReadError )
      MutexLock( Global_IRC.Mutex )
      If *Global_IRC.Shutdown = 0 Then
         Notice_Gui( "** DCC: " & DT->GetStatus( ), Global_IRC.Global_Options.ServerMessageColour )
      EndIf
      MutexUnLock( Global_IRC.Mutex )
      sleep( 2000, 1 )
      DT->ThreadEnd( )
      return FALSE
   EndIf

   dim As UInteger BUFFER_SIZE = DCC_BUFFER_SIZE
   Dim As UByte Ptr buffer = Allocate( BUFFER_SIZE )

   While Buffer = 0
      sleep( 26, 1 )
      If BUFFER_SIZE >= 1024 Then BUFFER_SIZE \= 2
      buffer = Allocate( BUFFER_SIZE )
   Wend

   Dim As UInteger filesize = Lof( ff )
   Dim As UInteger buff_caret
   Dim As Double TimeOut = Timer + 30
   Dim As UInteger bytesread
   Dim As UInteger reply

   LIC_DEBUG( "\\DCC: Starting file xfer" )

   MutexLock( Global_IRC.Mutex )
   Notice_Gui( _
      "** DCC: Starting file transfer " & DT->Argument & _
      " to " & DT->User & ". Use '/dcc list' to provide updates", _
      Global_IRC.Global_Options.ServerMessageColour )
   MutexUnLock( Global_IRC.Mutex )

   Var TT = CUInt( Timer )
   Var StatsUpdate = TT + 1
   Var StartSize = TotalSent
   Var StartTime = TT

   dim as uinteger sent30, sent30T = TT + 30

   Do Until sock->is_closed( ) = TRUE

      sleep( 1, 1 )
      TT = Timer

      If TT > StatsUpdate Then

         StatsUpdate += 1

         ScopeLock( DT->Mutex )

         MutexLock( sock->p_send_lock )
         DT->bytes_xfer = totalsent + sock->p_send_caret - iif( totalsent > BUFFER_SIZE, BUFFER_SIZE, 0 )
         MutexunLock( sock->p_send_lock )
         if limit <> DT->speedlimit then
            limit = DT->speedlimit
            sock->send_limit = limit * 1.1
         EndIf
         DT->speed = sock->send_rate

         if TT > sent30T then
            sent30T = TT + 30
            DT->avgspeed = sent30 \ 30
            sent30 = 0
         endif

         If sock->length( ) > 0 Then
            sock->Dump_data( sock->Length( ) )
         EndIf

      EndIf

      MutexLock( sock->p_send_lock )

      if totalsent >= filesize Then

         if sock->p_send_size <> 0 then
            MutexunLock( sock->p_send_lock )
            sleep( 100, 1 )
            Continue Do
         endif

         MutexunLock( sock->p_send_lock )
         Exit Do

      elseIf ( sock->p_send_size = 0 ) and ( sock->p_send_caret = 0 ) Then

         MutexunLock( sock->p_send_lock )

         If buff_caret >= bytesread Then
            Get #ff, totalsent + 1, *buffer, BUFFER_SIZE, bytesread
            buff_caret = 0
         EndIf

         var b_sent = 0
         var send_size = bytesread - buff_caret

         #define max_chunk 1024 * 128
         if send_size > max_chunk then send_size = max_chunk

         do
            b_sent = Sock->put_data( buffer + buff_caret, send_size )
            send_size \= 2
         loop while ( b_sent = 0 ) and ( send_size >= 512 )

         if b_sent > 0 then
            sent30 += b_sent
            totalsent += b_sent
            buff_caret += b_sent
            TimeOut = Timer + 30
         endif

      else
         MutexunLock( sock->p_send_lock )
      endif

   Loop

   Close #ff

   DeAllocate( buffer )

   MutexLock( DT->Mutex )

   DT->speed = 0

   if totalsent >= filesize then

      TT = Timer
      DT->status = DCC_STATUS.Complete
      DT->bytes_xfer = filesize
      DT->avgspeed = ( filesize - StartSize ) / ( TT - StartTime )
      LIC_DEBUG( "\\DCC: Complete" )

   elseIf ( sock->is_closed( ) = TRUE ) and ( DT->Status <> DCC_STATUS.Failed ) Then

      DT->status = DCC_STATUS.Failed
      DT->error_id = DCC_ERROR.Cancelled
      LIC_DEBUG( "\\DCC: Transfer Cancelled" )

   EndIf

   MutexunLock( DT->Mutex )

   Function = TRUE

End Function

Sub DCC_FILE_SEND_THREAD( ByVal DT As DCC_TRACKER Ptr )

   dim as integer status = TRUE

   if DT->Token = 0 then

      DT->SetStatus( DCC_STATUS.Listening )

      If ( DT->socket->listen( 45 ) <> TRUE ) Then
         DT->socket->Close( )
         MutexLock( DT->Mutex )
         If DT->Status = DCC_STATUS.Listening Then
            LIC_DEBUG( "\\DCC: Timed Out" )
            DT->Status = DCC_STATUS.Failed
            DT->Error_ID = DCC_ERROR.TimedOut
            MutexUnLock( DT->Mutex )
            MutexLock( Global_IRC.Mutex )
            If *Global_IRC.Shutdown = 0 Then
               Notice_Gui( "** DCC: " & DT->GetStatus( ), Global_IRC.Global_Options.ServerMessageColour )
            EndIf
            MutexUnLock( Global_IRC.Mutex )
         Else
            MutexUnLock( DT->Mutex )
         EndIf
         status = FALSE
      EndIf

   else

      var IP = DT->IP
      DT->IP = 0 'hack to display it as outgoing
      DT->socket = New chi.socket
      DT->SetStatus( DCC_STATUS.Connecting )
      LIC_DEBUG( "\\DCC: Connecting..." )

      if DT->Socket->client( IP, DT->port ) <> chi.socket_OK Then
         LIC_DEBUG( "\\DCC: Could not connect" )
         DT->SetStatus( DCC_STATUS.Failed, DCC_ERROR.NetworkError )
         MutexLock( Global_IRC.Mutex )
         If *Global_IRC.Shutdown = 0 Then
            Notice_Gui( "** DCC: " & DT->GetStatus( ), Global_IRC.Global_Options.ServerMessageColour )
         EndIf
         MutexUnLock( Global_IRC.Mutex )
         status = FALSE
      EndIf

   endif

   if status = FALSE then
      sleep( 2000, 1 )
      DT->ThreadEnd( )
      Exit sub
   EndIf

   if DCC_FILE_SEND( DT ) = FALSE then
      exit sub
   EndIf

   MutexLock( Global_IRC.Mutex )
   If *Global_IRC.Shutdown = 0 Then
      Notice_Gui( "** DCC: " & DT->GetStatus( ), Global_IRC.Global_Options.ServerMessageColour )
   EndIf
   MutexUnLock( Global_IRC.Mutex )

   var sock = DT->Socket
   var Reply = 20
   while Reply > 0
      Reply -= 1
      sleep( 500, 1 )
      MutexLock( Global_IRC.Mutex )
      if *Global_IRC.Shutdown <> 0 then
         Reply = 0
      EndIf
      MutexUnlock( Global_IRC.Mutex )
      If sock->length( ) > 0 then
         sock->Dump_data( sock->Length( ) )
      EndIf
      if Reply = 10 then
         Sock->Close( )
      EndIf
   wend

   if Sock->Is_Closed( ) = FALSE then
      Sock->Close( )
      sleep( 5000, 1 )
   endif

   DT->ThreadEnd( )

End Sub

#endif