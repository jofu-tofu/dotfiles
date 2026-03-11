local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- On Windows there is no system login shell, so launch zsh explicitly.
-- Using -i (interactive) instead of -l (login) to avoid Git for Windows'
-- bash-specific /etc/profile.d scripts that break under zsh (shopt, etc.)
local is_windows = wezterm.target_triple:find('windows') ~= nil
if is_windows then
  config.default_prog = { 'C:\\Program Files\\Git\\usr\\bin\\zsh.exe', '-i' }
end

-- Keep more terminal history and make wheel scrolling move further per tick.
config.scrollback_lines = 50000
config.alternate_buffer_wheel_scroll_speed = 5

local act = wezterm.action

-- Kill a pane's entire process tree (Windows), then close it.
-- Prevents orphaned node.exe processes when closing REPL panes.
-- NOTE: Close the pane first so WezTerm detaches cleanly, then kill
-- orphaned processes afterward to avoid a race-condition crash.
local function close_pane_kill_tree(window, pane)
  local pids = {}
  if is_windows then
    local ok, proc = pcall(pane.get_foreground_process_info, pane)
    if ok and proc then
      -- Collect every PID in the tree (breadth-first)
      local queue = { proc }
      while #queue > 0 do
        local p = table.remove(queue, 1)
        table.insert(pids, p.pid)
        if p.children then
          for _, child in pairs(p.children) do
            table.insert(queue, child)
          end
        end
      end
    end
  end
  -- Close the pane first so WezTerm updates its internal state cleanly
  window:perform_action(act.CloseCurrentPane { confirm = false }, pane)
  -- Then kill any orphaned processes (leaf-first so children don't re-spawn)
  for i = #pids, 1, -1 do
    wezterm.run_child_process({ 'taskkill', '/F', '/PID', tostring(pids[i]) })
  end
end

-- Scroll 5 lines per wheel tick in normal scrollback
config.mouse_bindings = {
  {
    event = { Down = { streak = 1, button = { WheelUp = 1 } } },
    mods = 'NONE',
    action = act.ScrollByLine(-10),
  },
  {
    event = { Down = { streak = 1, button = { WheelDown = 1 } } },
    mods = 'NONE',
    action = act.ScrollByLine(10),
  },
}

-- Dim inactive panes so the active pane stands out
config.inactive_pane_hsb = {
  saturation = 0.7,
  brightness = 0.6,
}

config.keys = {
  { key = '\\', mods = 'CTRL', action = act.SplitHorizontal { domain = 'DefaultDomain' } },
  { key = '/', mods = 'CTRL', action = act.SplitVertical { domain = 'DefaultDomain' } },
  { key = 'Tab', mods = 'CTRL', action = act.ActivatePaneDirection 'Next' },
  { key = 'X', mods = 'CTRL|SHIFT', action = act.TogglePaneZoomState },
  { key = ',', mods = 'CTRL|SHIFT', action = act.ReloadConfiguration },
  -- Close pane with full process-tree cleanup (replaces default Ctrl+Shift+W)
  { key = 'w', mods = 'CTRL|SHIFT', action = wezterm.action_callback(close_pane_kill_tree) },
}

return config
