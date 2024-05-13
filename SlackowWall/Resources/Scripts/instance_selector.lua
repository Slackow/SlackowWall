
-- Don't touch this, configure in scripts window
path = "/tmp/slackowwall.txt"
sourceName = "minecraft"
obs = obslua



print("Hello world")

-- Description displayed in the Scripts dialog window
function script_description()
    print("in script_description")
    return [[Instance Selector
        Meant to work in conjunction with SlackowWall, changes a source named ']].. sourceName ..[[' to be the current instance you are playing on.]]
end

function readFile()
    -- Read the contents of the file
    local file = io.open(path, "r")
    if file == nil then
        return ":0"
    end
    local res = file:read("*all")
    file:close()
    return res
end
print("reading")
-- Global animation activity flag
last = readFile()

print("read: " .. last)
-- Callback for the hotkey
function on_run_hotkey(pressed)
     if (not pressed) then return end
    print("Run hotkey pressed " .. os.time())

    local attempts = 100
    -- Get the last modified time of the file
    while last == readFile() do
        attempts = attempts - 1
        if attempts < 0 then
            print("OOPSIE: " .. last)
            return
        end
        os.execute("sleep 0.003")
    end
    last = readFile()
    print("attempt " .. attempts .. " File contents: " .. last)
    print("Source " .. sourceName)
    modifySource(readNumber(last))
    switch_to_scene_with_source()
end

function modifySource(num)
        -- 1. Get the source object by its name
    local source_object = obs.obs_get_source_by_name(sourceName)
    local settings_object = obs.obs_source_get_settings(source_object)

    obs.obs_data_set_int(settings_object, "window", num)
    obs.obs_source_update(source_object, settings_object)

    -- Release the settings and source objects to free resources
    obs.obs_data_release(settings_object)
    obs.obs_source_release(source_object)

end


-- Function to check if a source exists in a scene
function source_in_scene(scene_object, target_source_name)
  local scene_enum = obs.obs_scene_enum_items(scene_object)
  local found = false

  for _, scene_item in ipairs(scene_enum) do
    local source = obs.obs_sceneitem_get_source(scene_item)
    local name = obs.obs_source_get_name(source)

    if name == target_source_name then
      found = true
      break
    end
  end

  return found
end

function switch_to_scene_with_source()
  -- Get the list of all scenes
  local scene_list = obs.obs_frontend_get_scenes()

  -- Loop through all scenes
  for i, scene in ipairs(scene_list) do
    local scene_object = obs.obs_scene_from_source(scene)

    if source_in_scene(scene_object, sourceName) then
      -- Switch to this scene
      obs.obs_frontend_set_current_scene(scene)
      break
    end

    obs.obs_source_release(scene)
  end
end



function readNumber(str)
    local lastColon = 0

    for i = #str, 1, -1 do
      if str:sub(i, i) == ":" then
        lastColon = i
        break
      end
    end

    local lastPart = str:sub(lastColon + 1)
    local num = tonumber(lastPart)

    if not num then
      num = 0
    end

    return num
end

-- Identifier of the hotkey set by OBS
hotkey_id = obs.OBS_INVALID_HOTKEY_ID
hotkey_id2 = obs.OBS_INVALID_HOTKEY_ID

-- Called at script load
function script_load(settings)
    hotkey_id = obs.obs_hotkey_register_frontend(script_path(), "Run Instance Hotkey", on_run_hotkey)
    local hotkey_save_array = obs.obs_data_get_array(settings, "run_hotkey")
    obs.obs_hotkey_load(hotkey_id, hotkey_save_array)
    obs.obs_data_array_release(hotkey_save_array)
end


function script_save(settings)
    local hotkey_save_array = obs.obs_hotkey_save(hotkey_id)
    obs.obs_data_set_array(settings, "run_hotkey", hotkey_save_array)
    obs.obs_data_array_release(hotkey_save_array)
end

function script_properties(settings)
    local props = obs.obs_properties_create()
    obs.obs_properties_add_text(props, "sourceName", "The source for your current Minecraft Instance,\nReload your scripts after editing this.\nDefaults to \"minecraft\"", obs.OBS_TEXT_DEFAULT)
    return props
end

function script_update(settings)
  local name = obs.obs_data_get_string(settings, "sourceName")
  if #name < 1 then
    name = "minecraft"
    obs.obs_data_set_string(settings, "sourceName", name)
  end
  sourceName = name
end