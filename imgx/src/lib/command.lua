local util = require "util"
local cv = require "luacv"
local magick = require "magick"
local lock = require "resty.lock" 
local conf = require "config"
local stoerr = require "stoerr"
local cjson = require "cjson.safe"
local magick_type = require "magick_type"

local _M = {
	_VERSION = '0.1.0',
}

local CMD_LIST = {
	['c']  = true,
	['w']  = true,
	['h']  = true,
	['g']  = true,
	['x']  = true,
	['y']  = true,
	['q']  = true,
	['r']  = true,
	['a']  = true,
	['e']  = true,
	['o']  = true,
	['bo'] = true,
	['b']  = true,
	['l']  = true,
	['u']  = true,
	['d']  = true,
	['f']  = true,
	['t']  = true,
	['v']  = true, 
}

CMD_LIST['c'] = {
	['scale'] = true,
	['fill'] = true,
	['lfill'] = true,
	['fit'] = true,
	['mfit'] = true,
	['limit'] = true,
	['pad'] = true,
	['lpad'] = true,
	['mpad'] = true,
	['crop'] = true,
	['thumb'] = true,
}

CMD_LIST['g'] = {
	['north_west'] = 'GRAVITY_NORTH_WEST',
	['north'] = 'GRAVITY_NORTH',
	['north_east'] = 'GRAVITY_NORTH_EAST',
	['west'] = 'GRAVITY_WEST',
	['center'] = 'GRAVITY_CENTER',
	['east'] = 'GRAVITY_EAST',
	['south_west'] = 'GRAVITY_SOUTH_WEST',
	['south'] = 'GRAVITY_SOUTH',
	['south_east'] = 'GRAVITY_SOUTH_EAST',
	['xy_center'] = 'GRAVITY_XY_CENTER',
	['face'] = 'GRAVITY_FACE',
	['faces'] = 'GRAVITY_FACES',
	['face:center'] = 'GRAVITY_FACE_CENTER',
	['faces:center'] = 'GRAVITY_FACES_CENTER',
}

CMD_LIST['f'] = {
	['png'] = 'png',
	['webp'] = 'webp',
	['jpeg'] = 'jpeg',
	['jpg'] = 'jpeg',
	--['gif'] = true,
}

local CMD_LONG_LIST = {
	['crop'] = 'c',
	['width'] = 'w',
	['height'] = 'h',
	['gravity'] = 'g',
	['x'] = 'x',
	['y'] = 'y',
	['quality'] = 'q',
	['radius'] = 'r',
	['angle'] = 'a',
	['effect'] = 'e',
	['opacity'] = 'o',
	['border'] = 'bo',
	['background'] = 'b',
	['overlay'] = 'l',
	['underlay'] = 'u',
	['default_image'] = 'd',
	['format'] = 'f',
	--['version'] = 'v',
}

function _M.parse_trans(c)
	if #c == 1 and c[1] and c[1]['t'] then
		local try_json_ok, json_path = _M.try_file('imgx/t/' .. ngx.escape_uri(c[1]['t']) .. '.json')
		if try_json_ok and json_path then
			local decode_ok, trans_style = pcall(function()
				local json_str = util.file_get_contents(json_path)
				if json_str then
					return cjson.decode(json_str)
				end
			end)
			if decode_ok and trans_style and trans_style[1] then
				local trans_count = #trans_style > 4 and 4 or #trans_style
				local i, ok, err
				for i = 1, trans_count do
					ok, err = _M.parse_cmd_sub(trans_style[i], true)
					if ok then
						c[i] = ok
					else
						os.remove(json_path)
						stoerr.err_exit('InvalidTransformation', err) 
						return false
					end
				end
				return true
			end
		end
		pcall(function()
			os.remove(json_path)
		end)
		stoerr.err_exit('UnknownTransformation') 
		return false
	end
	return true
end

function _M.parse_cmd(cmd)
	local subs = util.split(cmd, '%-%-')
	--local subs = util.split(cmd, ',%-,')
	--local subs = util.split(cmd, '%.%.')
	if #subs == 0 then
		return false, nil
	end
	local c = {}
	local v_count, t_count = 0, 0
	local i
	for i = 1, #subs do
		local sub, err = _M.parse_cmd_sub(subs[i])
		if sub then
			if sub['v'] then
				v_count = v_count + 1
				ngx.ctx.cmd_v = sub['v']
			end
			if sub['t'] then
				t_count = t_count + 1
				ngx.ctx.cmd_t = sub['t']
			end
			table.insert(c, sub)
		else
			return false, err
		end
	end
	if v_count > 1 then
		return false, "Invalid Argument, 'v' must be alone"
	end
	if t_count > 1 or (t_count == 1 and #subs > 1) then
		return false, "Invalid Argument, 't' must be a separate"
	end
	return c
end

function _M.parse_cmd_sub(cmd, trans)
	local lines
	if not trans then
		cmd = ngx.unescape_uri(cmd)
		lines = util.split(cmd, ",")
	else
		if type(cmd) ~= 'table' then
			return false, nil
		end
		lines = {}
		local c_key, c_val
		for c_key, c_val in pairs(cmd) do
			if CMD_LONG_LIST[c_key] then
				table.insert(lines, {
					['key'] = CMD_LONG_LIST[c_key],
					['val'] = tostring(c_val),
				})
			else
				return false, nil
			end
		end
	end

	if #lines == 0 then
		return false, nil
	end

	local c = {}
	local c_keys = {}
	local v_count = 0

	local i
	for i = 1, #lines do
		local m, err
		if not trans then
			--local m, err = ngx.re.match(lines[i], "^([a-z]{1,2})_([a-zA-Z0-9:_\\-\\.]+)$")
			m, err = ngx.re.match(lines[i], "^([a-z]{1,2})_(.+)$")
		else
			m = {lines[i]['key'], lines[i]['val']}
		end
		if m and m[1] and m[2] and CMD_LIST[m[1]] then
			local key, val = m[1], m[2]
			if key == 'c' then
				if not CMD_LIST['c'][val] then
					return false, "Invalid Argument '" .. key .. ":" .. val .. "'"
				end
			elseif key == 'w' or key == 'h' then
				local num_val = tonumber(val)
				if not (num_val and num_val > 0 and num_val <= 5000) then
					return false, "Invalid Argument '" .. key .. ":" .. val .. "', must be a (float, >0 and <1) or (integer, >=1 and <=5000)"
				end
				if not ((ngx.re.match(val, "^[1-9][0-9]*$") and num_val >= 1 and num_val <= 5000) or (ngx.re.match(val, "^0\\.[0-9]+$") and num_val > 0 and num_val < 1)) then
					return false, "Invalid Argument '" .. key .. ":" .. val .. "', must be a (float, >0 and <1) or (integer, >=1 and <=5000)"
				end
				val = tonumber(val)
			elseif key == 'x' or key == 'y' then
				local num_val = tonumber(val)
				if not (num_val and num_val >= -5000 and num_val <= 5000 and ngx.re.match(val, "^-?(([1-9][0-9]*)|0)$")) then
					return false, "Invalid Argument '" .. key .. ":" .. val .. "', must be a integer, >=-5000 and <=5000"
				end
				val = tonumber(val)
			elseif key == 'q' then
				local num_val = tonumber(val)
				if not (num_val and num_val >= 1 and num_val <= 100 and ngx.re.match(val, "^[1-9][0-9]*$")) then
					return false, "Invalid Argument '" .. key .. ":" .. val .. "', must be a integer, >=1 and <=100"
				end
				val = tonumber(val)
			elseif key == 'r' then
				local num_val = tonumber(val)
				if not (val == 'max' or (num_val and num_val >= 0 and num_val <= 5000 and ngx.re.match(val, "^(([1-9][0-9]*)|0)$"))) then
					return false, "Invalid Argument '" .. key .. ":" .. val .. "', must be (string 'max') or (integer, >=0 and <=5000)"
				end
			elseif key == 'a' then
				local num_val = tonumber(val)
				if not (val == 'vflip' or val == 'hflip' or val == 'exif' or (num_val and num_val >= -360 and num_val <= 360 and ngx.re.match(val, "^-?(([1-9][0-9]*)|0)$"))) then
					return false, "Invalid Argument '" .. key .. ":" .. val .. "', must be (string 'vflip', 'hflip', 'exif') or (integer, >=-360 and <=360)"
				end
			elseif key == 'o' then
				local num_val = tonumber(val)
				if not (num_val and num_val >= 0 and num_val <= 100 and ngx.re.match(val, "^(([1-9][0-9]*)|0)$")) then
					return false, "Invalid Argument '" .. key .. ":" .. val .. "', must be a integer, >=0 and <=100"
				end
				val = tonumber(val)
			elseif key == 'b' then
				if not ngx.re.match(val, "^([0-9a-f]{6}|[0-9a-f]{8})$") then
					return false, "Invalid Argument '" .. key .. ":" .. val .. "', must be lower case string rgb from '000000' to 'ffffff', rgba from '00000000' to 'ffffffff'"
				end
			elseif key == 'f' then
				if not CMD_LIST['f'][val] then
					return false, "Invalid Argument '" .. key .. ":" .. val .. "'"
				end
				val = CMD_LIST['f'][val]
			elseif key == 'g' then
				if not CMD_LIST['g'][val] then
					return false, "Invalid Argument '" .. key .. ":" .. val .. "'"
				end
			elseif key == 'bo' then
				local m = ngx.re.match(val, "^([1-9][0-9]*)_([0-9a-f]{6}|[0-9a-f]{8})$")
				if not m then
					return false, "Invalid Argument '" .. key .. ":" .. val .. "', must be like <px>_<rgb color>, px > 0"
				end
				val = {
					["px"] = tonumber(m[1]),
					["color"] = m[2],
				} 
			elseif key == 'v' then
				if not tonumber(val) then
					return false, "Invalid Argument '" .. key .. ":" .. val .. "', must be a number"
				end
				v_count = v_count + 1
			elseif key == 't' then
				local m = ngx.re.match(val, "^([a-zA-Z0-9_\\-]{1,32})$")
				if not m then
					return false, "Invalid Argument '" .. key .. ":" .. val .. "'"
				end 
			elseif key == 'l' then
				local m = ngx.re.match(val, "^text:([a-zA-Z0-9_\\-]{1,32}):(.{1,128})$")
				if not m then
					m = ngx.re.match(val, "^([a-zA-Z0-9_\\-]{1,32})$")
					if m then
						val = {
							["key"] = m[1]
						}
					end
				else
					val = {
						["text"] = m[2],
						["font"] = m[1]
					}
				end
				if not m then
					m = ngx.re.match(val, "^text:([a-zA-Z0-9_\\-]{1,32})$")
					if not m then
						return false, "Invalid Argument '" .. key .. ":" .. val .. ""
					else
						val = {
							["font"] = m[1],
						}
					end
				end
				if not m then
					return false, "Invalid Argument '" .. key .. ":" .. val .. "" 
				end
			elseif key == 'e' then
				local m = ngx.re.match(val, "^([a-z_\\-]{3,20}):(-?[0-9]{1,4})$")
				if not m then
					m = ngx.re.match(val, "^([a-z_\\-]{3,20})$")
					if m then
						val = {
							["name"] = m[1],
						}
					end
				else
					val = {
						["name"] = m[1],
						["value"] = m[2],
					}
				end
				if not m then
					return false, "Invalid Argument '" .. key .. ":" .. val .. ""
				end
			end
			c[key] = val
			table.insert(c_keys, key)
		else
			return false, nil
		end
	end
	if (c['t'] and (not c['v']) and #c_keys > 1) or (c['t'] and c['v'] and #c_keys > 2) then
		return false, "Invalid Argument 't' must be separated"
	end
	local count_c_l_u = 0
	count_c_l_u = c['c'] and (count_c_l_u + 1) or count_c_l_u
	count_c_l_u = c['l'] and (count_c_l_u + 1) or count_c_l_u
	count_c_l_u = c['u'] and (count_c_l_u + 1) or count_c_l_u
	if count_c_l_u > 1 then
		return false, "Invalid Argument 'c' 'l' 'u' must be alone"
	end
	if v_count > 1 then
		return false, "Invalid Argument 'v' must be alone"
	end
	return c
end

function _M.download(key)

	local au, bucket = ngx.ctx.au, ngx.ctx.bucket
	local res, err, httpc = au:scs_request(bucket, key)
	
	if not res then
		util.release_http_connect(httpc)
		return false, 'InternalServerError'
	end
	
	if res.status ~= 200 and res.status ~= 304 then
		util.release_http_connect(httpc)
		return false, res.headers["x-error-code"]
	end

	local content_type
	local file_size = res.headers["Content-Length"] or res.headers["X-Filesize"]

	if res.headers and file_size and res.headers["Content-Type"] then
		if tonumber(file_size) > (512 * 1024) then
			util.release_http_connect(httpc)
			return false, 'EntityTooLarge'
		end
		
		if tonumber(file_size) <= 1 then
			util.release_http_connect(httpc)
			return false, 'EntityTooSmall'
		end

		content_type = res.headers["Content-Type"]
		content_type = content_type:lower()		

		if not conf.get_conf("allowed_file_mime_type")[content_type] then
			util.release_http_connect(httpc)
			return false, 'InvalidFileType'
		end
	else
		util.release_http_connect(httpc)
		return false, 'InternalServerError'
	end

	local reader = res.body_reader
    if not reader then
        ngx.log(ngx.ERR, "no response provided")
		util.release_http_connect(httpc)
        return false, "InternalServerError"
    end

	local fpath, sha1 = util.get_file_path(bucket, key, true)	
	local tmpath = util.get_tmpfile_path(fpath)

	local fp, fp_err = io.open(tmpath, 'w+')
    if fp_err ~= nil then
		ngx.log(ngx.ERR, 'FileHandleError:' .. fp_err)
		util.release_http_connect(httpc)
        return false, 'InternalServerError'
    end

	repeat
        local chunk, err = reader(1024 * 1024)
        if err then
            ngx.log(ngx.ERR, err)
			util.release_http_connect(httpc)
			fp:close()
            os.remove(tmpath)
			return false, 'InternalServerError'
		end
        if chunk then
			local ret, fw_err = fp:write(chunk)
			if fw_err ~= nil then
				fp:close()
				os.remove(tmpath)
				ngx.log(ngx.ERR, 'FileHandleError:' .. fw_err)
				util.release_http_connect(httpc)
				return false, 'InternalServerError'
			end
			--ngx.print(chunk)
        end
    until not chunk
	
	fp:close()
	util.release_http_connect(httpc)
	
	local rename_ok, rename_err, rename_err_num = os.rename(tmpath, fpath)
	if err ~= nil  then
		ngx.log(ngx.ERR, string.format('rename %s to %s fail, err:%s', tmpath, fpath, rename_err))
		os.remove(tmpath)
		return false, 'InternalServerError'
	end

	return true

end

function _M.download_overlay(key)
	return _M.download(key)
end

function _M.try_file(key)
	local bucket = ngx.ctx.bucket 
	local fpath, sha1, relative_path = util.get_file_path(bucket, key)
	if not util.file_exist(fpath) then
		local lock = lock:new("processing_locks", {exptime = 300, timeout = 300})
		local elapsed, err = lock:lock(sha1)
		if not elapsed then
			ngx.log(ngx.ERR, err) 
			return false
		end
		if util.file_exist(fpath) then
			local unlock_ok, err = lock:unlock()
			if not unlock_ok then
				ngx.log(ngx.ERR, err)
				return false
			end
			return true, fpath
		end

		local ok, err = _M.download_overlay(key)
		local unlock_ok, unlock_err = lock:unlock()
        if not unlock_ok then
			ngx.log(ngx.ERR, unlock_err)
			return false
        end
		if ok then
			return true, fpath  
		else
			return false
		end
	else
		return true, fpath
	end
end

function _M.try_overlay_file(key)
	return _M.try_file(key)
end

function _M.processing(style, src_path, dst_path)

	local sha1 = util.sha1_hex(dst_path)
	local old_dst_path = dst_path
	local lock = lock:new("processing_locks", {exptime = 60, timeout = 60})
	local elapsed, err = lock:lock(sha1)
	if not elapsed then
		ngx.log(ngx.ERR, err) 
		stoerr.err_exit('InternalError')
		return false
	end

	local unlock = function()
		local unlock_ok, err = lock:unlock()
		if not unlock_ok then
			ngx.log(ngx.ERR, err)
			stoerr.err_exit('InternalError')
			return false
		end
		return true
	end

	local exist, new_path = util.img_file_exist(dst_path)
	if exist then	
		if unlock() then
			ngx.exec(new_path .. '?bucket=' .. ngx.ctx.bucket)
			return true
		end
	end

	local mgk = magick.load_image(src_path)
	if not mgk then
		os.remove(src_path)
		if unlock() then
			stoerr.err_exit('InvalidFileType')
			return false
		end
	end
	pcall(function()
		return mgk:auto_orient()
	end)
	local width, height = mgk:get_width(),  mgk:get_height()
	local format = mgk:get_format():lower()
	--ngx.log(ngx.ALERT, '----' .. format .. '-----')
	local new_format = format
	if width < 1 or height < 1 or (not conf.get_conf("allowed_file_type")[format]) then
		os.remove(src_path)
		mgk:destroy()
		if unlock() then
			stoerr.err_exit('InvalidFileType')
			return false
		end
	end
	
	local fn, en = util.get_filename(dst_path)

	if format == 'jpeg' and (en ~= 'jpg' or en ~= 'jpeg') then
		dst_path = dst_path .. '.jpg' 
		new_format = 'jpeg'
	end

	if format == 'png' and en ~= 'png' then
		dst_path = dst_path .. '.png' 
		new_format = 'png'
	end

	if format == 'webp' and en ~= 'webp' then
		dst_path = dst_path .. '.webp' 
		new_format = 'webp'
	end

	if format ~= 'jpeg' and format ~= 'png' and format ~= 'webp' and format ~= 'gif' then
		dst_path = dst_path .. '.jpg'
		new_format = 'jpeg'
	end 

	if format == 'gif' then
		mgk:set_first_iterator()
		mgk:set_format('png')
		dst_path = dst_path .. '.png'
		new_format = 'png'
	end

	mgk:fix_image_type()
	local cvimg = cv.create_image(width, height, 8, 4)
	mgk:export_image_pixels(0, 0, width, height, 'BGRA', 'CharPixel', cvimg:get_image_data())
	mgk:destroy()

	local count_style = #style > 4 and 4 or #style
	local q, f

	local process_img = function(sty)
		local c = sty['c']
		local w = sty['w']
		local h = sty['h']
		local g = sty['g']
		local x = sty['x']
		local y = sty['y']
		local r = sty['r']
		local a = sty['a']
		local o = sty['o']
		local bo = sty['bo']
		local b = sty['b']
		local l = sty['l']
		local e = sty['e']
		f = sty['f'] or f
		q = sty['q'] or q
		
		if w and w < 1 and w > 0 then
			w = w * width
		end

		if h and h < 1 and h > 0 then
			h = h * height
		end

		if (not l) and x and x < 0 then
			x = 0
		end

		if (not l) and y and y < 0 then
			y = 0
		end

		local g_mode = CMD_LIST['g'][g]
		local bg_color
		
		if b then
			bg_color = {}
			local i
			for i = 1, b:len(), 2 do
				local num = tonumber(b:sub(i, i + 1), 16)
				table.insert(bg_color, num)
			end	
			--if bo then
			--	bg_color[4] = 255
			--end
		else
			--[[
			if bo then
				bg_color = {255, 255, 255, 255}
			else
				bg_color = {255, 255, 255, 0}
			end
			--]]
			bg_color = {255, 255, 255, 0}
		end

		local bo_color
		if bo then
			bo_color = {}
			local i
			for i = 1, bo['color']:len(), 2 do
				local num = tonumber(bo['color']:sub(i, i + 1), 16) 
				table.insert(bo_color, num)
			end
		end

		local call_ok, call_ret
		if c then
			if c == 'scale' then
				call_ok, call_ret = pcall(function()
					return cvimg:resize(w, h, 'RESIZE_SCALE')
				end)
			elseif c == 'fill' then
				call_ok, call_ret = pcall(function()
					return cvimg:fill(w, h, 'FILL_DEFAULT', g_mode)
				end)
			elseif c == 'lfill' then
				call_ok, call_ret = pcall(function()
					return cvimg:fill(w, h, 'FILL_LIMIT', g_mode)
				end)
			elseif c == 'fit' then 
				call_ok, call_ret = pcall(function()
					return cvimg:resize(w, h, 'RESIZE_FIT') 
				end)
			elseif c == 'mfit' then 
				call_ok, call_ret = pcall(function()
					return cvimg:resize(w, h, 'RESIZE_MFIT')
				end)
			elseif c == 'limit' then 
				call_ok, call_ret = pcall(function()
					return cvimg:resize(w, h, 'RESIZE_LIMIT')
				end)
			elseif c == 'pad' then 
				call_ok, call_ret = pcall(function()
					return cvimg:pad(w, h, 'PAD_DEFAULT', g_mode, bg_color) 
				end)
			elseif c == 'lpad' then
				call_ok, call_ret = pcall(function()
					return cvimg:pad(w, h, 'PAD_LIMIT', g_mode, bg_color)
				end)
			elseif c == 'mpad' then
				call_ok, call_ret = pcall(function()
					return cvimg:pad(w, h, 'PAD_M_LIMIT', g_mode, bg_color)
				end)
			elseif c == 'crop' then
				call_ok, call_ret = pcall(function()
					return cvimg:crop(x, y, w, h, g_mode)
				end)
			elseif c == 'thumb' then
				call_ok, call_ret = pcall(function()
					cvimg:fill(w, h, 'FILL_THUMB', g_mode)
				end)
			end
		end 
		
		--[[
		if not call_ok then
			return call_ok, call_ret
		end
		----------------]]
				
		--[[
		if not call_ok then
			return call_ok, call_ret
		end
		----------------]]
		if (w or h) and (x or y) and (not c) and (not l) and (not u) then
			call_ok, call_ret = pcall(function()
				return cvimg:crop(x, y, w, h, g_mode)
			end)
		end

		if (w or h) and (not c) and (not l) and (not u) then
			call_ok, call_ret = pcall(function()
				return cvimg:fill(w, h, 'FILL_DEFAULT', g_mode)
			end)
		end

		--[[
		if not call_ok then
			return call_ok, call_ret
		end
		----------------]]

		local magck_overlay
		local overlay_width, overlay_height
		local init_magck_overlay = function(key)
			local try_ok, fpath = _M.try_overlay_file(key)
			if try_ok and fpath then
				magck_overlay = magick.load_image(fpath)
				if not magck_overlay then
					os.remove(fpath)
					return
				end
				pcall(function()
					return magck_overlay:auto_orient()
				end)
				overlay_width, overlay_height = magck_overlay:get_width(), magck_overlay:get_height()
				local format = magck_overlay:get_format():lower()
				if overlay_width < 1 or overlay_height < 1 or (not conf.get_conf("allowed_file_type")[format]) then
					os.remove(fpath)
					magck_overlay:destroy()
					magck_overlay = nil
					return
				end
			end
			return
		end

		if l then
			
			local font = l['font']
			local key = l['key']
			local key_prefix = 'imgx/l/'
	
			if key then
				key = key_prefix .. ngx.escape_uri(key) .. '.png'
				call_ok, magck = pcall(function()
					init_magck_overlay(key)
					if magck_overlay and (w or h) then
						magck_overlay:resize(w, h)
					end 
				end)
			elseif font then
				local text = l['text']
				local font_family, font_size, font_color, font_style, background, padding, word_spacing, kerning, line_spacing, pierced, tile, font_color_table, background_color
				local try_font_ok, font_path = _M.try_file(key_prefix .. ngx.escape_uri(font) .. '.json')
				if try_font_ok and font_path then
					local decode_ok, text_style = pcall(function()
						local json_str = util.file_get_contents(font_path)
						if json_str then
							return cjson.decode(json_str)
						end
					end)
					if decode_ok and text_style then
						if (not text) then
							text = text_style['text']
						end
						font_family = text_style['font_family']
						font_size = text_style['font_size'] or 14
						font_color = text_style['font_color']
						background = text_style['background']
						padding = text_style['padding']
						word_spacing = text_style['word_spacing']
						kerning = text_style['kerning']
						line_spacing = text_style['line_spacing']
						pierced = text_style['pierced']
						tile = text_style['tile']
						font_color_table = {0, 0, 0, 255}
						if font_color and ngx.re.match(tostring(font_color), "^([0-9a-f]{6}|[0-9a-f]{8})$") then 
							local i
							for i = 1, font_color:len(), 2 do
								font_color_table[(i + 1) / 2] = tonumber(font_color:sub(i, i + 1), 16)
							end	
						end
						if background and ngx.re.match(tostring(background), "^([0-9a-f]{6}|[0-9a-f]{8})$") then 
							local i
							local bg_table = {255, 255, 255, 255}
							for i = 1, background:len(), 2 do
								bg_table[(i + 1) / 2] = tonumber(background:sub(i, i + 1), 16)
							end	
							background_color = string.format("rgba(%d,%d,%d,%f)", bg_table[1], bg_table[2], bg_table[3], bg_table[4] / 255)
						end

						if pierced then
							font_color_table = {0, 0, 0, 255}
						end
						if text_style['font_style'] then
							if text_style['font_style'] == 'bold' then
								font_style = 'bold'
							elseif text_style['font_style'] == 'italic' then
								font_style = 'italic'
							elseif text_style['font_style'] == 'normal' then
								font_style = 'normal'
							elseif text_style['font_style'] == 'light' then
								font_style = 'light'
							end
						end
					end
				end
				if text then
					call_ok, magck = pcall(function()
						--[[
						local mask_w, mask_h = cvimg:get_size()
						magck_overlay = magick.new_image(mask_w, mask_h)
						magck_overlay:text(text, font_name, font_size, font_color, font_weight, font_style, background, padding, word_spacing, letter_spacing, line_spacing, pierced, tile)
						if magck_overlay and (w or h) then
							magck_overlay:resize(w, h)
						end 
						]]
						local mtype = magick_type.new(font_family)
						mtype:set_font(font_size, font_color_table, font_style, 0, kerning, word_spacing, line_spacing)
						mtype:draw_text(text, w, h)
						magck_overlay = magick.constitute_image(mtype.mt_image.im_w, mtype.mt_image.im_h, "BGRA", "CharPixel", mtype.mt_image.image_data)
						
						local mask_w, mask_h = cvimg:get_size()
						magck_overlay:mtype_extend(background_color, padding, pierced, tile, mask_w, mask_h)
						mtype:destroy()
						mtype = nil
					end)
				end
			end
			
		end


		local magck
		
		if (not l) and (bo or a or r or o or e) then 
			call_ok, magck = pcall(function()
				return cvimg:to_magick()
			end)
		elseif l and magck_overlay then
			call_ok, magck = pcall(function()
				return cvimg:to_magick()
			end)
		end

		if e then
			local e_name, e_value = e['name'], tonumber(e['value'])
			local mk_
			if (not l) and  magck then
				mk_ = magck
			elseif l and magck_overlay then
				mk_ = magck_overlay
			end

			if e_name == 'blur' then
				if (not e_value) or e_value < 0 then
					e_value = 100
				else
					if e_value > 2000  then
						e_value = 2000
					end
				end
				local radius = mk_:get_width()
				local sigma = 1 + (math.log(e_value) / math.log(1.8))
				pcall(function()
					mk_:blur(radius, sigma)
				end)
			elseif e_name == 'pixelate' then
				e_value = e_value or 5
				pcall(function()
					mk_:pixelate(e_value)
				end)
			elseif e_name == 'negate' then
				pcall(function()
					mk_:negate()
				end)
			elseif e_name == 'grayscale' then
				pcall(function()
					mk_:grayscale()
				end)
			elseif e_name == 'oil_paint' then
				if (not e_value) or e_value < 1 then
					e_value = 4
				elseif e_value > 8 then
					e_value = 8
				end
				pcall(function()
					mk_:oil_paint(e_value)
				end)
			elseif e_name == 'sepia' or e_name == 'red' or e_name == 'green' or e_name == 'yellow' or e_name == 'blue' or e_name == 'cyan' or e_name == 'magenta' then
				if (not e_value) or e_value < 1 then
					if e_name == 'sepia' then
						e_value = 80
					else
						e_value = 60
					end
				elseif e_value > 100 then
					e_value = 100
				end
				pcall(function()
					mk_:tone(e_name, (e_value / 100) + 1)
				end)
			elseif e_name == 'sharpen' then
				if (not e_value) or e_value < 0 then
					e_value = 100
				else
					if e_value > 2000  then
						e_value = 2000
					end
				end
				local radius = mk_:get_width()
				local sigma = 1 + (math.log(e_value) / math.log(2.1))
				pcall(function()
					mk_:sharpen(radius, sigma)
				end)
			elseif e_name == 'auto_contrast' then
				pcall(function()
					mk_:auto_contrast(true)
				end)
			elseif e_name == 'improve' then
				pcall(function()
					mk_:enhance()
				end)
			elseif e_name == 'charcoal1' then
				if (not e_value) or e_value < 0 then
					e_value = 100
				else
					if e_value > 2000  then
						e_value = 2000
					end
				end
				local radius = 100
				local sigma = 0 + (math.log(e_value) / math.log(4))
				pcall(function()
					mk_:charcoal(radius, sigma)
				end)
			elseif e_name == 'brightness' then
				if not (e_value and e_value >= -100 and e_value <= 100) then
					e_value = 30
				end
				pcall(function()
					mk_:brightness(e_value, 0)
				end)
			end	
			mk_ = nil
		end

		if (not l) and r and magck then
			if r == 'max' then
				r = -1
			end
			call_ok, call_ret = pcall(function()
				local bc
				if bg_color then
					if ((not f) and new_format == 'jpeg') or (f and f == 'jpeg') then 
						bc = string.format("rgba(%d,%d,%d,1)", bg_color[1], bg_color[2], bg_color[3]) 
					else
						local bg_color_a = bg_color[4] or 255
						bc = string.format("rgba(%d,%d,%d,%f)", bg_color[1], bg_color[2], bg_color[3], bg_color_a / 255)
					end
				end
				return magck:rounded_corner(tonumber(r), bc)
			end)
		elseif l and r and magck_overlay then
			if r == 'max' then
				r = -1
			end
			call_ok, call_ret = pcall(function()
				return magck_overlay:rounded_corner(tonumber(r), "transparent")
			end)
		end
		
		if (not l) and bo and magck then
			if bo_color then
				local bo_color_a = bo_color[4] or 255
				if ((not f) and new_format == 'jpeg') or (f and f == 'jpeg') then
					bo_color_a = 255
				end
				local boc = string.format("rgba(%d,%d,%d,%f)", bo_color[1], bo_color[2], bo_color[3], bo_color_a / 255)
				call_ok, call_ret = pcall(function()
					--return magck:frame(boc, bo['px'], bo['px'], 0, 0)
					--return magck:frame(boc, bo['px'], bo['px'], bo['px']/5, bo['px']/5)
					local radius = nil;
					if r then
						if r == 'max' then
							r = -1
						end
						radius = tonumber(r)
					end
					return magck:border(boc, bo['px'], radius)
				end)
			end
		elseif l and bo and magck_overlay then
			if bo_color then
				local bo_color_a = bo_color[4] or 255
				local boc = string.format("rgba(%d,%d,%d,%f)", bo_color[1], bo_color[2], bo_color[3], bo_color_a / 255)
				call_ok, call_ret = pcall(function()
					local radius = nil;
					if r then
						if r == 'max' then
							r = -1
						end
						radius = tonumber(r)
					end
					return magck_overlay:border(boc, bo['px'], radius)
				end)
			end
		end

		--[[
		if not call_ok then
			return call_ok, call_ret
		end
		----------------]]

		if (not l) and a and magck then

			local bc

			if bg_color then
				if ((not f) and new_format == 'jpeg') or (f and f == 'jpeg') then
					bc = string.format("rgba(%d,%d,%d,1)", bg_color[1], bg_color[2], bg_color[3])
				else
					local bg_color_a = bg_color[4] or 255
					--if bo then
					--	bg_color_a = 255
					--end
					bc = string.format("rgba(%d,%d,%d,%f)", bg_color[1], bg_color[2], bg_color[3], bg_color_a / 255)
				end
			else
				if ((not f) and new_format == 'jpeg') or (f and f == 'jpeg') then
					bc = 'rgba(255,255,255,1)'
				else
					bc = 'rgba(255,255,255,0)'
					--if bo then
					--	bc = 'rgba(255,255,255,1)'
					--end
				end
			end

			local degrees = tonumber(a) or nil

			if degrees then
				call_ok, call_ret = pcall(function()
					return magck:rotate(degrees, bc)
				end)
			elseif a == 'vflip' then
				call_ok, call_ret = pcall(function()
					return magck:flip()
				end)
			elseif a == 'hflip' then
				call_ok, call_ret = pcall(function()
					return magck:flop()
				end)
			end
		elseif l and a and magck_overlay then
			local degrees = tonumber(a) or nil
			if degrees then
				call_ok, call_ret = pcall(function()
					return magck_overlay:rotate(degrees, "transparent")
				end)
			elseif a == 'vflip' then
				call_ok, call_ret = pcall(function()
					return magck_overlay:flip()
				end)
			elseif a == 'hflip' then
				call_ok, call_ret = pcall(function()
					return magck_ovarlay:flop()
				end)
			end
		end
		
		--[[
		if not call_ok then
			return call_ok, call_ret
		end
		---------------]]	

		if (not l) and o and magck then
			call_ok, call_ret = pcall(function()
				return magck:opacity(o / 100)
			end)
		elseif l and o and magck_overlay then
			call_ok, call_ret = pcall(function()
				return magck_overlay:opacity(o / 100)
			end)
		end

		--[[
		if b and magck then
			--magck:set_bg_color('rgba(0,255,255,1)')
		end
		--]]

		if magck and magck_overlay then
			width = magck:get_width()
			height = magck:get_height()
			local new_cvimg = cv.create_image(width, height, 8, 4)
			call_ok, call_ret = pcall(function()
				return magck:export_image_pixels(0, 0, width, height, 'BGRA', 'CharPixel', new_cvimg:get_image_data())
			end)
			magck:destroy()
			magck = nil

			if bg_color then
				if ((not f) and new_format == 'jpeg') or (f and f == 'jpeg') then 
					bg_color[4] = 255 
				end
			else
				if ((not f) and new_format == 'jpeg') or (f and f == 'jpeg') then
					bg_color = {255, 255, 255, 255}
				end
			end


			call_ok, call_ret = pcall(function()
				x, y = new_cvimg:overlay_canvas(x, y, magck_overlay:get_width(), magck_overlay:get_height(), g_mode, bg_color)
				--ngx.log(ngx.ERR, x, " ", y)
			end)

			call_ok, magck = pcall(function()
				return new_cvimg:to_magick()
			end)

			new_cvimg:release_image()
			new_cvimg = nil

			x = x or 0
			y = y or 0

			call_ok, call_ret = pcall(function()
				return magck:composite(magck_overlay, x, y)
			end)
		end
		
		if magck then
			width = magck:get_width()
			height = magck:get_height()
			local new_cvimg = cv.create_image(width, height, 8, 4)
			call_ok, call_ret = pcall(function()
				return magck:export_image_pixels(0, 0, width, height, 'BGRA', 'CharPixel', new_cvimg:get_image_data())
			end)
			magck:destroy()
			magck = nil
			cvimg:release_image()
			cvimg = new_cvimg
		end

		if magck_overlay then
			magck_overlay:destroy()
			magck_overlay = nil
		end

		return call_ok, call_ret	
	end


	if not (count_style == 1 and style[1] and style[1]['t']) then
		local i
		for i = 1, count_style, 1 do
			local sty = style[i]
			process_img(sty)
		end
	end
	
	if f then
		local new_ext_name = (f == 'jpeg') and 'jpg' or f
		dst_path = old_dst_path .. '.' .. new_ext_name
		new_format = f
	end

	if q and new_format == 'jpeg' then
		pcall(function()
			cvimg:save_image(dst_path, {['JPEG_QUALITY'] = q})
		end)
	elseif (not q) and new_format == 'jpeg' then
		pcall(function()
			cvimg:save_image(dst_path, {['JPEG_QUALITY'] = 75})
		end)
	--[[
	elseif q and new_format == 'png' then
		q = (q > 9) and 9 or q
		pcall(function()
			cvimg:save_image(dst_path, {['PNG_COMPRESSION'] = q})
		end)
	elseif (not q) and new_format == 'png' then
		pcall(function()
			cvimg:save_image(dst_path, {['PNG_COMPRESSION'] = 9})
		end)
	--]]
	elseif q and new_format == 'webp' then
		pcall(function()
			cvimg:save_image(dst_path, {['WEBP_QUALITY'] = q})
		end)
	elseif (not q) and new_format == 'webp' then
		pcall(function()
			cvimg:save_image(dst_path, {['WEBP_QUALITY'] = 50})
		end)
	else
		pcall(function()
			cvimg:save_image(dst_path)
		end)
	end
	
	--[
	--local cvimg = cv.load_image(src_path, "UNCHANGED")
	--local cvimg1 = cvimg:pad(200, 200, "PAD_LIMIT", "GRAVITY_CENTER", {220, 220, 220, 220})
	--local cvimg1 = cvimg:round_corner(400)
	--cvimg1:save_image(dst_path, {['PNG_COMPRESSION'] = 9})

	

	cvimg:release_image()
	--cvimg1:release_image()
	--]]
	if unlock() then
		ngx.header["Content-Type"] = "image/" .. new_format
		ngx.header["ETag"] = ngx.ctx.etag
		ngx.exec(dst_path .. '?bucket=' .. ngx.ctx.bucket)
	end	
end


return _M
