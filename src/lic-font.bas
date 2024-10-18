#if __LIC__
   #define LIC_WIN_INCLUDE 1
   #include once "lic.bi"
#else
   #ifdef __FB_WIN32__
      #include once "windows.bi"
   #endif
   #include once "lic-font.bi"
   #include once "lic-compile-options.bi"
   #include once "fbgfx.bi"
#endif

namespace font

#ifdef __FB_WIN32__

function font_obj.Load_W32Font( byref font as string, _size_ as integer, lower as integer = 0, upper as integer = 255 ) as integer

   if len( font_ ) then this.destructor( )

   font_ = font
   lower_ = lower
   upper_ = upper
   hint = font_w32

   dim as hfont newfont
   dim as hdc THEDC

   THEDC = CreateDC("DISPLAY",null,null,null)
   #define FontSize(PointSize) -MulDiv(PointSize, GetDeviceCaps(THEDC, LOGPIXELSY), 72)
   newfont = CreateFont(FontSize(_size_),0,0,0,0,0,0,0,6,OUT_OUTLINE_PRECIS,CLIP_DEFAULT_PRECIS,DEFAULT_QUALITY,0,cast(Any Ptr,Strptr(font)))

   if newfont = 0 then
      DeleteDC(THEDC)
      return create_font_failed
   endif

   dim as MAT2 m2 = ((0, 1), (0, 0), (0, 0), (0, 1))
   dim as GLYPHMETRICS GM
   dim as integer Height1, Height2, bufsize
   dim as ubyte ptr pBuf

   SelectObject(THEDC,newfont)

   for i as integer = lower to upper

      dim as integer outsize = GetGlyphOutline( THEDC, i, GGO_GRAY8_BITMAP, @GM, 0, 0, @m2 )

      glyph( i ).bTop = _size_ - ( GM.gmCellIncY + GM.gmptGlyphOrigin.Y )
      glyph( i ).bLeft = GM.gmptGlyphOrigin.X
      glyph( i ).advance_x = GM.gmCellIncX
      glyph( i ).advance_y = GM.gmCellIncY + GM.gmptGlyphOrigin.Y

      if outsize > bufsize then
         bufsize = outsize * 1.5
         pBuf = reallocate( pBuf, bufsize )
      EndIf

      if outsize > 0 then

         dim as integer p, char

         if GetGlyphOutline( THEDC, i, GGO_GRAY8_BITMAP, @GM, bufsize, pBuf, @m2 ) <= 0 then
            Continue for
         EndIf

         glyph( i ).greyscale = ImageCreate( GM.gmBlackBoxX, GM.gmBlackBoxY, 0, 8 )

         if glyph( i ).greyscale = 0 then
             continue for
         endif

         var offset = GM.gmBlackBoxX and 3
         if offset <> 0 then
            offset = 4 - offset
         endif

         if glyph( i ).advance_y > Height1 then Height1 = glyph( i ).advance_y
         if glyph( i ).bTop < Height2 then Height1 = glyph( i ).bTop

#define FontSmooth 1

         for y as integer = 0 to GM.gmBlackBoxY - 1
            for x as integer = 0 to GM.gmBlackBoxX - 1
               char = pBuf[ p ]
               if char > 0 then
                  if FontSmooth <> 0 then
                     pset glyph( i ).greyscale, ( x, y ), char * 4 - 1
                  else
                     pset glyph( i ).greyscale, ( x, y ), 255
                  endif
               endif
               p += 1
            next
            p += offset
         next

      endif

   next

   size_ = Height1 - Height2 + 1

   if pBuf <> 0 then
      deallocate( pBuf )
   EndIf

   DeleteObject(newfont)
   DeleteDC(THEDC)

end function

#endif

' ---------    Free Type   -------
#if LIC_FREETYPE

extern "c"
dim shared FT_Init_FreeType    as Function (byval as FT_Library ptr) as FT_Error
dim shared FT_Done_FreeType    as Function (byval as FT_Library) as FT_Error
dim shared FT_Set_Pixel_Sizes  as Function (byval as FT_Face, byval as FT_UInt, byval as FT_UInt) as FT_Error
dim shared FT_MulFix           as Function (byval as FT_Long, byval as FT_Long) as FT_Long
dim shared FT_New_Face         as Function (byval as FT_Library, byval as zstring ptr, byval as FT_Long, byval as FT_Face ptr) as FT_Error
dim shared FT_Done_Face        as Function (byval as FT_Face) as FT_Error
dim shared FT_Load_Char        as Function (byval as FT_Face, byval as FT_ULong, byval as FT_Int32) as FT_Error
dim shared FT_Bitmap_Convert   as Function (byval as FT_Library, byval as FT_Bitmap ptr, byval as FT_Bitmap ptr, byval as FT_Int) as FT_Error
end extern

#endif
dim shared ttf_main as __ttfont_main__ ptr

Function getFullFontFilePath( ByRef fontname As Const String ) As String
	If asc( fontname ) <> Asc("#") Then Return fontname

#ifdef __FB_WIN32__
	Function = environ("WINDIR") & "\Fonts\" & mid( fontname, 2 )
#EndIf

#Ifdef __FB_LINUX__
	Function = "/usr/share/fonts/truetype/" & mid( fontname, 2 )
#EndIf

End Function

Function ttf_init( ) as integer

   if ttf_main = 0 then
      ttf_main = new __ttfont_main__
   EndIf

   if ttf_main->dll = 0 then

#ifdef __FB_WIN32__
      ttf_main->dll = DyLibLoad("freetype6.dll")
#else
   #if LIC_FREETYPE
      ttf_main->dll = DyLibLoad("freetype.so.6")
      if ttf_main->dll = 0 then ttf_main->dll = DyLibLoad("freetype.so")
   #endif
#endif

      if ttf_main->dll = 0 then
         ttf_main->internal_error = dll_not_found
         return ttf_main->internal_error
      endif

   EndIf

#if LIC_FREETYPE
   if ttf_main->symbols = 0 then
      ttf_main->symbols = 1

      FT_Set_Pixel_Sizes   = DyLibSymbol( ttf_main->dll, "FT_Set_Pixel_Sizes" )
      FT_New_Face          = DyLibSymbol( ttf_main->dll, "FT_New_Face" )
      FT_Done_Face         = DyLibSymbol( ttf_main->dll, "FT_Done_Face" )
      FT_Load_Char         = DyLibSymbol( ttf_main->dll, "FT_Load_Char" )
      FT_MulFix            = DyLibSymbol( ttf_main->dll, "FT_MulFix" )
      FT_Done_FreeType     = DyLibSymbol( ttf_main->dll, "FT_Done_FreeType" )
      FT_Init_FreeType     = DyLibSymbol( ttf_main->dll, "FT_Init_FreeType" )
      FT_Bitmap_Convert    = DyLibSymbol( ttf_main->dll, "FT_Bitmap_Convert" )

   endif

   if ttf_main->init = 0 then

      ttf_main->external_error = FT_Init_FreeType( varptr( ttf_main->library ) )
      if ttf_main->external_error <> 0 then
         ttf_main->internal_error = init_failed
         Return init_failed
      EndIf

      ttf_main->Init = 1

   EndIf
#endif

   ttf_main->internal_error = no_error
   Function = no_error

End Function

sub ttf_deinit( ) DESTRUCTOR

#if LIC_FREETYPE
   if ttf_main <> 0 then

      if ttf_main->dll <> 0 then

         if ttf_main->init <> 0 then
            FT_Done_FreeType( ttf_main->library )
         EndIf

         DyLibFree( ttf_main->dll )

      endif

      delete ttf_main

   EndIf

   ttf_main = 0
#endif

End sub

#if LIC_FREETYPE
'from Anson on the mailing list:
'http://lists.nongnu.org/archive/html/freetype/2005-06/msg00033.html
function DeriveDesignHeightFromMaxHeight(byval aFace as FT_Face, byval aMaxHeightInPixel as integer) as integer

	dim as integer boundingBoxHeightInFontUnit = aFace->bbox.yMax - aFace->bbox.yMin
	' TODO next line should probably be \ not /
	dim as integer designHeightInPixels = ( ( aMaxHeightInPixel * aFace->units_per_EM ) / boundingBoxHeightInFontUnit )
	dim as integer maxHeightInFontUnit = aMaxHeightInPixel shl 6
	FT_Set_Pixel_Sizes( aFace, designHeightInPixels, designHeightInPixels )
	dim as integer currentMaxHeightInFontUnit = FT_MulFix( boundingBoxHeightInFontUnit, aFace->size->metrics.y_scale )

	while currentMaxHeightInFontUnit < maxHeightInFontUnit
		designHeightInPixels += 1
		FT_Set_Pixel_Sizes( aFace, designHeightInPixels, designHeightInPixels )
		currentMaxHeightInFontUnit = FT_MulFix( boundingBoxHeightInFontUnit, aFace->size->metrics.y_scale )
	wend

	while currentMaxHeightInFontUnit > maxHeightInFontUnit
		designHeightInPixels -= 1
		FT_Set_Pixel_Sizes( aFace, designHeightInPixels, designHeightInPixels )
		currentMaxHeightInFontUnit = FT_MulFix( boundingBoxHeightInFontUnit, aFace->size->metrics.y_scale )
	wend

	return designHeightInPixels

end function

#endif

Function font_obj.Load_TTFont( byref font as string, size as integer, lower as integer = 0, upper as integer = 255 ) as integer

   dim as integer ret
#if LIC_FREETYPE

   ret = ttf_init( )
   if ret <> no_error then
      return ret
   endif

   if len( font_ ) then this.destructor( )

   hint = font_ttf
   font_ = getFullFontFilePath( font )
   lower_ = lower
   upper_ = upper

   dim as FT_Face face
   ret = FT_New_Face( ttf_main->library, font_, 0, @face )

   if ret <> 0 then
      ttf_main->external_error = ret
      ttf_main->internal_error = load_face_failed
      return load_face_failed
   EndIf
   
#ifdef LIC_UNICODE 'WIP
   ret = FT_Select_Charmap( face, ft_encoding_unicode )
   if ret <> 0 then
      LIC_DEBUG( "\\Unicode font loading failed" )
   EndIf
#endif

   size = DeriveDesignHeightFromMaxHeight( face, int( size * 2 ) )
   ret = FT_Set_Pixel_Sizes( face, size, 0 )

   if ret <> 0 then
      ttf_main->external_error = ret
      ttf_main->internal_error = set_size_failed
      return set_size_failed
   EndIf

   size_ = face->size->metrics.height shr 6

   for i as integer = lower_ to upper_

      ret = FT_Load_Char( face, i, FT_LOAD_RENDER )
      
      if ret <> 0 then
         ttf_main->external_error = ret
         ttf_main->internal_error = load_char_failed
         LIC_DEBUG( "\\Freetype error loading char: " & i )
         return load_char_failed
      EndIf

      glyph( i ).bLeft = face->Glyph->Bitmap_Left
      glyph( i ).bTop = face->Glyph->Bitmap_Top
      glyph( i ).advance_x = face->Glyph->Advance.x shr 6
      glyph( i ).advance_y = face->Glyph->Advance.y shr 6
      
      if ( face->Glyph->Bitmap.Width = 0 ) or ( face->Glyph->bitmap.pixel_mode <> FT_PIXEL_MODE_GRAY ) then 'space etc
         continue for
      EndIf
      
      glyph( i ).greyscale = ImageCreate( face->Glyph->Bitmap.Width, face->Glyph->Bitmap.Rows, , 8 )

      dim as ubyte ptr fp = face->Glyph->Bitmap.Buffer
      dim as ubyte ptr pp
      dim as int32_t pitch, offset

      ImageInfo( glyph( i ).greyscale, , , , pitch, pp )      
      
      if face->Glyph->Bitmap.pitch = pitch then 'pitch perfect
         memcpy( pp, fp, face->Glyph->Bitmap.pitch * face->Glyph->Bitmap.Rows )
      else
         offset = pitch - face->Glyph->Bitmap.pitch
         for y as integer = 0 to face->Glyph->Bitmap.Rows - 1
      		for x as integer = 0 to face->Glyph->Bitmap.Width - 1
    			   *pp = *fp
       			fp += 1
      			pp += 1
      		next x
      		pp += offset
      	next y
      EndIf
      
   	

   Next i

   FT_Done_Face( face )
   
#endif
   Function = ret

End Function

Function font_obj.DrawString( byval pos_x as integer, byval pos_y as integer, byref s as string, byval colour as uInt32_t ) as integer

   static as ubyte ptr fp
   static as any ptr imgp
   static as uInt32_t rb, g
   static as int32_t a, h, p, char, draw_x, draw_y, pitch, pitchdiff, imgw
   static as integer BPP

   'NULL is at 4 BPP (do not render)
   if BPP <= 4 then
      ScreenControl( fb.GET_SCREEN_DEPTH, BPP )
      if BPP <= 4 then
         return pos_x + imgw
      EndIf
   EndIf
   
   imgw = GetWidth( s )
   if imgw = 0 then
      return pos_x
   else
      imgw += 16
   EndIf
   
   if ( img = 0 ) or ( pimgw < imgw ) or ( pbpp < BPP ) or ( psize < size_ ) then
      
      if img <> 0 then ImageDestroy( img )
      
      img = ImageCreate( imgw, size_ * 2, iif( BPP <> 8, rgb(255, 0, 255), 0 ), BPP )
      assert( img )
      
      pimgw = imgw
      psize = size_
      pbpp = BPP

   else
      
      line img, ( 0, 0 )-( pimgw - 1, psize * 2 - 1 ), iif( pbpp <> 8, rgb(255, 0, 255), 0 ), bf
   
   endif
   
   ImageInfo( img, , , , pitch, origimgp )
   
   draw_y = iif( hint = font_TTF, size_, size_ / 2 )
   draw_x = 8

#if __LIC__
      #define bg Global_IRC.Global_Options.BackGroundColour
#else
      dim as uint32_t bg = 0 
#endif

   for i as integer = 0 to len_hack(s) - 1

      char = s[i]
      if ( char < lower_ ) or ( char > upper_ ) then
         continue for
      EndIf

      with glyph( char )

      draw_x += .bLeft
 	   if hint = font_TTF then
 	      draw_y -= .bTop
 	   else
 	      draw_y += .bTop
 	   EndIf

      if .greyscale <> 0 then

         ImageInfo( .greyscale, , h, , p, fp )
         h -= 1

#if LIC_NUKE_ASM

         if BPP = 8 then

            for y as integer = 0 to h
         		for x as integer = 0 to p - 1
         		   a = *fp
         			if a >= 128 then
                     pset img, ( draw_x + x, draw_y + y ), colour
      			   end if
         			fp += 1
         		next x
         	next y

         else

            for y as integer = 0 to h
      		   for x as integer = 0 to p - 1

         		   a = *fp

         			if a <> 0 then

      				   ' http://www.daniweb.com/code/snippet216791.html
      				   #if 1 'blend background pixel?
      				   'bg = point( draw_x + x, draw_y + y )
         				rb = (((colour and &H00ff00ff) * a) + ((bg and &H00ff00ff) * (&Hff - a))) and &Hff00ff00
         				g =  (((colour and &H0000ff00) * a) + ((bg and &H0000ff00) * (&Hff - a))) and &H00ff0000
         				#else
         				rb = ((colour and &H00ff00ff) * a) and &Hff00ff00
         				g =  ((colour and &H0000ff00) * a) and &H00ff0000
         				#endif

      				   pset img, ( draw_x + x, draw_y + y ), (rb or g) shr 8

      			   end if
         			fp += 1

      		   next x
      	   next y

      	endif

#else '#if LIC_NUKE_ASM

         if BPP = 16 then

            imgp = origimgp + ( draw_y * ( pitch \ 2 ) + draw_x ) * 2
            pitchdiff = ( ( pitch \ 2 ) - p ) * 2

            asm

               mov eax, [h]
               shl eax, 16
               mov ax, [p]

               mov esi, [imgp]
               mov edi, [fp]

               nextpixel16:

               movzx ecx, byte ptr [edi]
               test ecx, ecx

               jz increment16

               push eax

               mov ebx, &hff
               sub ebx, ecx

               mov edx, [colour]
               mov eax, [c2]

               and edx, &H00ff00ff
               imul edx, ecx

               and eax, &H00ff00ff
               imul eax, ebx
               add edx, eax
               and edx, &Hff00ff00

               push edx

               mov edx, [colour]
               mov eax, [c2]

               and edx, &H0000ff00
               imul edx, ecx

               and eax, &H0000ff00
               imul eax, ebx
               add edx, eax
               and edx, &H00ff0000

               pop ebx
               pop eax

               or edx, ebx

               and edx, &b11111000111111001111100000000000
               shr edx, 10
               shl dl, 2
               shr edx, 1
               shl dx, 3
               shr edx, 5

               mov word ptr [esi], dx

               increment16:

               inc edi
               add esi, 2

               dec ax
               jnz nextpixel16

               add esi, [pitchdiff]
               mov ax, [p]

               sub eax, 65536

               jns nextpixel16

            End Asm


         elseif BPP = 32 then

            imgp = origimgp + ( draw_y * ( pitch \ 4 ) + draw_x ) * 4
            pitchdiff = ( ( pitch \ 4 ) - p ) * 4

            asm

               mov eax, [h]
               shl eax, 16
               mov ax, [p]

               mov esi, [fp]
               mov edi, [imgp]

               nextpixel32:

               movzx ecx, byte ptr [esi]
               test ecx, ecx

               jz increment32

               push eax

               mov ebx, &hff
               sub ebx, ecx

               mov edx, [colour]
               mov eax, [c2]

               and edx, &H00ff00ff
               imul edx, ecx

               and eax, &H00ff00ff
               imul eax, ebx
               add edx, eax
               and edx, &Hff00ff00

               push edx

               mov edx, [colour]
               mov eax, [c2]

               and edx, &H0000ff00
               imul edx, ecx

               and eax, &H0000ff00
               imul eax, ebx
               add edx, eax
               and edx, &H00ff0000

               pop ebx
               pop eax

               or edx, ebx
               shr edx, 8

               mov [edi], edx

               increment32:

               add edi, 4
               inc esi
               dec ax
               jnz nextpixel32

               add edi, [pitchdiff]
               mov ax, [p]
               sub eax, 65536

               jns nextpixel32

            End Asm

         Else 'BPP = 8

            imgp = origimgp + ( draw_y * pitch + draw_x )
            pitchdiff = pitch - p

            asm

               mov edx, 128

               mov eax, [h]
               shl eax, 16
               mov ax, [p]

               mov esi, [imgp]
               mov edi, [fp]
               mov ebx, [colour]

               nextpixel8:

               movzx ecx, byte ptr [edi]
               cmp ecx, edx

               jl increment8

               mov byte ptr [esi], bl

               increment8:

               inc edi
               inc esi

               dec ax
               jnz nextpixel8

               add esi, [pitchdiff]
               mov ax, [p]
               sub eax, 65536

               jns nextpixel8

            End Asm

         endif

#endif '#if LIC_NUKE_ASM

      endif

      if hint = font_TTF then
 	      draw_y += .bTop
 	   else
 	      draw_y -= .bTop
 	   EndIf
   	draw_x += .advance_x - .bLeft

   	end with

   next i

   put ( pos_x - 8, pos_y - draw_y \ 2 ), img, trans

   'imagedestroy( img )

	function = draw_x - 8 + pos_x

end function

Function font_obj.GetWidth( byref s as string ) as integer

   dim as integer ret

   for i as integer = 0 to len_hack(s) - 1
      ret += glyph( s[i] ).advance_x ' - glyph( s[i] ).bLeft
   Next

   Function = ret

End Function

Function geterror( ) as string

   dim as string ret

   select case ttf_main->internal_error

   case no_error
      return "No error"
   case init_failed
      ret += "Failed to init FT Library"
   case set_size_failed
      ret += "Failed to set font size"
   case load_face_failed
      ret += "Failed to load font face"
   case load_char_failed
      ret += "Failed to load font character"
   case dll_not_found
      ret += "Failed to load shared library"
   end select

   ret += ". FT Error# :" & ttf_main->external_error

   Function = ret

End Function

Destructor font_obj( )
   for i as integer = 0 to 255
      if glyph( i ).greyscale <> 0 then
         ImageDestroy( glyph( i ).greyscale )
         glyph( i ).greyscale = 0
      EndIf
   Next
   size_ = 0
   font_ = ""
   if img <> 0 then
      ImageDestroy( img )
      img = 0
   EndIf
End Destructor

end namespace
