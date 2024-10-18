
namespace font

#undef no_error
const as integer no_error = 0

enum ttfont_errors
   dll_not_found = 1
   init_failed
   create_font_failed
   set_size_failed
   load_face_failed
   load_char_failed
End Enum

enum font_id
   font_w32
   font_ttf
End Enum

type __ttfont_main__

   as any ptr library
   as any ptr dll

   as integer internal_error, external_error
   as integer init, symbols

End Type

type font_glyph

   as integer btop, bleft

   as integer advance_x, advance_y
   as any ptr greyscale

End Type

type font_obj

   declare Function DrawString( byval as integer, byval as integer, byref s as string, byval colour as uInt32_t ) as integer
   declare Function GetWidth( byref s as string ) as integer

   Declare Function Load_TTFont( byref font as string, size as integer, lower as integer = 0, upper as integer = 255 ) as integer
#ifdef __FB_WIN32__
   Declare Function Load_W32Font( byref font as string, _size_ as integer, lower as integer = 0, upper as integer = 255 ) as integer
#endif

   Declare Destructor

   'private:

   as font_glyph glyph( 255 )

   as string font_
   as integer size_, lower_, upper_
   as integer hint
   
   as integer pimgw, pbpp, psize
   as any ptr img, origimgp

End Type

Declare Function ttf_init( ) as integer
Declare sub ttf_deinit( )
Declare Function geterror( ) as string

end namespace


#if LIC_FREETYPE


#if 0 'static link?
   #include once "freetype2/freetype.bi"

#else

#include once "freetype2/config/ftconfig.bi"
#include once "freetype2/fterrors.bi"
#include once "freetype2/fttypes.bi"

#define FREETYPE_MAJOR 2
#define FREETYPE_MINOR 1
#define FREETYPE_PATCH 9

type FT_Glyph_Metrics_
	width as FT_Pos
	height as FT_Pos
	horiBearingX as FT_Pos
	horiBearingY as FT_Pos
	horiAdvance as FT_Pos
	vertBearingX as FT_Pos
	vertBearingY as FT_Pos
	vertAdvance as FT_Pos
end type

type FT_Glyph_Metrics as FT_Glyph_Metrics_

type FT_Bitmap_Size_
	height as FT_Short
	width as FT_Short
	size as FT_Pos
	x_ppem as FT_Pos
	y_ppem as FT_Pos
end type

type FT_Bitmap_Size as FT_Bitmap_Size_
type FT_Library as FT_LibraryRec_ ptr
type FT_Module as FT_ModuleRec_ ptr
type FT_Driver as FT_DriverRec_ ptr
type FT_Renderer as FT_RendererRec_ ptr
type FT_Face as FT_FaceRec_ ptr
type FT_Size as FT_SizeRec_ ptr
type FT_GlyphSlot as FT_GlyphSlotRec_ ptr

#define FT_ENC_TAG( value, a, b, c, d ) _
          value = ( ( cuint(a) shl 24 ) or ( cuint(b) shl 16 ) or ( cuint(c) shl  8 ) or cuint(d) )

enum  FT_Encoding_
    FT_ENC_TAG( FT_ENCODING_NONE, 0, 0, 0, 0 )

    FT_ENC_TAG( FT_ENCODING_MS_SYMBOL,  asc("s"), asc("y"), asc("m"), asc("b") )
    FT_ENC_TAG( FT_ENCODING_UNICODE,    asc("u"), asc("n"), asc("i"), asc("c") )

    FT_ENC_TAG( FT_ENCODING_SJIS,    asc("s"), asc("j"), asc("i"), asc("s") )
    FT_ENC_TAG( FT_ENCODING_GB2312,  asc("g"), asc("b"), asc(" "), asc(" ") )
    FT_ENC_TAG( FT_ENCODING_BIG5,    asc("b"), asc("i"), asc("g"), asc("5") )
    FT_ENC_TAG( FT_ENCODING_WANSUNG, asc("w"), asc("a"), asc("n"), asc("s") )
    FT_ENC_TAG( FT_ENCODING_JOHAB,   asc("j"), asc("o"), asc("h"), asc("a") )

    FT_ENCODING_MS_SJIS    = FT_ENCODING_SJIS
    FT_ENCODING_MS_GB2312  = FT_ENCODING_GB2312
    FT_ENCODING_MS_BIG5    = FT_ENCODING_BIG5
    FT_ENCODING_MS_WANSUNG = FT_ENCODING_WANSUNG
    FT_ENCODING_MS_JOHAB   = FT_ENCODING_JOHAB

    FT_ENC_TAG( FT_ENCODING_ADOBE_STANDARD, asc("A"), asc("D"), asc("O"), asc("B") )
    FT_ENC_TAG( FT_ENCODING_ADOBE_EXPERT,   asc("A"), asc("D"), asc("B"), asc("E") )
    FT_ENC_TAG( FT_ENCODING_ADOBE_CUSTOM,   asc("A"), asc("D"), asc("B"), asc("C") )
    FT_ENC_TAG( FT_ENCODING_ADOBE_LATIN_1,  asc("l"), asc("a"), asc("t"), asc("1") )

    FT_ENC_TAG( FT_ENCODING_OLD_LATIN_2, asc("l"), asc("a"), asc("t"), asc("2") )

    FT_ENC_TAG( FT_ENCODING_APPLE_ROMAN, asc("a"), asc("r"), asc("m"), asc("n") )
end enum

type FT_Encoding as FT_Encoding_

type FT_CharMap as FT_CharMapRec_ ptr

type FT_CharMapRec_
	face as FT_Face
	encoding as FT_Encoding
	platform_id as FT_UShort
	encoding_id as FT_UShort
end type

type FT_CharMapRec as FT_CharMapRec_
type FT_Face_Internal as FT_Face_InternalRec_ ptr

type FT_FaceRec_
	num_faces as FT_Long
	face_index as FT_Long
	face_flags as FT_Long
	style_flags as FT_Long
	num_glyphs as FT_Long
	family_name as FT_String ptr
	style_name as FT_String ptr
	num_fixed_sizes as FT_Int
	available_sizes as FT_Bitmap_Size ptr
	num_charmaps as FT_Int
	charmaps as FT_CharMap ptr
	generic as FT_Generic
	bbox as FT_BBox
	units_per_EM as FT_UShort
	ascender as FT_Short
	descender as FT_Short
	height as FT_Short
	max_advance_width as FT_Short
	max_advance_height as FT_Short
	underline_position as FT_Short
	underline_thickness as FT_Short
	glyph as FT_GlyphSlot
	size as FT_Size
	charmap as FT_CharMap
	driver as FT_Driver
	memory as FT_Memory
	stream as FT_Stream
	sizes_list as FT_ListRec
	autohint as FT_Generic
	extensions as any ptr
	internal as FT_Face_Internal
end type

type FT_FaceRec as FT_FaceRec_

#define FT_FACE_FLAG_SCALABLE (1L shl 0)
#define FT_FACE_FLAG_FIXED_SIZES (1L shl 1)
#define FT_FACE_FLAG_FIXED_WIDTH (1L shl 2)
#define FT_FACE_FLAG_SFNT (1L shl 3)
#define FT_FACE_FLAG_HORIZONTAL (1L shl 4)
#define FT_FACE_FLAG_VERTICAL (1L shl 5)
#define FT_FACE_FLAG_KERNING (1L shl 6)
#define FT_FACE_FLAG_FAST_GLYPHS (1L shl 7)
#define FT_FACE_FLAG_MULTIPLE_MASTERS (1L shl 8)
#define FT_FACE_FLAG_GLYPH_NAMES (1L shl 9)
#define FT_FACE_FLAG_EXTERNAL_STREAM (1L shl 10)
#define FT_STYLE_FLAG_ITALIC (1 shl 0)
#define FT_STYLE_FLAG_BOLD (1 shl 1)

type FT_Size_Internal as FT_Size_InternalRec_ ptr

type FT_Size_Metrics_
	x_ppem as FT_UShort
	y_ppem as FT_UShort
	x_scale as FT_Fixed
	y_scale as FT_Fixed
	ascender as FT_Pos
	descender as FT_Pos
	height as FT_Pos
	max_advance as FT_Pos
end type

type FT_Size_Metrics as FT_Size_Metrics_

type FT_SizeRec_
	face as FT_Face
	generic as FT_Generic
	metrics as FT_Size_Metrics
	internal as FT_Size_Internal
end type

type FT_SizeRec as FT_SizeRec_
type FT_SubGlyph as FT_SubGlyphRec_ ptr
type FT_Slot_Internal as FT_Slot_InternalRec_ ptr

type FT_GlyphSlotRec_
	library as FT_Library
	face as FT_Face
	next as FT_GlyphSlot
	reserved as FT_UInt
	generic as FT_Generic
	metrics as FT_Glyph_Metrics
	linearHoriAdvance as FT_Fixed
	linearVertAdvance as FT_Fixed
	advance as FT_Vector
	format as FT_Glyph_Format
	bitmap as FT_Bitmap
	bitmap_left as FT_Int
	bitmap_top as FT_Int
	outline as FT_Outline
	num_subglyphs as FT_UInt
	subglyphs as FT_SubGlyph
	control_data as any ptr
	control_len as integer
	lsb_delta as FT_Pos
	rsb_delta as FT_Pos
	other as any ptr
	internal as FT_Slot_Internal
end type

type FT_GlyphSlotRec as FT_GlyphSlotRec_

#define FT_OPEN_MEMORY &h1
#define FT_OPEN_STREAM &h2
#define FT_OPEN_PATHNAME &h4
#define FT_OPEN_DRIVER &h8
#define FT_OPEN_PARAMS &h10
#define ft_open_memory &h1
#define ft_open_stream &h2
#define ft_open_pathname &h4
#define ft_open_driver &h8
#define ft_open_params &h10

type FT_Parameter_
	tag as FT_ULong
	data as FT_Pointer
end type

type FT_Parameter as FT_Parameter_

type FT_Open_Args_
	flags as FT_UInt
	memory_base as FT_Byte ptr
	memory_size as FT_Long
	pathname as FT_String ptr
	stream as FT_Stream
	driver as FT_Module
	num_params as FT_Int
	params as FT_Parameter ptr
end type

type FT_Open_Args as FT_Open_Args_

#define FT_LOAD_DEFAULT &h0
#define FT_LOAD_NO_SCALE &h1
#define FT_LOAD_NO_HINTING &h2
#define FT_LOAD_RENDER &h4
#define FT_LOAD_NO_BITMAP &h8
#define FT_LOAD_VERTICAL_LAYOUT &h10
#define FT_LOAD_FORCE_AUTOHINT &h20
#define FT_LOAD_CROP_BITMAP &h40
#define FT_LOAD_PEDANTIC &h80
#define FT_LOAD_IGNORE_GLOBAL_ADVANCE_WIDTH &h200
#define FT_LOAD_NO_RECURSE &h400
#define FT_LOAD_IGNORE_TRANSFORM &h800
#define FT_LOAD_MONOCHROME &h1000
#define FT_LOAD_LINEAR_DESIGN &h2000
#define FT_LOAD_SBITS_ONLY &h4000
#define FT_LOAD_NO_AUTOHINT &h8000U

#define FT_LOAD_TARGET_(x) (cast(FT_Int32, (x) and 15) shl 16)
#define FT_LOAD_TARGET_LCD FT_LOAD_TARGET_(FT_RENDER_MODE_LCD)

enum FT_Render_Mode_
	FT_RENDER_MODE_NORMAL = 0
	FT_RENDER_MODE_LIGHT
	FT_RENDER_MODE_MONO
	FT_RENDER_MODE_LCD
	FT_RENDER_MODE_LCD_V
	FT_RENDER_MODE_MAX
end enum

type FT_Render_Mode as FT_Render_Mode_

enum FT_Kerning_Mode_
	FT_KERNING_DEFAULT = 0
	FT_KERNING_UNFITTED
	FT_KERNING_UNSCALED
end enum

type FT_Kerning_Mode as FT_Kerning_Mode_
#endif

#endif