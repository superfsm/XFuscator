require'XFuscator.init'

return function( code )
    local options = { 
        fluff = true,
        loadstring = false,
        level = 1,
        mxLevel = 1,
        comments = false,
        step2 = false,
        uglify = true,
        encryptConstants = false,
        tamperDetection = true,
    }

    local result, msg = XFuscator.XFuscate(code, options.level, options.mxLevel, options.loadstring, options.fluff, options.comments, options.step2, options.uglify, options.encryptConstants, options.tamperDetection)


    if not result then
        return false, msg
    else
        local func, msg = loadstring(result)

        if func then
            return result, nil
        end

        return false, msg
    end
end