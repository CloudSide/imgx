local _Conf = require "config"
local luafs = require "libluafs"
local fs = require "fs"
local lock = require "resty.lock"
local resolver = require "resty.dns.resolver"
local cjson = require "cjson.safe"

local _M = {
	_VERSION = '0.1.0',
}

function _M.img_file_exist(fpath)
	if luafs.is_exist(fpath) then
		return true, fpath
	elseif luafs.is_exist(fpath .. '.png') then
		return true, fpath .. '.png'
	elseif luafs.is_exist(fpath .. '.jpg') then
		return true, fpath .. '.jpg'
	elseif luafs.is_exist(fpath .. '.jpeg') then
		return true, fpath .. '.jpeg'
	elseif luafs.is_exist(fpath .. '.webp') then
		return true, fpath .. '.webp'
	end
	return false
end

function _M.file_exist(fpath)
	return luafs.is_exist(fpath)
	--[[
	if luafs.is_exist(fpath) then
		return fpath
	elseif luafs.is_exist(fpath .. '.png') then
		return fpath .. '.png'
	elseif luafs.is_exist(fpath .. '.jpg') then
		return fpath .. '.jpg'
	elseif luafs.is_exist(fpath .. '.jpeg') then
		return fpath .. '.jpeg'
	elseif luafs.is_exist(fpath .. '.webp') then
		return fpath .. '.webp'
	end
	return false
	]]
end

function _M.split(str, pat)
    local t = {}
	if not (str and pat) then
		return t
	end
    local fpat = "(.-)" .. pat
    local last_end = 1
    local s, e, cap = str:find(fpat, 1)
    while s do
        table.insert(t,cap)
        last_end = e+1
        s, e, cap = str:find(fpat, last_end)
    end
    cap = str:sub(last_end)
    table.insert(t, cap)
    return t
end

function _M.startswith( s, pref ) 
    return string.sub( s, 1, string.len( pref ) ) == pref
end 

function _M.parse_query_string( str, decode )
    local rst = {}
    local i, s, pair, k, v
    local arr = _M.split( str, '&' )
    if decode == nil then
        decode = true
    end
    if str == nil then
        return rst
    end
    for i, s in ipairs( arr ) do
        pair = _M.split( s, '=' )
        k, v = pair[ 1 ], pair[ 2 ]
        k = ngx.unescape_uri( k )
        if v == nil then
            rst[ k ] = true
        else
            if decode then
                v = ngx.unescape_uri( v )
            end
            rst[ k ] = v
        end
    end
    return rst
end

function _M.raw_query()
	return _M.parse_query_string(ngx.var.query_string, false)
end

function _M.calc_ssig( sec, stringtosign )
    local s = ngx.encode_base64 (
            ngx.hmac_sha1( sec, stringtosign ) )
    return s:sub( 6, 15 )
end

function _M.convert_bin_to_hex(bytes)
    local b, i, str
    local hex = ''
    for i = 1, string.len(bytes) do
        b = string.byte(bytes, i, i)
        str = string.format("%02x", b)
        hex = hex .. str
    end
    return hex
end

function _M.convert_hex_to_rgba_color(hex_color)
	local rgba_color = {}
	local i
	for i = 1, #hex_color, 2 do
		table.insert(rgba_color, tonumber(hex_color:sub(i, i + 1), 16))
	end
	if #rgba_color == 4 then
		rgba_color[4] = rgba_color[4] / 100
		rgba_color[4] = rgba_color[4] > 1 and 1 or rgba_color[4]
	end
	return rgba_color
end

function _M.get_host_bucket(host)
	if not host then
		host = ngx.var.host
	end
	local super_hosts = _Conf.get_conf("super_hosts")
	local super_hosts_regex = {}
	local idx, value
	for idx, value in pairs(super_hosts) do
		super_hosts_regex[idx] = ngx.re.gsub(value, "\\.", "\\.")
	end
	local regex = "^((?<host_bucket>.+)\\.)?(" .. table.concat(super_hosts_regex, "|") .. ")$"
	local m, err = ngx.re.match(host, regex)	
	if m and m["host_bucket"] then
		return m["host_bucket"], true, false
	elseif m and not m["host_bucket"] then
		return nil, false, false
	elseif not m and ngx.re.match(host, "\\d+\\.\\d+\\.\\d+\\.\\d+") then
		return nil, false, false
	end
	return host, true, true
	-- return bucket, host_style, host_as_bucket
end

function _M.escape_key_path( key )
	return ngx.escape_uri(key)
		:gsub("%%2F", "/")
end

function _M.parse_request_info(raw_uri, host)

	if not raw_uri then
		raw_uri = ngx.var.raw_uri
	end
	local bucket, host_style, host_as_bucket = _M.get_host_bucket(host)
	local regex
	if not bucket then
		regex = "^/(?<bucket>[^/]+)/(?<cmd>[^/]+)/(?<key>.+)$"
	else
		regex = "^/(?<cmd>[^/]+)/(?<key>.+)$"
	end
	local m, err = ngx.re.match(raw_uri, regex)
	local info = {}
	if m then
		info["bucket"] = bucket or m["bucket"]
		info["cmd"] = m["cmd"]
		info["key"] = m["key"]
		info["host_style"] = host_style
		info["host_as_bucket"] = host_as_bucket
	end
	return info, info["bucket"] and info["cmd"] and info["key"]
	-- return info, parse_is_ok
end

function _M.get_http_response_body(response, chunksize, output)
    local reader = response.body_reader
    if not reader then
        ngx.log(ngx.ERR, "no response provided")
        return nil, "no body to be read"
    end
	local chunks = {}
    local c = 1
    local chunk, err
    repeat
        chunk, err = reader(chunksize)
        if err then
            ngx.log(ngx.ERR, err)
			return nil, err, table.concat(chunks)
		end
        if chunk then
			if output then
				ngx.print(chunk)
			else
				chunks[c] = chunk
			end
			c = c + 1
        end
    until not chunk
	if output then
		return c
	else
		return table.concat(chunks)
	end	
end

function _M.release_http_connect(httpc)
	--return httpc:close()
	--local ok, err = httpc:set_keepalive()
	--if not ok then
		--ngx.log(ngx.ERR, err)
		--httpc:close()
	--end
end

function _M.get_tmpfile_path(fpath)
	local tmp_path
	math.randomseed(ngx.now() * 1000)
    repeat
        tmp_path = fpath .. '_' .. tostring(os.time()) ..
                            '_' .. tostring(math.random(10000)) .. '.tmp'
    until not luafs.is_exist(tmp_path)
    return tmp_path
end

function _M.get_filename(path)
	local sub_paths = _M.split(path, '/')
	local filename = sub_paths[#sub_paths]
	local sub_names = _M.split(path, '%.')
	local ext_name = ''
	if #sub_names > 1 then
		ext_name = sub_names[#sub_names]
	end
	return filename, ext_name:lower() 
end

function _M.sha1_hex(str)
	return _M.convert_bin_to_hex(ngx.sha1_bin(str))
end

function _M.get_file_path(bucket, key, mkdir)
	
	local v = ngx.ctx.cmd_v and ngx.ctx.cmd_v or 0
	local sha1 = _M.sha1_hex(bucket .. '/' .. key .. '/' .. v)
	--ngx.log(ngx.ERR, bucket .. '/' .. key .. '/' .. v)
	local filename, ext_name = _M.get_filename(key)
	--filename = '1.' .. ext_name
	filename = sha1 .. '.' .. ext_name
	local file_path = ngx.var.scs_cache_path_prefix
	local relative_path = ''
	--[[
	for i = 1, #sha1, 2 do
		file_path =  file_path  .. sha1:sub(i, i + 1) .. '/'
		relative_path = relative_path .. sha1:sub(i, i + 1) .. '/'
		if mkdir then
			luafs.mkdir(file_path)
		end
	end
	--]]
	file_path = file_path .. bucket .. '/'
	relative_path = relative_path .. bucket .. '/'
	if mkdir then
		luafs.mkdir(file_path)
	end

	return file_path .. filename, sha1, relative_path .. filename
end

local FILE_EXPIRE_TIME = 3600 * 24 * 1
local MAX_POOL_SIZE = 1024 * 1024 * 64

function _M.clean_tmp_pool()
	local req_info = _M.parse_request_info()
	if not req_info['bucket'] then
		return
	end
	local bt = req_info['bucket']
	local lock = lock:new("clean_cache_locks", {exptime = 600, timeout = 0})
	local elapsed, err = lock:lock(bt)
	if not elapsed then
		--ngx.log(ngx.ERR, "--------- lock ---------")
		return
	end
	-------------------------------------------
	local run_clean = function()	
		local pool_path = ngx.var.scs_cache_path_prefix .. bt
		local files, err_code = fs.read_dir(pool_path)
		if err_code ~= nil then
			--ngx.log(ngx.ERR, string.format('clean_tmp_pool: %s read_dir fail, err_code:%s', pool_path, err_code))
			return false
		end
		
		local filename, extname
		local i, fn, fpath, info, err, expire_time
		local fns = {}
		local exps = {}
		local size = 0

		for i, fn in ipairs(files) do
			fpath = pool_path .. '/' .. fn
			filename, extname = _M.get_filename(fpath)
			if extname ~= 'tmp' then
				info, err = luafs.stat(fpath)
				if err ~= nil then
					ngx.log(ngx.ERR, string.format('clean_tmp_pool: %s stat fail, err:%s', fpath, err))
					os.remove(fpath)
				else
					expire_time = info.access + FILE_EXPIRE_TIME
					if expire_time < os.time() then
						os.remove(fpath)
					else
						table.insert(fns, fn)
						table.insert(exps, expire_time)
						size = size + info.size
					end
				end
			end
		end	

		local maxn = table.getn(exps)
		local j, k
		for j = 1, maxn, 1 do
			for k = j, maxn, 1 do
				if exps[j] < exps[k] then
					fns[j], fns[k] = fns[k], fns[j]
					exps[j], exps[k] = exps[k], exps[j]
				end
			end
		end

		while size > MAX_POOL_SIZE and table.getn(fns) ~= 0 do
			fpath = pool_path .. '/' .. table.remove(fns)
			info, err = luafs.stat(fpath)
			if err ~= nil then
				ngx.log(ngx.ERR, string.format('clean_tmp_pool: %s stat fail, err:%s', pool_path, err))
			else
				size = size - info.size
			end
			os.remove(fpath)
		end

		if table.getn(fns) == 0 then
			os.remove(pool_path)
		end

		return true
	end

	run_clean()

	-------------------------------------------
	local unlock_ok, unlock_err = lock:unlock()
	if not unlock_ok then
		ngx.log(ngx.ERR, unlock_err)
		return
	end
end

function _M.file_get_contents(fname)
	local f = io.open(fname, 'r')
	local string = f:read("*all")
	f:close()
	return string
end

function _M.resolver_query(domain)

	local json = ngx.shared.resolver_cache:get(domain)
	if json then
		local cache_data = cjson.decode(json)
		if cache_data then
			--ngx.say("from cache")
			return cache_data
		end
	end

	local r, err = resolver:new{
		nameservers = { "223.5.5.5", {"223.6.6.6", 53} },
		retrans = 5,	-- 5 retransmissions on receive timeout
		timeout = 2000,	-- 2 sec
    }

	local ip_list = {}

	if not r then
		--ngx.say("failed to instantiate the resolver: ", err)
		table.insert(ip_list, domain)
        return ip_list
    end

    local answers, err = r:query(domain)
    if not answers then
		--ngx.say("failed to query the DNS server: ", err)
		table.insert(ip_list, domain)
		return ip_list
    end
       
	if answers.errcode then
		--ngx.say("server returned error code: ", answers.errcode, ": ", answers.errstr)
		table.insert(ip_list, domain)
		return ip_list
	end

	for i, ans in ipairs(answers) do
		table.insert(ip_list, ans.address or ans.cname)
		--[[
		ngx.say(ans.name, " ", ans.address or ans.cname,
						  " type:", ans.type, " class:", ans.class,
                          " ttl:", ans.ttl)
		]]
	end

	ngx.shared.resolver_cache:set(domain, cjson.encode(ip_list), 3600)
	--ngx.say("no cache")

	return ip_list
end

return _M
