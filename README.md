# MyLuaObfusor

A robust Lua obfuscator tool that provides various obfuscation techniques to protect Lua source code.

## Features

- **Local Variable/Function Obfuscation**: Replaces local variable and function names with meaningless random characters
- **String Encryption**: Replaces string literals with function calls that return the original strings, hiding plaintext from reverse engineers
- **Global Variable/Function Obfuscation**: Obfuscates all occurrences of the same global variable/function across multiple files consistently
- **Configuration-Based**: Flexible configuration file allows enabling/disabling different obfuscation features
- **Recursive Processing**: Automatically processes all Lua files in a directory tree
- **Structure Preservation**: Maintains original file names, paths, and directory structure

## Installation

Requirements:
- Lua 5.3 or later

No additional dependencies required - the obfuscator is self-contained.

## Usage

```bash
lua5.3 obfuscator.lua <input_path> <output_path> <config_path>
```

### Example

```bash
lua5.3 obfuscator.lua ./src ./obfuscated config.lua
```

This command will:
1. Recursively find all `.lua` files in `./src`
2. Apply obfuscation techniques based on `config.lua`
3. Write obfuscated files to `./obfuscated` maintaining the same directory structure

## Configuration

The configuration file (`config.lua`) allows you to enable or disable specific obfuscation features:

```lua
{
    -- Enable/disable local variable and function name obfuscation
    obfuscateLocals = true,
    
    -- Enable/disable string encryption
    -- Strings will be replaced with function calls that return the original string
    encryptStrings = true,
    
    -- Enable/disable global variable and function obfuscation
    -- All instances of the same global name will be obfuscated to the same new name
    obfuscateGlobals = true
}
```

## Obfuscation Techniques

### 1. Local Variable Obfuscation

Replaces local variable and function names with random strings:

**Before:**
```lua
local function calculateSum(a, b)
    local result = a + b
    return result
end
```

**After:**
```lua
local function _wImZdEgN(a, b)
    local _OSZrBcXJ = a + b
    return _OSZrBcXJ
end
```

### 2. String Encryption

Converts string literals into function calls:

**Before:**
```lua
print("Hello World")
local message = "Welcome"
```

**After:**
```lua
local _BzRlkDvGLI=(function()local _t={"Hello World","Welcome"};return function(_i)return _t[_i]end end)()
print(_BzRlkDvGLI(1))
local message = _BzRlkDvGLI(2)
```

### 3. Global Variable Obfuscation

Obfuscates global variables consistently across all files:

**Before (file1.lua):**
```lua
globalVar = "data"
function globalFunc()
    print(globalVar)
end
```

**Before (file2.lua):**
```lua
function useGlobal()
    return globalVar .. globalFunc()
end
```

**After:** All instances of `globalVar` and `globalFunc` are replaced with the same obfuscated names across both files.

## Implementation Details

- Uses Lua's pattern matching for robust code analysis
- Preserves Lua syntax and functionality
- Does not obfuscate Lua standard library functions (print, pairs, table, string, math, io, etc.)
- Handles edge cases like word boundaries to avoid partial replacements
- Error handling with detailed reporting of success/failure for each file

## Robustness

The obfuscator is designed for complex Lua projects:
- Pattern-based approach avoids complex AST parsing
- Handles various Lua syntax patterns
- Graceful error handling for individual files
- Maintains file structure integrity
- Preserves code functionality

## Example Output

```
Found 3 Lua files to obfuscate
Collecting global names across all files...
Found 8 global names to obfuscate
Processing: test_input/test1.lua
Processing: test_input/subdir/test3.lua
Processing: test_input/subdir/test2.lua

Obfuscation complete! Success: 3, Failed: 0
```

## License

Open source - feel free to use and modify.
