-- Vertex Auto Farm: Vertex UI + nearest coin farming logic
-- Intended for use in your own Roblox experience / authorized test environment.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local COIN_STOP_LIMIT = 50
local CoinsCollected = 0
local FarmStopped = false
local NoclipConnection
local activeTween

if CoreGui:FindFirstChild("VertexFarmUI") then
    CoreGui.VertexFarmUI:Destroy()
end

_G.ActiveCoinFarm = false
_G.FarmSpeedValue = _G.FarmSpeedValue or 40

-- Find the same collection remote used by the original farm script.
local GetCoinRemote = ReplicatedStorage:FindFirstChild("GetCoin", true)
if not GetCoinRemote then
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local gameplay = remotes and remotes:FindFirstChild("Gameplay")
    GetCoinRemote = gameplay and gameplay:FindFirstChild("CoinCollected")
end

local function create(className, properties, parent)
    local object = Instance.new(className)
    for property, value in pairs(properties) do
        object[property] = value
    end
    object.Parent = parent
    return object
end

local function corner(parent, radius)
    create("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local ScreenGui = create("ScreenGui", {
    Name = "VertexFarmUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, CoreGui)

local Main = create("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(580, 380),
    Position = UDim2.new(0.5, -290, 0.5, -190),
    BackgroundColor3 = Color3.fromRGB(14, 14, 15),
    BorderSizePixel = 0,
    Active = true
}, ScreenGui)
corner(Main, 12)

local TopBar = create("Frame", {
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = Color3.fromRGB(17, 17, 18),
    BorderSizePixel = 0
}, Main)

local function dot(color, x)
    local circle = create("Frame", {
        Size = UDim2.fromOffset(8, 8),
        Position = UDim2.fromOffset(x, 11),
        BackgroundColor3 = color,
        BorderSizePixel = 0
    }, TopBar)
    corner(circle, 10)
end

dot(Color3.fromRGB(255, 90, 90), 13)
dot(Color3.fromRGB(255, 190, 65), 26)
dot(Color3.fromRGB(65, 65, 65), 39)

create("TextLabel", {
    Position = UDim2.fromOffset(22, 38),
    Size = UDim2.fromOffset(145, 25),
    BackgroundTransparency = 1,
    Text = "vertex",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = Color3.fromRGB(225, 225, 225),
    TextXAlignment = Enum.TextXAlignment.Left
}, Main)

create("TextLabel", {
    Position = UDim2.fromOffset(22, 62),
    Size = UDim2.fromOffset(155, 18),
    BackgroundTransparency = 1,
    Text = "Auto Farm",
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextColor3 = Color3.fromRGB(110, 110, 115),
    TextXAlignment = Enum.TextXAlignment.Left
}, Main)

local Sidebar = create("Frame", {
    Position = UDim2.fromOffset(0, 30),
    Size = UDim2.new(0, 170, 1, -30),
    BackgroundColor3 = Color3.fromRGB(15, 15, 16),
    BorderSizePixel = 0
}, Main)

create("Frame", {
    Position = UDim2.new(0, 170, 0, 30),
    Size = UDim2.new(0, 1, 1, -30),
    BackgroundColor3 = Color3.fromRGB(43, 43, 44),
    BorderSizePixel = 0
}, Main)

local Nav = create("TextButton", {
    Position = UDim2.fromOffset(10, 83),
    Size = UDim2.fromOffset(150, 32),
    BackgroundColor3 = Color3.fromRGB(29, 29, 31),
    BorderSizePixel = 0,
    Text = "   ◉    Main",
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextColor3 = Color3.fromRGB(230, 230, 230),
    TextXAlignment = Enum.TextXAlignment.Left,
    AutoButtonColor = false
}, Sidebar)
corner(Nav, 8)

create("TextLabel", {
    Position = UDim2.new(0, 18, 1, -43),
    Size = UDim2.new(1, -25, 0, 30),
    BackgroundTransparency = 1,
    Text = LocalPlayer.DisplayName .. "\n@" .. LocalPlayer.Name,
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextColor3 = Color3.fromRGB(215, 215, 215),
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center
}, Sidebar)

local Content = create("Frame", {
    Position = UDim2.fromOffset(171, 30),
    Size = UDim2.new(1, -171, 1, -30),
    BackgroundTransparency = 1
}, Main)

create("TextLabel", {
    Position = UDim2.fromOffset(35, 17),
    Size = UDim2.new(1, -50, 0, 24),
    BackgroundTransparency = 1,
    Text = "Main",
    Font = Enum.Font.Gotham,
    TextSize = 13,
    TextColor3 = Color3.fromRGB(175, 175, 180),
    TextXAlignment = Enum.TextXAlignment.Left
}, Content)

local Panel = create("Frame", {
    Position = UDim2.fromOffset(28, 45),
    Size = UDim2.new(1, -55, 0, 255),
    BackgroundColor3 = Color3.fromRGB(17, 17, 18),
    BorderColor3 = Color3.fromRGB(37, 37, 39),
    BorderSizePixel = 1
}, Content)
corner(Panel, 10)

local function label(text, position, size)
    return create("TextLabel", {
        Position = position,
        Size = size,
        BackgroundTransparency = 1,
        Text = text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(165, 165, 170),
        TextXAlignment = Enum.TextXAlignment.Left
    }, Panel)
end

label("Auto Farm", UDim2.fromOffset(20, 24), UDim2.fromOffset(180, 22))

local Toggle = create("TextButton", {
    Position = UDim2.new(1, -59, 0, 28),
    Size = UDim2.fromOffset(40, 21),
    BackgroundColor3 = Color3.fromRGB(60, 60, 62),
    BorderSizePixel = 0,
    Text = "",
    AutoButtonColor = false
}, Panel)
corner(Toggle, 15)

local Knob = create("Frame", {
    Position = UDim2.fromOffset(3, 3),
    Size = UDim2.fromOffset(15, 15),
    BackgroundColor3 = Color3.fromRGB(175, 175, 175),
    BorderSizePixel = 0
}, Toggle)
corner(Knob, 15)

label("Glide Speed", UDim2.fromOffset(20, 88), UDim2.fromOffset(180, 20))
local SpeedValue = label(tostring(_G.FarmSpeedValue), UDim2.new(1, -55, 0, 88), UDim2.fromOffset(35, 20))
SpeedValue.TextXAlignment = Enum.TextXAlignment.Right

local Slider = create("TextButton", {
    Position = UDim2.fromOffset(20, 121),
    Size = UDim2.new(1, -40, 0, 6),
    BackgroundColor3 = Color3.fromRGB(48, 48, 50),
    BorderSizePixel = 0,
    Text = "",
    AutoButtonColor = false
}, Panel)
corner(Slider, 5)

local function speedPercent()
    return math.clamp((_G.FarmSpeedValue - 15) / 85, 0, 1)
end

local Fill = create("Frame", {
    Size = UDim2.new(speedPercent(), 0, 1, 0),
    BackgroundColor3 = Color3.fromRGB(220, 220, 225),
    BorderSizePixel = 0
}, Slider)
corner(Fill, 5)

local SliderKnob = create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(speedPercent(), 0, 0.5, 0),
    Size = UDim2.fromOffset(14, 14),
    BackgroundColor3 = Color3.fromRGB(245, 245, 245),
    BorderSizePixel = 0
}, Slider)
corner(SliderKnob, 10)

local function updateSlider(inputX)
    local percent = math.clamp(
        (inputX - Slider.AbsolutePosition.X) / Slider.AbsoluteSize.X,
        0, 1
    )
    _G.FarmSpeedValue = math.floor(15 + percent * 85)
    Fill.Size = UDim2.new(percent, 0, 1, 0)
    SliderKnob.Position = UDim2.new(percent, 0, 0.5, 0)
    SpeedValue.Text = tostring(_G.FarmSpeedValue)
end

local draggingSlider = false
Slider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSlider = true
        updateSlider(input.Position.X)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
        updateSlider(input.Position.X)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSlider = false
    end
end)

-- Noclip, matching the original farm's behavior.
local function EnableNoclip()
    if NoclipConnection then
        NoclipConnection:Disconnect()
    end
    NoclipConnection = RunService.Stepped:Connect(function()
        local character = LocalPlayer.Character
        if character and _G.ActiveCoinFarm then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function DisableNoclip()
    if NoclipConnection then
        NoclipConnection:Disconnect()
        NoclipConnection = nil
    end
end

local function updateToggle()
    if _G.ActiveCoinFarm and not FarmStopped then
        Toggle.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
        Knob.Position = UDim2.new(1, -18, 0, 3)
        Knob.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    else
        Toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 62)
        Knob.Position = UDim2.fromOffset(3, 3)
        Knob.BackgroundColor3 = Color3.fromRGB(175, 175, 175)
    end
end

local function StopCoinFarm(reason)
    if FarmStopped then return end
    FarmStopped = true
    _G.ActiveCoinFarm = false
    if activeTween then
        activeTween:Cancel()
        activeTween = nil
    end
    DisableNoclip()
    updateToggle()
    warn("[Vertex Coin Farm] " .. reason)
end

local function MonitorCharacter(character)
    local humanoid = character:WaitForChild("Humanoid", 10)
    if humanoid then
        humanoid.Died:Connect(function()
            StopCoinFarm("Character died")
        end)
    end
end

LocalPlayer.CharacterAdded:Connect(MonitorCharacter)
if LocalPlayer.Character then
    task.spawn(MonitorCharacter, LocalPlayer.Character)
end

Toggle.MouseButton1Click:Connect(function()
    if FarmStopped then return end
    _G.ActiveCoinFarm = not _G.ActiveCoinFarm
    if _G.ActiveCoinFarm then
        EnableNoclip()
    else
        DisableNoclip()
        if activeTween then
            activeTween:Cancel()
            activeTween = nil
        end
    end
    updateToggle()
end)

-- Drag the window from the top bar.
local draggingWindow = false
local dragStart
local startPosition
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingWindow = true
        dragStart = input.Position
        startPosition = Main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingWindow and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingWindow = false
    end
end)

-- Nearest coin targeting from the original farm script.
local function smoothGlideTo(targetPart)
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root or not targetPart or not targetPart.Parent then
        return false
    end

    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero

    local targetCFrame = targetPart.CFrame * CFrame.new(0, 1.5, 0)
    local distance = (root.Position - targetCFrame.Position).Magnitude
    local duration = distance / math.max(_G.FarmSpeedValue, 1)

    activeTween = TweenService:Create(
        root,
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { CFrame = targetCFrame }
    )
    activeTween:Play()
    local playbackState = activeTween.Completed:Wait()
    activeTween = nil

    if playbackState ~= Enum.PlaybackState.Completed then
        return false
    end
    root.AssemblyLinearVelocity = Vector3.zero
    return targetPart.Parent ~= nil
end

local function getLiveCoinContainer()
    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("Model")
            and not Players:GetPlayerFromCharacter(child)
            and child.Name ~= "Lobby" then
            local container = child:FindFirstChild("CoinContainer")
            if container then
                return container
            end
        end
    end
    return nil
end

local function getClosestCoin(rootPart, container)
    local closestItem
    local shortestDistance = math.huge
    for _, item in ipairs(container:GetChildren()) do
        if item:IsA("BasePart") and item.Name == "Coin_Server" then
            local distance = (rootPart.Position - item.Position).Magnitude
            if distance > 1 and distance < 600 and distance < shortestDistance then
                shortestDistance = distance
                closestItem = item
            end
        end
    end
    return closestItem
end

-- Farming loop. Uses the original remote invocation and target limit.
task.spawn(function()
    while ScreenGui.Parent do
        task.wait(0.1)

        if _G.ActiveCoinFarm and not FarmStopped then
            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local root = character and character:FindFirstChild("HumanoidRootPart")

            if not humanoid or humanoid.Health <= 0 then
                StopCoinFarm("Character died")
                continue
            end

            local activeContainer = getLiveCoinContainer()
            if root and activeContainer then
                local nearestCoin = getClosestCoin(root, activeContainer)
                if nearestCoin then
                    local reached = smoothGlideTo(nearestCoin)

                    if not _G.ActiveCoinFarm or FarmStopped then
                        continue
                    end

                    if reached and nearestCoin.Parent then
                        if GetCoinRemote then
                            pcall(function()
                                if GetCoinRemote:IsA("RemoteFunction") then
                                    GetCoinRemote:InvokeServer(nearestCoin)
                                elseif GetCoinRemote:IsA("RemoteEvent") then
                                    GetCoinRemote:FireServer(nearestCoin)
                                end
                            end)
                        else
                            warn("[Vertex Coin Farm] Collection remote was not found in ReplicatedStorage.")
                        end

                        CoinsCollected += 1
                        print("Coin targets processed: " .. CoinsCollected .. "/" .. COIN_STOP_LIMIT)

                        -- Preserve the original script's local cleanup behavior.
                        if nearestCoin.Parent then
                            nearestCoin:Destroy()
                        end

                        if CoinsCollected >= COIN_STOP_LIMIT then
                            StopCoinFarm("Reached 50 coin targets")
                        end
                        task.wait(0.05)
                    end
                end
            end
        end
    end
end)

updateToggle()
