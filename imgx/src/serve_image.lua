
-- "/images/abcd/10x10/hello.png"

local sig, size, path, ext =
  ngx.var.sig, ngx.var.size, ngx.var.path, ngx.var.ext

local secret = "hello_world" -- signature secret key
local images_dir = "images/" -- where images come from
local cache_dir = "cache/" -- where images are cached

local function return_not_found(msg)
  ngx.status = ngx.HTTP_NOT_FOUND
  ngx.header["Content-type"] = "text/html"
  ngx.say(msg or "not found")
  ngx.exit(0)
end

local function calculate_signature(str)
  return ngx.encode_base64(ngx.hmac_sha1(secret, str))
    :gsub("[+/=]", {["+"] = "-", ["/"] = "_", ["="] = ","})
    :sub(1,12)
end

--[[
if calculate_signature(size .. "/" .. path) ~= sig then
  return_not_found("invalid signature")
end
]]


ngx.header["Content-type"] = "text/html"

ngx.say(ngx.req.get_method())

for k,v in pairs(ngx.var) do
  ngx.say(k .. ":" .. v .. "<br>")
end

--ngx.say(tostring(ngx.var))

--[[
local http = require("http")
local httpc = http.new()
local res, err = httpc:request_uri("http://172.16.235.251/yun/%E6%BC%94%E7%A4%BA%E7%85%A7%E7%89%87.jpg", {
  method = "GET",
  headers = {
    ["Host"] = "sinacloud.net",
  } 
})

if not res then
  ngx.say("failed to request: ", err)
  return
end

ngx.status = res.status
--ngx.header = res.headers

for k,v in pairs(res.headers) do
  --ngx.say(k .. ":" .. v .. "<br>")
  ngx.header[k] = v
end

ngx.say(res.body)

]]
--[[

local source_fname = images_dir .. path

-- make sure the file exists
local file = io.open(source_fname)

if not file then
  return_not_found()
end

file:close()

local etag = ngx.md5(size .. "/" .. path)
local dest_fname = cache_dir .. etag .. "." .. ext

-- resize the image
local magick = require("magick")
--magick.thumb(source_fname, size, dest_fname)
local blob = magick.thumb(source_fname, size)
local img = assert(magick.load_image_from_blob(blob))
--print("width:", img:get_width(), "height:", img:get_height());
--img:sharpen(8, 10)
img:set_quality(10)
--img:sharpen(10, 10)
img:edge(2.5)
--img:shadow(80,1,5,5)
img:rotate(-30)
img:set_format('webp')
blob = img:get_blob()
img:destroy()

---ngx.header["Content-type"] = "text/html"
ngx.header["Content-type"] = "image/webp"
--ngx.header["Etag"] = "\"" .. etag .. "\""
ngx.header["Server"] = "SinaImgix/0.1.0"
ngx.say(blob)
--ngx.exec(ngx.var.request_uri)



]]--
