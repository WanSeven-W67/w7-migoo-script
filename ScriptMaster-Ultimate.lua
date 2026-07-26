--[[
    ================================================================
    SCRIPTMASTER ULTIMATE - FLOAT + SPIDERMAN + ALL 12 FEATURES
    Executor: Delta / Fluxus / Arceus X (Kompatibel)
    Author: ScriptMaster x W7s
    ================================================================
    FITUR LENGKAP:
    1.  Float Platform (lantai ikut pergerakan karakter)
    2.  Naik (Up Arrow) / Turun (Down Arrow)
    3.  Kecepatan bisa diatur 1-1000 stud
    4.  Wall Climb ala Spiderman (nempel & jalan di tembok)
    5.  Noclip Mode (tembus semua objek)
    6.  Fly Mode (terbang bebas WASD + Up/Down)
    7.  Speed Boost (atur WalkSpeed)
    8.  Super Jump (atur JumpPower)
    9.  Freeze Position (diam di udara)
    10. Waypoint System (save & teleport lokasi)
    11. Custom Platform Style (warna, ukuran, transparansi)
    12. Custom Keybind (ganti tombol naik/turun)
    ================================================================
]]

-- ===================== SERVICES =====================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

-- ===================== PLAYER SETUP =====================
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera

-- ===================== STATE VARIABLES =====================
local floatEnabled = false
local wallClimbEnabled = false
local noclipEnabled = false
local flyEnabled = false
local freezeEnabled = false
local floatSpeed = 50
local walkSpeedValue = 16
local jumpPowerValue = 50
local flySpeed = 80
local goingUp = false
local goingDown = false

-- Platform style defaults
local platformSize = Vector3.new(6, 0.5, 6)
local platformTransparency = 0.6
local platformColor = Color3.fromRGB(0, 100, 255)

-- Custom keybind defaults
local keyUp = Enum.KeyCode.Up
local keyDown = Enum.KeyCode.Down

-- References
local floatPart = nil
local bodyVelocityWC = nil
local bodyGyroWC = nil
local flyBodyVelocity = nil
local flyBodyGyro = nil
local frozenPosition = nil
local noclipConnection = nil
local floatConnection = nil
local wallClimbConnection = nil
local flyConnection = nil
local freezeConnection = nil

-- Waypoints
local waypoints = {}
local maxWaypoints = 5

-- ===================== ANTI-DUPLIKAT: HAPUS GUI LAMA =====================
if player.PlayerGui:FindFirstChild("ScriptMasterUltimateGUI") then
    player.PlayerGui:FindFirstChild("ScriptMasterUltimateGUI"):Destroy()
end

-- ===================== BUAT SCREEN GUI =====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ScriptMasterUltimateGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player.PlayerGui

-- ===================== SCROLLABLE MAIN FRAME =====================
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 280, 0, 420)
mainFrame.Position = UDim2.new(0, 10, 0.5, -210)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- Drop shadow effect
local shadow = Instance.new("ImageLabel")
shadow.Name = "Shadow"
shadow.Size = UDim2.new(1, 30, 1, 30)
shadow.Position = UDim2.new(0, -15, 0, -15)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://6015897843"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.5
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(49, 49, 450, 450)
shadow.ZIndex = -1
shadow.Parent = mainFrame

-- ===================== TITLE BAR =====================
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(100, 40, 200)
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 10
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

-- Bottom cover for title bar rounded corners
local titleCover = Instance.new("Frame")
titleCover.Size = UDim2.new(1, 0, 0, 12)
titleCover.Position = UDim2.new(0, 0, 1, -12)
titleCover.BackgroundColor3 = Color3.fromRGB(100, 40, 200)
titleCover.BorderSizePixel = 0
titleCover.ZIndex = 10
titleCover.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -40, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "ScriptMaster ULTIMATE"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 15
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 11
titleLabel.Parent = titleBar

-- Minimize button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -35, 0, 5)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
minimizeBtn.Text = "-"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.TextSize = 18
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.BorderSizePixel = 0
minimizeBtn.ZIndex = 12
minimizeBtn.Parent = titleBar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 6)
minCorner.Parent = minimizeBtn

-- ===================== SCROLLING CONTENT FRAME =====================
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "ContentScroll"
scrollFrame.Size = UDim2.new(1, 0, 1, -40)
scrollFrame.Position = UDim2.new(0, 0, 0, 40)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 40, 200)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 1150)
scrollFrame.BorderSizePixel = 0
scrollFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 6)
listLayout.Parent = scrollFrame

local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 8)
listPadding.PaddingLeft = UDim.new(0, 10)
listPadding.PaddingRight = UDim.new(0, 10)
listPadding.Parent = scrollFrame

-- ===================== UI HELPER FUNCTIONS =====================
local layoutOrder = 0

local function nextOrder()
    layoutOrder = layoutOrder + 1
    return layoutOrder
end

local function createSection(title)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, 25)
    section.BackgroundTransparency = 1
    section.LayoutOrder = nextOrder()
    section.Parent = scrollFrame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "-- " .. title .. " --"
    label.TextColor3 = Color3.fromRGB(130, 90, 230)
    label.TextSize = 12
    label.Font = Enum.Font.GothamBold
    label.Parent = section

    return section
end

local function createToggleButton(name, text, defaultColor)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = defaultColor or Color3.fromRGB(45, 45, 65)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = text
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamSemibold
    btn.BorderSizePixel = 0
    btn.LayoutOrder = nextOrder()
    btn.Parent = scrollFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    return btn
end

local function createInfoLabel(text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 18)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(170, 170, 190)
    lbl.Text = text
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = nextOrder()
    lbl.Parent = scrollFrame
    return lbl
end

local function createInputRow(labelText, defaultVal, btnText, btnColor)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 32)
    row.BackgroundTransparency = 1
    row.LayoutOrder = nextOrder()
    row.Parent = scrollFrame

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.35, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(180, 180, 200)
    lbl.Text = labelText
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(0.35, -5, 1, -4)
    input.Position = UDim2.new(0.35, 0, 0, 2)
    input.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
    input.TextColor3 = Color3.fromRGB(255, 255, 255)
    input.PlaceholderText = "..."
    input.Text = tostring(defaultVal)
    input.TextSize = 12
    input.Font = Enum.Font.GothamSemibold
    input.BorderSizePixel = 0
    input.ClearTextOnFocus = true
    input.Parent = row

    local inCorner = Instance.new("UICorner")
    inCorner.CornerRadius = UDim.new(0, 6)
    inCorner.Parent = input

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.28, 0, 1, -4)
    btn.Position = UDim2.new(0.72, 0, 0, 2)
    btn.BackgroundColor3 = btnColor or Color3.fromRGB(40, 120, 80)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = btnText or "SET"
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = row

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 6)
    bCorner.Parent = btn

    return input, btn, lbl
end

local function createSmallButton(text, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 28)
    btn.BackgroundColor3 = color or Color3.fromRGB(45, 45, 65)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = text
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamSemibold
    btn.BorderSizePixel = 0
    btn.LayoutOrder = nextOrder()
    btn.Parent = scrollFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    return btn
end

-- ===================== STATUS BAR =====================
local statusBar = Instance.new("TextLabel")
statusBar.Size = UDim2.new(1, 0, 0, 30)
statusBar.BackgroundTransparency = 1
statusBar.TextColor3 = Color3.fromRGB(100, 255, 100)
statusBar.Text = "Status: Ready"
statusBar.TextSize = 11
statusBar.Font = Enum.Font.GothamSemibold
statusBar.TextWrapped = true
statusBar.LayoutOrder = nextOrder()
statusBar.Parent = scrollFrame

local function setStatus(msg, color)
    statusBar.Text = ">> " .. msg
    statusBar.TextColor3 = color or Color3.fromRGB(100, 255, 100)
end

-- ================================================================
--                    SECTION 1: FLOAT PLATFORM
-- ================================================================
createSection("FLOAT PLATFORM")

local floatBtn = createToggleButton("FloatBtn", "Float Platform: OFF")
createInfoLabel("Up/Down Arrow untuk naik/turun")

-- Speed input
local speedInput, speedSetBtn, speedLbl = createInputRow("Speed:", 50, "SET")

-- ================================================================
--                  SECTION 2: WALL CLIMB (SPIDERMAN)
-- ================================================================
createSection("SPIDERMAN WALL CLIMB")

local wallBtn = createToggleButton("WallBtn", "Wall Climb: OFF")
createInfoLabel("Jalan ke tembok pakai W, naik/turun/geser")

-- ================================================================
--                    SECTION 3: NOCLIP MODE
-- ================================================================
createSection("NOCLIP MODE")

local noclipBtn = createToggleButton("NoclipBtn", "Noclip: OFF")
createInfoLabel("Tembus semua tembok & objek")

-- ================================================================
--                    SECTION 4: FLY MODE
-- ================================================================
createSection("FLY MODE")

local flyBtn = createToggleButton("FlyBtn", "Fly Mode: OFF")
createInfoLabel("WASD + Up/Down untuk terbang bebas")

local flySpeedInput, flySpeedSetBtn = createInputRow("Fly Speed:", 80, "SET")

-- ================================================================
--                   SECTION 5: SPEED BOOST
-- ================================================================
createSection("SPEED BOOST")

local walkSpeedInput, walkSpeedSetBtn, walkSpeedLbl = createInputRow("WalkSpeed:", 16, "SET")

local resetSpeedBtn = createSmallButton("Reset WalkSpeed (16)", Color3.fromRGB(120, 40, 40))

-- ================================================================
--                   SECTION 6: SUPER JUMP
-- ================================================================
createSection("SUPER JUMP")

local jumpInput, jumpSetBtn, jumpLbl = createInputRow("JumpPower:", 50, "SET")

local resetJumpBtn = createSmallButton("Reset JumpPower (50)", Color3.fromRGB(120, 40, 40))

-- ================================================================
--                SECTION 7: FREEZE POSITION
-- ================================================================
createSection("FREEZE POSITION")

local freezeBtn = createToggleButton("FreezeBtn", "Freeze: OFF")
createInfoLabel("Diam di udara, anti jatuh")

-- ================================================================
--               SECTION 8: WAYPOINT SYSTEM
-- ================================================================
createSection("WAYPOINT SYSTEM (Max 5)")

local saveWpBtn = createSmallButton("Save Waypoint", Color3.fromRGB(40, 100, 160))

-- Waypoint buttons container
local wpContainer = Instance.new("Frame")
wpContainer.Size = UDim2.new(1, 0, 0, 5)
wpContainer.BackgroundTransparency = 1
wpContainer.LayoutOrder = nextOrder()
wpContainer.Name = "WPContainer"
wpContainer.Parent = scrollFrame

local wpListLayout = Instance.new("UIListLayout")
wpListLayout.SortOrder = Enum.SortOrder.LayoutOrder
wpListLayout.Padding = UDim.new(0, 3)
wpListLayout.Parent = wpContainer

local clearWpBtn = createSmallButton("Clear All Waypoints", Color3.fromRGB(120, 40, 40))

-- ================================================================
--            SECTION 9: CUSTOM PLATFORM STYLE
-- ================================================================
createSection("PLATFORM STYLE")

local platSizeInput, platSizeSetBtn = createInputRow("Size:", "6", "SET")
local platTransInput, platTransSetBtn = createInputRow("Transp:", "0.6", "SET")

-- Color presets
local colorRow = Instance.new("Frame")
colorRow.Size = UDim2.new(1, 0, 0, 28)
colorRow.BackgroundTransparency = 1
colorRow.LayoutOrder = nextOrder()
colorRow.Parent = scrollFrame

local colorLabel = Instance.new("TextLabel")
colorLabel.Size = UDim2.new(0.3, 0, 1, 0)
colorLabel.BackgroundTransparency = 1
colorLabel.Text = "Color:"
colorLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
colorLabel.TextSize = 11
colorLabel.Font = Enum.Font.Gotham
colorLabel.TextXAlignment = Enum.TextXAlignment.Left
colorLabel.Parent = colorRow

local colorPresets = {
    {name = "Blue", color = Color3.fromRGB(0, 100, 255)},
    {name = "Red", color = Color3.fromRGB(255, 50, 50)},
    {name = "Green", color = Color3.fromRGB(50, 255, 50)},
    {name = "Purple", color = Color3.fromRGB(150, 50, 255)},
    {name = "Gold", color = Color3.fromRGB(255, 200, 0)},
}

local colorButtons = {}
for i, preset in ipairs(colorPresets) do
    local cBtn = Instance.new("TextButton")
    cBtn.Size = UDim2.new(0, 28, 0, 24)
    cBtn.Position = UDim2.new(0.3 + (i-1) * 0.13, 0, 0, 2)
    cBtn.BackgroundColor3 = preset.color
    cBtn.Text = ""
    cBtn.BorderSizePixel = 0
    cBtn.Parent = colorRow

    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(0, 6)
    cCorner.Parent = cBtn

    cBtn.MouseButton1Click:Connect(function()
        platformColor = preset.color
        if floatPart and floatPart.Parent then
            floatPart.Color = platformColor
        end
        setStatus("Platform color: " .. preset.name)
    end)

    table.insert(colorButtons, cBtn)
end

local invisPlatBtn = createSmallButton("Platform Invisible (Ghost Mode)", Color3.fromRGB(60, 60, 80))

-- ================================================================
--            SECTION 10: CUSTOM KEYBIND
-- ================================================================
createSection("CUSTOM KEYBIND")

createInfoLabel("Klik tombol lalu tekan key baru")

local keybindUpBtn = createSmallButton("UP Key: Up Arrow", Color3.fromRGB(50, 50, 75))
local keybindDownBtn = createSmallButton("DOWN Key: Down Arrow", Color3.fromRGB(50, 50, 75))

local waitingForKey = nil -- "up" or "down"

-- ================================================================
--               SECTION 11: MISC / EXTRA
-- ================================================================
createSection("EXTRAS")

local infiniteJumpBtn = createToggleButton("InfJumpBtn", "Infinite Jump: OFF")
local godModeBtn = createToggleButton("GodModeBtn", "Anti-Death (God Mode): OFF")

-- ================================================================
--                    STATUS INFO
-- ================================================================
createSection("INFO")

-- Move status bar to bottom
statusBar.LayoutOrder = nextOrder()

-- Update canvas size dynamically
local function updateCanvasSize()
    local totalHeight = listLayout.AbsoluteContentSize.Y + 20
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
end

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)
task.defer(updateCanvasSize)

-- ================================================================
--                CORE FUNCTIONS
-- ================================================================

-- ===================== FLOAT PLATFORM =====================
local function createFloatPlatform()
    if floatPart and floatPart.Parent then
        floatPart:Destroy()
    end

    floatPart = Instance.new("Part")
    floatPart.Name = "SM_FloatPlatform"
    floatPart.Size = platformSize
    floatPart.Transparency = platformTransparency
    floatPart.Color = platformColor
    floatPart.Material = Enum.Material.Neon
    floatPart.Anchored = true
    floatPart.CanCollide = true
    floatPart.CastShadow = false
    floatPart.Parent = workspace

    return floatPart
end

local function removeFloatPlatform()
    if floatPart and floatPart.Parent then
        floatPart:Destroy()
        floatPart = nil
    end
end

local function startFloatLoop()
    if floatConnection then floatConnection:Disconnect() end

    floatConnection = RunService.RenderStepped:Connect(function(dt)
        if not floatEnabled then return end
        if not humanoidRootPart or not humanoidRootPart.Parent then return end

        if floatPart and floatPart.Parent then
            floatPart.CFrame = CFrame.new(
                humanoidRootPart.Position.X,
                humanoidRootPart.Position.Y - 3.5,
                humanoidRootPart.Position.Z
            )
        end

        if goingUp then
            humanoidRootPart.CFrame = humanoidRootPart.CFrame + Vector3.new(0, floatSpeed * dt, 0)
        elseif goingDown then
            humanoidRootPart.CFrame = humanoidRootPart.CFrame + Vector3.new(0, -floatSpeed * dt, 0)
        end
    end)
end

-- ===================== WALL CLIMB (SPIDERMAN) =====================
local function enableWallClimb()
    if humanoidRootPart:FindFirstChild("SM_WallBV") then
        humanoidRootPart:FindFirstChild("SM_WallBV"):Destroy()
    end
    if humanoidRootPart:FindFirstChild("SM_WallBG") then
        humanoidRootPart:FindFirstChild("SM_WallBG"):Destroy()
    end

    bodyVelocityWC = Instance.new("BodyVelocity")
    bodyVelocityWC.Name = "SM_WallBV"
    bodyVelocityWC.MaxForce = Vector3.new(0, 0, 0)
    bodyVelocityWC.Velocity = Vector3.new(0, 0, 0)
    bodyVelocityWC.Parent = humanoidRootPart

    bodyGyroWC = Instance.new("BodyGyro")
    bodyGyroWC.Name = "SM_WallBG"
    bodyGyroWC.MaxTorque = Vector3.new(0, 0, 0)
    bodyGyroWC.D = 50
    bodyGyroWC.P = 10000
    bodyGyroWC.Parent = humanoidRootPart
end

local function disableWallClimb()
    if bodyVelocityWC then bodyVelocityWC:Destroy(); bodyVelocityWC = nil end
    if bodyGyroWC then bodyGyroWC:Destroy(); bodyGyroWC = nil end
end

local function detectWall()
    if not humanoidRootPart or not humanoidRootPart.Parent then return nil, nil end

    local rayOrigin = humanoidRootPart.Position
    local rayDirection = humanoidRootPart.CFrame.LookVector * 3.5

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

    if result then
        return result.Instance, result.Normal
    end
    return nil, nil
end

local function startWallClimbLoop()
    if wallClimbConnection then wallClimbConnection:Disconnect() end

    wallClimbConnection = RunService.RenderStepped:Connect(function()
        if not wallClimbEnabled then return end
        if not humanoidRootPart or not humanoidRootPart.Parent then return end
        if not bodyVelocityWC or not bodyGyroWC then return end

        local wallPart, wallNormal = detectWall()

        if wallPart then
            bodyVelocityWC.MaxForce = Vector3.new(50000, 50000, 50000)
            bodyGyroWC.MaxTorque = Vector3.new(50000, 50000, 50000)

            local wallLook = -wallNormal
            local wallUp = Vector3.new(0, 1, 0)
            local wallRight = wallUp:Cross(wallLook)
            if wallRight.Magnitude > 0.01 then
                wallRight = wallRight.Unit
            end

            bodyGyroWC.CFrame = CFrame.lookAt(Vector3.new(0, 0, 0), wallLook, wallUp)

            local moveDirection = humanoid.MoveDirection

            if moveDirection.Magnitude > 0 then
                local climbVelocity = Vector3.new(0, 0, 0)
                local forwardComponent = moveDirection:Dot(humanoidRootPart.CFrame.LookVector)
                local rightComponent = moveDirection:Dot(wallRight)

                if math.abs(forwardComponent) > 0.1 then
                    climbVelocity = climbVelocity + Vector3.new(0, floatSpeed * 0.6 * (forwardComponent > 0 and 1 or -1), 0)
                end

                climbVelocity = climbVelocity + wallRight * rightComponent * floatSpeed * 0.5
                climbVelocity = climbVelocity + wallLook * 5

                bodyVelocityWC.Velocity = climbVelocity
            else
                bodyVelocityWC.Velocity = wallLook * 5
            end

            humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
        else
            bodyVelocityWC.MaxForce = Vector3.new(0, 0, 0)
            bodyGyroWC.MaxTorque = Vector3.new(0, 0, 0)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
        end
    end)
end

-- ===================== NOCLIP =====================
local function startNoclip()
    if noclipConnection then noclipConnection:Disconnect() end

    noclipConnection = RunService.Stepped:Connect(function()
        if not noclipEnabled then return end
        if not character then return end

        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end

local function stopNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end

    if character then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
        -- Khusus HumanoidRootPart selalu CanCollide = true
        if humanoidRootPart and humanoidRootPart.Parent then
            humanoidRootPart.CanCollide = true
        end
    end
end

-- ===================== FLY MODE =====================
local function enableFly()
    if humanoidRootPart:FindFirstChild("SM_FlyBV") then
        humanoidRootPart:FindFirstChild("SM_FlyBV"):Destroy()
    end
    if humanoidRootPart:FindFirstChild("SM_FlyBG") then
        humanoidRootPart:FindFirstChild("SM_FlyBG"):Destroy()
    end

    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.Name = "SM_FlyBV"
    flyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    flyBodyVelocity.Parent = humanoidRootPart

    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.Name = "SM_FlyBG"
    flyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flyBodyGyro.D = 200
    flyBodyGyro.P = 40000
    flyBodyGyro.Parent = humanoidRootPart

    humanoid.PlatformStand = true
end

local function disableFly()
    if flyBodyVelocity then flyBodyVelocity:Destroy(); flyBodyVelocity = nil end
    if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro = nil end
    if humanoid then
        humanoid.PlatformStand = false
    end
end

local function startFlyLoop()
    if flyConnection then flyConnection:Disconnect() end

    flyConnection = RunService.RenderStepped:Connect(function()
        if not flyEnabled then return end
        if not humanoidRootPart or not humanoidRootPart.Parent then return end
        if not flyBodyVelocity or not flyBodyGyro then return end

        local camCF = camera.CFrame
        flyBodyGyro.CFrame = camCF

        local moveDir = Vector3.new(0, 0, 0)

        -- WASD movement relative to camera
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDir = moveDir + camCF.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDir = moveDir - camCF.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDir = moveDir - camCF.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDir = moveDir + camCF.RightVector
        end

        -- Up / Down using custom keybinds
        if UserInputService:IsKeyDown(keyUp) then
            moveDir = moveDir + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(keyDown) then
            moveDir = moveDir - Vector3.new(0, 1, 0)
        end

        -- Space juga bisa buat naik
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDir = moveDir + Vector3.new(0, 0.5, 0)
        end

        if moveDir.Magnitude > 0 then
            flyBodyVelocity.Velocity = moveDir.Unit * flySpeed
        else
            flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
        end
    end)
end

-- ===================== FREEZE POSITION =====================
local function startFreeze()
    frozenPosition = humanoidRootPart.CFrame

    if freezeConnection then freezeConnection:Disconnect() end

    freezeConnection = RunService.RenderStepped:Connect(function()
        if not freezeEnabled then return end
        if not humanoidRootPart or not humanoidRootPart.Parent then return end

        humanoidRootPart.CFrame = frozenPosition
        humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
        if humanoidRootPart:FindFirstChildOfClass("BodyVelocity") == nil then
            -- Prevent gravity
            humanoidRootPart.Anchored = true
        end
    end)
end

local function stopFreeze()
    if freezeConnection then
        freezeConnection:Disconnect()
        freezeConnection = nil
    end
    if humanoidRootPart and humanoidRootPart.Parent then
        humanoidRootPart.Anchored = false
    end
    frozenPosition = nil
end

-- ===================== WAYPOINT SYSTEM =====================
local function updateWaypointUI()
    -- Clear old buttons
    for _, child in pairs(wpContainer:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    for i, wp in ipairs(waypoints) do
        local wpBtn = Instance.new("TextButton")
        wpBtn.Size = UDim2.new(1, 0, 0, 24)
        wpBtn.BackgroundColor3 = Color3.fromRGB(35, 80, 130)
        wpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        wpBtn.Text = string.format("WP%d: [%.0f, %.0f, %.0f]", i, wp.X, wp.Y, wp.Z)
        wpBtn.TextSize = 10
        wpBtn.Font = Enum.Font.GothamSemibold
        wpBtn.BorderSizePixel = 0
        wpBtn.LayoutOrder = i
        wpBtn.Parent = wpContainer

        local wpCorner = Instance.new("UICorner")
        wpCorner.CornerRadius = UDim.new(0, 5)
        wpCorner.Parent = wpBtn

        wpBtn.MouseButton1Click:Connect(function()
            if humanoidRootPart and humanoidRootPart.Parent then
                humanoidRootPart.CFrame = CFrame.new(wp)
                setStatus("Teleported to WP" .. i)
            end
        end)
    end

    -- Update container size
    wpContainer.Size = UDim2.new(1, 0, 0, math.max(5, #waypoints * 27))
    task.defer(updateCanvasSize)
end

-- ===================== INFINITE JUMP =====================
local infiniteJumpEnabled = false
local infiniteJumpConn = nil

local function startInfiniteJump()
    if infiniteJumpConn then infiniteJumpConn:Disconnect() end

    infiniteJumpConn = UserInputService.JumpRequest:Connect(function()
        if not infiniteJumpEnabled then return end
        if humanoid and humanoid.Parent then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

local function stopInfiniteJump()
    if infiniteJumpConn then
        infiniteJumpConn:Disconnect()
        infiniteJumpConn = nil
    end
end

-- ===================== GOD MODE (Anti-Death) =====================
local godModeEnabled = false
local godModeConn = nil
local originalMaxHealth = 100

local function startGodMode()
    if humanoid then
        originalMaxHealth = humanoid.MaxHealth
        humanoid.MaxHealth = math.huge
        humanoid.Health = math.huge
    end

    if godModeConn then godModeConn:Disconnect() end

    godModeConn = RunService.Heartbeat:Connect(function()
        if not godModeEnabled then return end
        if humanoid and humanoid.Parent then
            humanoid.Health = humanoid.MaxHealth
        end
    end)
end

local function stopGodMode()
    if godModeConn then
        godModeConn:Disconnect()
        godModeConn = nil
    end
    if humanoid and humanoid.Parent then
        humanoid.MaxHealth = originalMaxHealth
        humanoid.Health = originalMaxHealth
    end
end

-- ================================================================
--              GUI EVENT HANDLERS
-- ================================================================

-- ===== FLOAT TOGGLE =====
floatBtn.MouseButton1Click:Connect(function()
    floatEnabled = not floatEnabled
    if floatEnabled then
        createFloatPlatform()
        startFloatLoop()
        floatBtn.Text = "Float Platform: ON"
        floatBtn.BackgroundColor3 = Color3.fromRGB(40, 130, 80)
        setStatus("Float AKTIF! Up/Down Arrow naik/turun")
    else
        removeFloatPlatform()
        if floatConnection then floatConnection:Disconnect() end
        floatBtn.Text = "Float Platform: OFF"
        floatBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
        setStatus("Float dimatikan")
    end
end)

-- ===== FLOAT SPEED =====
speedSetBtn.MouseButton1Click:Connect(function()
    local val = tonumber(speedInput.Text)
    if val then
        val = math.clamp(val, 1, 1000)
        floatSpeed = val
        speedInput.Text = tostring(val)
        setStatus("Float speed: " .. val .. " stud/s")
    else
        speedInput.Text = tostring(floatSpeed)
        setStatus("Input angka valid! (1-1000)", Color3.fromRGB(255, 100, 100))
    end
end)

-- ===== WALL CLIMB TOGGLE =====
wallBtn.MouseButton1Click:Connect(function()
    wallClimbEnabled = not wallClimbEnabled
    if wallClimbEnabled then
        enableWallClimb()
        startWallClimbLoop()
        wallBtn.Text = "Wall Climb: ON"
        wallBtn.BackgroundColor3 = Color3.fromRGB(160, 40, 40)
        setStatus("Spiderman Mode AKTIF!")
    else
        disableWallClimb()
        if wallClimbConnection then wallClimbConnection:Disconnect() end
        wallBtn.Text = "Wall Climb: OFF"
        wallBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
        setStatus("Wall Climb dimatikan")
    end
end)

-- ===== NOCLIP TOGGLE =====
noclipBtn.MouseButton1Click:Connect(function()
    noclipEnabled = not noclipEnabled
    if noclipEnabled then
        startNoclip()
        noclipBtn.Text = "Noclip: ON"
        noclipBtn.BackgroundColor3 = Color3.fromRGB(40, 130, 80)
        setStatus("Noclip AKTIF! Tembus semua objek")
    else
        stopNoclip()
        noclipBtn.Text = "Noclip: OFF"
        noclipBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
        setStatus("Noclip dimatikan")
    end
end)

-- ===== FLY MODE TOGGLE =====
flyBtn.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    if flyEnabled then
        enableFly()
        startFlyLoop()
        flyBtn.Text = "Fly Mode: ON"
        flyBtn.BackgroundColor3 = Color3.fromRGB(200, 120, 0)
        setStatus("Fly AKTIF! WASD + Up/Down terbang")
    else
        disableFly()
        if flyConnection then flyConnection:Disconnect() end
        flyBtn.Text = "Fly Mode: OFF"
        flyBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
        setStatus("Fly dimatikan")
    end
end)

-- ===== FLY SPEED =====
flySpeedSetBtn.MouseButton1Click:Connect(function()
    local val = tonumber(flySpeedInput.Text)
    if val then
        val = math.clamp(val, 1, 1000)
        flySpeed = val
        flySpeedInput.Text = tostring(val)
        setStatus("Fly speed: " .. val .. " stud/s")
    else
        flySpeedInput.Text = tostring(flySpeed)
        setStatus("Input angka valid! (1-1000)", Color3.fromRGB(255, 100, 100))
    end
end)

-- ===== WALK SPEED =====
walkSpeedSetBtn.MouseButton1Click:Connect(function()
    local val = tonumber(walkSpeedInput.Text)
    if val then
        val = math.clamp(val, 0, 1000)
        walkSpeedValue = val
        humanoid.WalkSpeed = val
        walkSpeedInput.Text = tostring(val)
        setStatus("WalkSpeed: " .. val)
    else
        walkSpeedInput.Text = tostring(walkSpeedValue)
        setStatus("Input angka valid! (0-1000)", Color3.fromRGB(255, 100, 100))
    end
end)

resetSpeedBtn.MouseButton1Click:Connect(function()
    walkSpeedValue = 16
    humanoid.WalkSpeed = 16
    walkSpeedInput.Text = "16"
    setStatus("WalkSpeed di-reset ke 16")
end)

-- ===== JUMP POWER =====
jumpSetBtn.MouseButton1Click:Connect(function()
    local val = tonumber(jumpInput.Text)
    if val then
        val = math.clamp(val, 0, 1000)
        jumpPowerValue = val
        humanoid.JumpPower = val
        humanoid.UseJumpPower = true
        jumpInput.Text = tostring(val)
        setStatus("JumpPower: " .. val)
    else
        jumpInput.Text = tostring(jumpPowerValue)
        setStatus("Input angka valid! (0-1000)", Color3.fromRGB(255, 100, 100))
    end
end)

resetJumpBtn.MouseButton1Click:Connect(function()
    jumpPowerValue = 50
    humanoid.JumpPower = 50
    jumpInput.Text = "50"
    setStatus("JumpPower di-reset ke 50")
end)

-- ===== FREEZE TOGGLE =====
freezeBtn.MouseButton1Click:Connect(function()
    freezeEnabled = not freezeEnabled
    if freezeEnabled then
        startFreeze()
        freezeBtn.Text = "Freeze: ON"
        freezeBtn.BackgroundColor3 = Color3.fromRGB(0, 130, 180)
        setStatus("Frozen! Posisi terkunci di udara")
    else
        stopFreeze()
        freezeBtn.Text = "Freeze: OFF"
        freezeBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
        setStatus("Freeze dimatikan, bisa gerak lagi")
    end
end)

-- ===== WAYPOINTS =====
saveWpBtn.MouseButton1Click:Connect(function()
    if #waypoints >= maxWaypoints then
        setStatus("Max " .. maxWaypoints .. " waypoints! Clear dulu", Color3.fromRGB(255, 100, 100))
        return
    end

    local pos = humanoidRootPart.Position
    table.insert(waypoints, pos)
    updateWaypointUI()
    setStatus("Waypoint " .. #waypoints .. " saved!")
end)

clearWpBtn.MouseButton1Click:Connect(function()
    waypoints = {}
    updateWaypointUI()
    setStatus("Semua waypoints dihapus")
end)

-- ===== PLATFORM STYLE =====
platSizeSetBtn.MouseButton1Click:Connect(function()
    local val = tonumber(platSizeInput.Text)
    if val then
        val = math.clamp(val, 1, 50)
        platformSize = Vector3.new(val, 0.5, val)
        if floatPart and floatPart.Parent then
            floatPart.Size = platformSize
        end
        platSizeInput.Text = tostring(val)
        setStatus("Platform size: " .. val .. "x" .. val)
    else
        setStatus("Input angka valid! (1-50)", Color3.fromRGB(255, 100, 100))
    end
end)

platTransSetBtn.MouseButton1Click:Connect(function()
    local val = tonumber(platTransInput.Text)
    if val then
        val = math.clamp(val, 0, 1)
        platformTransparency = val
        if floatPart and floatPart.Parent then
            floatPart.Transparency = platformTransparency
        end
        platTransInput.Text = tostring(val)
        setStatus("Platform transparency: " .. val)
    else
        setStatus("Input 0-1 (0=solid, 1=invisible)", Color3.fromRGB(255, 100, 100))
    end
end)

invisPlatBtn.MouseButton1Click:Connect(function()
    platformTransparency = 1
    if floatPart and floatPart.Parent then
        floatPart.Transparency = 1
    end
    platTransInput.Text = "1"
    setStatus("Platform INVISIBLE! Ghost mode aktif")
end)

-- ===== CUSTOM KEYBIND =====
local function getKeyName(keyCode)
    return tostring(keyCode):gsub("Enum.KeyCode.", "")
end

keybindUpBtn.MouseButton1Click:Connect(function()
    waitingForKey = "up"
    keybindUpBtn.Text = "UP Key: [Tekan key baru...]"
    keybindUpBtn.BackgroundColor3 = Color3.fromRGB(200, 120, 0)
    setStatus("Tekan tombol baru untuk UP...")
end)

keybindDownBtn.MouseButton1Click:Connect(function()
    waitingForKey = "down"
    keybindDownBtn.Text = "DOWN Key: [Tekan key baru...]"
    keybindDownBtn.BackgroundColor3 = Color3.fromRGB(200, 120, 0)
    setStatus("Tekan tombol baru untuk DOWN...")
end)

-- ===== INFINITE JUMP =====
infiniteJumpBtn.MouseButton1Click:Connect(function()
    infiniteJumpEnabled = not infiniteJumpEnabled
    if infiniteJumpEnabled then
        startInfiniteJump()
        infiniteJumpBtn.Text = "Infinite Jump: ON"
        infiniteJumpBtn.BackgroundColor3 = Color3.fromRGB(40, 130, 80)
        setStatus("Infinite Jump AKTIF!")
    else
        stopInfiniteJump()
        infiniteJumpBtn.Text = "Infinite Jump: OFF"
        infiniteJumpBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
        setStatus("Infinite Jump dimatikan")
    end
end)

-- ===== GOD MODE =====
godModeBtn.MouseButton1Click:Connect(function()
    godModeEnabled = not godModeEnabled
    if godModeEnabled then
        startGodMode()
        godModeBtn.Text = "Anti-Death (God Mode): ON"
        godModeBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
        setStatus("God Mode AKTIF! Gak bisa mati")
    else
        stopGodMode()
        godModeBtn.Text = "Anti-Death (God Mode): OFF"
        godModeBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
        setStatus("God Mode dimatikan")
    end
end)

-- ===== MINIMIZE =====
local isMinimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        scrollFrame.Visible = false
        mainFrame.Size = UDim2.new(0, 280, 0, 40)
        minimizeBtn.Text = "+"
    else
        scrollFrame.Visible = true
        mainFrame.Size = UDim2.new(0, 280, 0, 420)
        minimizeBtn.Text = "-"
    end
end)

-- ================================================================
--               GLOBAL INPUT HANDLER
-- ================================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    -- Custom keybind listener
    if waitingForKey and input.KeyCode ~= Enum.KeyCode.Unknown then
        if waitingForKey == "up" then
            keyUp = input.KeyCode
            keybindUpBtn.Text = "UP Key: " .. getKeyName(input.KeyCode)
            keybindUpBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 75)
            setStatus("UP key diubah ke: " .. getKeyName(input.KeyCode))
        elseif waitingForKey == "down" then
            keyDown = input.KeyCode
            keybindDownBtn.Text = "DOWN Key: " .. getKeyName(input.KeyCode)
            keybindDownBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 75)
            setStatus("DOWN key diubah ke: " .. getKeyName(input.KeyCode))
        end
        waitingForKey = nil
        return
    end

    -- Float naik/turun
    if input.KeyCode == keyUp then
        goingUp = true
    elseif input.KeyCode == keyDown then
        goingDown = true
    end

    -- Toggle shortcuts
    if input.KeyCode == Enum.KeyCode.F then
        -- F = toggle float (shortcut)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == keyUp then
        goingUp = false
    elseif input.KeyCode == keyDown then
        goingDown = false
    end
end)

-- ================================================================
--              RESPAWN HANDLER (ANTI-ERROR)
-- ================================================================
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")

    -- Reset all states
    floatEnabled = false
    wallClimbEnabled = false
    noclipEnabled = false
    flyEnabled = false
    freezeEnabled = false
    infiniteJumpEnabled = false
    godModeEnabled = false
    goingUp = false
    goingDown = false

    -- Cleanup
    removeFloatPlatform()
    disableWallClimb()
    stopNoclip()
    disableFly()
    stopFreeze()
    stopInfiniteJump()
    stopGodMode()

    -- Disconnect all loops
    if floatConnection then floatConnection:Disconnect(); floatConnection = nil end
    if wallClimbConnection then wallClimbConnection:Disconnect(); wallClimbConnection = nil end
    if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
    if freezeConnection then freezeConnection:Disconnect(); freezeConnection = nil end
    if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end

    -- Reset GUI buttons
    floatBtn.Text = "Float Platform: OFF"
    floatBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
    wallBtn.Text = "Wall Climb: OFF"
    wallBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
    noclipBtn.Text = "Noclip: OFF"
    noclipBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
    flyBtn.Text = "Fly Mode: OFF"
    flyBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
    freezeBtn.Text = "Freeze: OFF"
    freezeBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
    infiniteJumpBtn.Text = "Infinite Jump: OFF"
    infiniteJumpBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
    godModeBtn.Text = "Anti-Death (God Mode): OFF"
    godModeBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)

    -- Re-apply speed/jump if modified
    if walkSpeedValue ~= 16 then
        humanoid.WalkSpeed = walkSpeedValue
    end
    if jumpPowerValue ~= 50 then
        humanoid.JumpPower = jumpPowerValue
        humanoid.UseJumpPower = true
    end

    setStatus("Respawned! Semua fitur di-reset")
end)

-- ================================================================
--              STARTUP NOTIFICATION
-- ================================================================
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "ScriptMaster ULTIMATE",
        Text = "12 Fitur Loaded! GUI di kiri layar",
        Duration = 4
    })
end)

setStatus("ScriptMaster ULTIMATE Ready! 12 Fitur aktif")

-- ================================================================
--   LOADSTRING INFO: Untuk load dari GitHub
--   loadstring(game:HttpService():GetAsync('URL_RAW'))()
-- ================================================================
