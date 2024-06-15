local function GetVenvName()
    local f = io.open("pyrightconfig.json", "r")
    if f == nil then
        return nil
    end
    local content = f:read("*all")
    f:close()
    local VenvName = string.match(content, '"venv": "(.-)"')
    return VenvName
end

local function activateVenv()
    local VenvName = GetVenvName()
    if VenvName ~= nil then
        -- notify silently
        vim.cmd("PyLspActivateCondaEnv " .. VenvName)
    end
end

local function initPythonFunction()
    vim.notify("Activating virtual enviroment!", "info", {title = "Conda Enviroment", timeout = 1000})
    activateVenv()
end

initPythonFunction()
