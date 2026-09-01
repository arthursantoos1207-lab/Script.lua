local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local button = Instance.new("TextButton")
button.Name = "TeleportButton"
button.Text = "Teleport to Empty Server"
button.Size = UDim2.new(0, 200, 0, 50)
button.Position = UDim2.new(0.5, -100, 0, 20)
button.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local function teleport()
    local placeId = game.PlaceId
    local response = HttpService:RequestAsync({
        Url = "https://presence.roblox.com/v1/presence/users?universeId="..placeId,
        Method = "GET"
    })
    if response.StatusCode == 200 then
        local data = HttpService:JSONDecode(response.Body)
        for _, v in pairs(data.userPresences) do
            if v.lastLocation then
                local server = HttpService:JSONDecode(v.lastLocation)
                if server.serverSize == 0 then
                    TeleportService:TeleportToPlaceInstance(placeId, server.serverId)
                    return
                end
            end
        end
    end
    warn("No empty server found.")
end

button.MouseButton1Click:Connect(teleport)
