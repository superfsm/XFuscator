require 'LuaMinify.ParseLua'
require 'LuaMinify.FormatMini'
require 'LAT'

XFuscator = { }
XFuscator.ExtractConstants = require'XFuscator.ConstantExtractor'
XFuscator.GenerateFluff = require'XFuscator.FluffGenerator'
XFuscator.Uglify = require'XFuscator.Uglifier'
XFuscator.Precompile = require'XFuscator.Precompile'
XFuscator.RandomComments = require'XFuscator.RandomComments'
XFuscator.EncryptStrings = require'XFuscator.StringEncryptor'
XFuscator.Step2 = require'XFuscator.Step2'
XFuscator.TamperDetection = require'XFuscator.TamperDetection'

local replaces = {
    a = "\a",
    b = "\b",
    f = "\f",
    n = "\n",
    r = "\r",
    t = "\t",
    v = "\v"
}

XFuscator.DumpString = function(x)
    return x
        :gsub( "\\(%D?)(%d?%d?%d?)", function( symbol, code )
            if symbol ~= "" then
                if symbol == "x" then
                    return string.char( tonumber( "0x" .. code ) )
                elseif symbol == "\\" then
                    return "\\"
                end

                local rep = replaces[ symbol ]
                if rep then
                    return rep
                end
            elseif code ~= "" then
                return string.char( tonumber( code ) )
            end

            return symbol .. code
        end )

        :gsub( ".", function( d )
            return "\\" .. d:byte()
        end )
end

local function obfuscate(code, level, mxLevel, useLoadstring, makeFluff, randomComments, step2, useUglifier, encryptConstants, useTD)
    if useLoadstring == nil then useLoadstring = true end
    level = level or 1
    mxLevel = mxLevel or 2
    if makeFluff == nil then makeFluff = true end
    if randomComments == nil then randomComments = true end
    if step2 == nil then step2 = true end
    if useUglifier == nil then useUglifier = false end
    if encryptConstants == nil then encryptConstants = false end
    if useTD == nil then useTD = true end
    
    local function GenerateFluff()
        if makeFluff then
            return XFuscator.GenerateFluff()
        end

        return ""
    end
    local dumpString = XFuscator.DumpString
    local concat = function(...) return table.concat({...}, "") end
    
    math.randomseed(os and os.time() or tick())
    
    print("Inital parsing ...")
    local str = ""
    local success, ast = ParseLua(code)
    if not success then
        error("Failed to parse code: " .. ast)
    end
    
    print("Extracting constants ...")
    XFuscator.ExtractConstants(code, ast)
    
    if encryptConstants then
        print("Encrypting constants ...")
        XFuscator.EncryptStrings(ast)
    end
    
    local a = Format_Mini(ast)
    if useUglifier then
        print("Uglifying ...")
        a = XFuscator.Uglify(a)
    end
    
    --if useTD then
    --    a = XFuscator.TamperDetection(a)
    --end
    
    success, ast = ParseLua(a)
    if not success then
        -- If it got this far, and then fails, there is a problem with XFuscator
        error("Failed to parse code (internal XFuscator error, please report along with stack trace and problematic code): " .. ast)
    end
    
    a = Format_Mini(ast) -- Extra security (renames code from 'tmp' and CONSTANT_POOL, and constant encryption)
    
    if useLoadstring then
        print("Precompiling ...")
        a = XFuscator.Precompile(a)
    end
    
    local a2
    if step2 == true then
        print("Step 2 ...")
        -- Convert to char/table/loadstring thing
        a2 = XFuscator.Step2(a, GenerateFluff, useTD) or a or ""
    elseif useLoadstring then
        a2 = "return loadstring('" .. dumpString(a) .. "')()"
    else
        a2 = a or ""
    end
    
    if randomComments then
        print("Inserting unreadable and pointless comments ...")
        a2 = XFuscator.RandomComments(a2) or a2 or a or ""
    end
    
    a2 = a2:gsub("\r+", " ")
    a2 = a2:gsub("\n+", " ")
    a2 = a2:gsub("\t+", " ")
    a2 = a2:gsub("[ ]+", " ")
    
    --a2 = a2 .. GenerateFluff() TODO
    if level < mxLevel then
        print(concat("OBFUSCATED AT LEVEL ", level, " OUT OF ", mxLevel, " (" .. a:len() .. " Obfuscated characters)"))
        return obfuscate(a2, level + 1, mxLevel)
    else
        print(concat("OBFUSCATED AT LEVEL ", level, " OUT OF ", mxLevel, " (", a:len(), " Obfuscated Characters) [Done]"))
        return a2
    end
end

function XFuscator.XFuscate(...)
    local s, code = pcall(obfuscate, ...)
    if not s then 
        return nil, code
    else
        return code
    end
end
