local ffi = require("ffi")
local lib = ffi.load 'magicktype'
local fs = require 'fs'

ffi.cdef([[  

typedef enum {
    	MT_font_style_bold = 0,
    	MT_font_style_italic = 1,
    	MT_font_style_normal = 2,
	MT_font_style_light = 3
} MT_Font_Style;


typedef struct  MT_Font_Color_ {
    	unsigned char r;
    	unsigned char g;
    	unsigned char b;
    	unsigned char a;
} MT_Font_Color;


typedef struct  MT_Font_ {
    	int font_size;
    	float text_kerning;
    	float word_spacing;
    	float line_spacing;
    	float font_lean;
    	MT_Font_Color *font_color;
    	MT_Font_Style font_style;
	int font_file_index;
} MT_Font;


typedef struct  MT_Image_ {
    	int im_w;
    	int im_h;
    	unsigned char *image_data;
} MT_Image;

MT_Font_Color *new_font_color(unsigned char r, unsigned char g, unsigned char b, unsigned char a);
void destroy_font_color(MT_Font_Color *font_color);

MT_Font *new_font();
void destroy_font(MT_Font *font);

MT_Image *new_image();
void destroy_image(MT_Image *image);

int convert_unicode(char *str, int *code);

MT_Image *str_to_image(char *str, int im_w, int im_h, const char *font_name, MT_Font font, int resolution, int channels, int *err);

void unpack_font(const char *font_name, void *lua_function(char *family_name, char *style_name, int index));

]])

local _M = {
	_VERSION = '0.1.0',
}

local metatable = { __index = _M }

local font_style_opt = {
	["MT_font_style_bold"] = 0,
	["MT_font_style_italic"] = 1,
	["MT_font_style_normal"] = 2,
	["MT_font_style_light"] = 3,
}

local font_path_prefix = "src/lib/data/fonts/"
local font_table = nil
local font_family_defult = "Songti SC"

function get_font_list()
	local filenames = fs.read_dir(font_path_prefix)
	return filenames
end

function unpack_font()

	font_table = {}

	local font_list = get_font_list()
	
	if not font_list then
		return {}
	end
	
	local i, filename
	
	for i = 1, #font_list, 1 do
		filename = font_list[i]
		if filename ~= ".DS_Store" and filename ~= '.gitignore' and filename ~= '.svn' and fs.is_file(font_path_prefix .. filename) then
			local font_face = ffi.cast("char *", font_path_prefix .. filename)
			lib.unpack_font(font_face, function (family_name, style_name, index)
				if font_table[ffi.string(family_name)] == nil then
					font_table[ffi.string(family_name)] = {}
				end
				if font_table[ffi.string(family_name)]["font_style"] == nil then
					font_table[ffi.string(family_name)]["font_style"] = {}
				end
				if font_table[ffi.string(family_name)]["font_path"] and font_table[ffi.string(family_name)]["font_path"] ~= (font_path_prefix .. filename) then
					--[[
					if not font_table[filename] then
						font_table[filename] = {}
					end
					if not font_table[filename]['font_style'] then
						font_table[filename]['font_style'] = {}
					end
					font_table[filename]["font_style"][ffi.string(style_name)] = index
					font_table[filename]["font_path"] = font_path_prefix .. filename
					]]
					return
				end
				font_table[ffi.string(family_name)]["font_style"][ffi.string(style_name)] = index
				font_table[ffi.string(family_name)]["font_path"] = font_path_prefix .. filename
				
			end)
		end
	end
	
	return font_table
end

local function _font_face(family)
	
	if font_table == nil then
		font_table = unpack_font()
		--ngx.log(ngx.ALERT, '----- load font -----')
	end

	if font_table[family] then
		return family
	else
		return font_family_defult
	end
end


function _M.get_font_table()
	if font_table == nil then
		font_table = unpack_font()
	end
	return font_table
end

function _M.print_font_table()
	local key, val
	for key,val in pairs(font_table) do
	
		print(key,":","\n","{")
		
		if type(val) == "table" then
			
			local key_key, val_val
			
			for key_key, val_val in pairs(val) do
				
				if type(val_val) == "table" then
					print("	", key_key,":","\n","        {")
					local key_key_key, val_val_val
					for key_key_key, val_val_val in pairs(val_val) do
						print("				", key_key_key,":",val_val_val)
					end
					print("\n","        }")
				else
					print("	", key_key,":",val_val)
				end
			end
		end
		
		print("\n","}")
		
	end
end

function _M.MT(self, font, font_face)
	return setmetatable({ font = font, font_face = font_face, mt_image = nil}, metatable)
end


function _M.new(font_face)

	local font = lib.new_font()
	
	if font_face == nil then
		font_face = font_family_defult
	end
	
	return _M:MT(font, _font_face(font_face))
end

function _M.destroy(self)

	if self.font then
		lib.destroy_font(self.font)
		self.font = nil
	end
	
	if self.mt_image then
		lib.destroy_image(self.mt_image)
		self.mt_image = nil
	end

end


function _M.set_font(self, size, color, style, lean, kerning, word_spacing, line_spacing)

	if size then
		self.font.font_size = size
	end
	
	if color and (type(color)=="table") and (#color == 4) then
		self.font.font_color[0].r = color[1]
		self.font.font_color[0].g = color[2]
		self.font.font_color[0].b = color[3]
		self.font.font_color[0].a = color[4]
	end
	
	
	style = style or "MT_font_style_normal"
	
	self.font.font_style = font_style_opt[style] or font_style_opt["MT_font_style_normal"]
	
	if font_table[self.font_face] == nil then
		self.font_face = font_family_defult
	end

	if style == "MT_font_style_normal" then
		
		if font_table[self.font_face]["font_style"]["Regular"] then
			self.font.font_file_index = font_table[self.font_face]["font_style"]["Regular"]
		elseif font_table[self.font_face]["font_style"]["R"] then
			self.font.font_file_index = font_table[self.font_face]["font_style"]["R"]
		elseif font_table[self.font_face]["font_style"]["W3"] then
			self.font.font_file_index = font_table[self.font_face]["font_style"]["W3"]
		elseif font_table[self.font_face]["font_style"]["Demibold"] then
			self.font.font_file_index = font_table[self.font_face]["font_style"]["Demibold"]
		elseif font_table[self.font_face]["font_style"]["Medium"] then
			self.font.font_file_index = font_table[self.font_face]["font_style"]["Medium"]
		else
			self.font.font_file_index = 0
		end
		
	elseif style == "MT_font_style_bold" then
		
		if font_table[self.font_face]["font_style"]["Bold"] then
			self.font.font_file_index = font_table[self.font_face]["font_style"]["Bold"]
		elseif font_table[self.font_face]["font_style"]["Black"] then
			self.font.font_file_index = font_table[self.font_face]["font_style"]["Black"]
		elseif font_table[self.font_face]["font_style"]["Heavy"] then
			self.font.font_file_index = font_table[self.font_face]["font_style"]["Heavy"]
		elseif font_table[self.font_face]["font_style"]["W6"] then
			self.font.font_file_index = font_table[self.font_face]["font_style"]["W6"]
		else
			self.font.font_file_index = 0
		end
		
	elseif style == "MT_font_style_italic" then
		
		if font_table[self.font_face]["font_style"]["Italic"] then
			self.font.font_file_index = font_table[self.font_face]["font_style"]["Italic"]
		elseif font_table[self.font_face]["font_style"]["Oblique"] then
			self.font.font_file_index = font_table[self.font_face]["font_style"]["Oblique"]
		else
			self.font.font_file_index = 0
		end
		
	elseif style == "MT_font_style_light" then
		
		if font_table[self.font_face]["font_style"]["Light"] then
			self.font.font_file_index = font_table[self.font_face]["font_style"]["Light"]
		elseif font_table[self.font_face]["font_style"]["Extralight"] then
			self.font.font_file_index = font_table[self.font_face]["font_style"]["Extralight"]
		else
			self.font.font_file_index = 0
		end
	end
	
	
	if lean then
		self.font.font_lean = lean
	end
	
	if kerning then
		self.font.text_kerning = kerning
	end
	
	if word_spacing then
		self.font.word_spacing = word_spacing
	end
	
	if line_spacing then
		self.font.line_spacing = line_spacing
	end
end


function _M.draw_text(self, text, w, h, channels)               

	text = text or ""
	w = w or -1
	h = h or -1
	
	if channels == nil then
		channels = 4
	else
		if channels ~= 1 then
			channels = 4
		end
	end
	
	local font_face = ffi.cast("char *", font_table[self.font_face]["font_path"])
	local err = ffi.new("int[1]")
	self.mt_image = lib.str_to_image(ffi.cast("char *", text), w, h, font_face, self.font[0], 72, channels, err)
	if err[0] and tonumber(err[0]) == 0 then
		return true
	end
	return false
end

return _M
