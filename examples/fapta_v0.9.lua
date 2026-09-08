local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local SCRIPT_VERSION = "0.9"
local HertaIX = loadstring(game:HttpGet("https://raw.githubusercontent.com/midorimidoru1-collab/HertaIX/master/HertaIX.lua"))()
local Window = HertaIX:CreateWindow("Fapta demo v" .. SCRIPT_VERSION, "near_future")
Window:SetTitleRainbow(true)
Window:SetTitleFont("arcade")
local ReanimateTab = Window:CreateTab("REANIMATE")
local MoreFunctionTab = Window:CreateTab("MORE FUNCTION")
local AutoTab = Window:CreateTab("AUTO")
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
local FireworkOrbitAnchor = nil
local TetracubeIOrbitAnchor = nil
local CollisionState = {}
local CollisionRecorded = {}
local isBuilt = false
local isTracing = false
local fireworkSpinEnabled = false
local fireworkSpinAngle = 0
local tetracubelSpinEnabled = false
local tetracubelSpinAngle = 0
local autoSaveRunning = false
local autoSaveSession = 0
local autoSaveThread = nil
local autoSaveActiveState = nil
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
local FIREWORK_FOLLOW_RESPONSIVENESS = 8
local TETRACUBEI_FOLLOW_RESPONSIVENESS = 6
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
local function createOrbitAnchor(name)
    local anchor = Instance.new("Part")
    anchor.Name = name
    anchor.Size = Vector3.new(1, 1, 1)
    anchor.Transparency = 1
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.CanTouch = false
    anchor.CanQuery = false
    anchor.CastShadow = false
    anchor.Parent = Workspace
    return anchor
end
local function getYawOnlyCFrame(sourceCF, position)
    local flatLook = Vector3.new(sourceCF.LookVector.X, 0, sourceCF.LookVector.Z)
    if flatLook.Magnitude < 0.001 then
        flatLook = Vector3.new(0, 0, -1)
    else
        flatLook = flatLook.Unit
    end
    return CFrame.lookAt(position, position + flatLook, Vector3.new(0, 1, 0))
end
local function getBackOrbitTargetCF()
    local character = LP.Character
    local torso = character and (character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso"))
    if not torso then
        return nil
    end
    local centerPosition = torso.Position + Vector3.new(
        0,
        TORSO_TRACE_Y_OFFSET + backSpinVerticalOffset,
        0
    )
    return getYawOnlyCFrame(torso.CFrame, centerPosition) * CFrame.new(0, 0, BACK_SPIN_DISTANCE)
end
local function updateOrbitAnchor(anchor, targetCF, responsiveness, deltaTime)
    if not anchor or not anchor.Parent or not targetCF then
        return
    end
    local alpha = 1 - math.exp(-responsiveness * math.max(deltaTime, 0))
    anchor.CFrame = anchor.CFrame:Lerp(targetCF, math.clamp(alpha, 0, 1))
end
local function getSpinGroupCenterPosition(group)
    local totalPosition = Vector3.new()
    local count = 0
    for _, data in ipairs(group) do
        if data.Part and data.Part.Parent then
            totalPosition = totalPosition + data.Part.Position
            count = count + 1
        end
    end
    if count == 0 then
        return nil
    end
    return totalPosition / count
end
local function restoreFireworkSparklers()
    local hadToys = fireworkSpinEnabled or #FireworkSparklers > 0 or FireworkOrbitAnchor ~= nil
    fireworkSpinEnabled = false
    fireworkSpinAngle = 0
    restoreSpinGroup(FireworkSparklers)
    FireworkSparklers = {}
    if FireworkOrbitAnchor then
        FireworkOrbitAnchor:Destroy()
        FireworkOrbitAnchor = nil
    end
    return hadToys
end
local function restoreTetracubels()
    local hadToys = tetracubelSpinEnabled or #Tetracubels > 0 or TetracubeIOrbitAnchor ~= nil
    tetracubelSpinEnabled = false
    tetracubelSpinAngle = 0
    restoreSpinGroup(Tetracubels)
    Tetracubels = {}
    if TetracubeIOrbitAnchor then
        TetracubeIOrbitAnchor:Destroy()
        TetracubeIOrbitAnchor = nil
    end
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
    FireworkOrbitAnchor = createOrbitAnchor("FireworkOrbitAnchor")
    local targetCF = getBackOrbitTargetCF()
    local startPosition = getSpinGroupCenterPosition(toys) or toys[1].Part.Position
    FireworkOrbitAnchor.CFrame = getYawOnlyCFrame(targetCF or toys[1].Part.CFrame, startPosition)
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
    TetracubeIOrbitAnchor = createOrbitAnchor("TetracubeIOrbitAnchor")
    local targetCF = getBackOrbitTargetCF()
    local startPosition = getSpinGroupCenterPosition(toys) or toys[1].Part.Position
    TetracubeIOrbitAnchor.CFrame = getYawOnlyCFrame(targetCF or toys[1].Part.CFrame, startPosition)
    return true, message
end
local function updateSpinGroup(group, orbitCenterCF, spinAngle, radius)
    local count = #group
    if count == 0 then
        return
    end
    for index, data in ipairs(group) do
        if data.Part and data.Part.Parent and data.BP and data.BP.Parent and data.BG and data.BG.Parent then
            local angle = spinAngle + ((index - 1) / count) * math.pi * 2
            local orbitPositionCF = orbitCenterCF
                * CFrame.Angles(0, 0, angle)
                * CFrame.new(0, radius, 0)
            data.BP.Position = orbitPositionCF.Position
            data.BG.CFrame = orbitCenterCF
        end
    end
end
local function updateToyOrbit(group, anchor, currentAngle, direction, radius, animationEnabled, responsiveness, deltaTime)
    if not anchor or not anchor.Parent then
        return currentAngle
    end
    local targetCF = getBackOrbitTargetCF()
    updateOrbitAnchor(anchor, targetCF, responsiveness, deltaTime)
    if animationEnabled then
        currentAngle = (currentAngle + direction * math.rad(backSpinRotationSpeed) * deltaTime) % (math.pi * 2)
    end
    updateSpinGroup(group, anchor.CFrame, currentAngle, radius)
    return currentAngle
end
local function updateFireworkSpin(deltaTime)
    fireworkSpinAngle = updateToyOrbit(
        FireworkSparklers,
        FireworkOrbitAnchor,
        fireworkSpinAngle,
        1,
        fireworkOrbitRadius,
        fireworkSpinEnabled,
        FIREWORK_FOLLOW_RESPONSIVENESS,
        deltaTime
    )
end
local function updateTetracubelSpin(deltaTime)
    tetracubelSpinAngle = updateToyOrbit(
        Tetracubels,
        TetracubeIOrbitAnchor,
        tetracubelSpinAngle,
        -1,
        tetracubelOrbitRadius,
        tetracubelSpinEnabled,
        TETRACUBEI_FOLLOW_RESPONSIVENESS,
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
local function notifyAutoSave(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 3,
        })
    end)
end
local function restoreAutoSaveState(state)
    if not state then
        return
    end
    local ocarina = state.Ocarina
    if (not ocarina or not ocarina.Parent) and state.SpawnRequested and not state.OcarinaDestroyed then
        local toyFolder = Workspace:FindFirstChild(LP.Name .. "SpawnedInToys")
        ocarina = toyFolder and toyFolder:FindFirstChild("InstrumentWoodwindOcarina")
    end
    if ocarina and ocarina.Parent and state.DestroyToy and not state.OcarinaDestroyed then
        pcall(function()
            state.DestroyToy:FireServer(ocarina)
        end)
        state.OcarinaDestroyed = true
    end
    if state.Humanoid and state.Humanoid.Parent then
        state.Humanoid.WalkSpeed = state.OriginalWalkSpeed
    end
    if state.HRP and state.HRP.Parent then
        state.HRP.CFrame = state.OriginalPos
    end
end
local function resetAutoSaveProgress()
    autoSaveSession = autoSaveSession + 1
    local previousThread = autoSaveThread
    local previousState = autoSaveActiveState
    autoSaveRunning = false
    autoSaveThread = nil
    autoSaveActiveState = nil
    restoreAutoSaveState(previousState)
    if previousThread and previousThread ~= coroutine.running() then
        pcall(function()
            task.cancel(previousThread)
        end)
    end
end
local function runAutoSave()
    if autoSaveRunning then
        resetAutoSaveProgress()
        Window:Notify("Console", "auto save progress reset; restarting", 3)
    end
    autoSaveSession = autoSaveSession + 1
    local session = autoSaveSession
    autoSaveRunning = true
    autoSaveThread = coroutine.running()
    local plotItems = Workspace:FindFirstChild("PlotItems")
    if plotItems then
        local playersInPlots = plotItems:FindFirstChild("PlayersInPlots")
        if playersInPlots and playersInPlots:FindFirstChild(LP.Name) then
            notifyAutoSave("error", "get out this house")
            autoSaveRunning = false
            autoSaveThread = nil
            return
        end
    end
    local character = LP.Character
    if not character then
        notifyAutoSave("error", "errorcode:10223")
        autoSaveRunning = false
        autoSaveThread = nil
        return
    end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        notifyAutoSave("error", "HumanoidRootPart")
        autoSaveRunning = false
        autoSaveThread = nil
        return
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        notifyAutoSave("error", "unknown number response")
        autoSaveRunning = false
        autoSaveThread = nil
        return
    end
    local menuToys = ReplicatedStorage:FindFirstChild("MenuToys")
    if not menuToys then
        notifyAutoSave("error", "MenuToys")
        autoSaveRunning = false
        autoSaveThread = nil
        return
    end
    local spawnToyRemoteFunction = menuToys:FindFirstChild("SpawnToyRemoteFunction")
    local destroyToy = menuToys:FindFirstChild("DestroyToy")
    if not spawnToyRemoteFunction or not destroyToy then
        notifyAutoSave("error", "unknown error")
        autoSaveRunning = false
        autoSaveThread = nil
        return
    end
    local originalPos = hrp.CFrame
    local originalWalkSpeed = humanoid.WalkSpeed
    local runState = {
        HRP = hrp,
        Humanoid = humanoid,
        OriginalPos = originalPos,
        OriginalWalkSpeed = originalWalkSpeed,
        DestroyToy = destroyToy,
        SpawnRequested = false,
        Ocarina = nil,
        OcarinaDestroyed = false,
    }
    autoSaveActiveState = runState
    local function ensureCurrentSession()
        if session ~= autoSaveSession then
            error("auto save restarted", 0)
        end
    end
    local success, err = pcall(function()
        humanoid.WalkSpeed = 0
        ensureCurrentSession()
        runState.SpawnRequested = true
        spawnToyRemoteFunction:InvokeServer(
            "InstrumentWoodwindOcarina",
            CFrame.new(184.148834, -5.54824972, 498.136749),
            Vector3.new(0, 34, 0)
        )
        task.wait(0.4)
        ensureCurrentSession()
        local toyFolder = Workspace:FindFirstChild(LP.Name .. "SpawnedInToys")
        local ocarina = toyFolder and toyFolder:FindFirstChild("InstrumentWoodwindOcarina")
        if not ocarina or not ocarina:FindFirstChild("HoldPart") then
            error("cant find this")
        end
        runState.Ocarina = ocarina
        ocarina.HoldPart.HoldItemRemoteFunction:InvokeServer(
            ocarina,
            Workspace[LP.Name]
        )
        ensureCurrentSession()
        hrp.CFrame = CFrame.new(304.06, 25.77, 488.54)
        task.wait(0.21)
        ensureCurrentSession()
        destroyToy:FireServer(ocarina)
        runState.OcarinaDestroyed = true
        runState.Ocarina = nil
        hrp.CFrame = originalPos
        task.wait(0.7)
        ensureCurrentSession()
        spawnToyRemoteFunction:InvokeServer(
            "Campfire",
            CFrame.new(257.638672, -5.57392979, 450.103638),
            Vector3.new(0, 161.972)
        )
    end)
    if session ~= autoSaveSession then
        return
    end
    restoreAutoSaveState(runState)
    autoSaveRunning = false
    autoSaveThread = nil
    autoSaveActiveState = nil
    if success then
        notifyAutoSave("Success", "saved")
    else
        notifyAutoSave("Error", "try again later")
        warn("[fapta] auto save failed:", err)
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
    AntiKickSession = 0,
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
local function prepareBlitzKunai(kunai)
    for _, descendant in ipairs(kunai:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.CanQuery = false
            descendant.Transparency = 1
            descendant.CanCollide = false
        end
    end
end
local function getBlitzKunaiState(kunai, character)
    if not kunai or not kunai.Parent then
        return nil
    end
    local stickyPart = kunai:FindFirstChild("StickyPart")
    local stickyWeld = stickyPart and stickyPart:FindFirstChild("StickyWeld")
    if not stickyWeld then
        return nil
    end
    if stickyWeld.Enabled == false then
        return "Useless", stickyPart, stickyWeld
    end
    local attachedPart = stickyWeld.Part1
    if not attachedPart then
        return "No use!", stickyPart, stickyWeld
    end
    if character and attachedPart:IsDescendantOf(character) then
        return "Using", stickyPart, stickyWeld
    end
    return "Used", stickyPart, stickyWeld
end
local function AttachKunaiToLeftLeg(remotes, kunai, leftLeg, session)
    if not kunai or not kunai.Parent or not leftLeg or not leftLeg.Parent then
        return false
    end
    prepareBlitzKunai(kunai)
    local stickyPart = kunai:FindFirstChild("StickyPart") or kunai:WaitForChild("StickyPart", 2)
    local stickyWeld = stickyPart
        and (stickyPart:FindFirstChild("StickyWeld") or stickyPart:WaitForChild("StickyWeld", 2))
    if not stickyPart or not stickyWeld then
        return false
    end
    if remotes.SetNetworkOwner then
        pcall(function()
            remotes.SetNetworkOwner:FireServer(stickyPart, stickyPart.CFrame)
        end)
    end
    if stickyWeld.Enabled ~= false and stickyWeld.Part1 == leftLeg then
        return true
    end
    local retry = 0
    while State.AntiKick
        and session == State.AntiKickSession
        and stickyPart.Parent
        and leftLeg.Parent
        and (stickyWeld.Enabled == false or stickyWeld.Part1 ~= leftLeg)
        and retry < 20 do
        pcall(function()
            remotes.StickyPart:FireServer(
                stickyPart,
                leftLeg,
                CFrame.new(0, -0.5, 0) * CFrame.Angles(0, 0, math.rad(90))
            )
        end)
        task.wait(0.1)
        retry = retry + 1
    end
    return stickyWeld.Enabled ~= false and stickyWeld.Part1 == leftLeg
end
local function RunAntiKickCycle(session)
    if session ~= State.AntiKickSession then
        return
    end
    local character = LocalPlayer.Character
    if not character then
        return
    end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local leftLeg = character:FindFirstChild("Left Leg")
        or character:FindFirstChild("LeftLowerLeg")
        or character:FindFirstChild("LeftUpperLeg")
    if not hrp or not humanoid or not leftLeg or humanoid.Health <= 0 then
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
        local ok, purchaseResult = pcall(function()
            return remotes.BuyToy:InvokeServer("NinjaKunai")
        end)
        if not ok or purchaseResult == false then
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
        prepareBlitzKunai(kunai)
        local primaryPart = kunai.PrimaryPart or kunai:FindFirstChildWhichIsA("BasePart", true)
        local tooFar = primaryPart and LocalPlayer:DistanceFromCharacter(primaryPart.Position) > 30
        local kunaiState, stickyPart = getBlitzKunaiState(kunai, character)
        if kunaiState == "Useless" or tooFar then
            pcall(function()
                remotes.DestroyToy:FireServer(kunai)
            end)
            return
        end
        if kunaiState == "No use!" or not kunaiState then
            if not AttachKunaiToLeftLeg(remotes, kunai, leftLeg, session)
                and State.AntiKick
                and session == State.AntiKickSession
                and kunai.Parent then
                pcall(function()
                    remotes.DestroyToy:FireServer(kunai)
                end)
                task.wait(0.1)
            end
        elseif stickyPart and remotes.SetNetworkOwner then
            pcall(function()
                remotes.SetNetworkOwner:FireServer(stickyPart, stickyPart.CFrame)
            end)
        end
        return
    end
    local canSpawnToy = LocalPlayer:FindFirstChild("CanSpawnToy")
    if canSpawnToy and not canSpawnToy.Value then
        return
    end
    SpawnKunaiBehindPlayer(remotes, "NinjaKunai")
    if not spawnedToys then
        spawnedToys = Workspace:WaitForChild(LocalPlayer.Name .. "SpawnedInToys", 3)
    end
    local newKunai = spawnedToys and spawnedToys:WaitForChild("NinjaKunai", 3)
    if newKunai
        and not AttachKunaiToLeftLeg(remotes, newKunai, leftLeg, session)
        and State.AntiKick
        and session == State.AntiKickSession
        and newKunai.Parent then
        pcall(function()
            remotes.DestroyToy:FireServer(newKunai)
        end)
        task.wait(0.1)
    end
end
local function StartAntiKickLoop()
    State.AntiKickSession = State.AntiKickSession + 1
    local session = State.AntiKickSession
    State.AntiKickLoopRunning = true
    task.spawn(function()
        while State.AntiKick and session == State.AntiKickSession do
            local success, err = pcall(RunAntiKickCycle, session)
            if not success then
                warn("[fapta] AntiKick cycle failed:", err)
            end
            task.wait(0.1)
        end
        if session == State.AntiKickSession then
            State.AntiKickLoopRunning = false
        end
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
        State.AntiKickSession = State.AntiKickSession + 1
        State.AntiKickLoopRunning = false
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
local AutoState = {
    AutoSpin = false,
    AutoSpinSession = 0,
    PreserveTime = false,
    PreserveTimeSession = 0,
    RemainingTime = nil,
}
local PLOT_NAME_OPTIONS = {
    "Witch House",
    "Lumber House",
    "Common House",
    "American House",
    "Chinese House",
}
local PLOT_NAME_TO_FOLDER = {
    ["Witch House"] = "Plot3",
    ["Lumber House"] = "Plot2",
    ["Common House"] = "Plot1",
    ["American House"] = "Plot4",
    ["Chinese House"] = "Plot5",
}
local selectedAutoPlotName = "Witch House"
local PreserveTimeToggle
local function getCurrentCharacterRoot()
    local character = LP.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if humanoid and root and humanoid.Health > 0 then
        return root, humanoid
    end
    return nil, nil
end
local function getNetworkOwnerRemote()
    local grabEvents = ReplicatedStorage:FindFirstChild("GrabEvents")
    return grabEvents and grabEvents:FindFirstChild("SetNetworkOwner")
end
local function requestNetworkOwnership(part)
    local root = getCurrentCharacterRoot()
    local remote = getNetworkOwnerRemote()
    if not root or not remote or not part or not part.Parent then
        return
    end
    if LP:DistanceFromCharacter(part.Position) <= 30 then
        pcall(function()
            remote:FireServer(part, CFrame.lookAt(root.Position, part.Position))
        end)
    end
end
local function areSlotsReady()
    local slots = Workspace:FindFirstChild("Slots")
    if not slots then
        return false
    end
    local foundSlot = false
    for _, slot in ipairs(slots:GetChildren()) do
        local slotHandle = slot:FindFirstChild("SlotHandle")
        local lightBall = slotHandle and slotHandle:FindFirstChild("LightBall")
        if lightBall then
            foundSlot = true
            if lightBall.Material ~= Enum.Material.Neon then
                return false
            end
        end
    end
    return foundSlot
end
local function runAutoSpinSession(session)
    local slots = Workspace:FindFirstChild("Slots")
    local root = getCurrentCharacterRoot()
    if not slots or not root then
        return
    end
    local originalCF = root.CFrame
    for _, slot in ipairs(slots:GetChildren()) do
        if not AutoState.AutoSpin or session ~= AutoState.AutoSpinSession then
            break
        end
        local slotHandle = slot:FindFirstChild("SlotHandle")
        local handle = slotHandle and slotHandle:FindFirstChild("Handle")
        if handle and handle:IsA("BasePart") then
            local originalCanCollide = handle.CanCollide
            handle.CanCollide = false
            for _ = 1, 5 do
                if not AutoState.AutoSpin or session ~= AutoState.AutoSpinSession then
                    break
                end
                root = getCurrentCharacterRoot()
                if not root then
                    break
                end
                root.CFrame = CFrame.new(handle.Position + Vector3.new(0, 5, 0)) * root.CFrame.Rotation
                requestNetworkOwnership(handle)
                task.wait(0.2)
            end
            if handle.Parent then
                handle.CanCollide = originalCanCollide
            end
        end
    end
    root = getCurrentCharacterRoot()
    if root then
        root.CFrame = originalCF
    end
end
local function startAutoSpin()
    AutoState.AutoSpinSession = AutoState.AutoSpinSession + 1
    local session = AutoState.AutoSpinSession
    task.spawn(function()
        while AutoState.AutoSpin and session == AutoState.AutoSpinSession do
            if areSlotsReady() then
                runAutoSpinSession(session)
            end
            task.wait(5)
        end
    end)
end
local function findRemainingHouseTime()
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then
        return nil
    end
    for _, descendant in ipairs(plots:GetDescendants()) do
        if descendant.Name == "TimeRemainingNum" and descendant:IsA("IntValue") then
            local ownerValue = descendant.Parent
            if ownerValue and ownerValue.Value == LP.Name then
                return descendant
            end
        end
    end
    return nil
end
local function getPlotAreaFromRemainingTime(remainingTime)
    local current = remainingTime
    for _ = 1, 4 do
        current = current and current.Parent
    end
    return current and current:FindFirstChild("PlotArea") or nil
end
local function startPreserveTime()
    AutoState.PreserveTimeSession = AutoState.PreserveTimeSession + 1
    local session = AutoState.PreserveTimeSession
    task.spawn(function()
        while AutoState.PreserveTime and session == AutoState.PreserveTimeSession do
            local infiniteHouseTime = LP:FindFirstChild("InfiniteHouseTime")
            if infiniteHouseTime and infiniteHouseTime.Value then
                AutoState.PreserveTime = false
                task.defer(function()
                    if PreserveTimeToggle and PreserveTimeToggle:Get() then
                        PreserveTimeToggle:Set(false)
                    end
                end)
                Window:Notify("AUTO", "Infinite house time is already enabled", 4)
                break
            end
            local remainingTime = findRemainingHouseTime()
            AutoState.RemainingTime = remainingTime
            if remainingTime and remainingTime.Value < 20 then
                local plotArea = getPlotAreaFromRemainingTime(remainingTime)
                local root = getCurrentCharacterRoot()
                if plotArea and root then
                    local originalCF = root.CFrame
                    repeat
                        if not AutoState.PreserveTime
                            or session ~= AutoState.PreserveTimeSession
                            or not remainingTime.Parent then
                            break
                        end
                        root = getCurrentCharacterRoot()
                        if not root then
                            break
                        end
                        root.CFrame = CFrame.new(plotArea.Position) * root.CFrame.Rotation
                        task.wait(1)
                    until remainingTime.Value > 15
                    root = getCurrentCharacterRoot()
                    if root then
                        root.CFrame = originalCF
                    end
                end
            end
            task.wait(2)
        end
    end)
end
local function getSelectedPlotModel()
    local plots = Workspace:FindFirstChild("Plots")
    local folderName = PLOT_NAME_TO_FOLDER[selectedAutoPlotName]
    return plots and folderName and plots:FindFirstChild(folderName) or nil
end
local function getPlotOwnerContainer(plotModel)
    local plotSign = plotModel and plotModel:FindFirstChild("PlotSign")
    return plotSign and plotSign:FindFirstChild("ThisPlotsOwners") or nil
end
local function claimSelectedPlot()
    local plotModel = getSelectedPlotModel()
    if not plotModel then
        Window:Notify("AUTO", "Selected plot was not found", 4)
        return
    end
    local owners = getPlotOwnerContainer(plotModel)
    if owners and #owners:GetChildren() > 0 then
        Window:Notify("AUTO", "Selected plot already has an owner", 4)
        return
    end
    local plotSign = plotModel:FindFirstChild("PlotSign")
    local sign = plotSign and plotSign:FindFirstChild("Sign")
    local plus = sign and sign:FindFirstChild("Plus")
    local plusGrabPart = plus and plus:FindFirstChild("PlusGrabPart")
    local root = getCurrentCharacterRoot()
    if not plusGrabPart or not root then
        Window:Notify("AUTO", "Plot claim part was not found", 4)
        return
    end
    local originalCF = root.CFrame
    root.CFrame = plusGrabPart.CFrame * CFrame.new(-5, 0, -5)
    for _ = 1, 16 do
        requestNetworkOwnership(plusGrabPart)
        task.wait()
    end
    root = getCurrentCharacterRoot()
    if root then
        root.CFrame = originalCF
    end
end
AutoTab:AddSection("-- Auto Get Coins --")
AutoTab:AddToggle("Auto-Spin", false, function(value)
    AutoState.AutoSpin = value
    AutoState.AutoSpinSession = AutoState.AutoSpinSession + 1
    if value then
        startAutoSpin()
    end
end)
local TimeRemainingLabel = AutoTab:AddLabel("Time Remaining: 0:00")
local CoinsWonLabel = AutoTab:AddLabel("Coins Won: 0")
AutoTab:AddSection("-- Auto Time-Reset --")
PreserveTimeToggle = AutoTab:AddToggle("Preserve Time", false, function(value)
    AutoState.PreserveTime = value
    AutoState.PreserveTimeSession = AutoState.PreserveTimeSession + 1
    if value then
        startPreserveTime()
    end
end)
local TimeInHouseLabel = AutoTab:AddLabel("Plot Time: 0")
AutoTab:AddSection("-- Auto Claim-Plot --")
local AutoPlotDropdown = AutoTab:AddDropdown("Plot", PLOT_NAME_OPTIONS, function(value)
    selectedAutoPlotName = value
end)
AutoPlotDropdown:Set(selectedAutoPlotName)
local PlotOwnerLabel = AutoTab:AddLabel("Plot Owner:")
local PlayersInPlotLabel = AutoTab:AddLabel("Players in Plot: 0")
AutoTab:AddButton("Claim Plot!", function()
    claimSelectedPlot()
end)
local function getSlotTimeText()
    local slots = Workspace:FindFirstChild("Slots")
    local mainSlots = slots and slots:FindFirstChild("Slots")
    local screen = mainSlots and mainSlots:FindFirstChild("Screen")
    local slotGui = screen and screen:FindFirstChild("SlotGui")
    local timeLeftFrame = slotGui and slotGui:FindFirstChild("TimeLeftFrame")
    local timeText = timeLeftFrame and timeLeftFrame:FindFirstChild("TimeText")
    return timeText and timeText.Text or "0:00"
end
local function getCoinsWonText()
    local slots = Workspace:FindFirstChild("Slots")
    if not slots then
        return "0"
    end
    for _, descendant in ipairs(slots:GetDescendants()) do
        if descendant.Name == "CoinAmount" and descendant:IsA("TextLabel") then
            local coinsFrame = descendant.Parent
            local panel = coinsFrame and coinsFrame.Parent
            local spinningFrame = panel and panel:FindFirstChild("SpinningFrame")
            local playerName = spinningFrame and spinningFrame:FindFirstChild("PlayerName")
            if playerName and playerName.Text == LP.DisplayName then
                return descendant.Text
            end
        end
    end
    return "0"
end
local function getSelectedPlotStatus()
    local owners = getPlotOwnerContainer(getSelectedPlotModel())
    if not owners then
        return "Plot Owner:", 0
    end
    local children = owners:GetChildren()
    local ownerText = "Plot Available!"
    for _, ownerValue in ipairs(children) do
        if ownerValue:IsA("StringValue") and ownerValue.Value ~= "" then
            local ownerPlayer = Players:FindFirstChild(ownerValue.Value)
            ownerText = "Plot Owner: " .. (ownerPlayer and ownerPlayer.DisplayName or ownerValue.Value)
            break
        end
    end
    return ownerText, #children
end
task.spawn(function()
    while task.wait(0.5) do
        TimeRemainingLabel:Set("Time Remaining: " .. getSlotTimeText())
        CoinsWonLabel:Set("Coins Won: " .. getCoinsWonText())
        local remainingTime = findRemainingHouseTime()
        TimeInHouseLabel:Set("Plot Time: " .. tostring(remainingTime and remainingTime.Value or 0))
        local ownerText, playerCount = getSelectedPlotStatus()
        PlotOwnerLabel:Set(ownerText)
        PlayersInPlotLabel:Set("Players in Plot: " .. tostring(playerCount))
    end
end)
ReanimateTab:AddSection("-- build --")
local GiantTraceToggle
local FireworkSpinToggle
local TetracubelSpinToggle
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
    if FireworkOrbitAnchor then
        updateFireworkSpin(deltaTime)
    end
    if TetracubeIOrbitAnchor then
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
