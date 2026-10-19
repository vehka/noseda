local function default_steps() return {60, 64, 67, 72} end
local steps = default_steps()

local function install_pset_hooks()
  params.action_write = function(filename)
    local err = tab.save({schema = 1, steps = steps}, filename .. '.state')
    if err then print('state write failed: ' .. err) end
  end
  params.action_read = function(filename, silent)
    local ok, saved = pcall(tab.load, filename .. '.state')
    if ok and type(saved) == 'table' and saved.schema == 1
        and type(saved.steps) == 'table' then
      steps = saved.steps -- validate note ranges/shape for your instrument
    else
      steps = default_steps() -- deterministic behavior for absent/old data
      print('state missing or unsupported; using default steps')
    end
    -- Rebind sequins/playback data here; don't start transport on a read.
    -- Honor `silent` if this hook has audible or external side effects.
  end
  params.action_delete = function(filename)
    os.remove(filename .. '.state') -- only this PSET's owned sidecar
  end
end

return {install = install_pset_hooks, get = function() return steps end, set = function(v) steps = v end}
