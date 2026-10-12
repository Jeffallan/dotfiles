local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

config.keys = {
  -- Omarchy's universal Cmd+C / Cmd+V send Ctrl+Insert / Shift+Insert to terminals.
  -- WezTerm maps those to the primary selection by default; use the clipboard.
  { key = "Insert", mods = "CTRL", action = act.CopyTo("Clipboard") },
  { key = "Insert", mods = "SHIFT", action = act.PasteFrom("Clipboard") },

  -- iTerm2-style panes. Hyprland turns Cmd+W into Ctrl+Shift+W, and Cmd+Shift+D and
  -- Cmd+Option+arrows into WezTerm's default split and pane keys (hypr/bindings.lua).
  -- Closing the last pane closes the tab.
  { key = "d", mods = "SUPER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "W", mods = "CTRL|SHIFT", action = act.CloseCurrentPane({ confirm = true }) },

  -- Cmd+I renames the current tab (iTerm2's Edit Session); an empty name resets it.
  {
    key = "i",
    mods = "SUPER",
    action = act.PromptInputLine({
      description = "Tab name",
      action = wezterm.action_callback(function(window, _, line)
        if line then
          window:active_tab():set_title(line)
        end
      end),
    }),
  },
}

return config
