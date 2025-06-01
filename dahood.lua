local players = game:GetService("Players")
local runservice = game:GetService("RunService")
local camera = workspace.CurrentCamera
local localplayer = players.LocalPlayer
local playergui = localplayer:WaitForChild("PlayerGui")

if not playergui:FindFirstChild("gui") then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/RichidMonarch/monarch.cc/refs/heads/main/dahood.lua"))()
    return
end

local screengui = Instance.new("ScreenGui")
screengui.Name = "gui"
screengui.ResetOnSpawn = false
screengui.Parent = playergui

local togglebutton = Instance.new("TextButton")
togglebutton.Size = UDim2.new(0, 140, 0, 40)
togglebutton.Position = UDim2.new(0.5, -70, 0.5, -20)
togglebutton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
togglebutton.TextColor3 = Color3.fromRGB(0, 0, 0)
togglebutton.BorderSizePixel = 1
togglebutton.Transparency = 0.2
togglebutton.Font = Enum.Font.SourceSansBold
togglebutton.TextScaled = true
togglebutton.Text = "Aimlock"
togglebutton.TextStrokeTransparency = 0
togglebutton.TextStrokeColor3 = Color3.fromRGB(196, 115, 2)
togglebutton.BorderColor3 = Color3.fromRGB(196, 115, 2)
togglebutton.Active = true
togglebutton.Draggable = true
togglebutton.Parent = screengui

local aimbotenabled = false
local lockedtarget = nil

local function isinfirstperson()
    return (camera.Focus.Position - camera.CFrame.Position).Magnitude < 1
end

local function getclosesttocenter()
    local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    local closestplayer = nil
    local shortestdistance = math.huge
    for _, player in pairs(players:GetPlayers()) do
        if player ~= localplayer and player.Character and player.Character:FindFirstChild("Head") then
            local headpos = player.Character.Head.Position
            local screenpos, onscreen = camera:WorldToViewportPoint(headpos)
            if onscreen then
                local disttocenter = (Vector2.new(screenpos.X, screenpos.Y) - center).Magnitude
                if disttocenter < shortestdistance then
                    shortestdistance = disttocenter
                    closestplayer = player
                end
            end
        end
    end
    return closestplayer
end

local function notifytarget(target, locked)
    local text = (locked and "%s\n(@%s)" or "%s\n(@%s)"):format(target.DisplayName, target.Name)
    local icon = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. target.UserId .. "&width=420&height=420&format=png"
    game.StarterGui:SetCore("SendNotification", {
        Title = locked and "Locked" or "Unlocked",
        Text = text,
        Icon = icon,
        Duration = 3
    })
end

local function unlock()
    if aimbotenabled and lockedtarget then
        notifytarget(lockedtarget, false)
        lockedtarget = nil
        aimbotenabled = false
        togglebutton.Text = "Aimlock"
    end
end

togglebutton.MouseButton1Click:Connect(function()
    aimbotenabled = not aimbotenabled
    togglebutton.Text = aimbotenabled and "Unaimlock" or "Aimlock"
    if not aimbotenabled and lockedtarget then
        notifytarget(lockedtarget, false)
        lockedtarget = nil
    end
end)

runservice.RenderStepped:Connect(function()
    if not aimbotenabled or not isinfirstperson() then
        return
    end
    if not lockedtarget or not lockedtarget.Character or not lockedtarget.Character:FindFirstChild("Head") then
        lockedtarget = getclosesttocenter()
        if lockedtarget then
            notifytarget(lockedtarget, true)
        end
    end
    if lockedtarget and lockedtarget.Character and lockedtarget.Character:FindFirstChild("Head") then
        local headpos = lockedtarget.Character.Head.Position
        local targetcframe = CFrame.new(camera.CFrame.Position, headpos)
        camera.CFrame = camera.CFrame:Lerp(targetcframe, 1)
    end
end)

local function watchdeath()
    local character = localplayer.Character or localplayer.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid", 5)
    if humanoid then
        humanoid.Died:Connect(function()
            unlock()
            camera.CameraSubject = localplayer.Character:WaitForChild("Humanoid")
            camera.CameraType = Enum.CameraType.Custom
        end)
    end
end

players.PlayerRemoving:Connect(function(player)
    if player == lockedtarget then
        unlock()
    end
end)

localplayer.CharacterAdded:Connect(watchdeath)
watchdeath()
