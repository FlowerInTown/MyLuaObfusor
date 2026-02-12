# Quick Start Example

This example shows how to use the Lua obfuscator on a simple project.

## Step 1: Create Your Lua Project

Create a directory with some Lua files:

```
my_project/
├── main.lua
├── utils.lua
└── config/
    └── settings.lua
```

## Step 2: Create Configuration File

Create `config.lua` with your desired obfuscation settings:

```lua
{
    obfuscateLocals = true,
    encryptStrings = true,
    obfuscateGlobals = true
}
```

## Step 3: Run the Obfuscator

```bash
lua5.3 obfuscator.lua my_project my_project_obfuscated config.lua
```

This will create an obfuscated copy of your project in `my_project_obfuscated/`.

## Example: Before and After

**Original code (main.lua):**
```lua
-- Game initialization
local player = {
    health = 100,
    name = "Hero"
}

function startGame()
    print("Starting game with player: " .. player.name)
    return true
end

startGame()
```

**Obfuscated code:**
```lua
local _xYzAbCdEfG=(function()local _t={"Starting game with player: ","Hero"};return function(_i)return _t[_i]end end)()
-- Game initialization
local _hJkLmNoPq = {
    health = 100,
    name = _xYzAbCdEfG(2)
}

function _GstartGamefH()
    print(_xYzAbCdEfG(1) .. _hJkLmNoPq.name)
    return true
end

_GstartGamefH()
```

As you can see:
- Local variable `player` is now `_hJkLmNoPq`
- Global function `startGame` is now `_GstartGamefH`
- String literals are encrypted and replaced with function calls
- The code still works exactly the same!

## Customizing Obfuscation

You can enable/disable specific features in `config.lua`:

**Only obfuscate locals (keep strings and globals readable):**
```lua
{
    obfuscateLocals = true,
    encryptStrings = false,
    obfuscateGlobals = false
}
```

**Only encrypt strings (keep variable names readable for debugging):**
```lua
{
    obfuscateLocals = false,
    encryptStrings = true,
    obfuscateGlobals = false
}
```

## Tips

1. **Always test your obfuscated code** before deployment
2. **Keep the original source** - obfuscation is one-way
3. **Use version control** to track your original code
4. **Adjust configuration** based on your needs - sometimes partial obfuscation is better for debugging
