local _Conf = {
	["super_hosts"] = {
		"imgx.sinacloud.net",
		"imgx.sinastorage.cn"
	},
	["allowed_file_size_max"] = 6291456,
	["allowed_file_mime_type"] = {
		["image/gif"] = "gif",
		["image/jpeg"] = "jpeg jpg",
		["image/png"] = "png",
		--["image/tiff"] = "tif tiff",
		--["image/vnd.wap.wbmp"] = "wbmp",
		--["image/x-icon"] = "ico",
		--["image/x-jng"] = "jng",
		["image/x-ms-bmp"] = "bmp",
		["image/bmp"] = "bmp",
		--["image/svg+xml"] = "svg svgz",
		["image/webp"] = "webp",
		["application/json"] = "json",
		["text/json"] = "json",
	},
	["allowed_file_type"] = {
		["gif"] = "image/gif",
		["jpg"] = "image/jpeg",
		["jpeg"] = "image/jpeg",
		["png"] = "image/png",
		--["tif"] = "image/tiff",
		--["tiff"] = "image/tiff",
		--["ico"] = "image/icon",
		["bmp"] = "image/bmp",
		["bmp1"] = "image/bmp",
		["bmp2"] = "image/bmp",
		["bmp3"] = "image/bmp",
		["bmp4"] = "image/bmp",
		["webp"] = "image/webp",
		--["pdf"] = "application/pdf",
	}
}

local _M = {
	_VERSION = '0.1.0',
}

--local mt = { __index = _M }

function _M.get_conf(key)
	return _Conf[key]
end

--local M = setmetatable({}, mt)

return _M
