local util = require "util"
local auth = require "auth"
local stoerr = require "stoerr"
local cjson = require "cjson.safe"
local magick = require "magick"
local http = require "http"
local command = require "command"
local luafs = require "libluafs"
local fs = require "fs"
local lock = require "resty.lock"
local conf = require "config"

local path_info, au, err_code, err_msg = auth.auth_request()
if not path_info then
	stoerr.err_exit(err_code, err_msg)
end

ngx.ctx.au = au
ngx.ctx.bucket = path_info["bucket"]

ngx.var.scs_bucket = path_info["bucket"]
ngx.var.scs_key = path_info["key"]
ngx.var.scs_cmd = path_info["cmd"]
ngx.var.scs_style = cjson.encode(path_info['style'])

command.parse_trans(path_info['style'])

--[[
local function _process(blob)
	local img = magick.load_image_from_blob(blob)
	local src_w, src_h = img:get_width(), img:get_height()
	img:set_quality(65)
	img:resize_and_crop(100, 100)
	local blob = img:get_blob()
	img:destroy()
	ngx.print(blob)
end
--]]

local function get_tmpfile_path(fpath)
    return util.get_tmpfile_path(fpath)
end

local function get_file_path(bucket, key, mkdir)
	return util.get_file_path(bucket, key, mkdir)
end


local function download_file_atomic(bucket, key)
	bucket = bucket or path_info["bucket"]
	key = key or path_info["key"]
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
		if tonumber(file_size) > conf.get_conf("allowed_file_size_max") then
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

	local fpath, sha1 = get_file_path(bucket, key, true)
	local tmpath = get_tmpfile_path(fpath)

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
	--[[
	--if content_type == 'image/gif' then
	if true then
		local mgk = magick.load_image(tmpath)
		if not mgk then
			os.remove(tmpath)
			return false, 'InvalidFileType'
		end
		local format = mgk:get_format():lower()
		--ngx.say(format)
		--ngx.exit(ngx.HTTP_OK)
		--if (not mgk) or mgk:get_width() < 1 or mgk:get_height() < 1 or mgk:get_format() ~= 'gif' then
		if mgk:get_width() < 1 or mgk:get_height() < 1 or (not conf.get_conf("allowed_file_type")[format]) then
			os.remove(tmpath)
			mgk:destroy()
			return false, 'InvalidFileType'
		end

		if format == 'gif' then
			mgk:set_first_iterator()
			mgk:set_format('jpeg')
			local m_ok = mgk:write(fpath .. '.jpg')
			if not m_ok then
				mgk:destroy()
				os.remove(tmpath)
				return false, 'InternalServerError'
			else
				os.remove(tmpath)
			end
		else
			local rename_ok, rename_err, rename_err_num = os.rename(tmpath, fpath)
			if err ~= nil  then
				ngx.log(ngx.ERR, string.format('rename %s to %s fail, err:%s', tmpath, fpath, rename_err))
				os.remove(tmpath)
				return false, 'InternalServerError'
			end
		end

		mgk:destroy()

	else
		local rename_ok, rename_err, rename_err_num = os.rename(tmpath, fpath)
		if err ~= nil  then
			ngx.log(ngx.ERR, string.format('rename %s to %s fail, err:%s', tmpath, fpath, rename_err))
			os.remove(tmpath)
			return false, 'InternalServerError'
		end
	end
	--]]

	--[
	local rename_ok, rename_err, rename_err_num = os.rename(tmpath, fpath)
	if err ~= nil  then
		ngx.log(ngx.ERR, string.format('rename %s to %s fail, err:%s', tmpath, fpath, rename_err))
		os.remove(tmpath)
		return false, 'InternalServerError'
	end
	--]]

	return true
end


local function try_file(bucket, key)
	bucket = bucket or path_info["bucket"]
	key = key or path_info["key"]
	local fpath, sha1, relative_path = get_file_path(bucket, key)
	if not util.file_exist(fpath) then
		local lock = lock:new("processing_locks", {exptime = 300, timeout = 300})
		local elapsed, err = lock:lock(sha1)
		--ngx.log(ngx.alert, "lock --------------------")
		if not elapsed then
			ngx.log(ngx.ERR, err)
			stoerr.err_exit('InternalError')
			return false
		end
		if util.file_exist(fpath) then
			local unlock_ok, err = lock:unlock()
			if not unlock_ok then
				ngx.log(ngx.ERR, err)
				stoerr.err_exit('InternalError')
				return false
			end
			--ngx.log(ngx.alert, "unlock 1 --------------------")
			--ngx.exec('/cache_file/' .. relative_path)
			return true, fpath
		end

		local ok, err = download_file_atomic(bucket, key)
		local unlock_ok, unlock_err = lock:unlock()
        if not unlock_ok then
			ngx.log(ngx.ERR, unlock_err)
			stoerr.err_exit('InternalError')
			return false
        end
		if ok then
			return true, fpath
		else
			if err == 'NoSuchKey' then
				return false, nil, 'NoSuchKey'
			else
				stoerr.err_exit(err)
				return false
			end
		end
		--ngx.log(ngx.alert, "unlock 2 --------------------")
	else
		--ngx.say('/cache_file/' .. relative_path)
		--return
		--ngx.exec('/cache_file/' .. relative_path)
		return true, fpath
	end
end


local function processing()
	local ok, fpath, err = try_file()
	if (not ok) and err then
		stoerr.err_exit(err)
		return false
	end
	--ngx.exec(fpath)
	local dst_path, sha1 = get_file_path(path_info["bucket"], path_info["cmd"] .. '/' .. path_info["key"], true)
	command.processing(path_info["style"], fpath, dst_path)
end

--[[
local function scs_proxy()
	local meta, err = au:scs_proxy(path_info["bucket"], path_info["cmd"] .. '/' .. path_info["key"])
	if not meta then
		if err == 'NoSuchKey' then
			--ngx.exec('/index.php?' .. ngx.var.query_string)
			--ngx.exec('/index.php?' .. 'ak=' .. au.accesskey .. '&sk=' .. au.secretkey .. '&bucket=' .. path_info["bucket"] .. '&key=' .. path_info["key"])
			--processing()
			--try_file(path_info["bucket"], path_info["cmd"] .. '/' .. path_info["key"])
			--try_file()
			processing()
		else
			stoerr.err_exit(err)
		end
	else
		for key, val in pairs(path_info) do
			meta[key] = val
		end
		ngx.exit(ngx.http_ok)
	end
end
]]

local function scs_proxy()
	--local ok, fpath, err = try_file(path_info["bucket"], path_info["cmd"] .. '/' .. path_info["key"])
	--if (not ok) and err and err == 'NoSuchKey' then
	local fpath, sha1 = get_file_path(path_info["bucket"], path_info["cmd"] .. '/' .. path_info["key"])
	ngx.ctx.etag = '"' .. sha1 .. '"'
	local etag = ngx.req.get_headers()["If-None-Match"] or ngx.req.get_headers()["if-none-match"]

	-- --
	if etag and etag == ngx.ctx.etag then
		ngx.header["X-Imgx-HitInfo"] = 'TCP_HIT'
		ngx.var.hitinfo = ngx.header["X-Imgx-HitInfo"]
		ngx.exit(ngx.HTTP_NOT_MODIFIED)
	end
	-- --

	local exist, path = util.img_file_exist(fpath)
	if not exist then
		ngx.header["X-Imgx-HitInfo"] = 'TCP_MISS'
		ngx.var.hitinfo = ngx.header["X-Imgx-HitInfo"]
		processing()
	else
		-- local etag = ngx.req.get_headers()["If-None-Match"] or ngx.req.get_headers()["if-none-match"]
		if etag and etag == ngx.ctx.etag then
			ngx.header["X-Imgx-HitInfo"] = 'TCP_HIT'
			ngx.var.hitinfo = ngx.header["X-Imgx-HitInfo"]
			ngx.exit(ngx.HTTP_NOT_MODIFIED)
		else
			ngx.header["X-Imgx-HitInfo"] = 'TCP_REFERSH_HIT'
			ngx.var.hitinfo = ngx.header["X-Imgx-HitInfo"]
		end

		local fn, en = util.get_filename(path)
		ngx.header["Content-Type"] = conf.get_conf("allowed_file_type")[en]
		ngx.header["ETag"] = ngx.ctx.etag
		ngx.exec(path .. '?bucket=' .. path_info["bucket"])
	end
end

scs_proxy()
