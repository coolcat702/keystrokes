# Keystrokes

A plugin to show your keystrokes in 200 lines of code

## Installation

With lazy.nvim:

```lua

{
    "coolcat702/keystrokes",
    event = "VimEnter",
    opts = {}, -- your config here
    config = function(_, opts)
        require("keystrokes").setup(opts)
    end
}
```

## Usage

`KeystrokesOpen` to open plugin window

`KeystrokesClose` to close plugin window

`KeystrokesToggle` to toggle plugin window

## Config

This is the default config:

```lua
opts = {
    timeout = 2000,
    key_amount = 6,
    excluded_modes = {},
    style = "rounded",
    special_formats = {
        ["<BS>"] = "󰁮 ",
        ["<CR>"] = "󰌑 ",
        ["<Esc>"] = "󰿅 ",
        ["<Space>"] = "󱁐",
        ["<Tab>"] = "",
        ["<Up>"] = "",
        ["<Down>"] = "",
        ["<Left>"] = "",
        ["<Right>"] = "",
        ["<M>"] = "󰘵 ",
        ["<C>"] = "",
        ["<S>"] = "󰘶",
    },
    repeat_show = function(amt, key)
        return amt .. "(" .. key .. ")"
    end,
}
```
