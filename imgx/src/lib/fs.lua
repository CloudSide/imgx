local libfs = require "libluafs"

local _M = {
	_VERSION = '0.1.0',
}

math.randomseed(ngx.now() * 1000)

function _M.read_dir( name )

    local ds, i, k
    local dirs = {}

    if not libfs.is_dir(name) then
        --_M.err(name .. " is not a dir")
        return nil, 'PathError'
    end

    ds = libfs.readdir( name )
    if ds == nil then
        _M.err("can't read " .. name .. " dir")
        return nil, 'SystemError'
    end

    for i = 0, ds.n do
        name = ds[i]
        if name ~= '.' and name ~= '..' then
            table.insert( dirs, name )
        end
    end

    return dirs, nil

end

function _M.is_dir(path)
    return libfs.is_dir(path)
end

function _M.is_file(path)
    return libfs.is_file(path)
end

function _M.get_sorted_unique_fns(origin_fns)
    local i, fn
    local prev_fn = nil
    local fns = {}

    table.sort(origin_fns)

    for i, fn in ipairs(origin_fns) do
        if prev_fn ~= fn then
            table.insert(fns, fn)
            prev_fn = fn
        end
    end

    return fns

end

function _M.err( msg )
    ngx.log( ngx.ERR, "fs: " .. msg .. "\n" )
end


function rm_file( path )
    local rst, err = os.remove( path )
    return rst, err
end


function mk_dir( path, mode )

    local rst, err_msg = libluafs.makedir( path, mode or 0755 )

    if not rst and not libluafs.is_dir( path ) then

        err_msg = string.format( 'make dir %s error:%s',
                path, err_msg )

        return 'FileError', err_msg
    end

    return nil, nil
end

function atomic_write( fpath, data, mode )
    local res
    local tmp_fpath
    local rst, err_code, err_msg

    tmp_fpath = fpath .. '._tmp_.'
            .. math.random(10000).. ngx.md5(data)

    rst, err_code, err_msg = write( tmp_fpath, data, mode )
    if err_code ~= nil then
        os.remove(tmp_fpath)
        return nil, err_code, err_msg
    end

    res, err_msg = os.rename( tmp_fpath, fpath )
    if err_msg ~= nil then
        os.remove(tmp_fpath)
        return nil, 'FileError', err_msg
    end

    return rst, nil, nil
end

function write( fpath, data, mode )
    local fp
    local rst
    local err_msg

    fp, err_msg = io.open( fpath, mode or 'w' )
    if fp == nil then
        return nil, 'FileError', err_msg
    end

    rst, err_msg = fp:write( data )
    if rst == nil then
        fp:close()
        return nil, 'FileError', err_msg
    end

    fp:close()

    return #data, nil, nil
end

function read( fpath, mode )
    local fp
    local data
    local err_msg

    fp, err_msg = io.open( fpath , mode or 'r' )
    if fp == nil then
        return nil, 'FileError', err_msg
    end

	--  '*a' means read the whole file
    data = fp:read( '*a' )
    fp:close()

    if data == nil then
        return nil, 'FileError',
            'read data error,file path:' .. fpath
    end

    return data, nil, nil
end

return _M
