
--[[
    GHOSTLY HUB
    Auto Farm + Speed Slider + Candy Limit + Respawn
    Left Ctrl = Hide / Show UI
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- SETTINGS
local MIN_SPEED = 15
local MAX_SPEED = 30
local MAX_CANDY_OPTIONS = {40, 50}

local MaxCandy = 50
local CoinsCollected = 0
local WaitingForNextRound = false
local RoundContainerAtLimit = nil

local activeTween = nil
local noclipConnection = nil
local uiVisible = true
local draggingWindow = false
local draggingSlider = false

_G.ActiveCoinFarm = false
_G.FarmSpeedValue = math.clamp(
    _G.FarmSpeedValue or 25,
    MIN_SPEED,
    MAX_SPEED
)

-- CLEAN UP OLD UI
if CoreGui:FindFirstChild("GhostlyHubUI") then
    CoreGui.GhostlyHubUI:Destroy()
end

-- FIND COIN REMOTE
local CoinRemote = ReplicatedStorage:FindFirstChild("GetCoin", true)

if not CoinRemote then
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local gameplay = remotes and remotes:FindFirstChild("Gameplay")

    CoinRemote = gameplay and gameplay:FindFirstChild("CoinCollected")
end

-- UI HELPERS
local function create(className, properties, parent)
    local object = Instance.new(className)

    for property, value in pairs(properties) do
        object[property] = value
    end

    object.Parent = parent
    return object
end

local function round(object, radius)
    create("UICorner", {
        CornerRadius = UDim.new(0, radius)
    }, object)
end

local function makeLabel(text, position, size, parent)
    return create("TextLabel", {
        Position = position,
        Size = size,
        BackgroundTransparency = 1,
        Text = text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(195, 195, 200),
        TextXAlignment = Enum.TextXAlignment.Left
    }, parent)
end

-- GUI
local Gui = create("ScreenGui", {
    Name = "GhostlyHubUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, CoreGui)

local Main = create("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(580, 400),
    Position = UDim2.new(0.5, -290, 0.5, -200),
    BackgroundColor3 = Color3.fromRGB(14, 14, 16),
    BorderSizePixel = 0,
    Active = true
}, Gui)

round(Main, 12)

-- TOP BAR
local TopBar = create("Frame", {
    Size = UDim2.new(1, 0, 0, 34),
    BackgroundColor3 = Color3.fromRGB(20, 20, 22),
    BorderSizePixel = 0
}, Main)

for i, color in ipairs({
    Color3.fromRGB(255, 90, 90),
    Color3.fromRGB(255, 190, 65),
    Color3.fromRGB(75, 210, 125)
}) do
    local dot = create("Frame", {
        Size = UDim2.fromOffset(8, 8),
        Position = UDim2.fromOffset(13 + (i - 1) * 13, 13),
        BackgroundColor3 = color,
        BorderSizePixel = 0
    }, TopBar)

    round(dot, 10)
end

create("TextLabel", {
    Name = "HubTitle",
    Position = UDim2.fromOffset(62, 0),
    Size = UDim2.fromOffset(220, 34),
    BackgroundTransparency = 1,
    Text = "GHOSTLY HUB",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = Color3.fromRGB(240, 240, 245),
    TextXAlignment = Enum.TextXAlignment.Left
}, TopBar)

-- SIDEBAR
local Sidebar = create("Frame", {
    Position = UDim2.fromOffset(0, 34),
    Size = UDim2.new(0, 170, 1, -34),
    BackgroundColor3 = Color3.fromRGB(16, 16, 18),
    BorderSizePixel = 0
}, Main)

create("Frame", {
    Position = UDim2.new(0, 170, 0, 34),
    Size = UDim2.new(0, 1, 1, -34),
    BackgroundColor3 = Color3.fromRGB(45, 45, 48),
    BorderSizePixel = 0
}, Main)

local Nav = create("TextButton", {
    Position = UDim2.fromOffset(10, 50),
    Size = UDim2.fromOffset(150, 34),
    BackgroundColor3 = Color3.fromRGB(32, 32, 35),
    BorderSizePixel = 0,
    Text = "    ◉    Main",
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextColor3 = Color3.fromRGB(240, 240, 240),
    TextXAlignment = Enum.TextXAlignment.Left,
    AutoButtonColor = false
}, Sidebar)

round(Nav, 7)

create("TextLabel", {
    Position = UDim2.new(0, 15, 1, -48),
    Size = UDim2.new(1, -25, 0, 35),
    BackgroundTransparency = 1,
    Text = LocalPlayer.DisplayName .. "\n@" .. LocalPlayer.Name,
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextColor3 = Color3.fromRGB(200, 200, 205),
    TextXAlignment = Enum.TextXAlignment.Left
}, Sidebar)

-- CONTENT
local Content = create("Frame", {
    Position = UDim2.fromOffset(171, 34),
    Size = UDim2.new(1, -171, 1, -34),
    BackgroundTransparency = 1
}, Main)

makeLabel(
    "Main",
    UDim2.fromOffset(28, 15),
    UDim2.new(1, -45, 0, 25),
    Content
)

local Panel = create("Frame", {
    Position = UDim2.fromOffset(25, 47),
    Size = UDim2.new(1, -50, 0, 320),
    BackgroundColor3 = Color3.fromRGB(19, 19, 21),
    BorderColor3 = Color3.fromRGB(43, 43, 46),
    BorderSizePixel = 1
}, Content)

round(Panel, 10)

-- AUTO FARM LABEL
makeLabel(
    "Auto Farm",
    UDim2.fromOffset(18, 20),
    UDim2.fromOffset(180, 22),
    Panel
)

local Status = makeLabel(
    "Status: OFF",
    UDim2.fromOffset(18, 49),
    UDim2.new(1, -36, 0, 22),
    Panel
)

local CountLabel = makeLabel(
    "Candy: 0 / 50",
    UDim2.fromOffset(18, 72),
    UDim2.new(1, -36, 0, 20),
    Panel
)

-- TOGGLE
local Toggle = create("TextButton", {
    Position = UDim2.new(1, -58, 0, 21),
    Size = UDim2.fromOffset(40, 21),
    BackgroundColor3 = Color3.fromRGB(60, 60, 63),
    BorderSizePixel = 0,
    Text = "",
    AutoButtonColor = false
}, Panel)

round(Toggle, 15)

local Knob = create("Frame", {
    Position = UDim2.fromOffset(3, 3),
    Size = UDim2.fromOffset(15, 15),
    BackgroundColor3 = Color3.fromRGB(190, 190, 195),
    BorderSizePixel = 0
}, Toggle)

round(Knob, 15)

-- SPEED SLIDER
makeLabel(
    "Glide Speed (15 - 30)",
    UDim2.fromOffset(18, 108),
    UDim2.fromOffset(190, 20),
    Panel
)

local SpeedValue = makeLabel(
    tostring(_G.FarmSpeedValue),
    UDim2.new(1, -55, 0, 108),
    UDim2.fromOffset(35, 20),
    Panel
)

SpeedValue.TextXAlignment = Enum.TextXAlignment.Right

local Slider = create("TextButton", {
    Position = UDim2.fromOffset(18, 140),
    Size = UDim2.new(1, -36, 0, 6),
    BackgroundColor3 = Color3.fromRGB(52, 52, 55),
    BorderSizePixel = 0,
    Text = "",
    AutoButtonColor = false
}, Panel)

round(Slider, 5)

local function speedPercent()
    return math.clamp(
        (_G.FarmSpeedValue - MIN_SPEED) / (MAX_SPEED - MIN_SPEED),
        0,
        1
    )
end

local Fill = create("Frame", {
    Size = UDim2.new(speedPercent(), 0, 1, 0),
    BackgroundColor3 = Color3.fromRGB(225, 225, 230),
    BorderSizePixel = 0
}, Slider)

round(Fill, 5)

local SliderKnob = create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(speedPercent(), 0, 0.5, 0),
    Size = UDim2.fromOffset(14, 14),
    BackgroundColor3 = Color3.fromRGB(245, 245, 245),
    BorderSizePixel = 0
}, Slider)

round(SliderKnob, 10)

local function updateSlider(x)
    local width = Slider.AbsoluteSize.X
    if width <= 0 then
        return
    end

    local percent = math.clamp(
        (x - Slider.AbsolutePosition.X) / width,
        0,
        1
    )

    _G.FarmSpeedValue = math.floor(
        MIN_SPEED + percent * (MAX_SPEED - MIN_SPEED) + 0.5
    )

    Fill.Size = UDim2.new(percent, 0, 1, 0)
    SliderKnob.Position = UDim2.new(percent, 0, 0.5, 0)
    SpeedValue.Text = tostring(_G.FarmSpeedValue)
end

Slider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSlider = true
        updateSlider(input.Position.X)
    end
end)

-- CANDY LIMIT SELECTOR
makeLabel(
    "Maximum Candy",
    UDim2.fromOffset(18, 171),
    UDim2.fromOffset(180, 22),
    Panel
)

local LimitButtons = {}

local function updateLimitButtons()
    for amount, button in pairs(LimitButtons) do
        if amount == MaxCandy then
            button.BackgroundColor3 = Color3.fromRGB(225, 225, 230)
            button.TextColor3 = Color3.fromRGB(25, 25, 28)
        else
            button.BackgroundColor3 = Color3.fromRGB(40, 40, 43)
            button.TextColor3 = Color3.fromRGB(210, 210, 215)
        end
    end

    CountLabel.Text = "Candy: " .. CoinsCollected .. " / " .. MaxCandy
end

for index, amount in ipairs(MAX_CANDY_OPTIONS) do
    local button = create("TextButton", {
        Position = UDim2.fromOffset(18 + (index - 1) * 92, 201),
        Size = UDim2.fromOffset(82, 30),
        BackgroundColor3 = Color3.fromRGB(40, 40, 43),
        BorderSizePixel = 0,
        Text = tostring(amount) .. " Candy",
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = Color3.fromRGB(210, 210, 215),
        AutoButtonColor = false
    }, Panel)

    round(button, 7)
    LimitButtons[amount] = button

    button.MouseButton1Click:Connect(function()
        MaxCandy = amount
        updateLimitButtons()
    end)
end

-- NOC LIP
local function enableNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
    end

    noclipConnection = RunService.Stepped:Connect(function()
        if not _G.ActiveCoinFarm then
            return
        end

        local character = LocalPlayer.Character

        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function disableNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
end

local function updateToggle()
    if _G.ActiveCoinFarm then
        Toggle.BackgroundColor3 = Color3.fromRGB(225, 225, 230)
        Knob.Position = UDim2.new(1, -18, 0, 3)
        Knob.BackgroundColor3 = Color3.fromRGB(35, 35, 38)

        if not WaitingForNextRound then
            Status.Text = "Status: ON"
        end
    else
        Toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 63)
        Knob.Position = UDim2.fromOffset(3, 3)
        Knob.BackgroundColor3 = Color3.fromRGB(190, 190, 195)
        Status.Text = "Status: OFF"
    end
end

Toggle.MouseButton1Click:Connect(function()
    _G.ActiveCoinFarm = not _G.ActiveCoinFarm

    if _G.ActiveCoinFarm then
        enableNoclip()
    else
        disableNoclip()

        if activeTween then
            activeTween:Cancel()
            activeTween = nil
        end
    end

    updateToggle()
end)

-- LEFT CTRL: HIDE / SHOW UI
UserInputService.InputBegan:Connect(function(input, processed)
    if input.KeyCode == Enum.KeyCode.LeftControl and not processed then
        uiVisible = not uiVisible
        Main.Visible = uiVisible
    end
end)

-- WINDOW DRAGGING
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
    if draggingWindow
        and input.UserInputType == Enum.UserInputType.MouseMovement then

        local delta = input.Position - dragStart

        Main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end

    if draggingSlider
        and input.UserInputType == Enum.UserInputType.MouseMovement then
        updateSlider(input.Position.X)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingWindow = false
        draggingSlider = false
    end
end)

-- ROUND / COIN CONTAINER DETECTION
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

local function containerHasCoins(container)
    if not container or not container.Parent then
        return false
    end

    for _, item in ipairs(container:GetChildren()) do
        if item:IsA("BasePart") and item.Name == "Coin_Server" then
            return true
        end
    end

    return false
end

local function getClosestCoin(root, container)
    local closest = nil
    local shortestDistance = math.huge

    for _, item in ipairs(container:GetChildren()) do
        if item:IsA("BasePart") and item.Name == "Coin_Server" then
            local distance = (root.Position - item.Position).Magnitude

            if distance > 1
                and distance < 600
                and distance < shortestDistance then

                shortestDistance = distance
                closest = item
            end
        end
    end

    return closest
end

-- GLIDE TO COIN
local function glideTo(coin)
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not root or not coin or not coin.Parent then
        return false
    end

    local target = coin.CFrame * CFrame.new(0, 1.5, 0)
    local distance = (root.Position - target.Position).Magnitude

    local duration = math.max(
        distance / math.max(_G.FarmSpeedValue, 1),
        0.05
    )

    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero

    local tween = TweenService:Create(
        root,
        TweenInfo.new(
            duration,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        ),
        { CFrame = target }
    )

    activeTween = tween
    tween:Play()

    local result = tween.Completed:Wait()

    if activeTween == tween then
        activeTween = nil
    end

    return result == Enum.PlaybackState.Completed
        and coin.Parent ~= nil
end

-- RESET AVATAR AT SELECTED LIMIT
local function resetAvatar()
    local character = LocalPlayer.Character
    local humanoid = character
        and character:FindFirstChildOfClass("Humanoid")

    if activeTween then
        activeTween:Cancel()
        activeTween = nil
    end

    if humanoid and humanoid.Health > 0 then
        humanoid.Health = 0
    end
end

-- HANDLE RESPAWN WITHOUT DISABLING FARM
local function monitorCharacter(character)
    local humanoid = character:WaitForChild("Humanoid", 10)

    if humanoid then
        humanoid.Died:Connect(function()
            if activeTween then
                activeTween:Cancel()
                activeTween = nil
            end

            if _G.ActiveCoinFarm then
                Status.Text = WaitingForNextRound
                    and "Status: Waiting for next round..."
                    or "Status: Waiting for respawn..."
            end
        end)
    end
end

LocalPlayer.CharacterAdded:Connect(function(character)
    monitorCharacter(character)

    task.wait(1)

    if _G.ActiveCoinFarm then
        enableNoclip()

        if WaitingForNextRound then
            Status.Text = "Status: Waiting for next round..."
        else
            Status.Text = "Status: Farming"
        end
    end
end)

if LocalPlayer.Character then
    task.spawn(monitorCharacter, LocalPlayer.Character)
end

-- MAIN AUTO FARM LOOP
task.spawn(function()
    while Gui.Parent do
        task.wait(0.1)

        if not _G.ActiveCoinFarm then
            continue
        end

        -- After the selected limit, wait for the round to change.
        if WaitingForNextRound then
            Status.Text = "Status: Waiting for next round..."

            local currentContainer = getLiveCoinContainer()

            local roundEnded =
                currentContainer == nil
                or currentContainer ~= RoundContainerAtLimit
                or not containerHasCoins(RoundContainerAtLimit)

            if roundEnded then
                WaitingForNextRound = false
                RoundContainerAtLimit = nil
                CoinsCollected = 0

                CountLabel.Text = "Candy: 0 / " .. MaxCandy
                Status.Text = "Status: New round detected"

                print("[Ghostly Hub] Round detected; farming resumed.")

                task.wait(0.5)
            else
                task.wait(0.5)
            end

            continue
        end

        local character = LocalPlayer.Character
        local humanoid = character
            and character:FindFirstChildOfClass("Humanoid")
        local root = character
            and character:FindFirstChild("HumanoidRootPart")

        if not character or not humanoid
            or humanoid.Health <= 0 or not root then

            Status.Text = "Status: Waiting for respawn..."
            task.wait(0.5)
            continue
        end

        local container = getLiveCoinContainer()

        if not container then
            Status.Text = "Status: Waiting for round..."
            task.wait(0.5)
            continue
        end

        local coin = getClosestCoin(root, container)

        if not coin then
            Status.Text = "Status: Looking for candy..."
            task.wait(0.25)
            continue
        end

        Status.Text = "Status: Farming"
        CountLabel.Text = "Candy: "
            .. CoinsCollected .. " / " .. MaxCandy

        local reached = glideTo(coin)

        if not _G.ActiveCoinFarm then
            continue
        end

        if reached and coin.Parent then
            if CoinRemote then
                local success, err = pcall(function()
                    if CoinRemote:IsA("RemoteFunction") then
                        CoinRemote:InvokeServer(coin)
                    elseif CoinRemote:IsA("RemoteEvent") then
                        CoinRemote:FireServer(coin)
                    end
                end)

                if not success then
                    warn("[Ghostly Hub] Coin remote error:", err)
                end
            else
                warn("[Ghostly Hub] Coin remote not found.")
                Status.Text = "Status: Coin remote not found"
                task.wait(1)
                continue
            end

            CoinsCollected += 1
            CountLabel.Text = "Candy: "
                .. CoinsCollected .. " / " .. MaxCandy

            print(
                "[Ghostly Hub] Targets processed: "
                .. CoinsCollected .. "/" .. MaxCandy
            )

            -- Keep the original cleanup behavior.
            if coin.Parent then
                coin:Destroy()
            end

            if CoinsCollected >= MaxCandy then
                WaitingForNextRound = true
                RoundContainerAtLimit = container

                Status.Text = "Status: Limit reached - resetting..."
                print(
                    "[Ghostly Hub] Limit reached: "
                    .. MaxCandy
                    .. ". Resetting avatar and waiting for next round."
                )

                resetAvatar()
            end

            task.wait(0.05)
        end
    end
end)

updateLimitButtons()
updateToggle()

print("[Ghostly Hub] Loaded successfully.")
