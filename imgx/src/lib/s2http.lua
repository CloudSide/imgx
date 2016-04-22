local table = require("table")
local strutil = require( "strutil" )
local string = require( "string" )

local ngx = ngx
local base = _G

module("s2http")

-- current not support chunked encoding

-- for example:
-- local args = {ip= '127.0.0.1', port=80, url='/', method='GET', headers={}, body=''}
-- resp, err = request(args)
--
-- status = resp.status
-- headers = resp.headers
--
-- buf = read_body(resp, size)

local DEFAULT_ARGS = {
  ip = '127.0.0.1',
  port = 80,
  url = '/',
  method = 'GET',
  body = '',
  timeout = 60000,
}

local DEFAULT_HEADERS = {}

function request(args)

  local req_str
  local ret
  local err
  local sock

  merge_table(args, DEFAULT_ARGS)

  args.headers = args.headers or {}
  merge_table(args.headers, DEFAULT_HEADERS)
  args.headers.Host = args.headers.Host or args.ip

  sock= ngx.socket.tcp()
  sock:settimeout(args.timeout)

  ret, err = sock:connect(args.ip, args.port)
  if err ~= nil then
    return nil, 'SocketError', err
  end

  req_str = get_request_str(args.method, args.url, args.headers, args.body)

  ret, err = sock:send(req_str)
  if err ~= nil then
    return nil, 'SocketError', err
  end

  return get_respond(sock)

end

function read_body(resp, size)

  local ret, err

  ret, err =  resp.sock:receive(size)
  if err ~= nil then
    return nil, 'SocketError', err
  end

  return ret, nil, nil

end

function get_respond(sock)

  local status
  local err
  local line
  local elems
  local hname, hvalue
  local resp = {}
  local headers = {}

  line, err = sock:receive('*l')
  if err ~= nil then
    return nil, 'BadStatus', err
  end

  elems = strutil.split( line, ' ' )
  if table.getn(elems) < 3 then
    return nil, 'BadStatus', 'status line error, ' .. line
  end

  status = base.tonumber( elems[2] )
  if status == nil or status < 100 or status > 999 then
    return nil, 'BadStatus', 'status value is ' .. base.tostring(status)
  elseif status == 100 then
    return nil, 'BadStatus', 'not support continue status, value:100'
  end

  while true do

    line, err = sock:receive('*l')
    if err ~= nil then
      return nil, 'BadHeader', err
    elseif line == '' then
      break
    end

    elems = strutil.split( line, ': ' )
    if table.getn(elems) < 2 then
      return nil, 'BadHeader', 'header format error, ' .. line
    end

    hname = string.lower( trim( elems[1] ) )
    hvalue = trim( line:sub(string.len(hname) + 3) )

    headers[hname] = hvalue

  end

  if headers['transfer-encoding'] == 'chunked' then
    return nil, 'BadHeader', 'not support header chunked encoding'
  end

  resp['status'] = status
  resp['headers'] = headers
  resp['sock'] = sock

  return resp, nil, nil

end

function get_request_str(method, url, headers, body)

  local req_str
  local h, v

  req_str = string.format( '%s %s HTTP/1.0\r\n', method, url)

  for h, v in base.pairs(headers) do
    req_str = req_str .. string.format( '%s: %s\r\n', h, v)
  end

  req_str = req_str .. '\r\n' .. body

  return req_str

end

function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function merge_table(dst_table, src_table)
  for k, v in base.pairs(src_table) do
    if dst_table[k] == nil then
      dst_table[k] = v
    end
  end
end
