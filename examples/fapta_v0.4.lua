local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SCRIPT_VERSION = "0.4"
local HertaIX = loadstring(game:HttpGet("https://raw.githubusercontent.com/midorimidoru1-collab/HertaIX/master/HertaIX.lua"))()
local Window = HertaIX:CreateWindow("Fapta demo v" .. SCRIPT_VERSION, "near_future")
Window:SetTitleRainbow(true)
Window:SetTitleFont("arcade")
local ReanimateTab = Window:CreateTab("REANIMATE")
local MoreFunctionTab = Window:CreateTab("MORE FUNCTION")
local DefenseTab = Window:CreateTab("DEFENSE")
local StaffTab = Window:CreateTab("STAFF ROLL")
local LP = Players.LocalPlayer
local TOY_NAME = "TableWoodTwoLegs"
local HEAD_TOY_NAME = "GlassBoxGray"
local TOY_SIZE = Vector3.new(13.75, 7, 0.375)
local LIMB_ASSEMBLY_SIZE = Vector3.new(13.75, 7, 7)
local TORSO_ASSEMBLY_SIZE = Vector3.new(13.75, 14, 7)
local POSITION_SCALE = 7
local SIZE_TOLERANCE = 0.03
local TOY_ROTATION_OFFSET = CFrame.Angles(math.rad(180), 0, 0)
local WAIT_POS_Y = -70
local Units = {}
local HeadParts = {}
local TorsoParts = {}
local FireworkSparklers = {}
local Tetracubels = {}
local CollisionState = {}
local CollisionRecorded = {}
local isBuilt = false
local isTracing = false
local fireworkSpinEnabled = false
local fireworkSpinAngle = 0
local tetracubelSpinEnabled = false
local tetracubelSpinAngle = 0
local autoSaveRunning = false
local autoHouseEnabled = false
local tpWalkEnabled = false
local tpWalkOriginalGravity = nil
local tpWalkCharacterState = nil
local tpWalkHeartbeatConnection = nil
local tpWalkCharacterAddedConnection = nil
local TORSO_TRACE_Y_OFFSET = 17.875
local FIREWORK_TOY_NAME = "FireworkSparkler"
local TETRACUBEL_TOY_NAME = "TetracubeI"
local BACK_SPIN_DISTANCE = 8
local backSpinVerticalOffset = 0
local fireworkOrbitRadius = 7
local tetracubelOrbitRadius = 10
local backSpinRotationSpeed = 75
local autoHouseSession = 0
local FOLDER_OPTIONS = {"SpawnedInToys", "Plot1", "Plot2", "Plot3", "Plot4", "Plot5"}
local selectedFolderOption = "SpawnedInToys"
local function rotationOnly(cf)
    return cf - cf.Position
end
local function approximatelyEqual(a, b, tolerance)
    return math.abs(a - b) <= tolerance
end
local function approximatelyEqualVector(a, b, tolerance)
    return approximatelyEqual(a.X, b.X, tolerance)
        and approximatelyEqual(a.Y, b.Y, tolerance)
        and approximatelyEqual(a.Z, b.Z, tolerance)
end
local function clearAllBodyMovers(part)
    for _, child in ipairs(part:GetChildren()) do
        if child:IsA("BodyPosition") or child:IsA("BodyGyro") then
            child:Destroy()
        end
    end
end
local function clearOwnedBodyMovers(part)
    for _, child in ipairs(part:GetChildren()) do
        if child.Name == "GiantTraceBodyPosition" or child.Name == "GiantTraceBodyGyro" then
            child:Destroy()
        end
    end
end
local function attachBodyMovers(part)
    clearAllBodyMovers(part)
    local bodyPosition = Instance.new("BodyPosition")
    bodyPosition.Name = "GiantTraceBodyPosition"
    bodyPosition.MaxForce = Vector3.new(1, 1, 1) * 1e10
    bodyPosition.P = 15000
    bodyPosition.D = 200
    bodyPosition.Parent = part
    local bodyGyro = Instance.new("BodyGyro")
    bodyGyro.Name = "GiantTraceBodyGyro"
    bodyGyro.MaxTorque = Vector3.new(1, 1, 1) * 1e10
    bodyGyro.P = 15000
    bodyGyro.D = 200
    bodyGyro.Parent = part
    return bodyGyro, bodyPosition
end
local function recordAndDisableCollisions(model)
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            if not CollisionRecorded[descendant] then
                CollisionRecorded[descendant] = true
                table.insert(CollisionState, {
                    Part = descendant,
                    CanCollide = descendant.CanCollide,
                })
            end
            descendant.CanCollide = false
        end
    end
end
local function restoreCollisions()
    for _, entry in ipairs(CollisionState) do
        if entry.Part and entry.Part.Parent then
            entry.Part.CanCollide = entry.CanCollide
        end
    end
    CollisionState = {}
    CollisionRecorded = {}
end
local function destroyGroupMovers(group)
    for _, data in ipairs(group) do
        if data.Part and data.Part.Parent then
            clearOwnedBodyMovers(data.Part)
        end
    end
end
local function cleanupGiant()
    for _, group in ipairs(Units) do
        destroyGroupMovers(group)
    end
    destroyGroupMovers(HeadParts)
    destroyGroupMovers(TorsoParts)
    restoreCollisions()
    Units = {}
    HeadParts = {}
    TorsoParts = {}
    isBuilt = false
end
local function setTarget(data, targetCF)
    if data.Part and data.Part.Parent and data.BP and data.BG then
        local traceYOffset = isTracing and TORSO_TRACE_Y_OFFSET or 0
        local torsoAnchoredTargetCF = CFrame.new(0, traceYOffset, 0) * targetCF
        local finalCF = torsoAnchoredTargetCF * TOY_ROTATION_OFFSET
        data.BP.Position = finalCF.Position
        data.BG.CFrame = finalCF
    end
end
local function setGroupTarget(group, assemblyCF)
    for _, data in ipairs(group) do
        setTarget(data, assemblyCF * data.LocalCF)
    end
end
local function calculateAssemblyBounds(group)
    local minX, minY, minZ = math.huge, math.huge, math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
    for _, data in ipairs(group) do
        local cf = data.LocalCF
        local size = data.Part.Size
        local halfX = (
            math.abs(cf.XVector.X) * size.X
            + math.abs(cf.YVector.X) * size.Y
            + math.abs(cf.ZVector.X) * size.Z
        ) / 2
        local halfY = (
            math.abs(cf.XVector.Y) * size.X
            + math.abs(cf.YVector.Y) * size.Y
            + math.abs(cf.ZVector.Y) * size.Z
        ) / 2
        local halfZ = (
            math.abs(cf.XVector.Z) * size.X
            + math.abs(cf.YVector.Z) * size.Y
            + math.abs(cf.ZVector.Z) * size.Z
        ) / 2
        minX = math.min(minX, cf.Position.X - halfX)
        minY = math.min(minY, cf.Position.Y - halfY)
        minZ = math.min(minZ, cf.Position.Z - halfZ)
        maxX = math.max(maxX, cf.Position.X + halfX)
        maxY = math.max(maxY, cf.Position.Y + halfY)
        maxZ = math.max(maxZ, cf.Position.Z + halfZ)
    end
    return Vector3.new(maxX - minX, maxY - minY, maxZ - minZ)
end
local function validateAssemblySize(label, group, expectedSize)
    local measuredSize = calculateAssemblyBounds(group)
    if not approximatelyEqualVector(measuredSize, expectedSize, SIZE_TOLERANCE) then
        return false, string.format(
            "%s size mismatch. expected %.3f, %.3f, %.3f / measured %.3f, %.3f, %.3f",
            label,
            expectedSize.X, expectedSize.Y, expectedSize.Z,
            measuredSize.X, measuredSize.Y, measuredSize.Z
        )
    end
    return true, measuredSize
end
local function validateWoodToyPart(part)
    if not approximatelyEqualVector(part.Size, TOY_SIZE, SIZE_TOLERANCE) then
        return false, string.format(
            "TableWoodTwoLegs size mismatch. expected %.3f, %.3f, %.3f / got %.3f, %.3f, %.3f",
            TOY_SIZE.X, TOY_SIZE.Y, TOY_SIZE.Z,
            part.Size.X, part.Size.Y, part.Size.Z
        )
    end
    return true
end
local function findMatchingSoundPart(model)
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant.Name == "SoundPart"
            and descendant:IsA("BasePart")
            and approximatelyEqualVector(descendant.Size, TOY_SIZE, SIZE_TOLERANCE) then
            return descendant
        end
    end
    return nil
end
local function getHeadModelPart(model)
    return model:FindFirstChildWhichIsA("BasePart", true)
end
local function makePartData(model, part)
    recordAndDisableCollisions(model)
    local bg, bp = attachBodyMovers(part)
    return {
        Part = part,
        BG = bg,
        BP = bp,
        LocalCF = CFrame.new(),
    }
end
local function assignLimbLayout(group)
    local faceOffsetZ = (LIMB_ASSEMBLY_SIZE.Z - TOY_SIZE.Z) / 2
    local capOffsetY = (LIMB_ASSEMBLY_SIZE.Y - TOY_SIZE.Z) / 2
    local layout = {
        CFrame.new(0, 0, -faceOffsetZ),
        CFrame.new(0, 0, faceOffsetZ) * CFrame.Angles(0, math.rad(180), 0),
        CFrame.new(0, capOffsetY, 0) * CFrame.Angles(math.rad(90), 0, 0),
        CFrame.new(0, -capOffsetY, 0) * CFrame.Angles(math.rad(-90), 0, 0),
    }
    for slot, data in ipairs(group) do
        data.LocalCF = layout[slot]
    end
end
local function assignTorsoLayout(group)
    local faceOffsetZ = (TORSO_ASSEMBLY_SIZE.Z - TOY_SIZE.Z) / 2
    local faceHalfHeight = TOY_SIZE.Y / 2
    local capOffsetY = (TORSO_ASSEMBLY_SIZE.Y - TOY_SIZE.Z) / 2
    local layout = {
        CFrame.new(0, -faceHalfHeight, -faceOffsetZ),
        CFrame.new(0, faceHalfHeight, -faceOffsetZ),
        CFrame.new(0, -faceHalfHeight, faceOffsetZ) * CFrame.Angles(0, math.rad(180), 0),
        CFrame.new(0, faceHalfHeight, faceOffsetZ) * CFrame.Angles(0, math.rad(180), 0),
        CFrame.new(0, capOffsetY, 0) * CFrame.Angles(math.rad(90), 0, 0),
        CFrame.new(0, -capOffsetY, 0) * CFrame.Angles(math.rad(-90), 0, 0),
    }
    for slot, data in ipairs(group) do
        data.LocalCF = layout[slot]
    end
end
local function moveToWaitPosition()
    local spacing = 5
    local currentX = 0
    local currentZ = 0
    local function place(data)
        setTarget(data, CFrame.new(currentX, WAIT_POS_Y, currentZ))
        currentX = currentX + spacing
        if currentX > 50 then
            currentX = 0
            currentZ = currentZ + spacing
        end
    end
    for _, group in ipairs(Units) do
        for _, data in ipairs(group) do
            place(data)
        end
    end
    for _, data in ipairs(HeadParts) do
        place(data)
    end
    for _, data in ipairs(TorsoParts) do
        place(data)
    end
end
local function resolveSelectedFolder()
    if selectedFolderOption:match("^Plot[1-5]$") then
        local plotItems = workspace:FindFirstChild("PlotItems")
        local plotFolder = plotItems and plotItems:FindFirstChild(selectedFolderOption) or nil
        return plotFolder, "PlotItems." .. selectedFolderOption
    end
    local standardName = LP.Name .. "SpawnedInToys"
    local legacyName = LP.Name .. "SpawnedinToys"
    local folder = workspace:FindFirstChild(standardName) or workspace:FindFirstChild(legacyName)
    return folder, standardName .. " or " .. legacyName
end
local function restoreSpinGroup(group)
    for _, data in ipairs(group) do
        if data.Part and data.Part.Parent then
            clearOwnedBodyMovers(data.Part)
        end
        if data.Model and data.Model.Parent then
            pcall(function()
                data.Model:PivotTo(data.OriginalModelPivot)
            end)
        end
        for _, partState in ipairs(data.PartStates) do
            if partState.Part and partState.Part.Parent then
                partState.Part.Anchored = partState.Anchored
                partState.Part.CanCollide = partState.CanCollide
            end
        end
    end
end
local function restoreFireworkSparklers()
    local hadToys = fireworkSpinEnabled or #FireworkSparklers > 0
    fireworkSpinEnabled = false
    fireworkSpinAngle = 0
    restoreSpinGroup(FireworkSparklers)
    FireworkSparklers = {}
    return hadToys
end
local function restoreTetracubels()
    local hadToys = tetracubelSpinEnabled or #Tetracubels > 0
    tetracubelSpinEnabled = false
    tetracubelSpinAngle = 0
    restoreSpinGroup(Tetracubels)
    Tetracubels = {}
    return hadToys
end
local function collectAndAttachSpinToys(folder, toyName)
    local toys = {}
    for _, model in ipairs(folder:GetChildren()) do
        if model:IsA("Model") and model.Name == toyName then
            local soundPart = model:FindFirstChild("SoundPart")
            if soundPart and soundPart:IsA("BasePart") then
                local partStates = {}
                for _, descendant in ipairs(model:GetDescendants()) do
                    if descendant:IsA("BasePart") then
                        table.insert(partStates, {
                            Part = descendant,
                            Anchored = descendant.Anchored,
                            CanCollide = descendant.CanCollide,
                        })
                        descendant.Anchored = false
                        descendant.CanCollide = false
                    end
                end
                local bodyGyro, bodyPosition = attachBodyMovers(soundPart)
                bodyPosition.Position = soundPart.Position
                bodyGyro.CFrame = soundPart.CFrame
                table.insert(toys, {
                    Model = model,
                    Part = soundPart,
                    BP = bodyPosition,
                    BG = bodyGyro,
                    OriginalModelPivot = model:GetPivot(),
                    OriginalRotation = rotationOnly(soundPart.CFrame),
                    PartStates = partStates,
                })
            end
        end
    end
    return toys
end
local function prepareSpinToys(toyName)
    local folder, folderLabel = resolveSelectedFolder()
    if not folder then
        return false, {}, string.format("Selected folder is not found: %s", folderLabel)
    end
    local toys = collectAndAttachSpinToys(folder, toyName)
    if #toys == 0 then
        return false, {}, string.format("No %s objects were found in %s", toyName, folder.Name)
    end
    return true, toys, string.format("attached movers to %d %s objects", #toys, toyName)
end
local function applyFireworkSparklers()
    restoreFireworkSparklers()
    local success, toys, message = prepareSpinToys(FIREWORK_TOY_NAME)
    if not success then
        return false, message
    end
    FireworkSparklers = toys
    fireworkSpinAngle = 0
    return true, message
end
local function applyTetracubels()
    restoreTetracubels()
    local success, toys, message = prepareSpinToys(TETRACUBEL_TOY_NAME)
    if not success then
        return false, message
    end
    Tetracubels = toys
    tetracubelSpinAngle = 0
    return true, message
end
local function updateSpinGroup(group, backCenterCF, spinAngle, radius)
    local count = #group
    if count == 0 then
        return
    end
    for index, data in ipairs(group) do
        if data.Part and data.Part.Parent and data.BP and data.BP.Parent and data.BG and data.BG.Parent then
            local angle = spinAngle + ((index - 1) / count) * math.pi * 2
            local targetCF = backCenterCF
                * CFrame.Angles(0, 0, angle)
                * CFrame.new(0, radius, 0)
                * data.OriginalRotation
            data.BP.Position = targetCF.Position
            data.BG.CFrame = targetCF
        end
    end
end
local function updateToySpin(group, currentAngle, direction, radius, deltaTime)
    local character = LP.Character
    local torso = character and (character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso"))
    if not torso then
        return currentAngle
    end
    currentAngle = (currentAngle + direction * math.rad(backSpinRotationSpeed) * deltaTime) % (math.pi * 2)
    local giantTorsoCF = CFrame.new(0, TORSO_TRACE_Y_OFFSET, 0) * torso.CFrame
    local backCenterCF = giantTorsoCF * CFrame.new(0, backSpinVerticalOffset, BACK_SPIN_DISTANCE)
    updateSpinGroup(group, backCenterCF, currentAngle, radius)
    return currentAngle
end
local function updateFireworkSpin(deltaTime)
    if not fireworkSpinEnabled then
        return
    end
    fireworkSpinAngle = updateToySpin(
        FireworkSparklers,
        fireworkSpinAngle,
        1,
        fireworkOrbitRadius,
        deltaTime
    )
end
local function updateTetracubelSpin(deltaTime)
    if not tetracubelSpinEnabled then
        return
    end
    tetracubelSpinAngle = updateToySpin(
        Tetracubels,
        tetracubelSpinAngle,
        -1,
        tetracubelOrbitRadius,
        deltaTime
    )
end
local function buildGiant()
    cleanupGiant()
    local folder, folderLabel = resolveSelectedFolder()
    if not folder then
        Window:Notify("BUILD ERROR", string.format("Selected folder is not found: %s", folderLabel), 6)
        return
    end
    local woodCandidates = {}
    local headCandidates = {}
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") then
            if child.Name == TOY_NAME then
                local soundPart = findMatchingSoundPart(child)
                if soundPart then
                    table.insert(woodCandidates, {Model = child, Part = soundPart})
                end
            elseif child.Name == HEAD_TOY_NAME then
                local part = getHeadModelPart(child)
                if part then
                    table.insert(headCandidates, {Model = child, Part = part})
                end
            end
        end
    end
    if #woodCandidates == 0 then
        Window:Notify(
            "BUILD ERROR",
            "No TableWoodTwoLegs SoundPart with size 13.75, 7, 0.375 was found",
            7
        )
        return
    end
    local usableWoodCount = math.min(#woodCandidates, 22)
    for index = 1, usableWoodCount do
        local valid, message = validateWoodToyPart(woodCandidates[index].Part)
        if not valid then
            Window:Notify("BUILD ERROR", message, 7)
            return
        end
    end
    local nextWoodIndex = 1
    local function takeNextWoodPart()
        if nextWoodIndex > usableWoodCount then
            return nil
        end
        local candidate = woodCandidates[nextWoodIndex]
        nextWoodIndex = nextWoodIndex + 1
        return makePartData(candidate.Model, candidate.Part)
    end
    local completeLimbCount = 0
    local limbPartCount = 0
    for limbIndex = 1, 4 do
        local group = {}
        for _ = 1, 4 do
            local data = takeNextWoodPart()
            if not data then
                break
            end
            table.insert(group, data)
        end
        if #group > 0 then
            assignLimbLayout(group)
            limbPartCount = limbPartCount + #group
            if #group == 4 then
                local valid, result = validateAssemblySize("limb", group, LIMB_ASSEMBLY_SIZE)
                if not valid then
                    cleanupGiant()
                    Window:Notify("BUILD ERROR", result, 7)
                    return
                end
                completeLimbCount = completeLimbCount + 1
            end
            table.insert(Units, group)
        end
    end
    while #TorsoParts < 6 do
        local data = takeNextWoodPart()
        if not data then
            break
        end
        table.insert(TorsoParts, data)
    end
    if #TorsoParts > 0 then
        assignTorsoLayout(TorsoParts)
        if #TorsoParts == 6 then
            local torsoValid, torsoResult = validateAssemblySize("torso", TorsoParts, TORSO_ASSEMBLY_SIZE)
            if not torsoValid then
                cleanupGiant()
                Window:Notify("BUILD ERROR", torsoResult, 7)
                return
            end
        end
    end
    for _, candidate in ipairs(headCandidates) do
        table.insert(HeadParts, makePartData(candidate.Model, candidate.Part))
    end
    isBuilt = true
    moveToWaitPosition()
    local torsoFrontBackCount = math.min(#TorsoParts, 4)
    local torsoSideCount = math.max(#TorsoParts - 4, 0)
    local headMessage = #HeadParts > 0 and string.format("head parts: %d", #HeadParts) or "head part: none"
    Window:Notify(
        "GIANT BUILT",
        string.format(
            "folder %s | wood %d/22 | limbs %d/4 complete (%d parts) | torso front/back %d/4, sides %d/2 | %s",
            folder.Name, usableWoodCount, completeLimbCount, limbPartCount,
            torsoFrontBackCount, torsoSideCount, headMessage
        ),
        7
    )
end
local R6_LIMB_NAMES = {
    "Left Arm",
    "Right Arm",
    "Left Leg",
    "Right Leg",
}
local function getScaledRelativePartCF(torsoCF, partCF)
    local relativeCF = torsoCF:ToObjectSpace(partCF)
    local scaledPosition = relativeCF.Position * POSITION_SCALE
    return torsoCF * CFrame.new(scaledPosition) * rotationOnly(relativeCF)
end
local function traceHeadAsBefore(torso, head)
    local headRelativePosition = torso.CFrame:PointToObjectSpace(head.Position)
    local scaledHeadRelativePosition = Vector3.new(
        headRelativePosition.X * POSITION_SCALE,
        (headRelativePosition.Y * 4) + 5.7,
        headRelativePosition.Z * POSITION_SCALE
    )
    local worldHeadPosition = torso.CFrame:PointToWorldSpace(scaledHeadRelativePosition)
    local headRotation = rotationOnly(head.CFrame) * CFrame.Angles(math.rad(180), 0, 0)
    local headCF = CFrame.new(worldHeadPosition) * headRotation
    for _, data in ipairs(HeadParts) do
        local finalCF = headCF * CFrame.new(-4.5, 0, 0)
        setTarget(data, finalCF * CFrame.Angles(math.rad(90), 0, 0))
    end
end
local function tracePlayer()
    local character = LP.Character
    if not character then
        return
    end
    local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
    local head = character:FindFirstChild("Head")
    if not torso or not head then
        return
    end
    local limbAxisAlignment = CFrame.Angles(0, 0, math.rad(90))
    local limbTargetCFs = {}
    for index, limbName in ipairs(R6_LIMB_NAMES) do
        local limb = character:FindFirstChild(limbName)
        if limb then
            limbTargetCFs[index] = getScaledRelativePartCF(torso.CFrame, limb.CFrame) * limbAxisAlignment
        end
    end
    setGroupTarget(TorsoParts, torso.CFrame)
    for index, _ in ipairs(R6_LIMB_NAMES) do
        local group = Units[index]
        local targetCF = limbTargetCFs[index]
        if group and targetCF then
            setGroupTarget(group, targetCF)
        end
    end
    traceHeadAsBefore(torso, head)
end
local AUTO_HOUSE_TARGET_CFS = {
    Plot1 = CFrame.new(-550, -7.35, 50),
    Plot2 = CFrame.new(-500, -7.35, -150),
    Plot3 = CFrame.new(240, -7.35, 450),
    Plot4 = CFrame.new(500, 85, -340),
    Plot5 = CFrame.new(550, 125, -100),
}
local AUTO_HOUSE_HOLD_SECONDS = 0.5
local AUTO_HOUSE_INTERVAL_SECONDS = 80
local function saveHouseTeleport()
    local targetCF = AUTO_HOUSE_TARGET_CFS[selectedFolderOption]
    if not targetCF then
        Window:Notify("HOUSE", "House Ownership is available only for Plot1 - Plot5", 5)
        return false
    end
    local character = LP.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        Window:Notify("HOUSE", "HumanoidRootPart not found", 4)
        return false
    end
    local oldCFrame = root.CFrame
    local startedAt = tick()
    while tick() - startedAt < AUTO_HOUSE_HOLD_SECONDS do
        if not root.Parent then
            return false
        end
        root.CFrame = targetCF
        RunService.Heartbeat:Wait()
    end
    if root.Parent then
        root.CFrame = oldCFrame
    end
    return true
end
local function setAutoHouseEnabled(value)
    if value and not AUTO_HOUSE_TARGET_CFS[selectedFolderOption] then
        Window:Notify("HOUSE", "Select Plot1 - Plot5 before enabling House Ownership", 5)
        return false
    end
    local wasEnabled = autoHouseEnabled
    autoHouseEnabled = value
    autoHouseSession = autoHouseSession + 1
    local session = autoHouseSession
    if not value then
        if wasEnabled then
            Window:Notify("HOUSE", "off", 3)
        end
        return true
    end
    Window:Notify("HOUSE", selectedFolderOption .. " on (runs every 80 seconds)", 4)
    task.spawn(function()
        if not saveHouseTeleport() then
            autoHouseEnabled = false
            return
        end
        while autoHouseEnabled and session == autoHouseSession do
            task.wait(AUTO_HOUSE_INTERVAL_SECONDS)
            if autoHouseEnabled and session == autoHouseSession then
                if not saveHouseTeleport() then
                    autoHouseEnabled = false
                    return
                end
            end
        end
    end)
    return true
end
local AUTO_SAVE_URL = "https://pastebin.com/raw/g9NG7Jcq"
local function runAutoSave()
    if autoSaveRunning then
        Window:Notify("Console", "already running", 3)
        return
    end
    autoSaveRunning = true
    Window:Notify("Console", "loading external script...", 3)
    local success, err = pcall(function()
        local source = game:HttpGet(AUTO_SAVE_URL)
        local externalAutoSave, compileErr = loadstring(source)
        if not externalAutoSave then
            error("external script compile error: " .. tostring(compileErr))
        end
        externalAutoSave()
    end)
    autoSaveRunning = false
    if success then
        Window:Notify("Console", "external script finished", 4)
    else
        Window:Notify("ERROR", tostring(err), 6)
        warn("[fapta] external auto save failed:", err)
    end
end
do
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")
    local LocalPlayer = LP
local State = {
    AntiGrab = false,
    AntiKick = false,
    AntiGrabProcessing = false,
    AntiGrabRagdollCount = 0,
    AntiKickLoopRunning = false,
    AntiKickNoCoinsNotified = false,
    AntiLag = false,
    AntiKill = false,
    AntiKillBusy = false,
    AntiKillHolding = false,
    AntiKillLastAction = 0,
    AntiRagdoll = false,
    AntiRagdollLoopRunning = false,
}
local Connections = {
    CharacterAdded = nil,
    HeadAdded = nil,
    RenderStepped = nil,
}
local function GetRemotes()
    local grabEvents = ReplicatedStorage:FindFirstChild("GrabEvents")
    local characterEvents = ReplicatedStorage:FindFirstChild("CharacterEvents")
    local menuToys = ReplicatedStorage:FindFirstChild("MenuToys")
    local playerEvents = ReplicatedStorage:FindFirstChild("PlayerEvents")
    return {
        SetNetworkOwner = grabEvents and grabEvents:FindFirstChild("SetNetworkOwner"),
        RagdollRemote = characterEvents and characterEvents:FindFirstChild("RagdollRemote"),
        Struggle = characterEvents and characterEvents:FindFirstChild("Struggle"),
        BuyToy = menuToys and menuToys:FindFirstChild("BuyToyRemoteFunction"),
        SpawnToy = menuToys and menuToys:FindFirstChild("SpawnToyRemoteFunction"),
        DestroyToy = menuToys and menuToys:FindFirstChild("DestroyToy"),
        StickyPart = playerEvents and playerEvents:FindFirstChild("StickyPartEvent"),
    }
end
local function GetToyContents()
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    local menuGui = playerGui and playerGui:FindFirstChild("MenuGui")
    local menu = menuGui and menuGui:FindFirstChild("Menu")
    local tabContents = menu and menu:FindFirstChild("TabContents")
    local toys = tabContents and tabContents:FindFirstChild("Toys")
    return toys and toys:FindFirstChild("Contents")
end
local function Notify(title, message)
    Window:Notify(title, message, 3)
end
local function StopAntiGrabMovement(character)
    if Connections.RenderStepped then
        Connections.RenderStepped:Disconnect()
        Connections.RenderStepped = nil
    end
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.Anchored = false
    end
    State.AntiGrabProcessing = false
end
local function HandleAntiGrab(character, hrp, humanoid)
    if not State.AntiGrab or State.AntiGrabProcessing then
        return
    end
    State.AntiGrabProcessing = true
    humanoid.Sit = false
    local remotes = GetRemotes()
    if State.AntiGrabRagdollCount < 100 and remotes.RagdollRemote then
        pcall(function()
            remotes.RagdollRemote:FireServer(hrp, 0)
        end)
        State.AntiGrabRagdollCount = State.AntiGrabRagdollCount + 1
    end
    hrp.Anchored = true
    local isHeld
    repeat
        isHeld = LocalPlayer:FindFirstChild("IsHeld")
        task.wait()
    until not State.AntiGrab or (isHeld and isHeld.Value)
    if not State.AntiGrab then
        StopAntiGrabMovement(character)
        return
    end
    Connections.RenderStepped = RunService.RenderStepped:Connect(function()
        if not State.AntiGrab or not hrp.Parent or not humanoid.Parent then
            return
        end
        hrp.CFrame = hrp.CFrame + humanoid.MoveDirection * 0.3
    end)
    while State.AntiGrab and isHeld and isHeld.Value do
        task.wait()
    end
    StopAntiGrabMovement(character)
end
local function WatchCharacterForGrab(character)
    if Connections.HeadAdded then
        Connections.HeadAdded:Disconnect()
        Connections.HeadAdded = nil
    end
    local hrp = character:WaitForChild("HumanoidRootPart", 10)
    local humanoid = character:WaitForChild("Humanoid", 10)
    local head = character:WaitForChild("Head", 10)
    if not (hrp and humanoid and head) then
        return
    end
    local function OnPotentialGrab(child)
        if child.Name == "PartOwner" and State.AntiGrab then
            task.spawn(HandleAntiGrab, character, hrp, humanoid)
        end
    end
    Connections.HeadAdded = head.ChildAdded:Connect(OnPotentialGrab)
    local currentPartOwner = head:FindFirstChild("PartOwner")
    if currentPartOwner then
        OnPotentialGrab(currentPartOwner)
    end
end
Connections.CharacterAdded = LocalPlayer.CharacterAdded:Connect(WatchCharacterForGrab)
if LocalPlayer.Character then
    task.spawn(WatchCharacterForGrab, LocalPlayer.Character)
end
local function StartAntiGrabLoop()
    task.spawn(function()
        while State.AntiGrab do
            local remotes = GetRemotes()
            if remotes.Struggle then
                pcall(function()
                    remotes.Struggle:FireServer(LocalPlayer)
                end)
            end
            State.AntiGrabRagdollCount = 0
            task.wait(0.1)
        end
    end)
end
local AntiGrabToggle
AntiGrabToggle = DefenseTab:AddToggle("AntiGrab", false, function(enabled)
    State.AntiGrab = enabled
    if enabled then
        StartAntiGrabLoop()
        if LocalPlayer.Character then
            task.spawn(WatchCharacterForGrab, LocalPlayer.Character)
        end
        Notify("Anti-Grab", "Enabled")
    else
        StopAntiGrabMovement(LocalPlayer.Character)
        Notify("Anti-Grab", "Disabled")
    end
end)
local function SpawnKunaiBehindPlayer(remotes, toyName)
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not (hrp and remotes.SpawnToy) then
        return
    end
    local cf = hrp.CFrame
    pcall(function()
        remotes.SpawnToy:InvokeServer(
            toyName,
            cf - Vector3.new(cf.LookVector.X * 20, -15, cf.LookVector.Z * 20),
            Vector3.zero
        )
    end)
end
local function RunAntiKickCycle()
    local character = LocalPlayer.Character
    if not character then
        return
    end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rightLeg = character:FindFirstChild("Right Leg")
    if not hrp or not humanoid or not rightLeg or humanoid.Health <= 0 then
        return
    end
    local inPlot = LocalPlayer:FindFirstChild("InPlot")
    if inPlot and inPlot.Value then
        return
    end
    local remotes = GetRemotes()
    if not (remotes.BuyToy and remotes.SpawnToy and remotes.DestroyToy and remotes.StickyPart) then
        return
    end
    local toyContents = GetToyContents()
    if toyContents and not toyContents:FindFirstChild("NinjaKunai") then
        local success = false
        local ok = pcall(function()
            success = remotes.BuyToy:InvokeServer("NinjaKunai")
        end)
        if not ok or not success then
            if not State.AntiKickNoCoinsNotified then
                State.AntiKickNoCoinsNotified = true
                Notify("Anti-Kick", "NinjaKunai could not be purchased.")
            end
            return
        end
    end
    local spawnedToys = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
    local kunai = spawnedToys and spawnedToys:FindFirstChild("NinjaKunai")
    if kunai then
        local stickyPart = kunai:FindFirstChild("StickyPart")
        local stickyWeld = stickyPart and stickyPart:FindFirstChild("StickyWeld")
        local attachedPart = stickyWeld and stickyWeld.Part1
        if not stickyWeld or attachedPart ~= rightLeg then
            pcall(function()
                remotes.DestroyToy:FireServer(kunai)
            end)
            task.wait(0.1)
        end
        return
    end
    local canSpawnToy = LocalPlayer:FindFirstChild("CanSpawnToy")
    if not (canSpawnToy and canSpawnToy.Value) then
        return
    end
    SpawnKunaiBehindPlayer(remotes, "NinjaKunai")
    if not spawnedToys then
        spawnedToys = Workspace:WaitForChild(LocalPlayer.Name .. "SpawnedInToys", 3)
    end
    local newKunai = spawnedToys and spawnedToys:WaitForChild("NinjaKunai", 3)
    local stickyPart = newKunai and newKunai:WaitForChild("StickyPart", 2)
    local stickyWeld = stickyPart and stickyPart:FindFirstChild("StickyWeld")
    if not (stickyPart and stickyWeld) then
        return
    end
    if remotes.SetNetworkOwner then
        pcall(function()
            remotes.SetNetworkOwner:FireServer(stickyPart, stickyPart.CFrame)
        end)
    end
    local retry = 0
    while State.AntiKick and stickyWeld.Part1 == nil and retry < 20 do
        pcall(function()
            remotes.StickyPart:FireServer(
                stickyPart,
                rightLeg,
                CFrame.new(
                    0.0490287527, 0.5, 0,
                    0, 0.00739139877, -0.999561906,
                    -0.998452604, -0.0478846952, 0.0282763243,
                    -0.0476547107, 0.99882561, 0
                ) * CFrame.Angles(0, 0, 0)
            )
        end)
        task.wait(0.1)
        retry = retry + 1
    end
end
local function StartAntiKickLoop()
    if State.AntiKickLoopRunning then
        return
    end
    State.AntiKickLoopRunning = true
    task.spawn(function()
        while State.AntiKick do
            pcall(RunAntiKickCycle)
            task.wait()
        end
        State.AntiKickLoopRunning = false
    end)
end
local AntiKickToggle
AntiKickToggle = DefenseTab:AddToggle("AntiKick", false, function(enabled)
    State.AntiKick = enabled
    State.AntiKickNoCoinsNotified = false
    if enabled then
        StartAntiKickLoop()
        Notify("Anti-Kick", "Enabled")
    else
        Notify("Anti-Kick", "Disabled")
    end
end)
local AntiLagOriginalDisabled = nil
local AntiLagToggle
AntiLagToggle = DefenseTab:AddToggle("AntiLag", false, function(enabled)
    State.AntiLag = enabled
    local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
    local moveScript = playerScripts and playerScripts:FindFirstChild("CharacterAndBeamMove")
    if not moveScript then
        Notify("Anti-Lag", "CharacterAndBeamMove was not found.")
        return
    end
    if enabled then
        if AntiLagOriginalDisabled == nil then
            AntiLagOriginalDisabled = moveScript.Disabled
        end
        moveScript.Disabled = true
        Notify("Anti-Lag", "Enabled")
    else
        if AntiLagOriginalDisabled ~= nil then
            moveScript.Disabled = AntiLagOriginalDisabled
        else
            moveScript.Disabled = false
        end
        Notify("Anti-Lag", "Disabled")
    end
end)
local function RunAntiKillCycle()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not (character and humanoid and humanoid.Health > 0) then
        return
    end
    local remotes = GetRemotes()
    if not remotes.SpawnToy then
        return
    end
    local spawnedFolder = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
    local hamburger = spawnedFolder and spawnedFolder:FindFirstChild("FoodHamburger")
    if not hamburger then
        if os.clock() - State.AntiKillLastAction > 0.1 then
            pcall(function()
                remotes.SpawnToy:InvokeServer(
                    "FoodHamburger",
                    CFrame.new(0, 300, 0),
                    Vector3.zero
                )
            end)
            State.AntiKillLastAction = os.clock()
        end
        return
    end
    local holdPart = hamburger:FindFirstChild("HoldPart")
    if not holdPart then
        return
    end
    if not State.AntiKillHolding then
        local holdRemote = holdPart:FindFirstChild("HoldItemRemoteFunction")
        if holdRemote then
            local ok = pcall(function()
                holdRemote:InvokeServer(hamburger, character)
            end)
            if ok then
                State.AntiKillHolding = true
            end
        end
    else
        local dropRemote = holdPart:FindFirstChild("DropItemRemoteFunction")
        if dropRemote then
            local ok = pcall(function()
                dropRemote:InvokeServer(
                    hamburger,
                    CFrame.new(0, 300, 0),
                    Vector3.zero
                )
            end)
            if ok then
                State.AntiKillHolding = false
            end
        end
    end
end
local AntiKillConnection = nil
local function StopAntiKill()
    if AntiKillConnection then
        AntiKillConnection:Disconnect()
        AntiKillConnection = nil
    end
    State.AntiKillBusy = false
    State.AntiKillHolding = false
end
local function StartAntiKill()
    StopAntiKill()
    AntiKillConnection = RunService.Heartbeat:Connect(function()
        if not State.AntiKill or State.AntiKillBusy then
            return
        end
        State.AntiKillBusy = true
        task.spawn(function()
            pcall(RunAntiKillCycle)
            State.AntiKillBusy = false
        end)
    end)
end
local AntiKillToggle
AntiKillToggle = DefenseTab:AddToggle("AntiKill", false, function(enabled)
    State.AntiKill = enabled
    if enabled then
        StartAntiKill()
        Notify("Anti-Kill", "Enabled")
    else
        StopAntiKill()
        Notify("Anti-Kill", "Disabled")
    end
end)
local function StartAntiRagdollLoop()
    if State.AntiRagdollLoopRunning then
        return
    end
    State.AntiRagdollLoopRunning = true
    task.spawn(function()
        while State.AntiRagdoll do
            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.PlatformStand then
                humanoid.PlatformStand = false
            end
            task.wait(0.1)
        end
        State.AntiRagdollLoopRunning = false
    end)
end
local AntiRagdollToggle
AntiRagdollToggle = DefenseTab:AddToggle("AntiRagdoll", false, function(enabled)
    State.AntiRagdoll = enabled
    if enabled then
        StartAntiRagdollLoop()
        Notify("Anti-Ragdoll", "Enabled")
    else
        Notify("Anti-Ragdoll", "Disabled")
    end
end)
Window:Notify("HertaIX", "Five Defense features loaded.", 3)
end
local TP_WALK_MULTIPLIER = 7
local function enforceTPWalkJumpPower(state)
    if not (state and state.Humanoid and state.Humanoid.Parent) then
        return
    end
    local humanoid = state.Humanoid
    local targetJumpPower = state.JumpPower * TP_WALK_MULTIPLIER
    if humanoid.UseJumpPower ~= true then
        humanoid.UseJumpPower = true
    end
    if humanoid.JumpPower ~= targetJumpPower then
        humanoid.JumpPower = targetJumpPower
    end
end
local function restoreTPWalkCharacterState()
    local state = tpWalkCharacterState
    tpWalkCharacterState = nil
    if state then
        if state.JumpPowerConnection then
            state.JumpPowerConnection:Disconnect()
        end
        if state.UseJumpPowerConnection then
            state.UseJumpPowerConnection:Disconnect()
        end
    end
    if state and state.Humanoid and state.Humanoid.Parent then
        state.Humanoid.WalkSpeed = state.WalkSpeed
        state.Humanoid.JumpPower = state.JumpPower
        state.Humanoid.JumpHeight = state.JumpHeight
        state.Humanoid.UseJumpPower = state.UseJumpPower
    end
end
local function applyTPWalkToCurrentCharacter()
    local character = LP.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return nil
    end
    if tpWalkCharacterState and tpWalkCharacterState.Humanoid == humanoid then
        enforceTPWalkJumpPower(tpWalkCharacterState)
        return tpWalkCharacterState
    end
    restoreTPWalkCharacterState()
    local state = {
        Humanoid = humanoid,
        WalkSpeed = humanoid.WalkSpeed,
        JumpPower = humanoid.JumpPower,
        JumpHeight = humanoid.JumpHeight,
        UseJumpPower = humanoid.UseJumpPower,
    }
    tpWalkCharacterState = state
    enforceTPWalkJumpPower(state)
    state.JumpPowerConnection = humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
        if tpWalkEnabled and tpWalkCharacterState == state then
            enforceTPWalkJumpPower(state)
        end
    end)
    state.UseJumpPowerConnection = humanoid:GetPropertyChangedSignal("UseJumpPower"):Connect(function()
        if tpWalkEnabled and tpWalkCharacterState == state then
            enforceTPWalkJumpPower(state)
        end
    end)
    return state
end
local function stopTPWalk()
    tpWalkEnabled = false
    if tpWalkHeartbeatConnection then
        tpWalkHeartbeatConnection:Disconnect()
        tpWalkHeartbeatConnection = nil
    end
    if tpWalkCharacterAddedConnection then
        tpWalkCharacterAddedConnection:Disconnect()
        tpWalkCharacterAddedConnection = nil
    end
    if tpWalkOriginalGravity ~= nil then
        workspace.Gravity = tpWalkOriginalGravity
        tpWalkOriginalGravity = nil
    end
    restoreTPWalkCharacterState()
end
local function startTPWalk()
    if tpWalkEnabled then
        return
    end
    tpWalkEnabled = true
    tpWalkOriginalGravity = workspace.Gravity
    workspace.Gravity = tpWalkOriginalGravity * TP_WALK_MULTIPLIER
    applyTPWalkToCurrentCharacter()
    tpWalkHeartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if not tpWalkEnabled then
            return
        end
        local character = LP.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local state = applyTPWalkToCurrentCharacter()
        if not (root and humanoid and state and root.Parent and humanoid.Health > 0) then
            return
        end
        local moveDirection = humanoid.MoveDirection
        if moveDirection.Magnitude > 0 then
            local extraDistance = state.WalkSpeed * (TP_WALK_MULTIPLIER - 1) * deltaTime
            root.CFrame = root.CFrame + moveDirection * extraDistance
        end
    end)
    tpWalkCharacterAddedConnection = LP.CharacterAdded:Connect(function(character)
        task.spawn(function()
            character:WaitForChild("Humanoid", 10)
            if tpWalkEnabled and character == LP.Character then
                applyTPWalkToCurrentCharacter()
            end
        end)
    end)
end
local function setTPWalkEnabled(value)
    if value then
        startTPWalk()
        Window:Notify("fapta", "speed, gravity, and jump power enabled", 4)
    else
        stopTPWalk()
        Window:Notify("fapta", "original speed, gravity, and jump restored", 4)
    end
end
ReanimateTab:AddSection("-- build --")
local GiantTraceToggle
local FireworkSpinToggle
local TetracubelSpinToggle
local HouseOwnershipToggle
local FolderDropdown
FolderDropdown = ReanimateTab:AddDropdown("Toy Type", FOLDER_OPTIONS, function(option)
    if option == selectedFolderOption then
        return
    end
    isTracing = false
    if GiantTraceToggle and GiantTraceToggle:Get() then
        GiantTraceToggle:Set(false)
    end
    if FireworkSpinToggle and FireworkSpinToggle:Get() then
        FireworkSpinToggle:Set(false)
    end
    if TetracubelSpinToggle and TetracubelSpinToggle:Get() then
        TetracubelSpinToggle:Set(false)
    end
    restoreFireworkSparklers()
    restoreTetracubels()
    selectedFolderOption = option
    if option == "SpawnedInToys" and HouseOwnershipToggle and HouseOwnershipToggle:Get() then
        HouseOwnershipToggle:Set(false)
    end
    if isBuilt then
        cleanupGiant()
    end
    Window:Notify("FOLDER SELECTED", option .. " selected; build giant again", 5)
end)
FolderDropdown:Set(selectedFolderOption)
ReanimateTab:AddButton("build giant", function()
    buildGiant()
end)
ReanimateTab:AddButton("cleanup", function()
    if FireworkSpinToggle and FireworkSpinToggle:Get() then
        FireworkSpinToggle:Set(false)
    end
    if TetracubelSpinToggle and TetracubelSpinToggle:Get() then
        TetracubelSpinToggle:Set(false)
    end
    restoreFireworkSparklers()
    restoreTetracubels()
    cleanupGiant()
    Window:Notify("CLEANUP", "owned movers removed and collisions restored", 4)
end)
ReanimateTab:AddSection("-- trace --")
GiantTraceToggle = ReanimateTab:AddToggle("Be Giant", false, function(value)
    isTracing = value
    if not isTracing and isBuilt then
        moveToWaitPosition()
    end
end)
ReanimateTab:AddSection("-- Automatic --")
HouseOwnershipToggle = ReanimateTab:AddToggle("House Ownership", false, function(value)
    if value then
        if not setAutoHouseEnabled(true) then
            task.defer(function()
                if HouseOwnershipToggle and HouseOwnershipToggle:Get() then
                    HouseOwnershipToggle:Set(false)
                end
            end)
        end
    elseif autoHouseEnabled then
        setAutoHouseEnabled(false)
    end
end)
ReanimateTab:AddSection("-- super necessity --")
ReanimateTab:AddButton("BarrierBreak(other)", function()
    runAutoSave()
end)
MoreFunctionTab:AddSection("-- FireworkSparkler --")
MoreFunctionTab:AddButton("Apply Firework Anchor", function()
    if FireworkSpinToggle and FireworkSpinToggle:Get() then
        FireworkSpinToggle:Set(false)
    end
    local success, message = applyFireworkSparklers()
    if success then
        Window:Notify("FIREWORK APPLIED", message, 4)
    else
        Window:Notify("FIREWORK ERROR", message, 6)
    end
end)
FireworkSpinToggle = MoreFunctionTab:AddToggle("Firework Animation", false, function(value)
    if value then
        if #FireworkSparklers == 0 then
            Window:Notify("FIREWORK ERROR", "Press Apply Firework Anchor first", 5)
            task.defer(function()
                if FireworkSpinToggle and FireworkSpinToggle:Get() then
                    FireworkSpinToggle:Set(false)
                end
            end)
            return
        end
        fireworkSpinAngle = 0
        fireworkSpinEnabled = true
        Window:Notify("FIREWORK", "animation on", 3)
    else
        local wasEnabled = fireworkSpinEnabled
        fireworkSpinEnabled = false
        if wasEnabled then
            Window:Notify("FIREWORK", "animation off", 3)
        end
    end
end)
MoreFunctionTab:AddSlider("Spin Y Position", {
    Min = -30,
    Max = 30,
    Default = backSpinVerticalOffset,
}, function(value)
    backSpinVerticalOffset = value
end)
MoreFunctionTab:AddSlider("Firework Radius", {
    Min = 0,
    Max = 30,
    Default = fireworkOrbitRadius,
}, function(value)
    fireworkOrbitRadius = value
end)
MoreFunctionTab:AddSlider("Spin Speed", {
    Min = 0,
    Max = 360,
    Default = backSpinRotationSpeed,
}, function(value)
    backSpinRotationSpeed = value
end)
MoreFunctionTab:AddSection("-- TetracubeI --")
MoreFunctionTab:AddButton("Apply TetracubeI Anchor", function()
    if TetracubelSpinToggle and TetracubelSpinToggle:Get() then
        TetracubelSpinToggle:Set(false)
    end
    local success, message = applyTetracubels()
    if success then
        Window:Notify("TETRACUBEI APPLIED", message, 4)
    else
        Window:Notify("TETRACUBEI ERROR", message, 6)
    end
end)
TetracubelSpinToggle = MoreFunctionTab:AddToggle("TetracubeI Animation", false, function(value)
    if value then
        if #Tetracubels == 0 then
            Window:Notify("TETRACUBEI ERROR", "Press Apply TetracubeI Anchor first", 5)
            task.defer(function()
                if TetracubelSpinToggle and TetracubelSpinToggle:Get() then
                    TetracubelSpinToggle:Set(false)
                end
            end)
            return
        end
        tetracubelSpinAngle = 0
        tetracubelSpinEnabled = true
        Window:Notify("TETRACUBEI", "animation on", 3)
    else
        local wasEnabled = tetracubelSpinEnabled
        tetracubelSpinEnabled = false
        if wasEnabled then
            Window:Notify("TETRACUBEI", "animation off", 3)
        end
    end
end)
MoreFunctionTab:AddSlider("TetracubeI Radius", {
    Min = 0,
    Max = 40,
    Default = tetracubelOrbitRadius,
}, function(value)
    tetracubelOrbitRadius = value
end)
MoreFunctionTab:AddSection("-- Movement --")
MoreFunctionTab:AddToggle("×7 Experience(useless)", false, function(value)
    setTPWalkEnabled(value)
end)
RunService.RenderStepped:Connect(function(deltaTime)
    if isBuilt and isTracing then
        tracePlayer()
    end
    if fireworkSpinEnabled then
        updateFireworkSpin(deltaTime)
    end
    if tetracubelSpinEnabled then
        updateTetracubelSpin(deltaTime)
    end
end)
StaffTab:AddSection("-- STAFF ROLL --")
StaffTab:AddParagraph("HertaIX Library", "Library / Design: midori")
StaffTab:AddParagraph("fapta giant trace", "Toy-based giant body tracking rebuild")
StaffTab:AddParagraph("UI Assembly", "HertaIX / Orion_library / Rayfield_library")
StaffTab:AddSection("-- omake! --")
StaffTab:AddButton("...", function()
    local success, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/midorimidoru1-collab/bad-apple-roblox-script/main/bad_apple.lua"))()
    end)
    if success then
        Window:Notify("STAFF ROLL", "Bad Apple", 4)
    else
        Window:Notify("LOAD ERROR", tostring(err), 6)
        warn("[HertaIX] Bad Apple load failed:", err)
    end
end)
StaffTab:AddLabel("thx 4 useing this script")
Window:Notify("Console", "*0*error exist", 5)
