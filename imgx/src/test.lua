local req_method, bucket, cmd, key, args, req_headers =
	ngx.req.get_method(), ngx.var.bucket, ngx.var.cmd, ngx.var.key, ngx.req.get_uri_args(), ngx.req.get_headers()

local SCS_ACCESS_KEY_ID = "re5k9pAuLShG6tVcXOFr"
local SCS_SECRET_ACCESS_KEY = "80ee7216002fdc5efe980508c05ace2e807b4383"
local expires_time = ngx.http_time(9999999999)

lrucache:set("foo", "1111")
ngx.say(lrucache:get("foo"))
ngx.exit(0)

--[[
ngx.say("req_method: " .. req_method)
ngx.say("bucket: " .. bucket)
ngx.say("key: " .. key)
ngx.say("cmd: " .. cmd)

for key, val in pairs(args) do
	if type(val) == "table" then
		ngx.say(key, ": ", table.concat(val, ", "))
	else
		ngx.say(key, ": ", val)
	end
end
]]


local key_escape = ngx.escape_uri(key)
	:gsub("%%2F", "/")
local s3_uri = "http://sinacloud.net/" .. bucket .. "/" .. key_escape .. "?formatter=json"
--172.16.235.251
--ngx.say(s3_uri)
--ngx.exit(0)

local canonicalizedHeaderString =
  req_method .. "\n"
  .. "\n" -- (headers["Content-MD5"] or "")
  .. "\n" -- (headers["Content-Type"] or "")
  .. expires_time .. "\n" -- (headers["Date"] or "")
  .. "/" .. bucket .. "/" .. key_escape

local digest = ngx.hmac_sha1(SCS_SECRET_ACCESS_KEY, canonicalizedHeaderString)
local base64_string = ngx.encode_base64(digest)
local ssig = base64_string
	:sub(6, 15)

--ngx.say(ssig)
--ngx.exit(0)

local http = require("http")
local httpc = http.new()
local res, err = httpc:request_uri(s3_uri, {
	method = "GET",
	headers = {
		--["Host"] = "sinacloud.net",
		["Authorization"] = "SINA " .. SCS_ACCESS_KEY_ID .. ":" .. ssig,
		["Date"] = expires_time,
		["If-None-Match"] = (req_headers["If-None-Match"] or ""), 
	} 
})

if not res then
  ngx.say("failed to request: ", err)
  return
end

--ngx.status = res.status

for k,v in pairs(res.headers) do
--  ngx.header[k] = v
end


local magick = require("magick")
--local blob = magick.thumb(source_fname, "300x")
--local img = assert(magick.load_image_from_blob(res.body))
local img = magick.load_image_from_blob(res.body)

if img == nil then
	ngx.exec("/images/wow.png")
	ngx.exit(0)	
end



img:set_quality(10)
img:resize(200, 150)
--img:sharpen(10, 10)
--img:edge(2.5)
--img:shadow(80, 1, 5, 5)
img:rotate(-30)
--img:set_format('webp')
blob = img:get_blob()

ngx.header["Content-type"] = "image/" .. img:get_format()
ngx.header["Server"] = "SinaImgix/0.1.0"

img:destroy()

ngx.print(blob)

--ngx.say(res.body)
--ngx.exit(0)

--[[
local reader = res.body_reader

repeat
	local chunk, err = reader(8192)
	if err then
		ngx.log(ngx.ERR, err)
		break
	end

	if chunk then
		--ngx.say(chunk)
		--ngx.flush()
	end
until not chunk
]]
--ngx.say(res.body)


