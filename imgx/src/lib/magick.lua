local VERSION = "1.0.0"
local ffi = require("ffi")
local bit = require("bit")
ffi.cdef([[  

  typedef void MagickWand;
  typedef void PixelWand;
  typedef void DrawingWand;

  typedef int MagickBooleanType;
  typedef int ExceptionType;
  typedef int ssize_t;
  typedef int CompositeOperator;
  typedef int GravityType;

  typedef enum {
    UndefinedPixel,
    CharPixel,
    DoublePixel,
    FloatPixel,
    IntegerPixel,
    LongPixel,
    QuantumPixel,
    ShortPixel
  } StorageType;

  typedef enum {

    UndefinedChannel,
    RedChannel = 0x0001,
    GrayChannel = 0x0001,
    CyanChannel = 0x0001,
    GreenChannel = 0x0002,
    MagentaChannel = 0x0002,
    BlueChannel = 0x0004,
    YellowChannel = 0x0004,
    AlphaChannel = 0x0008,
    OpacityChannel = 0x0008,
    MatteChannel = 0x0008,     /* deprecated */
    BlackChannel = 0x0020,
    IndexChannel = 0x0020,
    CompositeChannels = 0x002F,
    //AllChannels = ~0UL,
    /* Special purpose channel types. */
    TrueAlphaChannel = 0x0040, /* extract actual alpha channel from opacity */
    RGBChannels = 0x0080,      /* set alpha from  grayscale mask in RGB */
    GrayChannels = 0x0080,
    SyncChannels = 0x0100,     /* channels should be modified equally */
    //DefaultChannels = ((AllChannels | SyncChannels) &~ OpacityChannel)
  } ChannelType;

  typedef enum {

    UndefinedEvaluateOperator,
    AddEvaluateOperator,
    AndEvaluateOperator,
    DivideEvaluateOperator,
    LeftShiftEvaluateOperator,
    MaxEvaluateOperator,
    MinEvaluateOperator,
    MultiplyEvaluateOperator,
    OrEvaluateOperator,
    RightShiftEvaluateOperator,
    SetEvaluateOperator,
    SubtractEvaluateOperator,
    XorEvaluateOperator,
    PowEvaluateOperator,
    LogEvaluateOperator,
    ThresholdEvaluateOperator,
    ThresholdBlackEvaluateOperator,
    ThresholdWhiteEvaluateOperator,
    GaussianNoiseEvaluateOperator,
    ImpulseNoiseEvaluateOperator,
    LaplacianNoiseEvaluateOperator,
    MultiplicativeNoiseEvaluateOperator,
    PoissonNoiseEvaluateOperator,
    UniformNoiseEvaluateOperator,
    CosineEvaluateOperator,
    SineEvaluateOperator,
    AddModulusEvaluateOperator,
    MeanEvaluateOperator,
    AbsEvaluateOperator,
    ExponentialEvaluateOperator,
    MedianEvaluateOperator
  } MagickEvaluateOperator;

  typedef enum {
	UndefinedStretch,
	NormalStretch,
	UltraCondensedStretch,
	ExtraCondensedStretch,
	CondensedStretch,
	SemiCondensedStretch,
	SemiExpandedStretch,
	ExpandedStretch,
	ExtraExpandedStretch,
	UltraExpandedStretch,
	AnyStretch
  } StretchType;

  typedef enum {
	UndefinedStyle,
	NormalStyle,
	ItalicStyle,
	ObliqueStyle,
	AnyStyle
  } StyleType;

  typedef enum {
	UndefinedAlign,
	LeftAlign,
	CenterAlign,
	RightAlign
  } AlignType;

  typedef enum {
	UndefinedDecoration,
	NoDecoration,
	UnderlineDecoration,
	OverlineDecoration,
	LineThroughDecoration
  } DecorationType;

  typedef enum {
	UndefinedDirection,
	RightToLeftDirection,
	LeftToRightDirection
  } DirectionType;

  typedef enum {
    UndefinedType,
    BilevelType,
    GrayscaleType,
    GrayscaleMatteType,
    PaletteType,
    PaletteMatteType,
    TrueColorType,
    TrueColorMatteType,
    ColorSeparationType,
    ColorSeparationMatteType,
    OptimizeType,
    PaletteBilevelMatteType
  } ImageType;

  DrawingWand *NewDrawingWand(void);
  DrawingWand *DestroyDrawingWand(DrawingWand *wand);
  void DrawSetFillColor(DrawingWand *wand, const PixelWand *fill_wand);
  void DrawSetStrokeColor(DrawingWand *wand, const PixelWand *stroke_wand);
  void DrawSetStrokeAntialias(DrawingWand *wand, const MagickBooleanType stroke_antialias);
  void DrawRoundRectangle(DrawingWand *wand, double x1, double y1, double x2,double y2, double rx, double ry);
  void DrawRectangle(DrawingWand *wand, const double x1, const double y1, const double x2, const double y2);
  void DrawEllipse(DrawingWand *wand, const double ox, const double oy, const double rx, const double ry, const double start, const double end);
  void DrawSetStrokeWidth(DrawingWand *wand, const double stroke_width);

  void PixelSetOpacity(PixelWand *wand, const double opacity);  
  double PixelGetRed(const PixelWand *wand);
  double PixelGetGreen(const PixelWand *wand);
  double PixelGetBlue(const PixelWand *wand);
  double PixelGetBlack(const PixelWand *wand);
  double PixelGetYellow(const PixelWand *wand);
  double PixelGetAlpha(const PixelWand *wand);

  MagickBooleanType MagickNewImage(MagickWand *wand, const size_t columns, const size_t rows, const PixelWand *background);

  MagickBooleanType MagickDrawImage(MagickWand *wand, const DrawingWand *drawing_wand);

  MagickBooleanType MagickSetImageBackgroundColor(MagickWand *wand, const PixelWand *background);

  MagickBooleanType MagickEvaluateImageChannel(MagickWand *wand, const ChannelType channel, const MagickEvaluateOperator op, const double value);

  MagickBooleanType MagickContrastImage(MagickWand *wand, const MagickBooleanType sharpen);

  MagickBooleanType MagickEnhanceImage(MagickWand *wand);
  MagickBooleanType MagickCharcoalImage(MagickWand *wand, const double radius,const double sigma);

  void MagickWandGenesis();
  void MagickSetFirstIterator(MagickWand *wand);
  MagickWand* NewMagickWand();
  MagickWand* DestroyMagickWand(MagickWand*);
  MagickBooleanType MagickReadImage(MagickWand*, const char*);
  MagickBooleanType MagickReadImageBlob(MagickWand*, const void*, const size_t);
  MagickBooleanType MagickConstituteImage(MagickWand *wand, 
	const size_t columns, const size_t rows, const char *map,
    const StorageType storage, void *pixels);
  MagickBooleanType MagickExportImagePixels(MagickWand *wand,
    const ssize_t x, const ssize_t y, const size_t columns,
    const size_t rows, const char *map, const StorageType storage,
    void *pixels);

  const char* MagickGetException(const MagickWand*, ExceptionType*);

  int MagickGetImageWidth(MagickWand*);
  int MagickGetImageHeight(MagickWand*);

  MagickBooleanType MagickAddImage(MagickWand*, const MagickWand*);

  MagickBooleanType MagickAdaptiveResizeImage(MagickWand*, const size_t, const size_t);

  MagickBooleanType MagickWriteImage(MagickWand*, const char*);

  unsigned char* MagickGetImageBlob(MagickWand*, size_t*);

  void* MagickRelinquishMemory(void*);

  MagickBooleanType MagickCropImage(MagickWand*, const size_t, const size_t, const ssize_t, const ssize_t);

  MagickBooleanType MagickBlurImage(MagickWand*, const double, const double);
  MagickBooleanType MagickAdaptiveBlurImage(MagickWand *wand, const double radius, const double sigma);
  MagickBooleanType MagickGaussianBlurImage(MagickWand *wand, const double radius, const double sigma);

  MagickBooleanType MagickNegateImage(MagickWand *wand, const MagickBooleanType gray);
  MagickBooleanType MagickSetImageType(MagickWand *wand, const ImageType image_type);
  ImageType MagickGetImageType(MagickWand *wand);

  MagickBooleanType MagickOilPaintImage(MagickWand *wand, const double radius);
  MagickBooleanType MagickSepiaToneImage(MagickWand *wand, const double threshold);

  MagickBooleanType MagickSetImageFormat(MagickWand* wand, const char* format);
  const char* MagickGetImageFormat(MagickWand* wand);

  size_t MagickGetImageCompressionQuality(MagickWand * wand);
  MagickBooleanType MagickSetImageCompressionQuality(MagickWand *wand,
    const size_t quality);

  MagickBooleanType MagickSharpenImage(MagickWand *wand,
    const double radius, const double sigma);

  MagickBooleanType MagickAdaptiveSharpenImage(MagickWand *wand,
    const double radius, const double sigma);

  MagickBooleanType MagickScaleImage(MagickWand *wand,
    const size_t columns,const size_t rows);

  MagickBooleanType MagickSetOption(MagickWand *,const char *,const char *);
    char* MagickGetOption(MagickWand *,const char *);

  MagickBooleanType MagickCompositeImage(MagickWand *wand,
    const MagickWand *source_wand,const CompositeOperator compose,
    const ssize_t x,const ssize_t y);

  GravityType MagickGetImageGravity(MagickWand *wand);
  MagickBooleanType MagickSetImageGravity(MagickWand *wand,
    const GravityType gravity);

  MagickBooleanType MagickStripImage(MagickWand *wand);

  MagickBooleanType MagickGetImagePixelColor(MagickWand *wand,
    const ssize_t x,const ssize_t y,PixelWand *color);

  MagickBooleanType MagickRotateImage(MagickWand *wand,
    const PixelWand *background,const double degrees);

  MagickBooleanType MagickEdgeImage(MagickWand *wand,const double radius);

  MagickBooleanType MagickShadowImage(MagickWand *wand,const double alpha,
    const double sigma,const ssize_t x,const ssize_t y);

  MagickBooleanType MagickBorderImage(MagickWand *wand,
	const PixelWand *bordercolor,
	const size_t width,
    const size_t height);
  
  MagickBooleanType MagickFrameImage(MagickWand *wand,
    const PixelWand *matte_color,const size_t width,
    const size_t height,const ssize_t inner_bevel,
    const ssize_t outer_bevel);

  MagickBooleanType MagickAutoOrientImage(MagickWand *image);

  PixelWand *NewPixelWand(void);
  MagickBooleanType PixelSetColor(PixelWand *wand,const char *color);
  PixelWand *DestroyPixelWand(PixelWand *);

  double PixelGetAlpha(const PixelWand *);
  double PixelGetRed(const PixelWand *);
  double PixelGetGreen(const PixelWand *);
  double PixelGetBlue(const PixelWand *);

  MagickBooleanType MagickFlopImage(MagickWand *wand);
  MagickBooleanType MagickFlipImage(MagickWand *wand);

  MagickBooleanType MagickSetImageOpacity(MagickWand *wand, const double alpha);

  MagickBooleanType DrawSetFontResolution(DrawingWand *wand, const double x_resolution, const double y_resolution);
  MagickBooleanType DrawSetFont(DrawingWand *wand, const char *font_name);
  MagickBooleanType DrawSetFontFamily(DrawingWand *wand, const char *font_family);
  void DrawSetFontSize(DrawingWand *wand, const double pointsize);
  void DrawSetFontStretch(DrawingWand *wand, const StretchType font_stretch);
  void DrawSetFontStyle(DrawingWand *wand, const StyleType style);
  void DrawSetFontWeight(DrawingWand *wand, const size_t font_weight);
  void DrawSetGravity(DrawingWand *wand, const GravityType gravity);
  void DrawSetFillOpacity(DrawingWand *wand, const double fill_opacity);

  MagickBooleanType MagickSetImageMatte(MagickWand *wand, const MagickBooleanType);
  MagickBooleanType MagickSetImageMatteColor(MagickWand *wand, const PixelWand *matte);
  MagickBooleanType MagickAnnotateImage(MagickWand *wand, const DrawingWand *drawing_wand, const double x, const double y, const double angle, const char *text);
  MagickBooleanType MagickBrightnessContrastImage(MagickWand *wand, const double brightness, const double contrast);

  void DrawSetTextAlignment(DrawingWand *wand, const AlignType alignment);
  void DrawSetTextAntialias(DrawingWand *wand, const MagickBooleanType text_antialias);
  void DrawSetTextDecoration(DrawingWand *wand, const DecorationType decoration);
  void DrawSetTextDirection(DrawingWand *wand, const DirectionType direction);
  void DrawSetTextEncoding(DrawingWand *wand, const char *encoding);
  void DrawSetTextKerning(DrawingWand *wand, const double kerning);
  void DrawSetTextInterlineSpacing(DrawingWand *wand, const double interline_spacing);
  void DrawSetTextInterwordSpacing(DrawingWand *wand, const double interword_spacing);
  void DrawSetTextUnderColor(DrawingWand *wand, const PixelWand *under_wand);

  MagickBooleanType MagickTrimImage(MagickWand *wand, const double fuzz);

  double *MagickQueryFontMetrics(MagickWand *wand, const DrawingWand *drawing_wand,const char *text);
  double *MagickQueryMultilineFontMetrics(MagickWand *wand, const DrawingWand *drawing_wand,const char *text);

]])
local get_flags
get_flags = function()
  local proc = io.popen("MagickWand-config --cflags --libs", "r")
  local flags = proc:read("*a")
  get_flags = function()
    return flags
  end
  proc:close()
  return flags
end
local get_filters
get_filters = function()
  local fname = "magick/resample.h"
  local prefixes = {
    "/usr/include/ImageMagick",
    "/usr/local/include/ImageMagick",
    function()
      return get_flags():match("-I([^%s]+)")
    end
  }
  for _index_0 = 1, #prefixes do
    local _continue_0 = false
    repeat
      local p = prefixes[_index_0]
      if "function" == type(p) then
        p = p()
        if not (p) then
          _continue_0 = true
          break
        end
      end
      local full = tostring(p) .. "/" .. tostring(fname)
      do
        local f = io.open(full)
        if f then
          local content
          do
            local _with_0 = f:read("*a")
            f:close()
            content = _with_0
          end
          local filter_types = content:match("(typedef enum.-FilterTypes;)")
          if filter_types then
            ffi.cdef(filter_types)
            return true
          end
        end
      end
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
  return false
end
local try_to_load
try_to_load = function(...)
  local out
  local _list_0 = {
    ...
  }
  for _index_0 = 1, #_list_0 do
    local _continue_0 = false
    repeat
      local name = _list_0[_index_0]
      if "function" == type(name) then
        name = name()
        if not (name) then
          _continue_0 = true
          break
        end
      end
      if pcall(function()
        out = ffi.load(name)
      end) then
        return out
      end
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
  return error("Failed to load ImageMagick (" .. tostring(...) .. ")")
end
local lib = try_to_load("MagickWand", function()
  local lname = get_flags():match("-l(MagickWand[^%s]*)")
  local suffix
  if ffi.os == "OSX" then
    suffix = ".dylib"
  elseif ffi.os == "Windows" then
    suffix = ".dll"
  else
    suffix = ".so"
  end
  return lname and "lib" .. lname .. suffix
end)
local can_resize
if get_filters() then
  ffi.cdef([[    MagickBooleanType MagickResizeImage(MagickWand*,
      const size_t, const size_t,
      const FilterTypes, const double);
  ]])
  can_resize = true
end
local storage_type_op = {
  ["UndefinedPixel"] = 0,
  ["CharPixel"] = 1,
  ["DoublePixel"] = 2,
  ["FloatPixel"] = 3,
  ["IntegerPixel"] = 4,
  ["LongPixel"] = 5,
  ["QuantumPixel"] = 6,
  ["ShortPixel"] = 7,
}

local orientation_op = {
  ["UndefinedOrientation"] = 0,
  ["TopLeftOrientation"] = 1,
  ["TopRightOrientation"] = 2,
  ["BottomRightOrientation"] = 3,
  ["BottomLeftOrientation"] = 4,
  ["LeftTopOrientation"] = 5,
  ["RightTopOrientation"] = 6,
  ["RightBottomOrientation"] = 7,
  ["LeftBottomOrientation"] = 8,
}

local composite_op = {
  ["UndefinedCompositeOp"] = 0,
  ["NoCompositeOp"] = 1,
  ["ModulusAddCompositeOp"] = 2,
  ["AtopCompositeOp"] = 3,
  ["BlendCompositeOp"] = 4,
  ["BumpmapCompositeOp"] = 5,
  ["ChangeMaskCompositeOp"] = 6,
  ["ClearCompositeOp"] = 7,
  ["ColorBurnCompositeOp"] = 8,
  ["ColorDodgeCompositeOp"] = 9,
  ["ColorizeCompositeOp"] = 10,
  ["CopyBlackCompositeOp"] = 11,
  ["CopyBlueCompositeOp"] = 12,
  ["CopyCompositeOp"] = 13,
  ["CopyCyanCompositeOp"] = 14,
  ["CopyGreenCompositeOp"] = 15,
  ["CopyMagentaCompositeOp"] = 16,
  ["CopyOpacityCompositeOp"] = 17,
  ["CopyRedCompositeOp"] = 18,
  ["CopyYellowCompositeOp"] = 19,
  ["DarkenCompositeOp"] = 20,
  ["DstAtopCompositeOp"] = 21,
  ["DstCompositeOp"] = 22,
  ["DstInCompositeOp"] = 23,
  ["DstOutCompositeOp"] = 24,
  ["DstOverCompositeOp"] = 25,
  ["DifferenceCompositeOp"] = 26,
  ["DisplaceCompositeOp"] = 27,
  ["DissolveCompositeOp"] = 28,
  ["ExclusionCompositeOp"] = 29,
  ["HardLightCompositeOp"] = 30,
  ["HueCompositeOp"] = 31,
  ["InCompositeOp"] = 32,
  ["LightenCompositeOp"] = 33,
  ["LinearLightCompositeOp"] = 34,
  ["LuminizeCompositeOp"] = 35,
  ["MinusDstCompositeOp"] = 36,
  ["ModulateCompositeOp"] = 37,
  ["MultiplyCompositeOp"] = 38,
  ["OutCompositeOp"] = 39,
  ["OverCompositeOp"] = 40,
  ["OverlayCompositeOp"] = 41,
  ["PlusCompositeOp"] = 42,
  ["ReplaceCompositeOp"] = 43,
  ["SaturateCompositeOp"] = 44,
  ["ScreenCompositeOp"] = 45,
  ["SoftLightCompositeOp"] = 46,
  ["SrcAtopCompositeOp"] = 47,
  ["SrcCompositeOp"] = 48,
  ["SrcInCompositeOp"] = 49,
  ["SrcOutCompositeOp"] = 50,
  ["SrcOverCompositeOp"] = 51,
  ["ModulusSubtractCompositeOp"] = 52,
  ["ThresholdCompositeOp"] = 53,
  ["XorCompositeOp"] = 54,
  ["DivideDstCompositeOp"] = 55,
  ["DistortCompositeOp"] = 56,
  ["BlurCompositeOp"] = 57,
  ["PegtopLightCompositeOp"] = 58,
  ["VividLightCompositeOp"] = 59,
  ["PinLightCompositeOp"] = 60,
  ["LinearDodgeCompositeOp"] = 61,
  ["LinearBurnCompositeOp"] = 62,
  ["MathematicsCompositeOp"] = 63,
  ["DivideSrcCompositeOp"] = 64,
  ["MinusSrcCompositeOp"] = 65,
  ["DarkenIntensityCompositeOp"] = 66,
  ["LightenIntensityCompositeOp"] = 67
}
local gravity_str = {
  "ForgetGravity",
  "NorthWestGravity",
  "NorthGravity",
  "NorthEastGravity",
  "WestGravity",
  "CenterGravity",
  "EastGravity",
  "SouthWestGravity",
  "SouthGravity",
  "SouthEastGravity",
  "StaticGravity"
}
local font_name_op = {
	['华文黑体'] = 'src/lib/data/fonts/华文黑体.ttf',
	['娃娃体-简'] = 'src/lib/data/fonts/WawaSC-Regular.otf',
	['报隶-简'] = 'src/lib/data/fonts/Baoli.ttc',
	['冬青黑体简体中文-W6'] = 'src/lib/data/fonts/Hiragino Sans GB W6.otf',
	['冬青黑体简体中文-W3'] = 'src/lib/data/fonts/Hiragino Sans GB W3.otf',
	['黑体-简-细'] = 'src/lib/data/fonts/STHeiti Light.ttc',
	['黑体-简-中'] = 'src/lib/data/fonts/STHeiti Medium.ttc',
	['黑体-简'] = 'src/lib/data/fonts/STHeiti Medium.ttc',
	['华文仿宋'] = 'src/lib/data/fonts/华文仿宋.ttf',
	['华文楷体'] = 'src/lib/data/fonts/Kaiti.ttc',
	['华文宋体'] = 'src/lib/data/fonts/Songti.ttc',
	['楷体-简'] = 'src/lib/data/fonts/Kaiti.ttc',
	['兰亭黑-简'] = 'src/lib/data/fonts/Lantinghei.ttc',
	['隶变-简'] = 'src/lib/data/fonts/Libian.ttc',
	['翩翩体-简'] = 'src/lib/data/fonts/Hanzipen.ttc',
	['手札体-简'] = 'src/lib/data/fonts/Hannotate.ttc',
	['宋体'] = 'src/lib/data/fonts/Microsoft/SimSun.ttf',
	['宋体-简'] = 'src/lib/data/fonts/Songti.ttc',
	['魏碑-简'] = 'src/lib/data/fonts//WeibeiSC-Bold.otf',
	['行楷-简'] = 'src/lib/data/fonts/Xingkai.ttc',
	['雅痞-简'] = 'src/lib/data/fonts/YuppySC-Regular.otf',
	['圆体-简'] = 'src/lib/data/fonts/Yuanti.ttc',
	['Adobe 仿宋 Std'] = 'src/lib/data/fonts/AdobeFangsongStd-Regular.otf',
	['Adobe 黑体 Std'] = 'src/lib/data/fonts/AdobeHeitiStd-Regular.otf',
	['Adobe 楷体 Std'] = 'src/lib/data/fonts/AdobeKaitiStd-Regular.otf',
	['Adobe 宋体 Std'] = 'src/lib/data/fonts/AdobeSongStd-Light.otf',
}
local gravity_type = { }
for i, t in ipairs(gravity_str) do
  gravity_type[t] = i
end
lib.MagickWandGenesis()
local filter
filter = function(name)
  return lib[name .. "Filter"]
end
local get_exception
get_exception = function(wand)
  local etype = ffi.new("ExceptionType[1]", 0)
  local msg = ffi.string(lib.MagickGetException(wand, etype))
  return etype[0], msg
end
local handle_result
handle_result = function(img_or_wand, status)
  local wand = img_or_wand.wand or img_or_wand
  if status == 0 then
    local code, msg = get_exception(wand)
    return nil, msg, code
  else
    return true
  end
end
local Image
do
  local _base_0 = {
    get_width = function(self)
      return lib.MagickGetImageWidth(self.wand)
    end,
    get_height = function(self)
      return lib.MagickGetImageHeight(self.wand)
    end,
    get_format = function(self)
      return ffi.string(lib.MagickGetImageFormat(self.wand)):lower()
    end,
    set_format = function(self, format)
      return handle_result(self, lib.MagickSetImageFormat(self.wand, format))
    end,
    get_quality = function(self)
      return lib.MagickGetImageCompressionQuality(self.wand)
    end,
    set_quality = function(self, quality)
      return handle_result(self, lib.MagickSetImageCompressionQuality(self.wand, quality))
    end,
    get_option = function(self, magick, key)
      local format = magick .. ":" .. key
      return ffi.string(lib.MagickGetOption(self.wand, format))
    end,
    set_option = function(self, magick, key, value)
      local format = magick .. ":" .. key
      return handle_result(self, lib.MagickSetOption(self.wand, format, value))
    end,
    get_gravity = function(self)
      return gravity_str[lib.MagickGetImageGravity(self.wand)]
    end,
    set_gravity = function(self, typestr)
      local type = gravity_type[typestr]
      if not (type) then
        error("invalid gravity type")
      end
      return lib.MagickSetImageGravity(self.wand, type)
    end,
	set_first_iterator = function(self)
		return lib.MagickSetFirstIterator(self.wand)
	end,
    strip = function(self)
      return lib.MagickStripImage(self.wand)
    end,
    _keep_aspect = function(self, w, h)
      if not w and h then
        return self:get_width() / self:get_height() * h, h
      elseif w and not h then
        return w, self:get_height() / self:get_width() * w
      else
        return w, h
      end
    end,
    clone = function(self)
      local wand = lib.NewMagickWand()
      lib.MagickAddImage(wand, self.wand)
      return Image(wand, self.path)
    end,
    resize = function(self, w, h, f, blur)
      if f == nil then
        f = "Lanczos2"
      end
      if blur == nil then
        blur = 1.0
      end
      if not (can_resize) then
        error("Failed to load filter list, can't resize")
      end
      w, h = self:_keep_aspect(w, h)
      return handle_result(self, lib.MagickResizeImage(self.wand, w, h, filter(f), blur))
    end,
    rotate = function(self, degrees, background)
      if background == nil then
        background = "rgba(255,255,255,0)"
      end
      local pixelWand = lib.NewPixelWand();
      lib.PixelSetColor(pixelWand, background)
      local hr = handle_result(self, lib.MagickRotateImage(self.wand, pixelWand, degrees))
	  lib.DestroyPixelWand(pixelWand)
	  return hr
    end,
    edge = function(self, radius)
      return handle_result(self, lib.MagickEdgeImage(self.wand, radius))
    end,
    shadow = function(self, alpha, sigma, x, y)
      return handle_result(self, lib.MagickShadowImage(self.wand, alpha, sigma, x, y))
    end,
    adaptive_resize = function(self, w, h)
      w, h = self:_keep_aspect(w, h)
      return handle_result(self, lib.MagickAdaptiveResizeImage(self.wand, w, h))
    end,
    scale = function(self, w, h)
      w, h = self:_keep_aspect(w, h)
      return handle_result(self, lib.MagickScaleImage(self.wand, w, h))
    end,
    crop = function(self, w, h, x, y)
      if x == nil then
        x = 0
      end
      if y == nil then
        y = 0
      end
      return handle_result(self, lib.MagickCropImage(self.wand, w, h, x, y))
    end,
    blur = function(self, sigma, radius)
      if radius == nil then
        radius = 0
      end
      return handle_result(self, lib.MagickBlurImage(self.wand, radius, sigma))
      --return handle_result(self, lib.MagickGaussianBlurImage(self.wand, radius, sigma))
      --return handle_result(self, lib.MagickAdaptiveBlurImage(self.wand, radius, sigma))
    end,
	pixelate = function(self, pixels)
		if (not pixels) or pixels <= 1 then
			return
		end
		local o_w = self:get_width()
		local o_h = self:get_height()
		local pixels_w_max = o_w / 5
		local pixels_h_max = o_h / 5
		if pixels > pixels_w_max then
			pixels = pixels_w_max
		end
		if pixels > pixels_h_max then
			pixels = pixels_h_max
		end
		local s_w = o_w / pixels
		local s_h = o_h / pixels
		self:scale(s_w, s_h)
		self:scale(o_w, o_h)
	end,
	grayscale = function(self)
		--return handle_result(self, lib.MagickSetImageType(self.wand, ffi.C.GrayscaleMatteType))
		return handle_result(self, lib.MagickSetImageType(self.wand, ffi.C.GrayscaleType))
	end,
	negate = function(self, gray)
		if gray then
			gray = true
		else
			gray = false
		end
		return handle_result(self, lib.MagickNegateImage(self.wand, gray))
	end,
	oil_paint = function(self, radius)
		return handle_result(self, lib.MagickOilPaintImage(self.wand, radius))	
	end,
	tone = function(self, channel_name, value)
		if channel_name == 'red' then
			lib.MagickEvaluateImageChannel(self.wand, ffi.C.RedChannel, ffi.C.MultiplyEvaluateOperator, value)
		elseif channel_name == 'green' then
			lib.MagickEvaluateImageChannel(self.wand, ffi.C.GreenChannel, ffi.C.MultiplyEvaluateOperator, value)
		elseif channel_name == 'yellow' then
			lib.MagickEvaluateImageChannel(self.wand, bit.bor(ffi.C.RedChannel, ffi.C.GreenChannel), ffi.C.MultiplyEvaluateOperator, value)
		elseif channel_name == 'blue' then
			lib.MagickEvaluateImageChannel(self.wand, ffi.C.BlueChannel, ffi.C.MultiplyEvaluateOperator, value)
		elseif channel_name == 'cyan' then
			lib.MagickEvaluateImageChannel(self.wand, bit.bor(ffi.C.GreenChannel, ffi.C.BlueChannel), ffi.C.MultiplyEvaluateOperator, value)
		elseif channel_name == 'magenta' then
			lib.MagickEvaluateImageChannel(self.wand, bit.bor(ffi.C.RedChannel, ffi.C.BlueChannel), ffi.C.MultiplyEvaluateOperator, value)
		elseif channel_name == 'sepia' then
			lib.MagickSepiaToneImage(self.wand, 52428 * (value - 0.8))
		elseif channel_name == 'hue' then
		end
	end,
    sharpen = function(self, sigma, radius)
      if radius == nil then
        radius = 0
      end
      return handle_result(self, lib.MagickSharpenImage(self.wand, radius, sigma))
      --return handle_result(self, lib.MagickAdaptiveSharpenImage(self.wand, radius, sigma))
    end,
	auto_contrast = function(self, sharpen)
		if sharpen then
			sharpen = true
		else
			sharpen = false
		end
		return handle_result(self, lib.MagickContrastImage(self.wand, sharpen))
	end,
	brightness = function(self, brightness, contrast)
		return handle_result(self, lib.MagickBrightnessContrastImage(self.wand, brightness, contrast))
	end,
	enhance = function(self)
		return handle_result(self, lib.MagickEnhanceImage(self.wand)) 
	end,
	charcoal = function(self, radius, sigma)
		return handle_result(self, lib.MagickCharcoalImage(self.wand, radius, sigma))
	end,
	flop = function(self)
		return handle_result(self, lib.MagickFlopImage(self.wand))
	end,
	flip = function(self)
		return handle_result(self, lib.MagickFlipImage(self.wand))
	end,
	opacity = function(self, alpha)
		return handle_result(self, lib.MagickEvaluateImageChannel(self.wand, ffi.C.AlphaChannel, ffi.C.MultiplyEvaluateOperator, alpha))
		--return handle_result(self, lib.MagickSetImageOpacity(self.wand, alpha))
	end,
	border = function(self, color, bw, radius)
	--[
		if not color then
			color = "rgba(255,255,255,0)"
		end

		if not bw then
			bw = 1
		end

		local w, h = self:get_width(), self:get_height()

		local draw = lib.NewDrawingWand()
		local pixelNone = lib.NewPixelWand() 
		lib.PixelSetColor(pixelNone, "none")
		local pixelBorder = lib.NewPixelWand()
		lib.PixelSetColor(pixelBorder, color)		
		
		local mask = lib.NewMagickWand()
		lib.MagickNewImage(mask, w, h, pixelNone)

		lib.DrawSetFillColor(draw, pixelNone)
		lib.DrawSetStrokeColor(draw, pixelBorder)
		lib.DrawSetStrokeWidth(draw, bw)
		lib.DrawSetStrokeAntialias(draw, true)

		if radius then
			radius = (radius < 0) and (w + h) or radius
			if w > h  then
				radius = (radius >= h / 2) and -1 or radius
			else
				radius = (radius >= w / 2) and -1 or radius
			end
			--lib.DrawSetStrokeAntialias(draw, true)
			if radius < 0 then
				lib.DrawEllipse(draw, w / 2 - 1, h / 2 - 1, (w - bw) / 2, (h - bw) / 2, 0, 362)
			else
				lib.DrawRoundRectangle(draw, bw / 2 - 0, bw / 2 - 0, w - bw / 2, h - bw / 2, radius - (bw / 2), radius - (bw / 2))
			end
		else
			lib.DrawRectangle(draw, bw / 2 - 1, bw / 2 - 1, w - bw / 2, h - bw / 2)
		end

		lib.MagickDrawImage(mask, draw)
		lib.MagickCompositeImage(self.wand, mask, composite_op["OverCompositeOp"], 0, 0)

		lib.DestroyPixelWand(pixelNone)
		lib.DestroyPixelWand(pixelBorder)
		lib.DestroyMagickWand(mask)
		lib.DestroyDrawingWand(draw)
	--]]
	end,
	mtype_extend = function(self, background, padding, pierced, tile, w, h)

		background = background or 'transparent'
		padding = tonumber(padding) or 6
		local width, height = self:get_width(), self:get_height()
		w = w or width
		h = h or height

		local pixelBg = lib.NewPixelWand()
		lib.PixelSetColor(pixelBg, background)		

		local x_offset = padding
		if tile then
			x_offset = ((w - (width + padding * 2)) / 2) + padding
			if x_offset < 0 then
				x_offset = 0
			end
		end

		local mask = lib.NewMagickWand()
		if tile then
			lib.MagickNewImage(mask, w, height + padding * 2, pixelBg)
		else
			lib.MagickNewImage(mask, width + padding * 2, height + padding * 2, pixelBg)
		end
		--lib.MagickNewImage(mask, width, height, pixelBg)

		if pierced then
			lib.MagickCompositeImage(mask, self.wand, composite_op["DstOutCompositeOp"], x_offset, padding)
		else
			lib.MagickCompositeImage(mask, self.wand, composite_op["OverCompositeOp"], x_offset, padding)
		end
		
		lib.DestroyMagickWand(self.wand)
		self.wand = mask

		--lib.DestroyMagickWand(mask)
		lib.DestroyPixelWand(pixelBg)
	end,
	text = function(self, text, font_name, font_size, font_color, font_weight, font_style, background, padding, word_spacing, letter_spacing, line_spacing, pierced, tile, text_decoration, opacity)

		text = text or ''
		font_name = font_name or '宋体'
		font_size = tonumber(font_size) or 14
		font_color = font_color or 'black'
		if pierced then
			font_color = 'black'
		end
		font_weight = tonumber(font_weight) or 0
		background = background or 'transparent'
		--opacity = tonumber(opacity) or 100
		padding = tonumber(padding) or 8

		local draw = lib.NewDrawingWand()
		local pixelText = lib.NewPixelWand()
		local pixelBg = lib.NewPixelWand()

		lib.PixelSetColor(pixelText, font_color)	
		lib.PixelSetColor(pixelBg, background)		
		lib.DrawSetFontSize(draw, font_size)
		lib.DrawSetFontWeight(draw, font_weight)

		lib.DrawSetFillColor(draw, pixelText)
		lib.DrawSetTextEncoding(draw, 'UTF8')
		--lib.DrawSetTextEncoding(draw, 'utf8mb4')
		lib.DrawSetGravity(draw, gravity_type['ForgetGravity'])

		if font_style then
			if font_style == 'normal' then
				lib.DrawSetFontStyle(draw, ffi.C.NormalStyle)
			elseif font_style == 'italic' then
				lib.DrawSetFontStyle(draw, ffi.C.ItalicStyle)
			elseif font_style == 'oblique' then
				lib.DrawSetFontStyle(draw, ffi.C.ObliqueStyle)
			end
		end

		if text_decoration then
			if text_decoration == 'underline' then
				lib.DrawSetTextDecoration(draw, ffi.C.UnderlineDecoration)
			elseif text_decoration == 'overline' then
				lib.DrawSetTextDecoration(draw, ffi.C.OverlineDecoration)
			elseif text_decoration == 'line_through' then
				lib.DrawSetTextDecoration(draw, ffi.C.LineThroughDecoration)
			end
		end

		lib.DrawSetTextAntialias(draw, true)

		--lib.DrawSetStrokeColor(draw, pixelText)
		--lib.DrawSetStrokeWidth(draw, 20)
		--lib.DrawSetTextUnderColor(draw, pixelText)
		--lib.DrawSetTextAlignment(draw, ffi.C.RightAlign)
		--lib.DrawSetFontFamily(draw, 'Helvetica Narrow')
		--lib.DrawSetFillOpacity(draw, 0.2)

		if font_name and font_name_op[font_name] then
			lib.DrawSetFont(draw, font_name_op[font_name])
		else
			lib.DrawSetFont(draw, font_name_op['宋体'])
		end

		if word_spacing then
			lib.DrawSetTextInterwordSpacing(draw, word_spacing)
		end

		if letter_spacing then
			lib.DrawSetTextKerning(draw, letter_spacing)
		end

		if line_spacing then
			lib.DrawSetTextInterlineSpacing(draw, line_spacing)
		end

		local metrics = lib.MagickQueryMultilineFontMetrics(self.wand, draw, text)
		--ngx.log(ngx.ALERT, metrics[0], " ", metrics[1], " ", metrics[2], " ", metrics[3], " ", metrics[4], " ", metrics[5])
		local o_w, o_h = self:get_width(), self:get_height()
		if metrics then
			if tile then
				self:resize(self:get_width(), metrics[5] + padding * 2)
			else
				self:resize(metrics[4] + padding * 2, metrics[5] + padding * 2)
			end
		else
			self:resize(200 + padding, 40 + padding * 2)
		end

		local x_offset = ((self:get_width() - (metrics[4] + padding * 2)) / 2) + padding
	
		lib.MagickAnnotateImage(self.wand, draw, x_offset, padding, 0, text)

		--lib.MagickTrimImage(self.wand, 0)
		local mask = lib.NewMagickWand()
		lib.MagickNewImage(mask, self:get_width(), self:get_height(), pixelBg)

		if pierced then
			lib.MagickCompositeImage(self.wand, mask, composite_op["SrcOutCompositeOp"], 0, 0)
		else
			lib.MagickCompositeImage(self.wand, mask, composite_op["OverlayCompositeOp"], 0, 0)
		end
		lib.DestroyMagickWand(mask)
		lib.DestroyPixelWand(pixelText)
		lib.DestroyPixelWand(pixelBg)
		lib.DestroyDrawingWand(draw)
	end,
	frame = function(self, color, w, h, inner_bevel, outer_bevel)
		if color == nil then
			color = "rgba(255,255,255,0)"
		end
		local pixelWand = lib.NewPixelWand();
		lib.PixelSetColor(pixelWand, color)
		local hr = handle_result(self, lib.MagickFrameImage(self.wand, pixelWand, w, h, inner_bevel, outer_bevel))
		lib.DestroyPixelWand(pixelWand)
		return hr
	end,
	auto_orient = function(self)
		return handle_result(self, lib.MagickAutoOrientImage(self.wand))
	end,
    composite = function(self, blob, x, y, opstr)
      if opstr == nil then
        opstr = "OverCompositeOp"
      end
      if type(blob) == "table" and blob.__class == Image then
        blob = blob.wand
      end
      local op = composite_op[opstr]
      if not (op) then
        error("invalid operator type")
      end
      return handle_result(self, lib.MagickCompositeImage(self.wand, blob, op, x, y))
    end,
	set_bg_color = function(self, color)
		color = color or "rgba(255,255,255,0)"
		local pixelWand = lib.NewPixelWand()
		lib.PixelSetColor(pixelWand, color)
		lib.MagickSetImageBackgroundColor(self.wand, pixelWand)
		lib.DestroyPixelWand(pixelWand)
	end,
	rounded_corner = function(self, radius, color)
		local w, h = self:get_width(), self:get_height()
		radius = radius or 0
		radius = (radius < 0) and (w + h) or radius
		if w > h  then
			--radius = (radius > h / 2) and (h / 2) or radius
			radius = (radius >= h / 2) and -1 or radius
		else
			--radius = (radius > w / 2) and (w / 2) or radius
			radius = (radius >= w / 2) and -1 or radius
		end

		local drawWand = lib.NewDrawingWand()
		local pixelBlack = lib.NewPixelWand()
		local pixelTrans = lib.NewPixelWand()
		local pixelWhite = lib.NewPixelWand() 
		lib.PixelSetColor(pixelBlack, "black")
		lib.PixelSetColor(pixelTrans, "transparent")
		lib.PixelSetColor(pixelWhite, "white")

		lib.DrawSetFillColor(drawWand, pixelBlack)
		lib.DrawSetStrokeColor(drawWand, pixelTrans)
		--lib.DrawSetStrokeWidth(drawWand, 0)
		lib.DrawSetStrokeAntialias(drawWand, true)
		
		if radius < 0 then
			lib.DrawEllipse(drawWand, w / 2 - 1, h / 2 - 1, w / 2 - 1, h / 2 - 1, 0, 360)
		else
			lib.DrawRoundRectangle(drawWand, 0, 0, w + 0, h + 0, radius + 2, radius + 2)
		end
		--local alpha = lib.PixelGetAlpha(pixelWand)
		--lib.PixelSetOpacity(pixelWand, alpha)

		local mask = lib.NewMagickWand()
		lib.MagickNewImage(mask, w, h, pixelTrans)
		lib.MagickSetImageBackgroundColor(mask, pixelTrans)


		lib.MagickDrawImage(mask, drawWand)
		lib.MagickCompositeImage(self.wand, mask, composite_op["DstInCompositeOp"], 0, 0)
		--lib.MagickCompositeImage(self.wand, mask, composite_op["CopyBlackCompositeOp"], 0, 0)

		--self.wand = mask
		
		lib.DestroyPixelWand(pixelBlack)
		lib.DestroyPixelWand(pixelTrans)
		lib.DestroyPixelWand(pixelWhite)
		lib.DestroyMagickWand(mask)
		lib.DestroyDrawingWand(drawWand)


		color = color or "white"
		local pixelWand = lib.NewPixelWand()
		lib.PixelSetColor(pixelWand, color)

		local mask_bg = lib.NewMagickWand()
		lib.MagickNewImage(mask_bg, w, h, pixelWand)
		lib.MagickCompositeImage(self.wand, mask_bg, composite_op["DstOverCompositeOp"], 0, 0)

		lib.DestroyPixelWand(pixelWand)
		lib.DestroyMagickWand(mask_bg)

	end,
    resize_and_crop = function(self, w, h)
      local src_w, src_h = self:get_width(), self:get_height()
      local ar_src = src_w / src_h
      local ar_dest = w / h
      if ar_dest > ar_src then
        local new_height = w / ar_src
        self:resize(w, new_height)
        return self:crop(w, h, 0, (new_height - h) / 2)
      else
        local new_width = h * ar_src
        self:resize(new_width, h)
        return self:crop(w, h, (new_width - w) / 2, 0)
      end
    end,
    scale_and_crop = function(self, w, h)
      local src_w, src_h = self:get_width(), self:get_height()
      local ar_src = src_w / src_h
      local ar_dest = w / h
      if ar_dest > ar_src then
        local new_height = w / ar_src
        self:resize(w, new_height)
        return self:scale(w, h)
      else
        local new_width = h * ar_src
        self:resize(new_width, h)
        return self:scale(w, h)
      end
    end,
    get_blob = function(self)
      local len = ffi.new("size_t[1]", 0)
      local blob = lib.MagickGetImageBlob(self.wand, len)
      do
        local _with_0 = ffi.string(blob, len[0])
        lib.MagickRelinquishMemory(blob)
        return _with_0
      end
    end,
    write = function(self, fname)
      return handle_result(self, lib.MagickWriteImage(self.wand, fname))
    end,
    destroy = function(self)
      if self.wand then
        lib.DestroyMagickWand(self.wand)
      end
      self.wand = nil
      if self.pixel_wand then
        lib.DestroyPixelWand(self.pixel_wand)
        self.pixel_wand = nil
      end
    end,
    get_pixel = function(self, x, y)
      self.pixel_wand = self.pixel_wand or lib.NewPixelWand()
      assert(lib.MagickGetImagePixelColor(self.wand, x, y, self.pixel_wand), "failed to get pixel")
      return lib.PixelGetRed(self.pixel_wand), lib.PixelGetGreen(self.pixel_wand), lib.PixelGetBlue(self.pixel_wand), lib.PixelGetAlpha(self.pixel_wand)
    end,
    __tostring = function(self)
      return "Image<" .. tostring(self.path) .. ", " .. tostring(self.wand) .. ">"
    end,
    fix_image_type = function(self)
      if lib.MagickGetImageType(self.wand) ~= ffi.C.TrueColorMatteType then
         return handle_result(self, lib.MagickSetImageType(self.wand, ffi.C.TrueColorMatteType))
      end
    end,
	export_image_pixels = function(self, x, y, w, h, map, storage, pixels)
		if 0 == lib.MagickExportImagePixels(self.wand, x, y, w, h, map, storage_type_op[storage], pixels) then
			return true
		end
		return false
	end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, wand, path)
      self.wand, self.path = wand, path
    end,
    __base = _base_0,
    __name = "Image"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Image = _class_0
end
local load_image
load_image = function(path)
  local wand = lib.NewMagickWand()
  if 0 == lib.MagickReadImage(wand, path) then
    local code, msg = get_exception(wand)
    lib.DestroyMagickWand(wand)
    return nil, msg, code
  end
  return Image(wand, path)
end
local constitute_image
constitute_image = function(w, h, map, storage_type, pixels)
	local wand = lib.NewMagickWand()
	if 0 == lib.MagickConstituteImage(wand, w, h, map, storage_type_op[storage_type], pixels) then
		local code, msg = get_exception(wand)
		lib.DestroyMagickWand(wand)
		return nil, msg, code
	end
	return Image(wand)
end
local new_image
new_image = function(w, h, color)
	w = w or 0
	h = h or 0
	color = color or 'none'
	local pixelNone = lib.NewPixelWand() 
	lib.PixelSetColor(pixelNone, color)
	local wand = lib.NewMagickWand()
	lib.MagickNewImage(wand, w, h, pixelNone)
	lib.DestroyPixelWand(pixelNone)
	return Image(wand)
end
local load_image_from_blob
load_image_from_blob = function(blob)
  local wand = lib.NewMagickWand()
  if 0 == lib.MagickReadImageBlob(wand, blob, #blob) then
    local code, msg = get_exception(wand)
    lib.DestroyMagickWand(wand)
    return nil, msg, code
  end
  return Image(wand, "<from_blob>")
end
local tonumber = tonumber
local parse_size_str
parse_size_str = function(str, src_w, src_h)
  local w, h, rest = str:match("^(%d*%%?)x(%d*%%?)(.*)$")
  if not w then
    return nil, "failed to parse string (" .. tostring(str) .. ")"
  end
  do
    local p = w:match("(%d+)%%")
    if p then
      w = tonumber(p) / 100 * src_w
    else
      w = tonumber(w)
    end
  end
  do
    local p = h:match("(%d+)%%")
    if p then
      h = tonumber(p) / 100 * src_h
    else
      h = tonumber(h)
    end
  end
  local center_crop = rest:match("#") and true
  local crop_x, crop_y = rest:match("%+(%d+)%+(%d+)")
  if crop_x then
    crop_x = tonumber(crop_x)
    crop_y = tonumber(crop_y)
  else
    if w and h and not center_crop then
      if not (rest:match("!")) then
        if src_w / src_h > w / h then
          h = nil
        else
          w = nil
        end
      end
    end
  end
  return {
    w = w,
    h = h,
    crop_x = crop_x,
    crop_y = crop_y,
    center_crop = center_crop
  }
end
local thumb
thumb = function(img, size_str, output)
  if type(img) == "string" then
    img = assert(load_image(img))
  end
  local src_w, src_h = img:get_width(), img:get_height()
  local opts = parse_size_str(size_str, src_w, src_h)
  if opts.center_crop then
    img:resize_and_crop(opts.w, opts.h)
  elseif opts.crop_x then
    img:crop(opts.w, opts.h, opts.crop_x, opts.crop_y)
  else
    img:resize(opts.w, opts.h)
  end
  local ret
  if output then
    ret = img:write(output)
  else
    ret = img:get_blob()
  end
  img:destroy()
  return ret
end
return {
  load_image = load_image,
  load_image_from_blob = load_image_from_blob,
  constitute_image = constitute_image,
  new_image = new_image,
  thumb = thumb,
  Image = Image,
  parse_size_str = parse_size_str,
  VERSION = VERSION
}
