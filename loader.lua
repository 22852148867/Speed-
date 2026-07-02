local success, result = pcall(function()
    local url = "https://githubusercontent.com" .. math.random(1, 999999)
    loadstring(game:HttpGet(url))()
end)

if not success then
    warn("Error: " .. tostring(result))
end
