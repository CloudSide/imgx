local table = require( "table" )
local string = require( "string" )

local base = _G
module( "strutil" )

function split( str, pat )

  local t = {}  -- NOTE: use {n = 0} in Lua-5.0
  local last_end, s, e = 1, 1, 0

  while s do
    s, e = string.find( str, pat, last_end )
    if s then
      table.insert( t, str:sub( last_end, s-1 ) )
      last_end = e + 1
    end
  end

  table.insert( t, str:sub( last_end ) )
  return t
end
