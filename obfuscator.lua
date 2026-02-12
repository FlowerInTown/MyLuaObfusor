#!/usr/bin/env lua5.3
-- Simple Lua Obfuscator
-- Uses pattern matching for obfuscation

local Obfuscator = {}

-- Load configuration from file (Lua table format)
function Obfuscator.loadConfig(configPath)
    local file = io.open(configPath, "r")
    if not file then
        error("Cannot open config file: " .. configPath)
    end
    
    local content = file:read("*all")
    file:close()
    
    -- Load as Lua file
    local chunk, err = load("return " .. content)
    if not chunk then
        error("Failed to parse config: " .. tostring(err))
    end
    
    return chunk()
end

-- Get all Lua files recursively from a directory
function Obfuscator.getLuaFiles(path)
    local fileList = {}
    
    -- Validate path - only allow alphanumeric, dash, underscore, slash, and dot
    if not path:match("^[%w%-%._/]+$") then
        error("Invalid path: contains potentially dangerous characters")
    end
    
    -- Use find command to locate all .lua files
    local cmd = string.format("find '%s' -name '*.lua' 2>/dev/null", path:gsub("'", "'\\''"))
    local handle = io.popen(cmd)
    
    if handle then
        for file in handle:lines() do
            table.insert(fileList, file)
        end
        handle:close()
    end
    
    return fileList
end

-- Generate random name
local function generateRandomName(length)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local name = "_"
    length = length or 12
    
    for i = 1, length do
        local idx = math.random(1, #chars)
        name = name .. chars:sub(idx, idx)
    end
    
    return name
end

math.randomseed(os.time())

-- Lua keywords that should never be obfuscated
local luaKeywords = {
    ["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true,
    ["elseif"] = true, ["end"] = true, ["false"] = true, ["for"] = true,
    ["function"] = true, ["goto"] = true, ["if"] = true, ["in"] = true,
    ["local"] = true, ["nil"] = true, ["not"] = true, ["or"] = true,
    ["repeat"] = true, ["return"] = true, ["then"] = true, ["true"] = true,
    ["until"] = true, ["while"] = true
}

-- Obfuscate local variables in code
function Obfuscator.obfuscateLocals(code)
    local mappings = {}
    
    -- Find all local variable declarations (with assignment)
    for localVars in code:gmatch("local%s+([%w_,%s]+)%s*=") do
        -- Split by comma to handle multiple declarations
        for varName in localVars:gmatch("([%w_]+)") do
            -- Don't create mappings for Lua keywords
            if not luaKeywords[varName] then
                if not mappings[varName] then
                    mappings[varName] = generateRandomName(8)
                end
            end
        end
    end
    
    -- Find local variables without assignment (e.g., local x, y)
    for localVars in code:gmatch("local%s+([%w_,%s]+)%s*[;\n]") do
        for varName in localVars:gmatch("([%w_]+)") do
            if not luaKeywords[varName] then
                if not mappings[varName] then
                    mappings[varName] = generateRandomName(8)
                end
            end
        end
    end
    
    -- Also find local functions
    for funcName in code:gmatch("local%s+function%s+([%w_]+)") do
        if not luaKeywords[funcName] then
            if not mappings[funcName] then
                mappings[funcName] = generateRandomName(8)
            end
        end
    end
    
    -- Replace all occurrences (simple word boundary replacement)
    for original, obfuscated in pairs(mappings) do
        -- Escape special pattern characters in the original name
        local escapedOriginal = original:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
        
        -- Use word boundaries to avoid partial replacements
        code = code:gsub("([^%w_])" .. escapedOriginal .. "([^%w_])", "%1" .. obfuscated .. "%2")
        -- Handle start of string
        code = code:gsub("^" .. escapedOriginal .. "([^%w_])", obfuscated .. "%1")
        -- Handle start of lines
        code = code:gsub("\n" .. escapedOriginal .. "([^%w_])", "\n" .. obfuscated .. "%1")
        -- Handle end of string
        code = code:gsub("([^%w_])" .. escapedOriginal .. "$", "%1" .. obfuscated)
        -- Handle end of lines
        code = code:gsub("([^%w_])" .. escapedOriginal .. "\n", "%1" .. obfuscated .. "\n")
    end
    
    return code, mappings
end

-- Encrypt strings in code
function Obfuscator.encryptStrings(code)
    local strings = {}
    local stringMap = {}
    local stringIndex = 0
    
    -- Collect all string literals (both single and double quotes)
    for str in code:gmatch('"([^"]*)"') do
        if not stringMap['"' .. str .. '"'] then
            stringIndex = stringIndex + 1
            stringMap['"' .. str .. '"'] = stringIndex
            table.insert(strings, '"' .. str .. '"')
        end
    end
    
    for str in code:gmatch("'([^']*)'") do
        if not stringMap["'" .. str .. "'"] then
            stringIndex = stringIndex + 1
            stringMap["'" .. str .. "'"] = stringIndex
            table.insert(strings, "'" .. str .. "'")
        end
    end
    
    if #strings == 0 then
        return code
    end
    
    -- Generate decryption function name
    local decryptFuncName = generateRandomName(10)
    
    -- Build decryption function
    local decryptFunc = string.format("local %s=(function()local _t={", decryptFuncName)
    for i, str in ipairs(strings) do
        if i > 1 then
            decryptFunc = decryptFunc .. ","
        end
        decryptFunc = decryptFunc .. str
    end
    decryptFunc = decryptFunc .. "};return function(_i)return _t[_i]end end)()\n"
    
    -- Replace strings with function calls
    for strLiteral, idx in pairs(stringMap) do
        local replacement = string.format("%s(%d)", decryptFuncName, idx)
        -- Escape special pattern characters in both pattern and replacement
        local escaped = strLiteral:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
        -- Use a function to avoid interpreting captures in replacement
        code = code:gsub(escaped, function() return replacement end)
    end
    
    -- Prepend decryption function
    code = decryptFunc .. code
    
    return code
end

-- Collect global names from all files
function Obfuscator.collectGlobals(files)
    local globals = {}
    
    for _, filePath in ipairs(files) do
        local file = io.open(filePath, "r")
        if file then
            local code = file:read("*all")
            file:close()
            
            -- Find function declarations (global functions)
            for funcName in code:gmatch("function%s+([%w_]+)%s*%(") do
                -- Skip if it's a local function
                local escapedFuncName = funcName:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
                local localCheck = code:match("local%s+function%s+" .. escapedFuncName)
                if not localCheck then
                    globals[funcName] = true
                end
            end
            
            -- Find assignments to potential globals (simplified detection)
            -- Only match at start of line to avoid table keys
            for varName in code:gmatch("^([%w_]+)%s*=") do
                globals[varName] = true
            end
            for varName in code:gmatch("\n([%w_]+)%s*=") do
                globals[varName] = true
            end
        end
    end
    
    -- Remove Lua standard library globals
    local reserved = {
        print = true, pairs = true, ipairs = true, type = true,
        tonumber = true, tostring = true, table = true, string = true,
        math = true, io = true, os = true, debug = true, require = true,
        module = true, package = true, _G = true, _VERSION = true,
        assert = true, error = true, pcall = true, xpcall = true,
        load = true, loadfile = true, dofile = true, rawget = true,
        rawset = true, rawequal = true, next = true, select = true,
        getmetatable = true, setmetatable = true, collectgarbage = true,
        coroutine = true, utf8 = true, bit32 = true
    }
    
    for name in pairs(reserved) do
        globals[name] = nil
    end
    
    return globals
end

-- Obfuscate global variables
function Obfuscator.obfuscateGlobals(code, globalMappings)
    for original, obfuscated in pairs(globalMappings) do
        -- Escape special pattern characters in the original name
        local escapedOriginal = original:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
        
        -- Use word boundaries to avoid partial replacements
        code = code:gsub("([^%w_])" .. escapedOriginal .. "([^%w_])", "%1" .. obfuscated .. "%2")
        -- Handle start of string
        code = code:gsub("^" .. escapedOriginal .. "([^%w_])", obfuscated .. "%1")
        -- Handle start of lines
        code = code:gsub("\n" .. escapedOriginal .. "([^%w_])", "\n" .. obfuscated .. "%1")
        -- Handle end of string
        code = code:gsub("([^%w_])" .. escapedOriginal .. "$", "%1" .. obfuscated)
        -- Handle end of lines
        code = code:gsub("([^%w_])" .. escapedOriginal .. "\n", "%1" .. obfuscated .. "\n")
    end
    
    return code
end

-- Main obfuscation function
function Obfuscator.obfuscate(inputPath, outputPath, configPath)
    -- Load configuration
    local config = Obfuscator.loadConfig(configPath)
    
    -- Normalize paths
    inputPath = inputPath:gsub("/$", "")
    outputPath = outputPath:gsub("/$", "")
    
    -- Get all Lua files
    local luaFiles = Obfuscator.getLuaFiles(inputPath)
    
    print(string.format("Found %d Lua files to obfuscate", #luaFiles))
    
    -- First pass: collect global names if needed
    local globalMappings = {}
    
    if config.obfuscateGlobals then
        print("Collecting global names across all files...")
        local globals = Obfuscator.collectGlobals(luaFiles)
        
        -- Generate mappings for globals
        for name in pairs(globals) do
            globalMappings[name] = "_G" .. generateRandomName(10)
        end
        
        local count = 0
        for _ in pairs(globalMappings) do count = count + 1 end
        print(string.format("Found %d global names to obfuscate", count))
    end
    
    -- Second pass: obfuscate each file
    local successCount = 0
    local failCount = 0
    
    for _, filePath in ipairs(luaFiles) do
        print("Processing: " .. filePath)
        
        local file = io.open(filePath, "r")
        if not file then
            print("Error: Cannot read " .. filePath)
            failCount = failCount + 1
            goto continue
        end
        
        local code = file:read("*all")
        file:close()
        
        -- Apply transformations based on config
        local success, result = pcall(function()
            local obfuscatedCode = code
            
            if config.obfuscateLocals then
                obfuscatedCode = Obfuscator.obfuscateLocals(obfuscatedCode)
            end
            
            if config.encryptStrings then
                obfuscatedCode = Obfuscator.encryptStrings(obfuscatedCode)
            end
            
            if config.obfuscateGlobals then
                obfuscatedCode = Obfuscator.obfuscateGlobals(obfuscatedCode, globalMappings)
            end
            
            return obfuscatedCode
        end)
        
        if not success then
            print("Error processing " .. filePath .. ": " .. tostring(result))
            failCount = failCount + 1
            goto continue
        end
        
        local obfuscatedCode = result
        
        -- Calculate output path maintaining directory structure
        local relativePath = filePath
        if filePath:sub(1, #inputPath) == inputPath then
            relativePath = filePath:sub(#inputPath + 2)
        end
        local outputFilePath = outputPath .. "/" .. relativePath
        
        -- Ensure output directory exists
        local outputDir = outputFilePath:match("^(.*/)[^/]+$")
        if outputDir then
            -- Validate directory path before using in shell command
            if outputDir:match("^[%w%-%._/]+$") then
                os.execute("mkdir -p '" .. outputDir:gsub("'", "'\\''") .. "'")
            else
                print("Error: Invalid output directory path: " .. outputDir)
                failCount = failCount + 1
                goto continue
            end
        end
        
        -- Write obfuscated code
        local outFile = io.open(outputFilePath, "w")
        if not outFile then
            print("Error: Cannot write to " .. outputFilePath)
            failCount = failCount + 1
            goto continue
        end
        
        outFile:write(obfuscatedCode)
        outFile:close()
        
        successCount = successCount + 1
        
        ::continue::
    end
    
    print(string.format("\nObfuscation complete! Success: %d, Failed: %d", successCount, failCount))
end

-- Command line interface
if arg and arg[0] and arg[0]:match("obfuscator%.lua$") then
    if #arg < 3 then
        print("Usage: lua5.3 obfuscator.lua <input_path> <output_path> <config_path>")
        print("Example: lua5.3 obfuscator.lua ./src ./obfuscated config.lua")
        os.exit(1)
    end
    
    local inputPath = arg[1]
    local outputPath = arg[2]
    local configPath = arg[3]
    
    Obfuscator.obfuscate(inputPath, outputPath, configPath)
end

return Obfuscator
