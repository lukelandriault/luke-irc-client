#include "lic.bi"

static shared as any ptr curl

private function curl_writer( src as any ptr, size as size_t, nmembers as size_t, obj as curl_obj ptr ) as integer
   if obj = NULL then return 0
   
   dim as int32_t bytes = nmembers * size
   if obj->allocated = 0 then
      obj->allocated = 1024 * 32
      obj->p = allocate( obj->allocated )
   endif
   if obj->allocated - bytes - obj->size <= 0 then
      obj->allocated = (obj->allocated + bytes) * 1.25
      obj->p = Reallocate( obj->p, obj->allocated )
   EndIf
   memcpy( obj->p + obj->size, src, bytes )
   
   obj->size += bytes
   return bytes
end function

function curlget( byref url as string, byref ret as curl_obj, compress as boolean, reuse as boolean ) as CURLcode

   if curl = 0 then
      curl = curl_easy_init()
      if curl = 0 then
         LIC_DEBUG( "\\curl init error" )
         return CURLE_FAILED_INIT
      endif
      'curl_easy_setopt( curl, CURLOPT_USERAGENT, "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.21 Safari/537.36" )
      curl_easy_setopt( curl, CURLOPT_WRITEFUNCTION, @curl_writer )
      curl_easy_setopt( curl, CURLOPT_TIMEOUT, 3 )
      'curl_easy_setopt( curl, CURLOPT_FILETIME, 1 )
      curl_easy_setopt( curl, CURLOPT_PROXY, "" )
      'curl_easy_setopt( curl, CURLOPT_VERBOSE, 1 )
   endif
   
   ret.size = 0
   curl_easy_setopt( curl, CURLOPT_URL, strptr( url ) )
   curl_easy_setopt( curl, CURLOPT_WRITEDATA, @ret )
   curl_easy_setopt( curl, CURLOPT_FORBID_REUSE, iif( reuse = true , 0 , 1 ) )
#if LIBCURL_VERSION_NUM >= &h071506
   curl_easy_setopt( curl, CURLOPT_ACCEPT_ENCODING, iif( compress = true, @"", NULL ) )
#else
   curl_easy_setopt( curl, CURLOPT_ENCODING, iif( compress = true, @"", NULL ) )
#endif

   dim as CURLcode res = curl_easy_perform( curl )
   dim as integer http_code = 0
   curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, @http_code)
   if( res <> CURLE_OK or http_code < 200 or http_code > 299 ) then
      ret.size = 0
      if http_code < 400 and http_code > 499 then
         LIC_DEBUG( "curlget() failed: " & *curl_easy_strerror(res) )
      endif
   endif
   
   return res
end function