local http = require "http"
local cjson = require "cjson.safe"
local util = require "util"
local conf = require "config"
local command = require "command"
--local curl = require "lcurl"

local ALLOWED_SUB_RESOURCE = {
	["acl"] = true,
	["location"] = true,
	["torrent"] = true,
	["website"] = true,
	["logging"] = true,
	["relax"] = true,
	["meta"] = true,
	["uploads"] = true,
	["multipart"] = true,
	["part"] = true,
	["copy"] = true
}


local ALLOWED_SUB_RESOURCE_WITH_VALUE = {
	["uploadId"] = true,
	["ip"] = true,
	["partNumber"] = true
}

local _M = {
	_VERSION = '0.1.0',
}

local mt = { __index = _M }

function _M.new(self, accesskey, secretkey)
	--[[
	if not secretkey then
		secretkey = _M.get_secretkey(secretkey)
	end
	]]
	if not (accesskey and secretkey) then
		return nil
	end
	return setmetatable({ accesskey = accesskey, secretkey = secretkey }, mt)
end

function _M.get_secretkey(accesskey)
	if not accesskey then
		return nil
	end
	if accesskey == 'scs0000000000000none' then
		return 'scs0000000000000none'
	end
	local sk_info = ngx.shared.keychain:get(accesskey)
	--sk_info = nil
	if not sk_info then
		local httpc = http.new()
		local res, err = httpc:request_uri("http://a_private_ip/accesskey/get?accesskey=" .. accesskey)
		--httpc:close()
		if not res then
			--ngx.say("failed to request: ", err)
			return nil
		end
		if res.status == ngx.HTTP_OK then
			local info = cjson.decode(res.body)
			if	info
				and type(info) == "table"
				and info[1]
				and type(info[1]) == "table"
				and info[1]["secretkey"]
				and info[1]["username"]
				and tonumber(info[1]["is_del"]) == 0
				and info[1]["accesskey"]
			then
				ngx.shared.keychain:set(accesskey, res.body, 7200)
				return info[1]["secretkey"]
			end
		end
	else
		--ngx.say("缓存了")
		return cjson.decode(sk_info)[1]["secretkey"]
	end
	return nil
end

function _M.generate_authorization_string( self, method, bucketName, objectName, headers, subResource, expires )
	if not headers then
		headers = {}
	end
	local function get_canonical_amz_headers( headers )
		local amz_headers = {}
		local header, value
		for header, value in pairs(headers) do
			if header:match('^x%-amz%-') or header:match('^x%-sina%-') then
				table.insert(amz_headers, header)
			end
		end
		if #amz_headers == 0 then
			return ""
		else
			table.sort(amz_headers)
			local header_lines = {}
			local i
			for i = 1, #amz_headers do
				local header = amz_headers[i]
				header_lines[#header_lines + 1] = header:lower() .. ':' .. headers[header]
			end
			return table.concat(header_lines, "\n") .. "\n"
		end
	end

	local function get_canonical_sub_resource_string( sub_resource )
		local subResourceString = ""
		local sub_resource_with_values = {}
		if sub_resource and type(sub_resource) == "table" then
			local key, value
			for key, value in pairs(sub_resource) do
				if subResourceString == "" and ALLOWED_SUB_RESOURCE[key] then
					subResourceString = subResourceString .. key
				end
				if ALLOWED_SUB_RESOURCE_WITH_VALUE[key] then
					table.insert(sub_resource_with_values, key)
				end
			end
			if #sub_resource_with_values == 0 then
				return subResourceString
			else
				table.sort(sub_resource_with_values)
				local sub_resource_with_value_lines = {}
				local i
				for i = 1, #sub_resource_with_values do
					local key = sub_resource_with_values[i]
					sub_resource_with_value_lines[#sub_resource_with_value_lines + 1] = key .. '=' .. tostring(sub_resource[key])
				end
				if subResourceString == "" then
					subResourceString = table.concat(sub_resource_with_value_lines, "&")
				else
					subResourceString = subResourceString .. "&" .. table.concat(sub_resource_with_value_lines, "&")
				end
			end
		end
		--ngx.say(subResourceString)
		return subResourceString
	end

    local canonicalizedResourceString = "/"
	if bucketName then
		canonicalizedResourceString = canonicalizedResourceString .. bucketName .. "/"
		if objectName then
			canonicalizedResourceString = canonicalizedResourceString .. objectName
		end
	end

	local subResourceString = get_canonical_sub_resource_string(subResource)
	if subResourceString and subResourceString ~= "" then
		canonicalizedResourceString = canonicalizedResourceString .. "?" .. subResourceString
	end

    local canonicalizedString =
        method .. "\n"
        .. (headers["s-sina-sha1"] or headers["s-sina-md5"] or headers["Content-MD5"] or "") .. "\n"
        .. (headers["Content-Type"] or "") .. "\n"
        .. (expires or subResource["Expires"] or headers["Date"] or "") .. "\n"
        .. get_canonical_amz_headers(headers)
        .. canonicalizedResourceString
	--ngx.say(canonicalizedString)
	return ngx.encode_base64(ngx.hmac_sha1(self.secretkey, canonicalizedString))
		:sub(6, 15)
end

function _M.parse_accesskey_ssig()
	local auth_header = ngx.req.get_headers()["Authorization"]
	local kid = ngx.req.get_uri_args()["KID"]
	local ssig = ngx.req.get_uri_args()["ssig"]
	if (not auth_header) and (not kid) and (not ssig) then
		return 'scs0000000000000none', ''
		-- return 'scs0000000000000imgx', ''
	end
	local accesskey
	if kid then
		local m = ngx.re.match(kid, "^sina,(?<ak>\\w{1,20})$")
		if m and ssig and type(ssig) == "string" and string.len(ssig) == 10 then
			return m["ak"], ssig
		end
	elseif auth_header then
		local m = ngx.re.match(auth_header, "^SINA (?<ak>\\w{1,20}):(?<ssig>[^:^\\s]{10})$")
		if m then
			return m["ak"], m["ssig"]
		end
	end
	return nil, nil
end


function _M.auth_request()
	ngx.header["X-RequestId"] = ngx.var.requestid
	--if ngx.req.get_method() ~= "GET" and ngx.req.get_method() ~= "HEAD" and ngx.req.get_method() ~= "OPTIONS" then
	if ngx.req.get_method() ~= "GET" then
		return false, false, 'MethodNotAllowed'
	end

	local path_info, path_info_ok = util.parse_request_info()
	if not path_info_ok then
		return false, false, 'InvalidURI'
	end

	local c, err_msg = command.parse_cmd(path_info['cmd'])
	if not  c then
		return false, false, 'InvalidArgument', err_msg
	end
	path_info['style'] = c

	local accesskey, ssig = _M.parse_accesskey_ssig()
	if not (accesskey and ssig) then
		return false, false, 'InvalidArgument'
	end

	local expires = ngx.var.arg_Expires
	local ip = ngx.var.arg_ip
	local remote_addr = ngx.req.get_headers()["Cdn-Src-Ip"] or ngx.req.get_headers()["X-Forwarded-For"] or ngx.var.remote_addr
	if ip and not util.startswith(remote_addr, ip) then
		return false, false, 'AccessDenied'
	end
	if expires and not tonumber(expires) then
		return false, false, 'InvalidArgument'
	end
	if ngx.req.get_headers()["Date"] and not ngx.parse_http_time(ngx.req.get_headers()["Date"]) then
		return false, false, 'InvalidArgument'
	end
	if expires and tonumber(expires) < ngx.time() then
		return false, false, 'ExpiredToken'
	elseif ngx.req.get_headers()["Date"] and ngx.parse_http_time(ngx.req.get_headers()["Date"]) < ngx.time() then
		return false, false, 'ExpiredToken'
	end

	local secretkey = _M.get_secretkey(accesskey)
	if not secretkey then
		return false, false, 'InvalidAccessKeyId'
	end
	-- to ngx var
	ngx.var.scs_accesskey = accesskey
	ngx.var.scs_secretkey = secretkey
	local auth = _M:new(accesskey, secretkey)
	if accesskey == 'scs0000000000000imgx' and ssig == '' then
		return path_info, auth
	end
	if accesskey == 'scs0000000000000none' and ssig == '' then
		return path_info, auth
	end
	--[[
	local path_info, path_info_ok = util.parse_request_info()
	if not path_info_ok then
		return false, 'InvalidURI'
	end
	]]
	local c_ssig = auth:generate_authorization_string(ngx.req.get_method(), path_info["bucket"], path_info["cmd"] .. "/" .. path_info["key"], ngx.req.get_headers(), util.raw_query(), expires)
	--ngx.say(c_ssig)
	--if c_ssig == ssig or ssig == 'nbnbnbnbnb' then
	if c_ssig == ssig then
		return path_info, auth
	else
		return false, false, 'SignatureDoesNotMatch'
	end
	return false, false, 'InvalidRequest'
end

function _M.scs_proxy(self, bucket, key)
	local headers = {}
	if ngx.req.get_headers()["If-None-Match"] then
		headers["If-None-Match"] = ngx.req.get_headers()["If-None-Match"]
	end

	local res, err, httpc = self:scs_request(bucket, key, "GET", headers)
	if not res then
		util.release_http_connect(httpc)
		return false, 'InternalServerError'
	end

	if res.status ~= 200 and res.status ~= 304 then
		util.release_http_connect(httpc)
		return false, res.headers["x-error-code"]
	end

	--[[
	if res.status == 404 then
		if res.header["x-error-code"] == 'NoSuchKey' then
		-- TODO
		else
			util.release_http_connect(httpc)
			return false, res.headers["x-error-code"]
		end
	end
	]]

	local file_size = res.headers["Content-Length"] or res.headers["X-Filesize"]
	if res.headers and file_size and res.headers["Content-Type"] then
		if tonumber(file_size) > conf.get_conf("allowed_file_size_max") then
			util.release_http_connect(httpc)
			return false, 'EntityTooLarge'
		end

		if tonumber(file_size) <= 2 then
			util.release_http_connect(httpc)
			return false, 'EntityTooSmall'
		end

		if not conf.get_conf("allowed_file_mime_type")[res.headers["Content-Type"]] then
			util.release_http_connect(httpc)
			return false, 'InvalidFileType'
		end

		local meta = {}
		httpc:proxy_response(res, 1024*1024*10)
		util.release_http_connect(httpc)

		local header, value
		for header, value in pairs(res.headers) do
			if header:match('^x%-amz%-') or header:match('^x%-sina%-') then
				meta[header] = value
			end
		end
		meta["Content-Type"] = res.headers["Content-Type"]
		meta["Content-Length"] = file_size
		meta["Last-Modified"] = res.headers["Last-Modified"]
		meta["ETag"] = res.headers["ETag"]

		return meta, nil
		--end
		--local meta = cjson.decode(res.body)
		--if meta and meta["Size"] and meta["File-Meta"] and meta["File-Meta"]["Content-Type"] then
		--	if meta["Size"] > conf.get_conf("allowed_file_size_max") then
		--		return false, 'EntityTooLarge'
		--	end
		--	if meta["Size"] <= 4 then
		--		return false, 'EntityTooSmall'
		--	end
		--	--ngx.say(meta["File-Meta"])
		--	if not conf.get_conf("allowed_file_mime_type")[meta["File-Meta"]["Content-Type"]] then
		--		return false, 'InvalidFileType'
		--	end
		--	meta["Path-Info"] = path_info
		--	return meta, nil, auth
	else
		util.release_http_connect(httpc)
		return false, 'InternalServerError'
	end
end

local S3_DOMAIN_LIST = {
	'sinastorage.com',
	'intra-gz.sinastorage.com',
	'intra-tj.sinastorage.com',
	'intra-xd.sinastorage.com',
	'intra-yf.sinastorage.com',
}

function _M.scs_request(self, bucket, key, method, headers, sub_resource, body)
	local request_uri = "/"
	if bucket then
		request_uri = request_uri .. bucket
		if key then
			request_uri = request_uri .. "/" .. key
		end
	end
	if not sub_resource then
		sub_resource = {}
	end
	sub_resource["formatter"] = "json"
	request_uri = request_uri .. "?" .. ngx.encode_args(sub_resource)
	--ngx.say(request_uri)
	if not headers then
		headers = {}
	end
	if not method then
		method = "GET"
	end

	if self.accesskey ~= 'scs0000000000000none' then
		headers["Date"] = ngx.http_time(ngx.time() + 86400)
		local ssig = self:generate_authorization_string(method, bucket, key, headers, sub_resource)
		headers["Authorization"] = "SINA " .. self.accesskey .. ":" .. ssig
		headers["Host"] = "sinastorage.com"
		headers["User-Agent"] = "imgx/0.9.0-dev"
	else
		headers["Host"] = bucket
		request_uri = '/' .. key
	end
	--[[
	intra-gz.sinastorage.com
	intra-tj.sinastorage.com
	intra-xd.sinastorage.com
	]]
	--[[
	local args = {
		ip = "intra-gz.sinastorage.com",
		port = 80,
		url = request_uri,
		headers = headers
	}
	local resp, err_code, err = s2http.request(args)
	if err_code ~= nil then
        return nil, err_code .. ':' ..err
    end
	resp.body = '';
	local remain_length = tonumber(resp.headers['content-length'])
	while remain_length > 0 do
        if remain_length < READ_BUF_SIZE then
            size = remain_length
        else
            size = READ_BUF_SIZE
        end
        local buf, err_code, err = s2http.read_body(resp, size)
        if err_code ~= nil then
            return resp, err_code .. ':' ..err
        end
		resp.body = resp.body .. buf
        remain_length = remain_length - size
    end
	return resp, nil
	]]

	local httpc = http.new()
	httpc:set_timeout(60000)
	--httpc:set_timeout(1000*3600)

	local function try_request(ip)
		local conn_ok, conn_err = httpc:connect(ip, 80)
		if conn_ok then
			local res, err = httpc:request{
				method = method,
				path = request_uri,
				headers = headers,
				body = body or "",
			}
			return res, err, httpc
		else
			return nil, conn_err, httpc
		end
	end

	--[[
	math.randomseed(ngx.now())
	local domain_idx = math.random(1, #S3_DOMAIN_LIST)
	local ip_list = util.resolver_query(S3_DOMAIN_LIST[domain_idx])
	local idx = math.random(1, #ip_list)
	]]

	--[[ cloudmario
	local idx_domain, domain, idx_ip, ip_addr, ip_list
	for idx_domain, domain in ipairs(S3_DOMAIN_LIST) do
		ip_list = util.resolver_query(domain)
		for idx_ip, ip_addr in ipairs(ip_list) do
			repeat
				local res, err, httpc = try_request(ip_addr)
				if err ~= nil or res == nil then
					break
				end
				return res, err, httpc
			until true
		end
	end
	]]

	local idx_ip, ip_addr, ip_list
	ip_list = util.resolver_query(bucket)
	for idx_ip, ip_addr in ipairs(ip_list) do
		repeat
			local res, err, httpc = try_request(ip_addr)
			if err ~= nil or res == nil then
				break
			end
			return res, err, httpc
		until true
	end

	return nil, 'GatewayTimeout', httpc
	--[[
	if not res then
		return res, err
	end
	local reader = res.body_reader
	if not reader then
		return res, "no body to be read"
    end
	local chunks = {}
    local c = 1
    local chunk, err
	repeat
		chunk, err = reader(1024*1024*10)
		if err then
          return res, err
        end
		if chunk then
			chunks[c] = chunk
            c = c + 1
		end
	until not chunk
	local ok, err = httpc:set_keepalive()
	if not ok then
		--ngx_log(ngx_ERR, err)
		httpc:close()
	end
	res.body = table.concat(chunks)
	return res, err
	]]
	--httpc.keepalive = false
	--local res, err = httpc:request_uri("http://172.16.7.239" .. request_uri, {
	--[[
	local res, err = httpc:request_uri("http://intra-gz.sinastorage.com" .. request_uri, {
	--local res, err = httpc:request_uri("http://sinastorage.com" .. request_uri, {
		method = method,
		body = body or "",
		headers = headers
	})
	--httpc:close()
	return res, err
	]]
	--[[
	local header_lines = {}
	for header, value in pairs(headers) do
		header_lines[#header_lines + 1] = header .. ": " .. value
	end
	local res = {body = "", status = 200}
	local writefunction = function(str)
		res.body = res.body .. str
	end
	curl.easy()
		:setopt_url("http://intra-gz.sinastorage.com" .. request_uri)
		:setopt_httpheader(header_lines)
		:setopt_writefunction(writefunction)
		:perform()
	:close()
	return res, nil
	]]
end

return _M
