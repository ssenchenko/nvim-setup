local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

-- Pick the Catppuccin flavor (and matching tab-bar palette) from the OS appearance.
-- get_appearance() returns "Light", "Dark", "LightHighContrast", or "DarkHighContrast".
local function palette_for_appearance(appearance)
  if appearance:find("Dark") then
    -- Catppuccin Macchiato
    return {
      scheme = "Catppuccin Macchiato",
      crust = "#181926", mantle = "#1e2030", base = "#24273a",
      surface0 = "#363a4f", surface1 = "#494d64",
      text = "#cad3f5", subtext0 = "#a5adcb",
      accent = "#c6a6f5", -- mauve
    }
  else
    -- Catppuccin Latte
    return {
      scheme = "Catppuccin Latte",
      crust = "#dce0e8", mantle = "#e6e9ef", base = "#eff1f5",
      surface0 = "#ccd0da", surface1 = "#bcc0cc",
      text = "#4c4f69", subtext0 = "#6c6f85",
      accent = "#8839ef", -- mauve
    }
  end
end

-- WezTerm re-evaluates this file when the OS switches light/dark,
-- so both the scheme and the tab-bar theme follow the system automatically.
local pal = palette_for_appearance(wezterm.gui.get_appearance())
config.color_scheme = pal.scheme

-- Font (the NF build bundles the icon glyphs so oil.nvim etc. render correctly).
-- Installed by `make font` (brew cask font-cascadia-code-nf).
local font_family = "Cascadia Code NF"
config.font = wezterm.font(font_family)
config.font_size = 13.0

-- macOS renders WezTerm's default (grayscale) antialiasing quite thin.
-- LCD/subpixel rendering fills glyphs out so text isn't so spindly.
config.freetype_load_target = "Light"
config.freetype_render_target = "HorizontalLcd"

-- Initial window size (in character cells, not pixels)
config.initial_cols = 190
config.initial_rows = 60

-- Tab bar
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = true

-- The bell is used as a "command finished" signal (see ~/.zshrc), so mute the
-- audible beep; WezTerm turns it into a desktop toast via the handler below.
config.audible_bell = "Disabled"

-- Larger font for the tab header (the fancy tab bar has its own font settings)
config.window_frame = {
  font = wezterm.font(font_family, { weight = "Bold" }),
  font_size = 14.0,
  active_titlebar_bg = pal.mantle,
  inactive_titlebar_bg = pal.crust,
}

-- Catppuccin-themed tab colors (follow light/dark via `pal`)
config.colors = {
  tab_bar = {
    background = pal.crust,
    active_tab = { bg_color = pal.accent, fg_color = pal.base, intensity = "Bold" },
    inactive_tab = { bg_color = pal.surface0, fg_color = pal.subtext0 },
    inactive_tab_hover = { bg_color = pal.surface1, fg_color = pal.text, italic = true },
    new_tab = { bg_color = pal.surface0, fg_color = pal.subtext0 },
    new_tab_hover = { bg_color = pal.surface1, fg_color = pal.text },
  },
}

config.keys = {
  -- Tabs
  { key = "t", mods = "CMD",       action = act.SpawnTab("CurrentPaneDomain") },
  { key = "w", mods = "CMD",       action = act.CloseCurrentTab({ confirm = false }) },
--  { key = "LeftArrow", mods = "CMD|SHIFT", action = act.ActivateTabRelative(-1) },
--  { key = "RightArrow", mods = "CMD|SHIFT", action = act.ActivateTabRelative(1) },

  -- Splits (panes)
  { key = "d", mods = "CMD",       action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) }, -- left/right
  { key = "d", mods = "CMD|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },   -- top/bottom
  { key = "x", mods = "CMD",       action = act.CloseCurrentPane({ confirm = false }) },

  -- Move between panes with Cmd + arrows
  { key = "LeftArrow",  mods = "CMD|SHIFT", action = act.ActivatePaneDirection("Left") },
  { key = "RightArrow", mods = "CMD|SHIFT", action = act.ActivatePaneDirection("Right") },
  { key = "UpArrow",    mods = "CMD|SHIFT", action = act.ActivatePaneDirection("Up") },
  { key = "DownArrow",  mods = "CMD|SHIFT", action = act.ActivatePaneDirection("Down") },

  -- macOS-style line navigation: Cmd+Left/Right = start/end of line (Home/End)
  { key = "LeftArrow",  mods = "CMD", action = act.SendKey({ key = "Home" }) },
  { key = "RightArrow", mods = "CMD", action = act.SendKey({ key = "End" }) },
}

-- Cmd+1..9 jump to tab N
for i = 1, 9 do
  table.insert(config.keys, { key = tostring(i), mods = "CMD", action = act.ActivateTab(i - 1) })
end

-- Tabs that finished a background task while unfocused, flashed until viewed.
local attention = {}
local blink_on = false
config.status_update_interval = 500 -- ms; drives the tab flash + repaints
wezterm.on("update-status", function()
  blink_on = not blink_on
end)

-- Tab title = current working directory (folder name) instead of the shell/process.
-- Requires the shell to report its cwd via OSC 7 (set up in ~/.zshrc).
local function basename(path)
  return (path:gsub("[/\\]+$", ""):match("([^/\\]+)$")) or path
end

wezterm.on("format-tab-title", function(tab, tabs, panes, cfg, hover, max_width)
  -- Honor an explicitly set title (e.g. from `tab:set_title`).
  local explicit = tab.tab_title
  if explicit and #explicit > 0 then
    return " " .. explicit .. " "
  end

  local pane = tab.active_pane
  local cwd_uri = pane.current_working_dir
  local label
  if cwd_uri then
    -- Newer WezTerm exposes a Url object; older versions a plain string.
    local path = type(cwd_uri) == "userdata" and cwd_uri.file_path
      or (tostring(cwd_uri):gsub("^file://[^/]*", ""))
    if path == os.getenv("HOME") then
      label = "~"
    else
      label = basename(path)
    end
  else
    label = pane.title
  end
  label = label or "shell"

  -- Flash the tab if it finished a background task; clear once you view it.
  if tab.is_active then
    attention[tab.tab_id] = nil
  elseif attention[tab.tab_id] then
    return {
      { Background = { Color = blink_on and pal.accent or pal.surface1 } },
      { Foreground = { Color = blink_on and pal.base or pal.text } },
      { Attribute = { Intensity = "Bold" } },
      { Text = " ⚑ " .. label .. " " },
    }
  end

  return " " .. label .. " "
end)

-- Desktop notification when a task finishes in a pane you're NOT looking at.
-- The shell rings the bell after a long-running command (~/.zshrc); we raise a
-- toast only if that pane isn't the focused/active one.
wezterm.on("bell", function(window, pane)
  local active = window:active_pane()
  local viewing_this_pane = active ~= nil and active:pane_id() == pane:pane_id()
  if viewing_this_pane and window:is_focused() then
    return -- you're already watching this pane; no toast needed
  end

  -- Exit status reported by the shell via a user var (see ~/.zshrc).
  local status = pane:get_user_vars().cmd_status
  local ok = (status == nil) or (status == "0")
  local headline = ok and "✅ Task finished"
    or ("❌ Task failed (exit " .. tostring(status) .. ")")

  -- Working directory of the pane that rang (HOME shown as ~).
  local dir = "shell"
  local cwd_uri = pane:get_current_working_dir()
  if cwd_uri then
    local path = type(cwd_uri) == "userdata" and cwd_uri.file_path
      or (tostring(cwd_uri):gsub("^file://[^/]*", ""))
    local home = os.getenv("HOME")
    if home and path:sub(1, #home) == home then
      path = "~" .. path:sub(#home + 1)
    end
    dir = path
  end

  window:toast_notification("WezTerm", headline .. "  •  " .. dir, nil, 6000)

  -- Flash the tab that rang until you switch to it.
  local mux_win = window:mux_window()
  if mux_win then
    for _, tab in ipairs(mux_win:tabs()) do
      for _, p in ipairs(tab:panes()) do
        if p:pane_id() == pane:pane_id() then
          attention[tab:tab_id()] = true
        end
      end
    end
  end
end)

return config
