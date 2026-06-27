-- ============================================================
--  Herta IX Library  |  Hologram GUI Library
--  loadstring 対応ライブラリ
-- ============================================================

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

local LP        = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")

-- ============================================================
--  カラーテーマ定義
-- ============================================================
local Themes = {
	near_future = {
		accent    = Color3.fromRGB(0,   255, 255),
		accentMid = Color3.fromRGB(150, 255, 255),
		accentLt  = Color3.fromRGB(180, 255, 255),
		text      = Color3.fromRGB(200, 255, 255),
		dark      = Color3.fromRGB(80,  120, 120),
		bg        = Color3.fromRGB(4,   18,  22),
		bgAlpha   = 0.45,
		mainAlpha = 0.93,
		mainBg    = Color3.fromRGB(0,   255, 255),
		rainbow   = false,
	},
	gameboy = {
		accent    = Color3.fromRGB(106, 190, 48),
		accentMid = Color3.fromRGB(80,  160, 30),
		accentLt  = Color3.fromRGB(130, 210, 70),
		text      = Color3.fromRGB(15,  30,  10),
		dark      = Color3.fromRGB(60,  100, 30),
		bg        = Color3.fromRGB(15,  30,  10),
		bgAlpha   = 0.30,
		mainAlpha = 0.92,
		mainBg    = Color3.fromRGB(106, 190, 48),
		rainbow   = false,
	},
	rainbow = {
		accent    = Color3.fromRGB(255, 0,   0),
		accentMid = Color3.fromRGB(255, 128, 0),
		accentLt  = Color3.fromRGB(255, 255, 0),
		text      = Color3.fromRGB(255, 255, 255),
		dark      = Color3.fromRGB(180, 180, 180),
		bg        = Color3.fromRGB(10,  10,  10),
		bgAlpha   = 0.30,
		mainAlpha = 0.92,
		mainBg    = Color3.fromRGB(255, 0,   0),
		rainbow   = true,
	},
	monotone = {
		accent    = Color3.fromRGB(255, 255, 255),
		accentMid = Color3.fromRGB(200, 200, 200),
		accentLt  = Color3.fromRGB(220, 220, 220),
		text      = Color3.fromRGB(10,  10,  10),
		dark      = Color3.fromRGB(100, 100, 100),
		bg        = Color3.fromRGB(10,  10,  10),
		bgAlpha   = 0.35,
		mainAlpha = 0.92,
		mainBg    = Color3.fromRGB(255, 255, 255),
		rainbow   = false,
	},
	undertale = {
		accent    = Color3.fromRGB(10,  10,  10),
		accentMid = Color3.fromRGB(40,  40,  40),
		accentLt  = Color3.fromRGB(60,  60,  60),
		text      = Color3.fromRGB(10,  10,  10),
		dark      = Color3.fromRGB(150, 150, 150),
		bg        = Color3.fromRGB(240, 240, 240),
		bgAlpha   = 0.20,
		mainAlpha = 0.88,
		mainBg    = Color3.fromRGB(10,  10,  10),
		rainbow   = false,
	},
	leaf = {
		accent    = Color3.fromRGB(0,   100, 30),
		accentMid = Color3.fromRGB(80,  200, 80),
		accentLt  = Color3.fromRGB(140, 240, 100),
		text      = Color3.fromRGB(140, 240, 100),
		dark      = Color3.fromRGB(40,  80,  40),
		bg        = Color3.fromRGB(5,   20,  5),
		bgAlpha   = 0.40,
		mainAlpha = 0.92,
		mainBg    = Color3.fromRGB(0,   100, 30),
		rainbow   = false,
	},
	herta = {
		accent    = Color3.fromRGB(180, 120, 220),
		accentMid = Color3.fromRGB(140, 80,  200),
		accentLt  = Color3.fromRGB(200, 160, 240),
		text      = Color3.fromRGB(80,  20,  140),
		dark      = Color3.fromRGB(120, 80,  160),
		bg        = Color3.fromRGB(30,  10,  50),
		bgAlpha   = 0.40,
		mainAlpha = 0.92,
		mainBg    = Color3.fromRGB(180, 120, 220),
		rainbow   = false,
	},
	king = {
		accent    = Color3.fromRGB(200, 160, 0),
		accentMid = Color3.fromRGB(180, 140, 0),
		accentLt  = Color3.fromRGB(220, 180, 20),
		text      = Color3.fromRGB(200, 160, 0),
		dark      = Color3.fromRGB(120, 90,  0),
		bg        = Color3.fromRGB(20,  15,  0),
		bgAlpha   = 0.40,
		mainAlpha = 0.92,
		mainBg    = Color3.fromRGB(200, 160, 0),
		rainbow   = false,
	},
}

-- ============================================================
--  動的カラー変数（テーマ切り替えで上書きされる）
-- ============================================================
local C_ACCENT     = Themes.near_future.accent
local C_ACCENT_MID = Themes.near_future.accentMid
local C_ACCENT_LT  = Themes.near_future.accentLt
local C_TEXT       = Themes.near_future.text
local C_DARK       = Themes.near_future.dark
local C_BG         = Themes.near_future.bg

-- テーマ変更時に更新が必要なオブジェクトを登録するテーブル
local ThemeListeners = {}  -- { type="stroke"|"bg"|"corner"|"text"|"mainbg", obj=Instance, ... }
local _RainbowActive = false  -- rainbow スレッド制御フラグ

-- ------------------------------------------------------------
--  内部: 破棄済みオブジェクトのエントリを ThemeListeners から除去
-- ------------------------------------------------------------
local function _PurgeThemeListeners()
	local alive = {}
	for _, entry in ipairs(ThemeListeners) do
		local ok, obj = pcall(function() return entry.obj end)
		if ok and obj and obj.Parent then
			table.insert(alive, entry)
		end
	end
	ThemeListeners = alive
end

local function RainbowColor(hue)
	return Color3.fromHSV(hue % 1, 1, 1)
end

local function ClearRainbow()
	_RainbowActive = false
end

local _CurrentMainAlpha = 0.93  -- 現在のmainAlpha（CRTアニメ用）

local function ApplyTheme(name)
	local T = Themes[name]
	if not T then return end
	_CurrentMainAlpha = T.mainAlpha

	ClearRainbow()

	-- 破棄済みエントリを掃除してからテーマ適用（メモリリーク防止）
	_PurgeThemeListeners()

	-- 動的変数を更新
	C_ACCENT     = T.accent
	C_ACCENT_MID = T.accentMid
	C_ACCENT_LT  = T.accentLt
	C_TEXT       = T.text
	C_DARK       = T.dark
	C_BG         = T.bg

	-- 登録済みオブジェクトに即時適用
	for _, entry in ipairs(ThemeListeners) do
		local ok, obj = pcall(function() return entry.obj end)
		if not ok or not obj or not obj.Parent then continue end

		if entry.type == "stroke" then
			obj.Color = C_ACCENT
		elseif entry.type == "stroke_faint" then
			obj.Color = C_ACCENT
			obj.Transparency = 0.7
		elseif entry.type == "corner_h" or entry.type == "corner_v" then
			obj.BackgroundColor3 = C_ACCENT
		elseif entry.type == "bg" then
			obj.BackgroundColor3 = C_BG
			obj.BackgroundTransparency = T.bgAlpha
		elseif entry.type == "mainbg" then
			obj.BackgroundColor3 = T.mainBg
			obj.BackgroundTransparency = T.mainAlpha
		elseif entry.type == "text_accent" then
			obj.TextColor3 = C_ACCENT
		elseif entry.type == "text_lt" then
			obj.TextColor3 = C_ACCENT_LT
		elseif entry.type == "text_mid" then
			obj.TextColor3 = C_ACCENT_MID
		elseif entry.type == "text_main" then
			obj.TextColor3 = C_TEXT
		elseif entry.type == "text_dark" then
			obj.TextColor3 = C_DARK
		elseif entry.type == "fill" then
			obj.BackgroundColor3 = C_ACCENT
		elseif entry.type == "track" then
			obj.BackgroundColor3 = C_BG
		elseif entry.type == "knob" then
			obj.BackgroundColor3 = C_ACCENT_LT
		elseif entry.type == "underline" then
			obj.BackgroundColor3 = C_ACCENT
		elseif entry.type == "badge_on_stroke" then
			-- 状態依存なので何もしない（UpdateToggle側で処理）
		elseif entry.type == "headerline" then
			obj.BackgroundColor3 = C_ACCENT
		elseif entry.type == "scanline" then
			obj.BackgroundColor3 = C_ACCENT
		elseif entry.type == "sweep" then
			obj.BackgroundColor3 = C_ACCENT_LT
		elseif entry.type == "dataline" then
			obj.BackgroundColor3 = C_ACCENT_MID
		end
	end

	-- rainbow アニメ（全要素が虹色になるよう全typeに対応）
	if T.rainbow then
		_RainbowActive = true
		local mainAlpha = T.mainAlpha
		spawn(function()
			while _RainbowActive do
				local hue = (tick() * 0.2) % 1
				local col = RainbowColor(hue)
				for _, entry in ipairs(ThemeListeners) do
					local ok2, obj2 = pcall(function() return entry.obj end)
					if not ok2 or not obj2 or not obj2.Parent then continue end
						local t = entry.type
					if t=="stroke" or t=="stroke_faint" then
						obj2.Color = col
						obj2.Transparency = 0
					elseif t=="badge_on_stroke" then
						obj2.Color = col
					elseif t=="corner_h" or t=="corner_v"
						or t=="fill" or t=="underline"
						or t=="headerline" or t=="scanline"
						or t=="sweep" or t=="dataline"
						or t=="track" or t=="knob" then
						obj2.BackgroundColor3 = col
					elseif t=="mainbg" then
						obj2.BackgroundColor3 = col
						obj2.BackgroundTransparency = mainAlpha
					elseif t=="text_accent" or t=="text_lt"
						or t=="text_mid" or t=="text_main"
						or t=="text_dark" then
						obj2.TextColor3 = col
					elseif t=="toggle_state" then
						obj2.TextColor3 = col
					end
				end
				task.wait(0.03)
			end
		end)
	end
end

-- ============================================================
--  内部ユーティリティ
-- ============================================================

-- コーナー装飾（登録付き）
local function MakeCorner(parent, xScale, yScale)
	local H = Instance.new("Frame")
	H.BorderSizePixel = 0
	H.Size = UDim2.fromOffset(23, 2)
	H.Position = UDim2.new(
		xScale, xScale == 1 and -23 or 0,
		yScale, yScale == 1 and -2  or 0
	)
	H.BackgroundColor3 = C_ACCENT
	H.Parent = parent
	table.insert(ThemeListeners, { type = "corner_h", obj = H })

	local V = Instance.new("Frame")
	V.BorderSizePixel = 0
	V.Size = UDim2.fromOffset(2, 23)
	V.Position = UDim2.new(
		xScale, xScale == 1 and -2  or 0,
		yScale, yScale == 1 and -23 or 0
	)
	V.BackgroundColor3 = C_ACCENT
	V.Parent = parent
	table.insert(ThemeListeners, { type = "corner_v", obj = V })
end

-- Herta IX デザインフレーム
local function MakeHertaFrame(parent, size, layoutOrder)
	local Bg = Instance.new("Frame")
	Bg.Size = size
	Bg.BackgroundColor3 = C_BG
	Bg.BackgroundTransparency = 0.45
	Bg.BorderSizePixel = 0
	Bg.LayoutOrder = layoutOrder
	Bg.ClipsDescendants = false
	Bg.Parent = parent
	table.insert(ThemeListeners, { type = "bg", obj = Bg })

	local Stroke = Instance.new("UIStroke")
	Stroke.Color = C_ACCENT
	Stroke.Thickness = 1
	Stroke.Transparency = 0.5
	Stroke.Parent = Bg
	table.insert(ThemeListeners, { type = "stroke", obj = Stroke })

	MakeCorner(Bg, 0, 0)
	MakeCorner(Bg, 1, 0)
	MakeCorner(Bg, 0, 1)
	MakeCorner(Bg, 1, 1)

	return Bg
end

local MakeBgFrame = MakeHertaFrame

-- ============================================================
--  ライブラリ本体
-- ============================================================

local HertaIX = {}
HertaIX.__index = HertaIX

-- ------------------------------------------------------------
--  CreateWindow(titleText)
-- ------------------------------------------------------------
-- ============================================================
--  アセット管理（getcustomasset 方式）
-- ============================================================
local _ASSET_FOLDER  = "HertaIX_Assets"
local _IMG_FOLDER    = _ASSET_FOLDER .. "/images"
local _AUDIO_FOLDER  = _ASSET_FOLDER .. "/audio"
local _ICON_FILENAME = "icon.png"
local _ICON_URL      = "https://raw.githubusercontent.com/midorimidoru1-collab/HertaIX/master/icon.png"

-- メインアイコン（親ファイル管理）
local _IconAssetId = nil

-- 子ファイル由来のアセットキャッシュ
local _ImageCache = {}  -- { [name] = assetId }
local _AudioCache = {}  -- { [name] = assetId }

-- 子ファイルのrawURL（GitHubから取得）
local _IMAGES_LUA_URL = "https://raw.githubusercontent.com/midorimidoru1-collab/HertaIX/master/images.lua"
local _AUDIO_LUA_URL  = "https://raw.githubusercontent.com/midorimidoru1-collab/HertaIX/master/audio.lua"

-- ------------------------------------------------------------
--  内部: ファイルをダウンロードして保存（初回のみ）
-- ------------------------------------------------------------
local function _DownloadAsset(url, path)
	if not isfile(path) then
		local ok, data = pcall(function() return game:HttpGet(url) end)
		if ok and data then writefile(path, data) end
	end
end

-- ------------------------------------------------------------
--  内部: Luaテーブル文字列を安全にロードしてテーブルを返す
-- ------------------------------------------------------------
local function _LoadLuaTable(luaStr)
	local fn, err = loadstring("return " .. luaStr)
	if fn then
		local ok, result = pcall(fn)
		if ok and type(result) == "table" then return result end
	end
	return nil
end

-- ------------------------------------------------------------
--  内部: メインアイコンを読み込む（親ファイル管理）
-- ------------------------------------------------------------
local function _LoadIconAsset()
	if not isfolder(_ASSET_FOLDER) then makefolder(_ASSET_FOLDER) end
	local path = _ASSET_FOLDER .. "/" .. _ICON_FILENAME
	_DownloadAsset(_ICON_URL, path)
	local ok, id = pcall(function() return getcustomasset(path) end)
	if ok then _IconAssetId = id end
end

-- ------------------------------------------------------------
--  内部: images.lua を取得してキャッシュに登録する
-- ------------------------------------------------------------
local function _LoadImageAssets()
	if not isfolder(_ASSET_FOLDER) then makefolder(_ASSET_FOLDER) end
	if not isfolder(_IMG_FOLDER)   then makefolder(_IMG_FOLDER)   end

	-- GitHubから images.lua を毎回取得（ユーザーが更新できるよう常に最新を使用）
	local ok, src = pcall(function() return game:HttpGet(_IMAGES_LUA_URL) end)
	if not ok or not src then return end

	-- 「return { ... }」形式のLuaソースをパース
	local entries = _LoadLuaTable(src:match("return%s*(%b{})") or "{}")
	if not entries then return end

	for name, entry in pairs(entries) do
		if type(entry) == "table" and entry.url and entry.filename then
			local path = _IMG_FOLDER .. "/" .. entry.filename
			_DownloadAsset(entry.url, path)
			local ok2, id = pcall(function() return getcustomasset(path) end)
			if ok2 then
				_ImageCache[tostring(name)] = id
			end
		end
	end
end

-- ------------------------------------------------------------
--  内部: audio.lua を取得してキャッシュに登録する
-- ------------------------------------------------------------
local function _LoadAudioAssets()
	if not isfolder(_ASSET_FOLDER) then makefolder(_ASSET_FOLDER) end
	if not isfolder(_AUDIO_FOLDER) then makefolder(_AUDIO_FOLDER) end

	-- GitHubから audio.lua を毎回取得（ユーザーが更新できるよう常に最新を使用）
	local ok, src = pcall(function() return game:HttpGet(_AUDIO_LUA_URL) end)
	if not ok or not src then return end

	local entries = _LoadLuaTable(src:match("return%s*(%b{})") or "{}")
	if not entries then return end

	for name, entry in pairs(entries) do
		if type(entry) == "table" and entry.url and entry.filename then
			local path = _AUDIO_FOLDER .. "/" .. entry.filename
			_DownloadAsset(entry.url, path)
			local ok2, id = pcall(function() return getcustomasset(path) end)
			if ok2 then
				_AudioCache[tostring(name)] = id
			end
		end
	end
end

-- 起動時に全アセットをロード（pcall保護）
pcall(_LoadIconAsset)
pcall(_LoadImageAssets)
pcall(_LoadAudioAssets)

-- ============================================================
--  パブリックAPI: アセットID取得
-- ============================================================

--- 登録済み画像のカスタムアセットIDを返す
--- @param name string  images.lua に定義したキー名
--- @return string|nil  アセットID（未登録または読み込み失敗時は nil）
function HertaIX:GetImage(name)
	return _ImageCache[tostring(name)]
end

--- 登録済み音声のカスタムアセットIDを返す
--- @param name string  audio.lua に定義したキー名
--- @return string|nil  アセットID（未登録または読み込み失敗時は nil）
function HertaIX:GetAudio(name)
	return _AudioCache[tostring(name)]
end

--- 登録済み画像の一覧を返す
--- @return table  { [name] = assetId } のテーブル
function HertaIX:GetAllImages()
	local t = {}
	for k, v in pairs(_ImageCache) do t[k] = v end
	return t
end

--- 登録済み音声の一覧を返す
--- @return table  { [name] = assetId } のテーブル
function HertaIX:GetAllAudios()
	local t = {}
	for k, v in pairs(_AudioCache) do t[k] = v end
	return t
end

--- アセットを手動で再読み込みする（images.lua / audio.lua を更新した後に使用）
function HertaIX:ReloadAssets()
	_ImageCache = {}
	_AudioCache = {}
	pcall(_LoadImageAssets)
	pcall(_LoadAudioAssets)
end

function HertaIX:CreateWindow(titleText, theme)

	-- テーマ引数が指定されていれば起動時に適用
	if theme then
		ApplyTheme(theme)
	end

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "HertaIXGui"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.Parent = PlayerGui

	local Main = Instance.new("Frame")
	Main.Size = UDim2.fromOffset(400, 253)
	Main.Position = UDim2.fromScale(0.5, 0.5)
	Main.AnchorPoint = Vector2.new(0.5, 0.5)
	Main.BackgroundColor3 = C_ACCENT
	Main.BackgroundTransparency = 0.93
	Main.BorderSizePixel = 0
	Main.ClipsDescendants = false
	Main.Parent = ScreenGui
	table.insert(ThemeListeners, { type = "mainbg", obj = Main })

	local Stroke = Instance.new("UIStroke")
	Stroke.Color = C_ACCENT
	Stroke.Thickness = 2
	Stroke.Parent = Main
	table.insert(ThemeListeners, { type = "stroke", obj = Stroke })

	local Inner = Instance.new("Frame")
	Inner.Size = UDim2.new(1, -8, 1, -8)
	Inner.Position = UDim2.fromOffset(4, 4)
	Inner.BackgroundTransparency = 1
	Inner.BorderSizePixel = 0
	Inner.Parent = Main

	local InnerStroke = Instance.new("UIStroke")
	InnerStroke.Color = C_ACCENT_MID
	InnerStroke.Thickness = 1
	InnerStroke.Parent = Inner
	table.insert(ThemeListeners, { type = "stroke", obj = InnerStroke })

	MakeCorner(Main, 0, 0)
	MakeCorner(Main, 1, 0)
	MakeCorner(Main, 0, 1)
	MakeCorner(Main, 1, 1)

	-- スキャンライン
	local ScanLayer = Instance.new("Frame")
	ScanLayer.Size = UDim2.fromScale(1, 1)
	ScanLayer.BackgroundTransparency = 1
	ScanLayer.ClipsDescendants = true
	ScanLayer.Parent = Main

	for i = 0, 50 do
		local Scan = Instance.new("Frame")
		Scan.BorderSizePixel = 0
		Scan.Size = UDim2.new(1, 0, 0, 1)
		Scan.Position = UDim2.new(0, 0, 0, i * 3)
		Scan.BackgroundColor3 = C_ACCENT
		Scan.BackgroundTransparency = 0.97
		Scan.Parent = ScanLayer
		table.insert(ThemeListeners, { type = "scanline", obj = Scan })
	end

	local Sweep = Instance.new("Frame")
	Sweep.BorderSizePixel = 0
	Sweep.Size = UDim2.new(1, 0, 0, 27)
	Sweep.BackgroundColor3 = C_ACCENT_LT
	Sweep.BackgroundTransparency = 0.95
	Sweep.Parent = ScanLayer
	table.insert(ThemeListeners, { type = "sweep", obj = Sweep })

	task.spawn(function()
		while ScreenGui.Parent do
			Sweep.Position = UDim2.new(0, 0, 0, -27)
			local Tween = TweenService:Create(
				Sweep,
				TweenInfo.new(3, Enum.EasingStyle.Linear),
				{ Position = UDim2.new(0, 0, 1, 27) }
			)
			Tween:Play()
			Tween.Completed:Wait()
			task.wait(0.5)
		end
	end)

	-- データストリーム
	local DataLayer = Instance.new("Frame")
	DataLayer.Size = UDim2.fromScale(1, 1)
	DataLayer.BackgroundTransparency = 1
	DataLayer.ClipsDescendants = true
	DataLayer.Parent = Main

	task.spawn(function()
		while ScreenGui.Parent do
			local Len = math.random(30, 80)
			local Line = Instance.new("Frame")
			Line.BorderSizePixel = 0
			Line.Size = UDim2.fromOffset(Len, 2)
			Line.Position = UDim2.new(0, -Len, 0, math.random(40, 240))
			Line.BackgroundColor3 = C_ACCENT_MID
			Line.Parent = DataLayer
			table.insert(ThemeListeners, { type = "dataline", obj = Line })

			local G = Instance.new("UIGradient")
			G.Transparency = NumberSequence.new{
				NumberSequenceKeypoint.new(0,    1),
				NumberSequenceKeypoint.new(0.25, 0),
				NumberSequenceKeypoint.new(0.75, 0),
				NumberSequenceKeypoint.new(1,    1),
			}
			G.Parent = Line

			local MT = TweenService:Create(
				Line,
				TweenInfo.new(math.random(20, 40) / 10, Enum.EasingStyle.Linear),
				{ Position = UDim2.new(0, 650, 0, Line.Position.Y.Offset) }
			)
			MT:Play()
			MT.Completed:Connect(function() Line:Destroy() end)
			task.wait(0.12)
		end
	end)

	-- ヘッダー：タイトル
	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Size = UDim2.new(1, -140, 0, 27)
	TitleLabel.Position = UDim2.fromOffset(36, 7)
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Text = ""
	TitleLabel.Font = Enum.Font.Code
	TitleLabel.TextSize = 19
	TitleLabel.TextColor3 = C_TEXT
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	TitleLabel.ZIndex = 10
	TitleLabel.Parent = Main
	table.insert(ThemeListeners, { type = "text_main", obj = TitleLabel })

	-- タイトル左側アイコン
	local HeaderIcon = Instance.new("ImageLabel")
	HeaderIcon.Size = UDim2.fromOffset(24, 24)
	HeaderIcon.AnchorPoint = Vector2.new(0, 0.5)
	HeaderIcon.Position = UDim2.fromOffset(8, 17)
	HeaderIcon.BackgroundTransparency = 1
	HeaderIcon.BorderSizePixel = 0
	HeaderIcon.ZIndex = 10
	HeaderIcon.Parent = Main
	if _IconAssetId then
		HeaderIcon.Image = _IconAssetId
	end

	local Cursor = Instance.new("TextLabel")
	Cursor.Size = UDim2.fromOffset(13, 27)
	Cursor.Position = UDim2.fromOffset(10, 7)
	Cursor.BackgroundTransparency = 1
	Cursor.Text = "_"
	Cursor.Font = Enum.Font.Code
	Cursor.TextSize = 19
	Cursor.TextColor3 = C_TEXT
	Cursor.ZIndex = 10
	Cursor.Parent = Main
	table.insert(ThemeListeners, { type = "text_main", obj = Cursor })

	-- ヘッダー：ドラッグハンドルボタン（押している間のみドラッグ可能）
	local DragHandle = Instance.new("TextButton")
	DragHandle.Size = UDim2.fromOffset(23, 23)
	DragHandle.Position = UDim2.new(1, -84, 0, 7)
	DragHandle.BackgroundTransparency = 1
	DragHandle.Text = "✚"
	DragHandle.Font = Enum.Font.Code
	DragHandle.TextSize = 16
	DragHandle.TextColor3 = C_ACCENT_LT
	DragHandle.ZIndex = 10
	DragHandle.Parent = Main
	table.insert(ThemeListeners, { type = "text_lt", obj = DragHandle })

	-- ヘッダー：最小化ボタン
	local Minimize = Instance.new("TextButton")
	Minimize.Size = UDim2.fromOffset(23, 23)
	Minimize.Position = UDim2.new(1, -57, 0, 7)
	Minimize.BackgroundTransparency = 1
	Minimize.Text = "-"
	Minimize.Font = Enum.Font.Code
	Minimize.TextSize = 16
	Minimize.TextColor3 = C_ACCENT_LT
	Minimize.ZIndex = 10
	Minimize.Parent = Main
	table.insert(ThemeListeners, { type = "text_lt", obj = Minimize })

	-- Minimizeボタンより左側に薄く by HertaIX Lib
	local ByLabel = Instance.new("TextLabel")
	ByLabel.Size = UDim2.fromOffset(87, 13)
	ByLabel.AnchorPoint = Vector2.new(1, 0.5)
	ByLabel.Position = UDim2.new(1, -88, 0, 18)
	ByLabel.BackgroundTransparency = 1
	ByLabel.Text = "by HertaIX Lib"
	ByLabel.Font = Enum.Font.Code
	ByLabel.TextSize = 8
	ByLabel.TextColor3 = C_ACCENT_LT
	ByLabel.TextTransparency = 0.6
	ByLabel.TextXAlignment = Enum.TextXAlignment.Right
	ByLabel.ZIndex = 10
	ByLabel.Parent = Main
	table.insert(ThemeListeners, { type = "text_lt", obj = ByLabel })

	-- ヘッダー：閉じるボタン（→ Rayfield風ミニバーに切り替え）
	local Close = Instance.new("TextButton")
	Close.Size = UDim2.fromOffset(23, 23)
	Close.Position = UDim2.new(1, -30, 0, 7)
	Close.BackgroundTransparency = 1
	Close.Text = "X"
	Close.Font = Enum.Font.Code
	Close.TextSize = 16
	Close.TextColor3 = Color3.fromRGB(255, 120, 120)
	Close.ZIndex = 10
	Close.Parent = Main

	-- ヘッダーライン
	local HeaderLine = Instance.new("Frame")
	HeaderLine.Name = "HeaderLine"
	HeaderLine.BorderSizePixel = 0
	HeaderLine.Size = UDim2.new(1, -13, 0, 1)
	HeaderLine.Position = UDim2.new(0, 7, 0, 33)
	HeaderLine.BackgroundColor3 = C_ACCENT
	HeaderLine.Parent = Main
	table.insert(ThemeListeners, { type = "headerline", obj = HeaderLine })

	local HeaderGradient = Instance.new("UIGradient")
	HeaderGradient.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0,    1),
		NumberSequenceKeypoint.new(0.15, 0),
		NumberSequenceKeypoint.new(0.85, 0),
		NumberSequenceKeypoint.new(1,    1),
	}
	HeaderGradient.Parent = HeaderLine

	local CenterMark = Instance.new("Frame")
	CenterMark.Name = "CenterMark"
	CenterMark.BorderSizePixel = 0
	CenterMark.Size = UDim2.fromOffset(40, 3)
	CenterMark.AnchorPoint = Vector2.new(0.5, 0)
	CenterMark.Position = UDim2.new(0.5, 0, 0, 33)
	CenterMark.BackgroundColor3 = C_ACCENT_LT
	CenterMark.ZIndex = 11
	CenterMark.Parent = Main
	table.insert(ThemeListeners, { type = "sweep", obj = CenterMark })

	local MarkGradient = Instance.new("UIGradient")
	MarkGradient.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0,   1),
		NumberSequenceKeypoint.new(0.2, 0),
		NumberSequenceKeypoint.new(0.8, 0),
		NumberSequenceKeypoint.new(1,   1),
	}
	MarkGradient.Parent = CenterMark

	-- タブバー（横スクロール対応）
	local TabBar = Instance.new("ScrollingFrame")
	TabBar.Name = "TabBar"
	TabBar.Size = UDim2.new(1, -13, 0, 30)
	TabBar.Position = UDim2.new(0, 7, 0, 37)
	TabBar.BackgroundTransparency = 1
	TabBar.BorderSizePixel = 0
	TabBar.ClipsDescendants = true
	TabBar.ZIndex = 10
	TabBar.ScrollBarThickness = 0
	TabBar.ScrollingDirection = Enum.ScrollingDirection.X
	TabBar.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
	TabBar.CanvasSize = UDim2.fromOffset(0, 30)
	TabBar.ScrollingEnabled = true
	TabBar.Parent = Main

	-- コンテンツ領域
	local ContentArea = Instance.new("Frame")
	ContentArea.Name = "ContentArea"
	ContentArea.Size = UDim2.new(1, -13, 1, -77)
	ContentArea.Position = UDim2.new(0, 7, 0, 71)
	ContentArea.BackgroundTransparency = 1
	ContentArea.BorderSizePixel = 0
	ContentArea.ClipsDescendants = true
	ContentArea.Parent = Main

	-- 下部ドラッグライン（Rayfield風・ここでもドラッグ可能）
	local DragLine = Instance.new("TextButton")
	DragLine.Name = "DragLine"
	DragLine.Size = UDim2.new(1, -20, 0, 6)
	DragLine.AnchorPoint = Vector2.new(0.5, 0)
	DragLine.Position = UDim2.new(0.5, 0, 1, 6)
	DragLine.BackgroundColor3 = C_ACCENT
	DragLine.BackgroundTransparency = 0.5
	DragLine.BorderSizePixel = 0
	DragLine.Text = ""
	DragLine.ZIndex = 10
	DragLine.Parent = Main
	table.insert(ThemeListeners, { type = "headerline", obj = DragLine })

	local DragLineCorner = Instance.new("UICorner")
	DragLineCorner.CornerRadius = UDim.new(1, 0)
	DragLineCorner.Parent = DragLine

	local DragLineGrad = Instance.new("UIGradient")
	DragLineGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0,    1),
		NumberSequenceKeypoint.new(0.15, 0.3),
		NumberSequenceKeypoint.new(0.85, 0.3),
		NumberSequenceKeypoint.new(1,    1),
	})
	DragLineGrad.Parent = DragLine

	-- タイプライター
	task.spawn(function()
		for i = 1, #titleText do
			TitleLabel.Text = string.sub(titleText, 1, i)
			task.wait(0.08)
		end
	end)

	-- カーソル点滅
	task.spawn(function()
		while ScreenGui.Parent do
			Cursor.Visible = not Cursor.Visible
			task.wait(0.5)
		end
	end)

	-- カーソル位置更新（task.spawn方式でスクリーンGUI破棄後に自動停止）
	task.spawn(function()
		while ScreenGui.Parent do
			if TitleLabel.Parent then
				-- TitleLabel の開始X(36px) + 実際のテキスト幅
				Cursor.Position = UDim2.fromOffset(36 + TitleLabel.TextBounds.X, 7)
			end
			task.wait(0.05)
		end
	end)

	-- 最小化（上端基準で畳む）
	local FullSize = Main.Size
	local Minimized = false

	Minimize.MouseButton1Click:Connect(function()
		Minimized = not Minimized
		if Minimized then
			local absPos  = Main.AbsolutePosition
			local absSize = Main.AbsoluteSize
			local topY    = absPos.Y
			local centerX = absPos.X + absSize.X / 2
			Main.AnchorPoint = Vector2.new(0.5, 0)
			Main.Position = UDim2.new(0, centerX, 0, topY)
			-- コンテンツを即座に隠す（ClipsDescendants=falseでもはみ出さないように）
			ContentArea.Visible = false
			TabBar.Visible = false
			TweenService:Create(
				Main,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Size = UDim2.new(FullSize.X.Scale, FullSize.X.Offset, 0, 37) }
			):Play()
		else
			TweenService:Create(
				Main,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Size = FullSize }
			):Play()
			-- 展開完了後にコンテンツを再表示
			task.delay(0.21, function()
				ContentArea.Visible = true
				TabBar.Visible = true
			end)
		end
	end)

	-- ============================================================
	--  Rayfield 風ミニバー（閉じるボタン → 再表示バー）
	-- ============================================================
	local MiniBar = Instance.new("TextButton")
	MiniBar.Size = UDim2.fromOffset(220, 28)
	MiniBar.AnchorPoint = Vector2.new(0.5, 0)
	MiniBar.Position = UDim2.new(0.5, 0, 0, -80)  -- 最初は画面外（十分上に隠す）
	MiniBar.BackgroundColor3 = C_BG
	MiniBar.BackgroundTransparency = 0.2
	MiniBar.BorderSizePixel = 0
	MiniBar.Text = ""
	MiniBar.ZIndex = 100
	MiniBar.Parent = ScreenGui
	table.insert(ThemeListeners, { type = "bg", obj = MiniBar })

	local MBCorner = Instance.new("UICorner")
	MBCorner.CornerRadius = UDim.new(0, 6)
	MBCorner.Parent = MiniBar

	local MBStroke = Instance.new("UIStroke")
	MBStroke.Color = C_ACCENT
	MBStroke.Thickness = 1
	MBStroke.Parent = MiniBar
	table.insert(ThemeListeners, { type = "stroke", obj = MBStroke })

	-- ミニバー：アイコン
	local MBIcon = Instance.new("ImageLabel")
	MBIcon.Size = UDim2.fromOffset(20, 20)
	MBIcon.AnchorPoint = Vector2.new(0, 0.5)
	MBIcon.Position = UDim2.fromOffset(8, 14)
	MBIcon.BackgroundTransparency = 1
	MBIcon.BorderSizePixel = 0
	MBIcon.ZIndex = 101
	MBIcon.Parent = MiniBar
	if _IconAssetId then
		MBIcon.Image = _IconAssetId
	end

	-- ミニバー：タイトルテキスト（titleText 左揃え）
	local MBLabel = Instance.new("TextLabel")
	MBLabel.Size = UDim2.new(1, -36, 1, 0)
	MBLabel.Position = UDim2.fromOffset(32, 0)
	MBLabel.BackgroundTransparency = 1
	MBLabel.Text = titleText
	MBLabel.Font = Enum.Font.Code
	MBLabel.TextSize = 14
	MBLabel.TextColor3 = C_ACCENT_LT
	MBLabel.TextXAlignment = Enum.TextXAlignment.Left
	MBLabel.ZIndex = 101
	MBLabel.Parent = MiniBar
	table.insert(ThemeListeners, { type = "text_lt", obj = MBLabel })

	-- ミニバー：右下に薄く HertaIX
	local MBSub = Instance.new("TextLabel")
	MBSub.Size = UDim2.fromOffset(80, 16)
	MBSub.AnchorPoint = Vector2.new(1, 1)
	MBSub.Position = UDim2.new(1, -6, 1, -3)
	MBSub.BackgroundTransparency = 1
	MBSub.Text = "HertaIX"
	MBSub.Font = Enum.Font.Code
	MBSub.TextSize = 10
	MBSub.TextColor3 = C_ACCENT_LT
	MBSub.TextTransparency = 0.6
	MBSub.TextXAlignment = Enum.TextXAlignment.Right
	MBSub.ZIndex = 101
	MBSub.Parent = MiniBar
	table.insert(ThemeListeners, { type = "text_lt", obj = MBSub })

	local MBAccent = Instance.new("Frame")
	MBAccent.Size = UDim2.new(1, 0, 0, 2)
	MBAccent.BorderSizePixel = 0
	MBAccent.BackgroundColor3 = C_ACCENT
	MBAccent.ZIndex = 101
	MBAccent.Parent = MiniBar
	table.insert(ThemeListeners, { type = "headerline", obj = MBAccent })

	-- CRTアニメーション共通関数
	local OriginalSize = Main.Size

	-- アニメ中に非表示にする子要素一覧
	local _CRTHideList = {
		ContentArea, TabBar, HeaderLine,
		DragHandle, Minimize, Close, ByLabel, TitleLabel, Cursor
	}

	local function _CRTHideChildren()
		for _, obj in ipairs(_CRTHideList) do
			if obj and obj.Parent then obj.Visible = false end
		end
	end

	local function _CRTShowChildren()
		for _, obj in ipairs(_CRTHideList) do
			if obj and obj.Parent then obj.Visible = true end
		end
	end

	local function CRTTween(obj, time, props)
		local t = TweenService:Create(
			obj,
			TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
			props
		)
		t:Play()
		return t
	end

	-- 開くアニメーション（点 → 横棒 → 通常サイズ）
	local function CRTOpen(onDone)
		_CRTHideChildren()  -- 子要素を先に隐す
		Main.Visible = true
		Main.Size = UDim2.new(0, 2, 0, 2)
		Main.BackgroundTransparency = 1
		local t5 = CRTTween(Main, 0.03, {
			Size = UDim2.new(0, 4, 0, 4),
			BackgroundTransparency = _CurrentMainAlpha
		})
		t5.Completed:Connect(function()
			local t6 = CRTTween(Main, 0.11, {
				Size = UDim2.new(
					OriginalSize.X.Scale, OriginalSize.X.Offset, 0, 2
				)
			})
			t6.Completed:Connect(function()
				local t7 = CRTTween(Main, 0.16, { Size = OriginalSize })
				t7.Completed:Connect(function()
					_CRTShowChildren()  -- 通常サイズに戻った後に子要素を再表示
					if onDone then onDone() end
				end)
			end)
		end)
	end

	-- 閉じるアニメーション（通常サイズ → 横棒 → 点 → 消灯）
	local function CRTClose(onDone)
		_CRTHideChildren()  -- 即座に子要素を隐す
		local t1 = CRTTween(Main, 0.16, {
			Size = UDim2.new(
				OriginalSize.X.Scale, OriginalSize.X.Offset, 0, 2
			)
		})
		t1.Completed:Connect(function()
			local t2 = CRTTween(Main, 0.10, {
				Size = UDim2.new(0, 8, 0, 2)
			})
			t2.Completed:Connect(function()
				local t3 = CRTTween(Main, 0.02, {
					Size = UDim2.new(0, 4, 0, 4)
				})
				t3.Completed:Connect(function()
					local t4 = CRTTween(Main, 0.02, {
						Size = UDim2.new(0, 2, 0, 2),
						BackgroundTransparency = 1
					})
					t4.Completed:Connect(function()
						Main.Visible = false
						Main.Size = OriginalSize
						Main.BackgroundTransparency = _CurrentMainAlpha
						if onDone then onDone() end
					end)
				end)
			end)
		end)
	end

	local function ShowMiniBar()
		CRTClose(function()
			-- 閉じるアニメ完了後にミニバーを表示
			local inset = game:GetService("GuiService"):GetGuiInset()
			MiniBar.Position = UDim2.new(0.5, 0, 0, -80)
			TweenService:Create(
				MiniBar,
				TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Position = UDim2.new(0.5, 0, 0, -inset.Y) }
			):Play()
		end)
	end

	local function HideMiniBar()
		TweenService:Create(
			MiniBar,
			TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.new(0.5, 0, 0, -80) }
		):Play()
		task.delay(0.2, function()
			CRTOpen()
		end)
	end

	Close.MouseButton1Click:Connect(ShowMiniBar)
	MiniBar.MouseButton1Click:Connect(HideMiniBar)

	-- ドラッグ（DragHandleボDragLineを押している間のみ可能）
	local Dragging = false
	local DragStart, StartPos

	local function StartDrag(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1
		or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging = true
			DragStart = Input.Position
			StartPos = Main.Position
			Input.Changed:Connect(function()
				if Input.UserInputState == Enum.UserInputState.End then
					Dragging = false
				end
			end)
		end
	end

	DragHandle.InputBegan:Connect(StartDrag)
	DragLine.InputBegan:Connect(StartDrag)

	UserInputService.InputChanged:Connect(function(Input)
		if Dragging and (
			Input.UserInputType == Enum.UserInputType.MouseMovement
			or Input.UserInputType == Enum.UserInputType.Touch
		) then
			local Delta = Input.Position - DragStart
			Main.Position = UDim2.new(
				StartPos.X.Scale, StartPos.X.Offset + Delta.X,
				StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y
			)
		end
	end)

	-- ============================================================
	--  Window オブジェクト
	-- ============================================================
	local Window = {}
	Window._ScreenGui   = ScreenGui
	Window._Main        = Main
	Window._TabBar      = TabBar
	Window._ContentArea = ContentArea
	Window._Tabs        = {}
	Window._ActiveTab   = nil
	Window._TabOffset   = 0

	-- ----------------------------------------------------------
	--  Window:ApplyTheme(name)
	--  実行時にテーマを切り替える（複数ウィンドウ安全）
	-- ----------------------------------------------------------
	function Window:ApplyTheme(name)
		ApplyTheme(name)
	end

	local function SwitchTab(target)
		for _, t in ipairs(Window._Tabs) do
			local active = (t == target)
			t.Page.Visible = active
			t.Underline.Visible = active
			if t.Status then
				t.Status.Text = active and "Selected" or ""
			end
		end
		Window._ActiveTab = target
	end

	-- ----------------------------------------------------------
	--  Window:CreateTab(name)
	-- ----------------------------------------------------------
	function Window:CreateTab(name)

		local TAB_W = 73
		local TAB_H = 30

		-- タブボタン：TextButton（透明・クリック受付け用）
		local Btn = Instance.new("TextButton")
		Btn.Size = UDim2.fromOffset(TAB_W, TAB_H)
		Btn.Position = UDim2.fromOffset(self._TabOffset, 0)
		Btn.BackgroundTransparency = 1
		Btn.BorderSizePixel = 0
		Btn.Text = ""
		Btn.ZIndex = 10
		Btn.Parent = self._TabBar

		-- タブボタン：暗い半透明背景
		local BtnBg = Instance.new("Frame")
		BtnBg.Size = UDim2.fromScale(1, 1)
		BtnBg.BackgroundColor3 = C_BG
		BtnBg.BackgroundTransparency = 0.45
		BtnBg.BorderSizePixel = 0
		BtnBg.ZIndex = 9
		BtnBg.Parent = Btn
		table.insert(ThemeListeners, { type = "bg", obj = BtnBg })

		local BtnStroke = Instance.new("UIStroke")
		BtnStroke.Color = C_ACCENT
		BtnStroke.Thickness = 1
		BtnStroke.Transparency = 0.5
		BtnStroke.Parent = BtnBg
		table.insert(ThemeListeners, { type = "stroke", obj = BtnStroke })

		-- L字コーナー（4隅）
		MakeCorner(Btn, 0, 0)
		MakeCorner(Btn, 1, 0)
		MakeCorner(Btn, 0, 1)
		MakeCorner(Btn, 1, 1)

		-- タブタイトル（上段）
		local BtnTitle = Instance.new("TextLabel")
		BtnTitle.Size = UDim2.new(1, 0, 0, 15)
		BtnTitle.BackgroundTransparency = 1
		BtnTitle.Text = name
		BtnTitle.Font = Enum.Font.Code
		BtnTitle.TextSize = 12
		BtnTitle.TextColor3 = C_ACCENT_LT
		BtnTitle.ZIndex = 11
		BtnTitle.Parent = Btn
		table.insert(ThemeListeners, { type = "text_lt", obj = BtnTitle })

		-- タブステータス（下段）
		local BtnStatus = Instance.new("TextLabel")
		BtnStatus.Size = UDim2.new(1, 0, 0, 10)
		BtnStatus.Position = UDim2.new(0, 0, 0, 15)
		BtnStatus.BackgroundTransparency = 1
		BtnStatus.Text = ""
		BtnStatus.Font = Enum.Font.Code
		BtnStatus.TextSize = 8
		BtnStatus.TextColor3 = C_ACCENT
		BtnStatus.ZIndex = 11
		BtnStatus.Parent = Btn
		table.insert(ThemeListeners, { type = "text_accent", obj = BtnStatus })

		local Underline = Instance.new("Frame")
		Underline.Size = UDim2.new(1, 0, 0, 1)
		Underline.Position = UDim2.new(0, 0, 1, -1)
		Underline.BorderSizePixel = 0
		Underline.BackgroundColor3 = C_ACCENT
		Underline.Visible = false
		Underline.ZIndex = 10
		Underline.Parent = Btn
		table.insert(ThemeListeners, { type = "underline", obj = Underline })

		local Page = Instance.new("ScrollingFrame")
		Page.Size = UDim2.fromScale(1, 1)
		Page.BackgroundTransparency = 1
		Page.BorderSizePixel = 0
		Page.ScrollBarThickness = 4
		Page.ScrollBarImageColor3 = C_ACCENT
		Page.ScrollBarImageTransparency = 0.3
		Page.CanvasSize = UDim2.fromOffset(0, 0)
		Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
		Page.ScrollingEnabled = true
		Page.ScrollingDirection = Enum.ScrollingDirection.Y
		Page.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
		Page.Visible = false
		Page.Parent = self._ContentArea

		local ListLayout = Instance.new("UIListLayout")
		ListLayout.Padding = UDim.new(0, 6)
		ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ListLayout.Parent = Page

		local Padding = Instance.new("UIPadding")
		Padding.PaddingTop = UDim.new(0, 4)
		Padding.PaddingBottom = UDim.new(0, 8)
		Padding.PaddingLeft = UDim.new(0, 2)
		Padding.PaddingRight = UDim.new(0, 6)
		Padding.Parent = Page

		local tabEntry = {
			Button    = Btn,
			Page      = Page,
			Underline = Underline,
			Status    = BtnStatus,
			_Order    = 0,
		}

		table.insert(self._Tabs, tabEntry)
		self._TabOffset = self._TabOffset + TAB_W + 5
		-- CanvasSizeを更新して横スクロール範囲を拡張する
		self._TabBar.CanvasSize = UDim2.fromOffset(self._TabOffset, 30)

		if #self._Tabs == 1 then
			SwitchTab(tabEntry)
		end

		Btn.MouseButton1Click:Connect(function()
			SwitchTab(tabEntry)
		end)

		-- ============================================================
		--  Tab オブジェクト
		-- ============================================================
		local Tab = {}
		Tab._Entry = tabEntry

		local function NextOrder()
			tabEntry._Order = tabEntry._Order + 1
			return tabEntry._Order
		end

			-- --------------------------------------------------------
			--  Tab:AddButton(labelText, callback)
			-- --------------------------------------------------------
			function Tab:AddButton(labelText, callback)

				local Bg = MakeHertaFrame(tabEntry.Page, UDim2.new(1, 0, 0, 24), NextOrder())

					-- 左側: 説明ラベル（Toggleの NameLabel と同構造）
					local NameLabel = Instance.new("TextLabel")
					NameLabel.BackgroundTransparency = 1
					NameLabel.Size = UDim2.new(0.7, -5, 1, 0)
					NameLabel.Position = UDim2.fromOffset(7, 0)
					NameLabel.Text = labelText
					NameLabel.Font = Enum.Font.Code
					NameLabel.TextSize = 11
					NameLabel.TextXAlignment = Enum.TextXAlignment.Left
					NameLabel.TextColor3 = C_ACCENT_LT
					NameLabel.Parent = Bg
					table.insert(ThemeListeners, { type = "text_lt", obj = NameLabel })

					-- 右側: Clickバッジ（Toggleの BadgeBg と同じサイズ・構造）
					local BadgeBg = Instance.new("Frame")
					BadgeBg.Size = UDim2.fromOffset(35, 15)
					BadgeBg.AnchorPoint = Vector2.new(1, 0.5)
					BadgeBg.Position = UDim2.new(1, -7, 0.5, 0)
					BadgeBg.BackgroundColor3 = C_BG
					BadgeBg.BackgroundTransparency = 0.3
					BadgeBg.BorderSizePixel = 0
					BadgeBg.Parent = Bg
					table.insert(ThemeListeners, { type = "bg", obj = BadgeBg })

					local BadgeCorner = Instance.new("UICorner")
					BadgeCorner.CornerRadius = UDim.new(0, 4)
					BadgeCorner.Parent = BadgeBg

					local BadgeStroke = Instance.new("UIStroke")
					BadgeStroke.Color = C_ACCENT
					BadgeStroke.Thickness = 1
					BadgeStroke.Transparency = 0.5
					BadgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
					BadgeStroke.Parent = BadgeBg
					table.insert(ThemeListeners, { type = "stroke", obj = BadgeStroke })

					local ClickLabel = Instance.new("TextLabel")
					ClickLabel.Size = UDim2.fromScale(1, 1)
					ClickLabel.BackgroundTransparency = 1
					ClickLabel.Text = "Click"
					ClickLabel.Font = Enum.Font.Code
					ClickLabel.TextSize = 11
					ClickLabel.TextColor3 = C_ACCENT_LT
					ClickLabel.Parent = BadgeBg
					table.insert(ThemeListeners, { type = "text_lt", obj = ClickLabel })

					-- クリック受付ボタン（Bg全体）
					local Btn = Instance.new("TextButton")
					Btn.Size = UDim2.fromScale(1, 1)
					Btn.BackgroundTransparency = 1
					Btn.Text = ""
					Btn.ZIndex = 5
					Btn.Parent = Bg

					-- ホバー時に Badge を光らせる
					Btn.MouseEnter:Connect(function()
						TweenService:Create(ClickLabel, TweenInfo.new(0.12), { TextColor3 = C_ACCENT }):Play()
						TweenService:Create(BadgeStroke, TweenInfo.new(0.12), { Transparency = 0 }):Play()
					end)
					Btn.MouseLeave:Connect(function()
						TweenService:Create(ClickLabel, TweenInfo.new(0.12), { TextColor3 = C_ACCENT_LT }):Play()
						TweenService:Create(BadgeStroke, TweenInfo.new(0.12), { Transparency = 0.5 }):Play()
					end)

					Btn.MouseButton1Click:Connect(function()
						if callback then callback() end
					end)

					local obj = {}
					function obj:SetLabel(text)
						NameLabel.Text = text
					end
					return obj
				end

			-- --------------------------------------------------------
			--  Tab:AddToggle(labelText, default, callback)
			-- --------------------------------------------------------
			function Tab:AddToggle(labelText, default, callback)

			local Enabled = (default == true)

			local Bg = MakeHertaFrame(tabEntry.Page, UDim2.new(1, 0, 0, 24), NextOrder())

			local Toggle = Instance.new("TextButton")
			Toggle.Size = UDim2.fromScale(1, 1)
			Toggle.BackgroundTransparency = 1
			Toggle.Text = ""
			Toggle.Parent = Bg

			local NameLabel = Instance.new("TextLabel")
			NameLabel.BackgroundTransparency = 1
			NameLabel.Size = UDim2.new(0.7, -5, 1, 0)
			NameLabel.Position = UDim2.fromOffset(7, 0)
			NameLabel.Text = labelText
			NameLabel.Font = Enum.Font.Code
			NameLabel.TextSize = 11
			NameLabel.TextXAlignment = Enum.TextXAlignment.Left
			NameLabel.TextColor3 = C_ACCENT_LT
			NameLabel.Parent = Toggle
			table.insert(ThemeListeners, { type = "text_lt", obj = NameLabel })

			local BadgeBg = Instance.new("Frame")
			BadgeBg.Size = UDim2.fromOffset(35, 15)
			BadgeBg.AnchorPoint = Vector2.new(1, 0.5)
			BadgeBg.Position = UDim2.new(1, -7, 0.5, 0)
			BadgeBg.BackgroundColor3 = C_BG
			BadgeBg.BackgroundTransparency = 0.3
			BadgeBg.BorderSizePixel = 0
			BadgeBg.Parent = Toggle
			table.insert(ThemeListeners, { type = "bg", obj = BadgeBg })

			local BadgeCorner = Instance.new("UICorner")
			BadgeCorner.CornerRadius = UDim.new(0, 4)
			BadgeCorner.Parent = BadgeBg

				local BadgeStroke = Instance.new("UIStroke")
				BadgeStroke.Thickness = 1
				BadgeStroke.Transparency = 0.5
				BadgeStroke.Parent = BadgeBg
				table.insert(ThemeListeners, { type = "badge_on_stroke", obj = BadgeStroke, stateRef = nil })
				local badgeStrokeEntry = ThemeListeners[#ThemeListeners]

				local StateLabel = Instance.new("TextLabel")
				StateLabel.Size = UDim2.fromScale(1, 1)
				StateLabel.BackgroundTransparency = 1
				StateLabel.Font = Enum.Font.Code
				StateLabel.TextSize = 11
				StateLabel.Parent = BadgeBg
				table.insert(ThemeListeners, { type = "toggle_state", obj = StateLabel, stateRef = nil })
				local stateLabelEntry = ThemeListeners[#ThemeListeners]

				local function UpdateToggle()
					if Enabled then
						StateLabel.Text = "ON"
						StateLabel.TextColor3 = C_ACCENT
						BadgeStroke.Color = C_ACCENT
						stateLabelEntry.isOn = true
						badgeStrokeEntry.isOn = true
					else
						StateLabel.Text = "OFF"
						StateLabel.TextColor3 = C_DARK
						BadgeStroke.Color = C_DARK
						stateLabelEntry.isOn = false
						badgeStrokeEntry.isOn = false
					end
				end

			Toggle.MouseButton1Click:Connect(function()
				Enabled = not Enabled
				UpdateToggle()
				if callback then callback(Enabled) end
			end)

			UpdateToggle()

			local obj = {}
			function obj:Set(v)
				Enabled = v
				UpdateToggle()
				if callback then callback(Enabled) end
			end
			function obj:Get() return Enabled end
			return obj
		end

		-- --------------------------------------------------------
		--  Tab:AddSlider(labelText, options, callback)
		-- --------------------------------------------------------
		function Tab:AddSlider(labelText, options, callback)

			local Min   = options.Min     or 0
			local Max   = options.Max     or 100
			local Value = options.Default or Min

			local Bg = MakeHertaFrame(tabEntry.Page, UDim2.new(1, 0, 0, 37), NextOrder())

			local NameLabel = Instance.new("TextLabel")
			NameLabel.Size = UDim2.new(0.65, 0, 0, 16)
			NameLabel.Position = UDim2.fromOffset(7, 3)
			NameLabel.BackgroundTransparency = 1
			NameLabel.Text = labelText
			NameLabel.Font = Enum.Font.Code
			NameLabel.TextSize = 11
			NameLabel.TextXAlignment = Enum.TextXAlignment.Left
			NameLabel.TextColor3 = C_ACCENT_LT
			NameLabel.Parent = Bg
			table.insert(ThemeListeners, { type = "text_lt", obj = NameLabel })

			local ValueLabel = Instance.new("TextLabel")
			ValueLabel.Size = UDim2.new(0.3, -7, 0, 16)
			ValueLabel.Position = UDim2.new(0.7, 0, 0, 3)
			ValueLabel.BackgroundTransparency = 1
			ValueLabel.Font = Enum.Font.Code
			ValueLabel.TextSize = 11
			ValueLabel.TextColor3 = C_ACCENT
			ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
			ValueLabel.Parent = Bg
			table.insert(ThemeListeners, { type = "text_accent", obj = ValueLabel })

			local TrackBg = Instance.new("Frame")
			TrackBg.Size = UDim2.new(1, -13, 0, 4)
			TrackBg.Position = UDim2.new(0, 7, 0, 23)
			TrackBg.BackgroundColor3 = C_BG
			TrackBg.BackgroundTransparency = 0.2
			TrackBg.BorderSizePixel = 0
			TrackBg.Parent = Bg
			table.insert(ThemeListeners, { type = "track", obj = TrackBg })

			local TrackCorner = Instance.new("UICorner")
			TrackCorner.CornerRadius = UDim.new(1, 0)
			TrackCorner.Parent = TrackBg

			local Fill = Instance.new("Frame")
			Fill.Size = UDim2.new(0, 0, 1, 0)
			Fill.BackgroundColor3 = C_ACCENT
			Fill.BorderSizePixel = 0
			Fill.Parent = TrackBg
			table.insert(ThemeListeners, { type = "fill", obj = Fill })

			local FillCorner = Instance.new("UICorner")
			FillCorner.CornerRadius = UDim.new(1, 0)
			FillCorner.Parent = Fill

			local Knob = Instance.new("Frame")
			Knob.Size = UDim2.fromOffset(9, 9)
			Knob.AnchorPoint = Vector2.new(0.5, 0.5)
			Knob.Position = UDim2.new(0, 0, 0.5, 0)
			Knob.BackgroundColor3 = C_ACCENT_LT
			Knob.BorderSizePixel = 0
			Knob.ZIndex = 2
			Knob.Parent = TrackBg
			table.insert(ThemeListeners, { type = "knob", obj = Knob })

			local KnobCorner = Instance.new("UICorner")
			KnobCorner.CornerRadius = UDim.new(1, 0)
			KnobCorner.Parent = Knob

			local SliderDragging = false

			local function UpdateSlider()
				local Percent = (Value - Min) / (Max - Min)
				Fill.Size = UDim2.new(Percent, 0, 1, 0)
				Knob.Position = UDim2.new(Percent, 0, 0.5, 0)
				ValueLabel.Text = tostring(math.floor(Value + 0.5))
			end

			local function SetFromPosition(X)
				local TrackStart = TrackBg.AbsolutePosition.X
				local TrackWidth = TrackBg.AbsoluteSize.X
				local Percent = math.clamp((X - TrackStart) / TrackWidth, 0, 1)
				Value = Min + (Max - Min) * Percent
				UpdateSlider()
				if callback then callback(Value) end
			end

			Knob.InputBegan:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1
				or Input.UserInputType == Enum.UserInputType.Touch then
					SliderDragging = true
				end
			end)

			Knob.InputEnded:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1
				or Input.UserInputType == Enum.UserInputType.Touch then
					SliderDragging = false
				end
			end)

			TrackBg.InputBegan:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1
				or Input.UserInputType == Enum.UserInputType.Touch then
					SetFromPosition(Input.Position.X)
					SliderDragging = true
				end
			end)

			UserInputService.InputChanged:Connect(function(Input)
				if not SliderDragging then return end
				if Input.UserInputType ~= Enum.UserInputType.MouseMovement
				and Input.UserInputType ~= Enum.UserInputType.Touch then return end
				SetFromPosition(Input.Position.X)
			end)

			UserInputService.InputEnded:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1
				or Input.UserInputType == Enum.UserInputType.Touch then
					SliderDragging = false
				end
			end)

			UpdateSlider()

			local obj = {}
			function obj:Set(v)
				Value = math.clamp(v, Min, Max)
				UpdateSlider()
				if callback then callback(Value) end
			end
			function obj:Get() return Value end
			return obj
		end

		-- --------------------------------------------------------
		--  Tab:AddDropdown(titleText, options, callback)
		-- --------------------------------------------------------
		function Tab:AddDropdown(titleText2, options, callback)

			local Selected = nil
			local Open     = false

				local Container = Instance.new("Frame")
				Container.Size = UDim2.new(1, 0, 0, 24)
				Container.BackgroundTransparency = 1
				Container.BorderSizePixel = 0
				Container.ClipsDescendants = false
				Container.LayoutOrder = NextOrder()
				Container.ZIndex = 20
				Container.Parent = tabEntry.Page

				local MainButton = Instance.new("TextButton")
				MainButton.Size = UDim2.new(1, 0, 0, 24)
				MainButton.BackgroundColor3 = C_BG
				MainButton.BackgroundTransparency = 0.45
				MainButton.BorderSizePixel = 0
				MainButton.Text = ""
				MainButton.ZIndex = 20
				MainButton.Parent = Container
				table.insert(ThemeListeners, { type = "bg", obj = MainButton })

				local MBCorner2 = Instance.new("UICorner")
				MBCorner2.CornerRadius = UDim.new(0, 4)
				MBCorner2.Parent = MainButton

				local MBStroke2 = Instance.new("UIStroke")
				MBStroke2.Color = C_ACCENT
				MBStroke2.Thickness = 1
				MBStroke2.Transparency = 0.5
				MBStroke2.Parent = MainButton
				table.insert(ThemeListeners, { type = "stroke", obj = MBStroke2 })

				-- 4隅コーナー
				MakeCorner(MainButton, 0, 0)
				MakeCorner(MainButton, 1, 0)
				MakeCorner(MainButton, 0, 1)
				MakeCorner(MainButton, 1, 1)

				local Header = Instance.new("TextLabel")
				Header.Size = UDim2.new(1, -7, 1, 0)
				Header.Position = UDim2.fromOffset(7, 0)
				Header.BackgroundTransparency = 1
				Header.Font = Enum.Font.Code
				Header.TextSize = 11
				Header.TextColor3 = C_ACCENT_LT
				Header.TextXAlignment = Enum.TextXAlignment.Left
				Header.Text = titleText2 .. "  ▼"
				Header.ZIndex = 21
				Header.Parent = MainButton
				table.insert(ThemeListeners, { type = "text_lt", obj = Header })

					-- ListFrameはMainの子として配置し、ZIndexで前面に重ねる（ScrollingFrame: 3段分 = 84px 上限）
					local ITEM_H   = 19
					local MAX_ROWS = 3
					local MAX_H    = ITEM_H * MAX_ROWS  -- 84px

					local ListFrame = Instance.new("ScrollingFrame")
					ListFrame.Size = UDim2.fromOffset(0, 0)
					ListFrame.BackgroundColor3 = C_BG
					ListFrame.BackgroundTransparency = 0.3
					ListFrame.BorderSizePixel = 0
					ListFrame.ClipsDescendants = true
					ListFrame.ZIndex = 50
					ListFrame.Visible = false
					ListFrame.ScrollBarThickness = 4
					ListFrame.ScrollBarImageColor3 = C_ACCENT
					ListFrame.ScrollBarImageTransparency = 0.3
					ListFrame.CanvasSize = UDim2.fromOffset(0, 0)
					ListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
					ListFrame.ScrollingDirection = Enum.ScrollingDirection.Y
					ListFrame.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
					ListFrame.Parent = Main
					table.insert(ThemeListeners, { type = "bg", obj = ListFrame })

					local LFCorner = Instance.new("UICorner")
					LFCorner.CornerRadius = UDim.new(0, 4)
					LFCorner.Parent = ListFrame

					local LFStroke = Instance.new("UIStroke")
					LFStroke.Color = C_ACCENT
					LFStroke.Thickness = 1
					LFStroke.Transparency = 0.5
					LFStroke.Parent = ListFrame
					table.insert(ThemeListeners, { type = "stroke", obj = LFStroke })

					local Layout = Instance.new("UIListLayout")
					Layout.SortOrder = Enum.SortOrder.LayoutOrder
					Layout.Parent = ListFrame

					local function UpdateHeader()
						Header.Text = (Selected and tostring(Selected) or titleText2) .. "  ▼"
						Header.TextColor3 = Selected and C_ACCENT or C_ACCENT_LT
						MBStroke2.Color = C_ACCENT
					end

						local function RefreshList()
							-- 表示高さ: 項目数に応じて最大 MAX_H まで
							local itemCount = #options
							local listH = Open and math.min(itemCount * ITEM_H, MAX_H) or 0
							if Open then
								-- Main相対座標で配置位置を計算
								local mainAbs = Main.AbsolutePosition
								local mainSize = Main.AbsoluteSize
								local btnAbs  = MainButton.AbsolutePosition
								local btnSize = MainButton.AbsoluteSize
								local relX = btnAbs.X - mainAbs.X
								-- 下方展開時の下端 Y座標（Main相対）
								local downY  = btnAbs.Y - mainAbs.Y + btnSize.Y + 2
								local downEnd = downY + listH
								-- 下に展開するスペースが足りない場合は上方展開
								local relY
								if downEnd > mainSize.Y - 6 then
									-- 上方展開: ボタンの上端から listH 分上に配置
									relY = btnAbs.Y - mainAbs.Y - listH - 2
								else
									relY = downY
								end
								ListFrame.Position = UDim2.fromOffset(relX, relY)
								ListFrame.Size = UDim2.fromOffset(btnSize.X, 0)
								ListFrame.Visible = true
							end
							TweenService:Create(
								ListFrame,
								TweenInfo.new(0.18, Enum.EasingStyle.Quad),
								{ Size = UDim2.fromOffset(
									MainButton.AbsoluteSize.X,
									listH
								)}
							):Play()
							if not Open then
								task.delay(0.19, function() ListFrame.Visible = false end)
							end
						end

			local function BuildOptions()
				for _, child in ipairs(ListFrame:GetChildren()) do
					if child:IsA("TextButton") then child:Destroy() end
				end
				for i, optName in ipairs(options) do
					local Opt = Instance.new("TextButton")
					Opt.Size = UDim2.new(1, 0, 0, 19)
					Opt.BackgroundTransparency = 1
					Opt.BorderSizePixel = 0
					Opt.Font = Enum.Font.Code
					Opt.TextSize = 10
					Opt.TextColor3 = C_ACCENT_LT
					Opt.TextXAlignment = Enum.TextXAlignment.Left
					Opt.Text = "  " .. tostring(optName)
					Opt.LayoutOrder = i
					Opt.ZIndex = 23
					Opt.Parent = ListFrame
					table.insert(ThemeListeners, { type = "text_lt", obj = Opt })

					Opt.MouseEnter:Connect(function() Opt.TextColor3 = C_ACCENT end)
					Opt.MouseLeave:Connect(function() Opt.TextColor3 = C_ACCENT_LT end)

					Opt.MouseButton1Click:Connect(function()
						Selected = optName
						UpdateHeader()
						Open = false
						RefreshList()
						if callback then callback(optName) end
					end)
				end
			end

					-- Mainの子なのでドラッグ時も自動追従。RenderStepped不要

				MainButton.MouseButton1Click:Connect(function()
					Open = not Open
					RefreshList()
				end)

			BuildOptions()
			UpdateHeader()

			local obj = {}
			function obj:Set(v)
				Selected = v
				UpdateHeader()
				if callback then callback(v) end
			end
			function obj:Get() return Selected end
			function obj:Refresh(newOptions)
				options = newOptions
				BuildOptions()
			end
			return obj
		end

			-- --------------------------------------------------------
			--  Tab:AddLabel(text)
			-- --------------------------------------------------------
			function Tab:AddLabel(text)

				local Bg = Instance.new("Frame")
				Bg.Size = UDim2.new(1, 0, 0, 20)
				Bg.BackgroundColor3 = C_BG
				Bg.BackgroundTransparency = 0.55
				Bg.BorderSizePixel = 0
				Bg.LayoutOrder = NextOrder()
				Bg.Parent = tabEntry.Page
				table.insert(ThemeListeners, { type = "bg", obj = Bg })

				local BgCorner = Instance.new("UICorner")
				BgCorner.CornerRadius = UDim.new(0, 4)
				BgCorner.Parent = Bg

				local TopLine = Instance.new("Frame")
				TopLine.Size = UDim2.new(1, 0, 0, 1)
				TopLine.BorderSizePixel = 0
				TopLine.BackgroundColor3 = C_ACCENT
				TopLine.Parent = Bg
				table.insert(ThemeListeners, { type = "headerline", obj = TopLine })

				local BottomLine = Instance.new("Frame")
				BottomLine.Size = UDim2.new(1, 0, 0, 1)
				BottomLine.Position = UDim2.new(0, 0, 1, -1)
				BottomLine.BorderSizePixel = 0
				BottomLine.BackgroundColor3 = C_ACCENT
				BottomLine.Parent = Bg
				table.insert(ThemeListeners, { type = "headerline", obj = BottomLine })

				local Label = Instance.new("TextLabel")
				Label.Size = UDim2.new(1, -11, 1, -3)
				Label.Position = UDim2.fromOffset(5, 1)
				Label.BackgroundTransparency = 1
				Label.Text = text or ""
				Label.Font = Enum.Font.Code
				Label.TextSize = 10
				Label.TextColor3 = C_ACCENT_LT
				Label.TextXAlignment = Enum.TextXAlignment.Left
				Label.Parent = Bg
				table.insert(ThemeListeners, { type = "text_lt", obj = Label })

				local obj = {}
				function obj:Set(v) Label.Text = tostring(v) end
				function obj:Get() return Label.Text end
				return obj
			end

			-- --------------------------------------------------------
			--  Tab:AddTextbox(Config)
				-- --------------------------------------------------------
				function Tab:AddTextbox(Config)

					-- Toggleと同じ 36px フレームをベースに使用
					local Bg = MakeHertaFrame(tabEntry.Page, UDim2.new(1, 0, 0, 24), NextOrder())

					-- 左側: 説明ラベル
					local NameLabel = Instance.new("TextLabel")
					NameLabel.BackgroundTransparency = 1
					NameLabel.Size = UDim2.new(0.45, -5, 1, 0)
					NameLabel.Position = UDim2.fromOffset(7, 0)
					NameLabel.Text = Config.Name or ""
					NameLabel.Font = Enum.Font.Code
					NameLabel.TextSize = 11
					NameLabel.TextXAlignment = Enum.TextXAlignment.Left
					NameLabel.TextColor3 = C_ACCENT_LT
					NameLabel.Parent = Bg
					table.insert(ThemeListeners, { type = "text_lt", obj = NameLabel })

					-- 右側: テキスト入力ボックス（Toggleの BadgeBg と同じサイズ感）
					local Box = Instance.new("TextBox")
					Box.Size = UDim2.new(0.55, -12, 0, 16)
					Box.AnchorPoint = Vector2.new(1, 0.5)
					Box.Position = UDim2.new(1, -7, 0.5, 0)
					Box.BackgroundColor3 = C_BG
					Box.BackgroundTransparency = 0.3
					Box.BorderSizePixel = 0
					Box.ClearTextOnFocus = false
					Box.Text = tostring(Config.Default or "")
					Box.PlaceholderText = tostring(Config.Placeholder or "Value...")
					Box.PlaceholderColor3 = C_DARK
					Box.Font = Enum.Font.Code
					Box.TextSize = 10
					Box.TextColor3 = C_ACCENT_LT
					Box.Parent = Bg
					table.insert(ThemeListeners, { type = "bg",      obj = Box })
					table.insert(ThemeListeners, { type = "text_lt", obj = Box })

					-- ボーダー（UIStrokeはテキストに適用しないよう TextBox の親フレームに付ける）
					local BoxHolder = Instance.new("Frame")
					BoxHolder.Size = UDim2.new(0.55, -12, 0, 16)
					BoxHolder.AnchorPoint = Vector2.new(1, 0.5)
					BoxHolder.Position = UDim2.new(1, -7, 0.5, 0)
					BoxHolder.BackgroundTransparency = 1
					BoxHolder.BorderSizePixel = 0
					BoxHolder.ZIndex = 2
					BoxHolder.Parent = Bg

					-- BoxHolderにコーナーとストローク
					local BoxCorner = Instance.new("UICorner")
					BoxCorner.CornerRadius = UDim.new(0, 4)
					BoxCorner.Parent = Box

					local BoxStroke = Instance.new("UIStroke")
					BoxStroke.Color = C_ACCENT
					BoxStroke.Thickness = 1
					BoxStroke.Transparency = 0.5
					BoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
					BoxStroke.Parent = Box
					table.insert(ThemeListeners, { type = "stroke", obj = BoxStroke })

					Box.Focused:Connect(function()
						BoxStroke.Thickness = 2
						BoxStroke.Transparency = 0
					end)

					Box.FocusLost:Connect(function()
						BoxStroke.Thickness = 1
						BoxStroke.Transparency = 0.5
						if Config.Callback then
							Config.Callback(Box.Text)
						end
					end)

					local TextboxObject = {}
					function TextboxObject:Set(Value)
						Box.Text = tostring(Value)
					end
					function TextboxObject:Get()
						return Box.Text
					end
					function TextboxObject:Clear()
						Box.Text = ""
					end
					function TextboxObject:SetPlaceholder(Text)
						Box.PlaceholderText = tostring(Text)
					end
					TextboxObject.Object = Bg
					return TextboxObject
				end

				-- --------------------------------------------------------
				--  Tab:AddColorPicker(Config)
				--  Config: { Name, Default(Color3), Callback }
				-- --------------------------------------------------------
				function Tab:AddColorPicker(Config)

					local currentColor = Config.Default or Color3.fromRGB(255, 0, 0)
				local pickerOpen = false

					-- 外側コンテナ（閉じた状態: 36px、開いた状態: 36+120=156px）
					local Container = Instance.new("Frame")
					Container.Size = UDim2.new(1, 0, 0, 24)
					Container.BackgroundTransparency = 1
					Container.BorderSizePixel = 0
					Container.ClipsDescendants = false
					Container.LayoutOrder = NextOrder()
					Container.Parent = tabEntry.Page

					-- ヘッダー行（MakeHertaFrame）
					local Header = MakeHertaFrame(Container, UDim2.new(1, 0, 0, 24), 0)

					-- ラベル
					local NameLbl = Instance.new("TextLabel")
					NameLbl.Size = UDim2.new(1, -53, 1, 0)
					NameLbl.Position = UDim2.fromOffset(7, 0)
					NameLbl.BackgroundTransparency = 1
					NameLbl.Text = Config.Name or "Color"
					NameLbl.Font = Enum.Font.Code
					NameLbl.TextSize = 11
					NameLbl.TextColor3 = C_ACCENT_LT
					NameLbl.TextXAlignment = Enum.TextXAlignment.Left
					NameLbl.Parent = Header
					table.insert(ThemeListeners, { type = "text_lt", obj = NameLbl })

					-- カラープレビューボックス
					local Preview = Instance.new("Frame")
					Preview.Size = UDim2.fromOffset(29, 15)
					Preview.AnchorPoint = Vector2.new(1, 0.5)
					Preview.Position = UDim2.new(1, -7, 0.5, 0)
					Preview.BackgroundColor3 = currentColor
					Preview.BorderSizePixel = 0
					Preview.Parent = Header

					local PreviewStroke = Instance.new("UIStroke")
					PreviewStroke.Color = C_ACCENT
					PreviewStroke.Thickness = 1
					PreviewStroke.Parent = Preview
					table.insert(ThemeListeners, { type = "stroke", obj = PreviewStroke })

					-- クリック受付ボタン（ヘッダー全体）
					local HBtn = Instance.new("TextButton")
					HBtn.Size = UDim2.fromScale(1, 1)
					HBtn.BackgroundTransparency = 1
					HBtn.Text = ""
					HBtn.ZIndex = 5
					HBtn.Parent = Header

					-- ピッカーパネル（ドロップダウン風にMainの子として配置）
					local Panel = Instance.new("Frame")
					Panel.Size = UDim2.fromOffset(0, 0)
					Panel.BackgroundColor3 = C_BG
					Panel.BackgroundTransparency = 0.2
					Panel.BorderSizePixel = 0
					Panel.ClipsDescendants = true
					Panel.ZIndex = 50
					Panel.Visible = false
					Panel.Parent = Main
					table.insert(ThemeListeners, { type = "bg", obj = Panel })

					local PanelCorner = Instance.new("UICorner")
					PanelCorner.CornerRadius = UDim.new(0, 4)
					PanelCorner.Parent = Panel

					local PanelStroke = Instance.new("UIStroke")
					PanelStroke.Color = C_ACCENT
					PanelStroke.Thickness = 1
					PanelStroke.Transparency = 0.4
					PanelStroke.Parent = Panel
					table.insert(ThemeListeners, { type = "stroke", obj = PanelStroke })

					-- ---- Hueスライダー（横長バー）----
					local HueBar = Instance.new("Frame")
					HueBar.Size = UDim2.new(1, -11, 0, 9)
					HueBar.Position = UDim2.fromOffset(5, 5)
					HueBar.BorderSizePixel = 0
					HueBar.ZIndex = 51
					HueBar.Parent = Panel

					local HueGrad = Instance.new("UIGradient")
					HueGrad.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0,    Color3.fromHSV(0,   1, 1)),
						ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17,1, 1)),
						ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33,1, 1)),
						ColorSequenceKeypoint.new(0.5,  Color3.fromHSV(0.5, 1, 1)),
						ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67,1, 1)),
						ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83,1, 1)),
						ColorSequenceKeypoint.new(1,    Color3.fromHSV(1,   1, 1)),
					})
					HueGrad.Parent = HueBar

					-- Hueカーソル
					local HueCursor = Instance.new("Frame")
					HueCursor.Size = UDim2.fromOffset(3, 12)
					HueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
					HueCursor.Position = UDim2.new(0, 0, 0.5, 0)
					HueCursor.BackgroundColor3 = Color3.fromRGB(255,255,255)
					HueCursor.BorderSizePixel = 0
					HueCursor.ZIndex = 52
					HueCursor.Parent = HueBar

					-- ---- SV四角パレット ----
					local SVBox = Instance.new("Frame")
					SVBox.Size = UDim2.new(1, -11, 0, 47)
					SVBox.Position = UDim2.fromOffset(5, 19)
					SVBox.BorderSizePixel = 0
					SVBox.ZIndex = 51
					SVBox.Parent = Panel

					-- 白→Hue色のグラデーション（横）
					local SVGradH = Instance.new("UIGradient")
					SVGradH.Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromHSV(0,1,1))
					SVGradH.Parent = SVBox

						-- 黒（上）→透明（下）のグラデーションをオーバーレイ
					--  Rotation=0: UIGradientのデフォルトは左→右、Rotation=90で上→下になる
					local SVOverlay = Instance.new("Frame")
					SVOverlay.Size = UDim2.fromScale(1, 1)
					SVOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
					SVOverlay.BackgroundTransparency = 0
					SVOverlay.BorderSizePixel = 0
					SVOverlay.ZIndex = 52
					SVOverlay.Parent = SVBox

					local SVGradV = Instance.new("UIGradient")
					SVGradV.Color = ColorSequence.new(Color3.fromRGB(0,0,0), Color3.fromRGB(0,0,0))
					-- 上端（Rotation=90の先端）が黒、下端が透明
					SVGradV.Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 1),  -- 上端: 透明（明るい）
						NumberSequenceKeypoint.new(1, 0),  -- 下端: 黒（暗い）
					})
					SVGradV.Rotation = 90
					SVGradV.Parent = SVOverlay

					-- SVカーソル
					local SVCursor = Instance.new("Frame")
					SVCursor.Size = UDim2.fromOffset(7, 7)
					SVCursor.AnchorPoint = Vector2.new(0.5, 0.5)
					SVCursor.Position = UDim2.fromScale(1, 0)
					SVCursor.BackgroundColor3 = Color3.fromRGB(255,255,255)
					SVCursor.BorderSizePixel = 0
					SVCursor.ZIndex = 53
					SVCursor.Parent = SVBox

					local SVCursorCorner = Instance.new("UICorner")
					SVCursorCorner.CornerRadius = UDim.new(1, 0)
					SVCursorCorner.Parent = SVCursor

					-- ---- 内部状態 ----
					local H_val, S_val, V_val = Color3.toHSV(currentColor)

					local function UpdateVisuals()
						-- Hueカーソル位置
						HueCursor.Position = UDim2.new(H_val, 0, 0.5, 0)
						-- SVBox の横グラデーションをHueに合わせて更新
						SVGradH.Color = ColorSequence.new(
							Color3.fromRGB(255,255,255),
							Color3.fromHSV(H_val, 1, 1)
						)
						-- SVカーソル位置
						SVCursor.Position = UDim2.new(S_val, 0, 1 - V_val, 0)
						-- プレビュー更新
						currentColor = Color3.fromHSV(H_val, S_val, V_val)
						Preview.BackgroundColor3 = currentColor
					end

					local function FireCallback()
						if Config.Callback then Config.Callback(currentColor) end
					end

					-- ---- パネル表示/非表示 ----
					local PANEL_W = 133
					local PANEL_H = 72

					local function RefreshPanel()
						if pickerOpen then
							local mainAbs = Main.AbsolutePosition
							local mainSize = Main.AbsoluteSize
							local hdrAbs  = Header.AbsolutePosition
							local hdrSize = Header.AbsoluteSize
							local relX = hdrAbs.X - mainAbs.X
							local downY = hdrAbs.Y - mainAbs.Y + hdrSize.Y + 2
							local relY
							if downY + PANEL_H > mainSize.Y - 6 then
								relY = hdrAbs.Y - mainAbs.Y - PANEL_H - 2
							else
								relY = downY
							end
							Panel.Position = UDim2.fromOffset(relX, relY)
							Panel.Size = UDim2.fromOffset(PANEL_W, 0)
							Panel.Visible = true
						end
						TweenService:Create(
							Panel,
							TweenInfo.new(0.18, Enum.EasingStyle.Quad),
							{ Size = UDim2.fromOffset(PANEL_W, pickerOpen and PANEL_H or 0) }
						):Play()
						if not pickerOpen then
							task.delay(0.19, function() Panel.Visible = false end)
						end
					end

					HBtn.MouseButton1Click:Connect(function()
						pickerOpen = not pickerOpen
						if pickerOpen then UpdateVisuals() end
						RefreshPanel()
					end)

					-- ---- Hueスライダー操作 ----
					local hueDragging = false
					local function UpdateHue(inputPos)
						local abs = HueBar.AbsolutePosition
						local sz  = HueBar.AbsoluteSize
						H_val = math.clamp((inputPos.X - abs.X) / sz.X, 0, 1)
						UpdateVisuals()
						FireCallback()
					end

					HueBar.InputBegan:Connect(function(inp)
						if inp.UserInputType == Enum.UserInputType.MouseButton1
							or inp.UserInputType == Enum.UserInputType.Touch then
							hueDragging = true
							UpdateHue(inp.Position)
						end
					end)
					HueBar.InputEnded:Connect(function(inp)
						if inp.UserInputType == Enum.UserInputType.MouseButton1
							or inp.UserInputType == Enum.UserInputType.Touch then
							hueDragging = false
						end
					end)
					UserInputService.InputChanged:Connect(function(inp)
						if hueDragging and (
							inp.UserInputType == Enum.UserInputType.MouseMovement
							or inp.UserInputType == Enum.UserInputType.Touch
						) then
							UpdateHue(inp.Position)
						end
					end)

					-- ---- SVパレット操作 ----
					local svDragging = false
					local function UpdateSV(inputPos)
						local abs = SVBox.AbsolutePosition
						local sz  = SVBox.AbsoluteSize
						S_val = math.clamp((inputPos.X - abs.X) / sz.X, 0, 1)
						V_val = 1 - math.clamp((inputPos.Y - abs.Y) / sz.Y, 0, 1)
						UpdateVisuals()
						FireCallback()
					end

					SVBox.InputBegan:Connect(function(inp)
						if inp.UserInputType == Enum.UserInputType.MouseButton1
							or inp.UserInputType == Enum.UserInputType.Touch then
							svDragging = true
							UpdateSV(inp.Position)
						end
					end)
					SVBox.InputEnded:Connect(function(inp)
						if inp.UserInputType == Enum.UserInputType.MouseButton1
							or inp.UserInputType == Enum.UserInputType.Touch then
							svDragging = false
						end
					end)
					UserInputService.InputChanged:Connect(function(inp)
						if svDragging and (
							inp.UserInputType == Enum.UserInputType.MouseMovement
							or inp.UserInputType == Enum.UserInputType.Touch
						) then
							UpdateSV(inp.Position)
						end
					end)

					-- 初期ビジュアル更新
					UpdateVisuals()

					local cpObj = {}
					function cpObj:Set(color)
						currentColor = color
						H_val, S_val, V_val = Color3.toHSV(color)
						UpdateVisuals()
					end
					function cpObj:Get()
						return currentColor
					end
					return cpObj
				end

				-- --------------------------------------------------------
				--  Tab:AddKeybind(Config)
				--  Config: { Name, Default(Enum.KeyCode), Callback }
				-- --------------------------------------------------------
				function Tab:AddKeybind(Config)

					local currentKey = Config.Default or Enum.KeyCode.Unknown
					local listening  = false

					local Bg = MakeHertaFrame(tabEntry.Page, UDim2.new(1, 0, 0, 24), NextOrder())

					-- ラベル
					local NameLbl = Instance.new("TextLabel")
					NameLbl.Size = UDim2.new(1, -73, 1, 0)
					NameLbl.Position = UDim2.fromOffset(7, 0)
					NameLbl.BackgroundTransparency = 1
					NameLbl.Text = Config.Name or "Keybind"
					NameLbl.Font = Enum.Font.Code
					NameLbl.TextSize = 11
					NameLbl.TextColor3 = C_ACCENT_LT
					NameLbl.TextXAlignment = Enum.TextXAlignment.Left
					NameLbl.Parent = Bg
					table.insert(ThemeListeners, { type = "text_lt", obj = NameLbl })

					-- キー表示ボタン
					local KeyBtn = Instance.new("TextButton")
					KeyBtn.Size = UDim2.fromOffset(64, 16)
					KeyBtn.AnchorPoint = Vector2.new(1, 0.5)
					KeyBtn.Position = UDim2.new(1, -7, 0.5, 0)
					KeyBtn.BackgroundColor3 = C_BG
					KeyBtn.BackgroundTransparency = 0.4
					KeyBtn.BorderSizePixel = 0
					KeyBtn.Font = Enum.Font.Code
					KeyBtn.TextSize = 9
					KeyBtn.TextColor3 = C_ACCENT
					KeyBtn.ZIndex = 5
					KeyBtn.Parent = Bg
					table.insert(ThemeListeners, { type = "bg",         obj = KeyBtn })
					table.insert(ThemeListeners, { type = "text_accent", obj = KeyBtn })

					local KBStroke = Instance.new("UIStroke")
					KBStroke.Color = C_ACCENT
					KBStroke.Thickness = 1
					KBStroke.Transparency = 0.5
					KBStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
					KBStroke.Parent = KeyBtn
					table.insert(ThemeListeners, { type = "stroke", obj = KBStroke })

					local KBCorner = Instance.new("UICorner")
					KBCorner.CornerRadius = UDim.new(0, 4)
					KBCorner.Parent = KeyBtn

					local function UpdateKeyLabel()
						if listening then
							KeyBtn.Text = "[ ... ]"
							KeyBtn.TextColor3 = C_ACCENT_MID
						else
							local name = currentKey.Name
							KeyBtn.Text = "[ " .. name .. " ]"
							KeyBtn.TextColor3 = C_ACCENT
						end
					end

					UpdateKeyLabel()

					local conn = nil

					KeyBtn.MouseButton1Click:Connect(function()
						if listening then return end
						listening = true
						UpdateKeyLabel()
						KBStroke.Thickness = 2
						KBStroke.Transparency = 0

						conn = UserInputService.InputBegan:Connect(function(inp, gp)
							if gp then return end
							if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end

							conn:Disconnect()
							conn = nil
							listening = false
							KBStroke.Thickness = 1
							KBStroke.Transparency = 0.5

							-- ESCでキャンセル
							if inp.KeyCode == Enum.KeyCode.Escape then
								UpdateKeyLabel()
								return
							end

							currentKey = inp.KeyCode
							UpdateKeyLabel()
							if Config.Callback then Config.Callback(currentKey) end
						end)
					end)

					local kbObj = {}
					function kbObj:Set(keyCode)
						currentKey = keyCode
						UpdateKeyLabel()
					end
					function kbObj:Get()
						return currentKey
					end
					return kbObj
				end

				-- --------------------------------------------------------
				--  Tab:AddMultiDropdown(titleText, options, callback)
				--  複数選択可能なドロップダウン
				-- --------------------------------------------------------
				function Tab:AddMultiDropdown(titleText2, options, callback)

					local Selected = {}  -- { [optName] = true }
					local Open     = false

					local Container = Instance.new("Frame")
					Container.Size = UDim2.new(1, 0, 0, 24)
					Container.BackgroundTransparency = 1
					Container.BorderSizePixel = 0
					Container.ClipsDescendants = false
					Container.LayoutOrder = NextOrder()
					Container.Parent = tabEntry.Page

					local MainButton = MakeHertaFrame(Container, UDim2.new(1, 0, 0, 24), 0)

					local MBStroke2 = MainButton:FindFirstChildOfClass("UIStroke")

					-- ヘッダーテキスト
					local Header = Instance.new("TextLabel")
					Header.Size = UDim2.new(1, -7, 1, 0)
					Header.Position = UDim2.fromOffset(7, 0)
					Header.BackgroundTransparency = 1
					Header.Font = Enum.Font.Code
					Header.TextSize = 11
					Header.TextXAlignment = Enum.TextXAlignment.Left
					Header.ZIndex = 3
					Header.Parent = MainButton
					table.insert(ThemeListeners, { type = "text_lt", obj = Header })

					-- クリックボタン
					local ClickBtn = Instance.new("TextButton")
					ClickBtn.Size = UDim2.fromScale(1, 1)
					ClickBtn.BackgroundTransparency = 1
					ClickBtn.Text = ""
					ClickBtn.ZIndex = 4
					ClickBtn.Parent = MainButton

					-- リスト（ScrollingFrame、Mainの子）
					local ITEM_H   = 19
					local MAX_ROWS = 3
					local MAX_H    = ITEM_H * MAX_ROWS

					local ListFrame = Instance.new("ScrollingFrame")
					ListFrame.Size = UDim2.fromOffset(0, 0)
					ListFrame.BackgroundColor3 = C_BG
					ListFrame.BackgroundTransparency = 0.3
					ListFrame.BorderSizePixel = 0
					ListFrame.ClipsDescendants = true
					ListFrame.ZIndex = 50
					ListFrame.Visible = false
					ListFrame.ScrollBarThickness = 4
					ListFrame.ScrollBarImageColor3 = C_ACCENT
					ListFrame.ScrollBarImageTransparency = 0.3
					ListFrame.CanvasSize = UDim2.fromOffset(0, 0)
					ListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
					ListFrame.ScrollingDirection = Enum.ScrollingDirection.Y
					ListFrame.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
					ListFrame.Parent = Main
					table.insert(ThemeListeners, { type = "bg", obj = ListFrame })

					local LFCorner = Instance.new("UICorner")
					LFCorner.CornerRadius = UDim.new(0, 4)
					LFCorner.Parent = ListFrame

					local LFStroke = Instance.new("UIStroke")
					LFStroke.Color = C_ACCENT
					LFStroke.Thickness = 1
					LFStroke.Transparency = 0.5
					LFStroke.Parent = ListFrame
					table.insert(ThemeListeners, { type = "stroke", obj = LFStroke })

					local Layout = Instance.new("UIListLayout")
					Layout.SortOrder = Enum.SortOrder.LayoutOrder
					Layout.Parent = ListFrame

					-- 選択数をヘッダーに反映
					local function UpdateHeader()
						local count = 0
						for _ in pairs(Selected) do count = count + 1 end
						if count == 0 then
							Header.Text = titleText2 .. "  [未選択]  ▼"
							Header.TextColor3 = C_ACCENT_LT
						else
							Header.Text = titleText2 .. "  [" .. count .. "選択]  ▼"
							Header.TextColor3 = C_ACCENT
						end
					end

					local function GetSelected()
						local arr = {}
						for k in pairs(Selected) do table.insert(arr, k) end
						return arr
					end

					-- リスト展開/折りたたみ
					local function RefreshList()
						local itemCount = #options
						local listH = Open and math.min(itemCount * ITEM_H, MAX_H) or 0
						if Open then
							local mainAbs  = Main.AbsolutePosition
							local mainSize = Main.AbsoluteSize
							local btnAbs   = MainButton.AbsolutePosition
							local btnSize  = MainButton.AbsoluteSize
							local relX     = btnAbs.X - mainAbs.X
							local downY    = btnAbs.Y - mainAbs.Y + btnSize.Y + 2
							local relY
							if downY + listH > mainSize.Y - 6 then
								relY = btnAbs.Y - mainAbs.Y - listH - 2
							else
								relY = downY
							end
							ListFrame.Position = UDim2.fromOffset(relX, relY)
							ListFrame.Size = UDim2.fromOffset(btnSize.X, 0)
							ListFrame.Visible = true
						end
						TweenService:Create(
							ListFrame,
							TweenInfo.new(0.18, Enum.EasingStyle.Quad),
							{ Size = UDim2.fromOffset(MainButton.AbsoluteSize.X, listH) }
						):Play()
						if not Open then
							task.delay(0.19, function() ListFrame.Visible = false end)
						end
					end

					-- 各項目のチェックボックス付きボタンを構築
					local function BuildOptions()
						for _, child in ipairs(ListFrame:GetChildren()) do
							if child:IsA("TextButton") then child:Destroy() end
						end
						for i, optName in ipairs(options) do
							local Row = Instance.new("TextButton")
							Row.Size = UDim2.new(1, 0, 0, ITEM_H)
							Row.BackgroundTransparency = 1
							Row.BorderSizePixel = 0
							Row.Font = Enum.Font.Code
							Row.TextSize = 10
							Row.TextXAlignment = Enum.TextXAlignment.Left
							Row.LayoutOrder = i
							Row.ZIndex = 51
							Row.Parent = ListFrame

							local function RefreshRow()
								if Selected[optName] then
									Row.Text = "  ■ " .. tostring(optName)
									Row.TextColor3 = C_ACCENT
								else
									Row.Text = "  □ " .. tostring(optName)
									Row.TextColor3 = C_ACCENT_LT
								end
							end
							RefreshRow()

							Row.MouseEnter:Connect(function()
								Row.BackgroundTransparency = 0.85
								Row.BackgroundColor3 = C_ACCENT
							end)
							Row.MouseLeave:Connect(function()
								Row.BackgroundTransparency = 1
							end)

							Row.MouseButton1Click:Connect(function()
								if Selected[optName] then
									Selected[optName] = nil
								else
									Selected[optName] = true
								end
								RefreshRow()
								UpdateHeader()
								if callback then callback(GetSelected()) end
							end)
						end
					end

					ClickBtn.MouseButton1Click:Connect(function()
						Open = not Open
						RefreshList()
					end)

					BuildOptions()
					UpdateHeader()

					local mdObj = {}
					function mdObj:Get()
						return GetSelected()
					end
					function mdObj:Set(arr)
						Selected = {}
						for _, v in ipairs(arr) do Selected[v] = true end
						BuildOptions()
						UpdateHeader()
						if callback then callback(GetSelected()) end
					end
					function mdObj:Clear()
						Selected = {}
						BuildOptions()
						UpdateHeader()
						if callback then callback({}) end
					end
					function mdObj:Refresh(newOptions)
						options = newOptions
						Selected = {}
						BuildOptions()
						UpdateHeader()
					end
					return mdObj
				end

				-- --------------------------------------------------------
				--  Tab:AddSection(text)
				--  セクション区切り見出し
				-- --------------------------------------------------------
				function Tab:AddSection(text)

					local Container = Instance.new("Frame")
					Container.Size = UDim2.new(1, 0, 0, 13)
					Container.BackgroundTransparency = 1
					Container.BorderSizePixel = 0
					Container.ClipsDescendants = false
					Container.LayoutOrder = NextOrder()
					Container.Parent = tabEntry.Page

					-- 左ライン
					local LineL = Instance.new("Frame")
					LineL.Size = UDim2.new(0.5, -40, 0, 1)
					LineL.Position = UDim2.new(0, 0, 0.5, 0)
					LineL.AnchorPoint = Vector2.new(0, 0.5)
					LineL.BorderSizePixel = 0
					LineL.BackgroundColor3 = C_ACCENT
					LineL.Parent = Container
					table.insert(ThemeListeners, { type = "headerline", obj = LineL })

					local LineGradL = Instance.new("UIGradient")
					LineGradL.Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 1),
						NumberSequenceKeypoint.new(1, 0),
					})
					LineGradL.Parent = LineL

					-- 右ライン
					local LineR = Instance.new("Frame")
					LineR.Size = UDim2.new(0.5, -40, 0, 1)
					LineR.Position = UDim2.new(0.5, 40, 0.5, 0)
					LineR.AnchorPoint = Vector2.new(0, 0.5)
					LineR.BorderSizePixel = 0
					LineR.BackgroundColor3 = C_ACCENT
					LineR.Parent = Container
					table.insert(ThemeListeners, { type = "headerline", obj = LineR })

					local LineGradR = Instance.new("UIGradient")
					LineGradR.Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0),
						NumberSequenceKeypoint.new(1, 1),
					})
					LineGradR.Parent = LineR

					-- 中央テキスト
					local SectionLbl = Instance.new("TextLabel")
					SectionLbl.Size = UDim2.new(0, 80, 1, 0)
					SectionLbl.AnchorPoint = Vector2.new(0.5, 0.5)
					SectionLbl.Position = UDim2.new(0.5, 0, 0.5, 0)
					SectionLbl.BackgroundTransparency = 1
					SectionLbl.Text = tostring(text or "")
					SectionLbl.Font = Enum.Font.Code
					SectionLbl.TextSize = 9
					SectionLbl.TextColor3 = C_ACCENT_MID
					SectionLbl.Parent = Container
					table.insert(ThemeListeners, { type = "text_mid", obj = SectionLbl })

					local secObj = {}
					function secObj:Set(v) SectionLbl.Text = tostring(v) end
					function secObj:Get() return SectionLbl.Text end
					return secObj
				end

				-- --------------------------------------------------------
				--  Tab:AddProgressBar(Config)
				--  Config: { Name, Min(0), Max(100), Default(0) }
				--  表示専用のプログレスバー
				-- --------------------------------------------------------
				function Tab:AddProgressBar(Config)

					local minVal = Config.Min     or 0
					local maxVal = Config.Max     or 100
					local curVal = Config.Default or minVal

					local Container = Instance.new("Frame")
					Container.Size = UDim2.new(1, 0, 0, 31)
					Container.BackgroundTransparency = 1
					Container.BorderSizePixel = 0
					Container.LayoutOrder = NextOrder()
					Container.Parent = tabEntry.Page

					-- ラベル行
					local NameLbl = Instance.new("TextLabel")
					NameLbl.Size = UDim2.new(1, -7, 0, 11)
					NameLbl.Position = UDim2.fromOffset(7, 0)
					NameLbl.BackgroundTransparency = 1
					NameLbl.Text = Config.Name or "Progress"
					NameLbl.Font = Enum.Font.Code
					NameLbl.TextSize = 9
					NameLbl.TextColor3 = C_ACCENT_LT
					NameLbl.TextXAlignment = Enum.TextXAlignment.Left
					NameLbl.Parent = Container
					table.insert(ThemeListeners, { type = "text_lt", obj = NameLbl })

					-- 数値テキスト（右端）
					local ValLbl = Instance.new("TextLabel")
					ValLbl.Size = UDim2.fromOffset(53, 11)
					ValLbl.AnchorPoint = Vector2.new(1, 0)
					ValLbl.Position = UDim2.new(1, -7, 0, 0)
					ValLbl.BackgroundTransparency = 1
					ValLbl.Font = Enum.Font.Code
					ValLbl.TextSize = 9
					ValLbl.TextColor3 = C_ACCENT_MID
					ValLbl.TextXAlignment = Enum.TextXAlignment.Right
					ValLbl.Parent = Container
					table.insert(ThemeListeners, { type = "text_mid", obj = ValLbl })

					-- トラック（バー背景）
					local Track = Instance.new("Frame")
					Track.Size = UDim2.new(1, -13, 0, 7)
					Track.Position = UDim2.fromOffset(7, 15)
					Track.BackgroundColor3 = C_BG
					Track.BackgroundTransparency = 0.3
					Track.BorderSizePixel = 0
					Track.ClipsDescendants = true
					Track.Parent = Container
					table.insert(ThemeListeners, { type = "track", obj = Track })

					local TrackCorner = Instance.new("UICorner")
					TrackCorner.CornerRadius = UDim.new(1, 0)
					TrackCorner.Parent = Track

					local TrackStroke = Instance.new("UIStroke")
					TrackStroke.Color = C_ACCENT
					TrackStroke.Thickness = 1
					TrackStroke.Transparency = 0.6
					TrackStroke.Parent = Track
					table.insert(ThemeListeners, { type = "stroke", obj = TrackStroke })

					-- フィル（進捗部分）
					local Fill = Instance.new("Frame")
					Fill.Size = UDim2.fromScale(0, 1)
					Fill.BackgroundColor3 = C_ACCENT
					Fill.BorderSizePixel = 0
					Fill.Parent = Track
					table.insert(ThemeListeners, { type = "fill", obj = Fill })

					local FillCorner = Instance.new("UICorner")
					FillCorner.CornerRadius = UDim.new(1, 0)
					FillCorner.Parent = Fill

					-- フィルにグラデーション
					local FillGrad = Instance.new("UIGradient")
					FillGrad.Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0.2),
						NumberSequenceKeypoint.new(1, 0),
					})
					FillGrad.Parent = Fill

					-- 内部更新関数
					local function UpdateBar()
						local pct = math.clamp((curVal - minVal) / math.max(maxVal - minVal, 1e-6), 0, 1)
						TweenService:Create(
							Fill,
							TweenInfo.new(0.15, Enum.EasingStyle.Quad),
							{ Size = UDim2.fromScale(pct, 1) }
						):Play()
						ValLbl.Text = tostring(math.floor(curVal)) .. " / " .. tostring(maxVal)
					end

					UpdateBar()

					local pbObj = {}
					function pbObj:Set(v)
						curVal = math.clamp(tonumber(v) or minVal, minVal, maxVal)
						UpdateBar()
					end
					function pbObj:Get()
						return curVal
					end
					function pbObj:SetMax(v)
						maxVal = tonumber(v) or maxVal
						UpdateBar()
					end
					return pbObj
				end

				-- --------------------------------------------------------
				--  Tab:AddImage(imageName, height)
				--  GetImage APIと連携して画像をタブ内に表示する
				--  imageName: images.lua に登録したキー名、または直接アセットID文字列
				--  height: 表示高さ(px)、デフォルト120
				-- --------------------------------------------------------
				function Tab:AddImage(imageName, height)

					height = height or 80

					local Bg = MakeHertaFrame(tabEntry.Page, UDim2.new(1, 0, 0, height), NextOrder())

					local ImgLabel = Instance.new("ImageLabel")
					ImgLabel.Size = UDim2.new(1, -5, 1, -5)
					ImgLabel.Position = UDim2.fromOffset(3, 3)
					ImgLabel.BackgroundTransparency = 1
					ImgLabel.BorderSizePixel = 0
					ImgLabel.ScaleType = Enum.ScaleType.Fit
					ImgLabel.ZIndex = 3
					ImgLabel.Parent = Bg

					-- アスペクト比を保って表示
					local AspectConstraint = Instance.new("UIAspectRatioConstraint")
					AspectConstraint.AspectType = Enum.AspectType.FitWithinMaxSize
					AspectConstraint.DominantAxis = Enum.DominantAxis.Width
					AspectConstraint.Parent = ImgLabel

					-- 画像を適用（GetImage API または直接ID）
					local function ApplyImage(nameOrId)
						local assetId = HertaIX:GetImage(nameOrId)
						if assetId then
							ImgLabel.Image = assetId
						else
							-- 直接ID文字列として試みる
							ImgLabel.Image = tostring(nameOrId)
						end
					end

					ApplyImage(imageName)

					local imgObj = {}
					function imgObj:SetImage(nameOrId)
						ApplyImage(nameOrId)
					end
					function imgObj:SetHeight(h)
						height = h
						Bg.Size = UDim2.new(1, 0, 0, h)
					end
					function imgObj:GetImageLabel()
						return ImgLabel
					end
					return imgObj
				end

					-- --------------------------------------------------------
					--  Tab:AddViewport(Config)
					-- --------------------------------------------------------
					function Tab:AddViewport(Config)
						Config = Config or {}
						local height  = Config.Height or 80
						local doRotate = Config.Rotate ~= false

						-- 外枠（L字コーナー付き）
						local Bg = MakeHertaFrame(
							tabEntry.Page,
							UDim2.new(1, 0, 0, height),
							NextOrder()
						)

						-- 左側: ViewportFrame（幅40%）
						local VP = Instance.new("ViewportFrame")
						VP.Size = UDim2.new(0.4, -4, 1, -4)
						VP.Position = UDim2.fromOffset(2, 2)
						VP.BackgroundColor3 = C_BG
						VP.BackgroundTransparency = 0.3
						VP.BorderSizePixel = 0
						VP.ZIndex = 3
						VP.Parent = Bg
						table.insert(ThemeListeners, { type = "bg", obj = VP })

						-- ViewportFrame専用カメラ
						local VPCam = Instance.new("Camera")
						VPCam.Name = "Camera"
						VP.CurrentCamera = VPCam
						VPCam.Parent = VP

						-- WorldModel（アニメーション・物理が正しく動作する）
						local WorldModel = Instance.new("WorldModel")
						WorldModel.Name = "WorldModel"
						WorldModel.Parent = VP

						-- ライティング設定
						VP.Ambient       = Color3.fromRGB(200, 200, 200)
						VP.LightColor    = Color3.fromRGB(255, 255, 255)
						VP.LightDirection = Vector3.new(-1, -1, -1)

						-- 右側: 情報パネル（幅60%）
						local InfoPanel = Instance.new("Frame")
						InfoPanel.Size = UDim2.new(0.6, -6, 1, -4)
						InfoPanel.Position = UDim2.new(0.4, 4, 0, 2)
						InfoPanel.BackgroundTransparency = 1
						InfoPanel.BorderSizePixel = 0
						InfoPanel.ZIndex = 3
						InfoPanel.Parent = Bg

						local function MakeInfoLabel(yOffset, labelText)
							local lbl = Instance.new("TextLabel")
							lbl.Size = UDim2.new(1, 0, 0, 13)
							lbl.Position = UDim2.fromOffset(2, yOffset)
							lbl.BackgroundTransparency = 1
							lbl.BorderSizePixel = 0
							lbl.Font = Enum.Font.Code
							lbl.TextSize = 10
							lbl.TextXAlignment = Enum.TextXAlignment.Left
							lbl.TextColor3 = C_ACCENT_LT
							lbl.Text = labelText
							lbl.ZIndex = 4
							lbl.Parent = InfoPanel
							table.insert(ThemeListeners, { type = "text_lt", obj = lbl })
							return lbl
						end

						local NameLabel = MakeInfoLabel(4,  "Name: --")
						local IdLabel   = MakeInfoLabel(19, "ID:   --")
						local PosLabel  = MakeInfoLabel(34, "Pos:  --")

						-- HPゲージ背景
						local HPTrack = Instance.new("Frame")
						HPTrack.Size = UDim2.new(1, -4, 0, 7)
						HPTrack.Position = UDim2.fromOffset(2, 52)
						HPTrack.BackgroundColor3 = C_BG
						HPTrack.BackgroundTransparency = 0.3
						HPTrack.BorderSizePixel = 0
						HPTrack.ZIndex = 4
						HPTrack.Parent = InfoPanel
						table.insert(ThemeListeners, { type = "track", obj = HPTrack })

						-- HPゲージ塗り
						local HPFill = Instance.new("Frame")
						HPFill.Size = UDim2.new(0, 0, 1, 0)
						HPFill.BackgroundColor3 = C_ACCENT
						HPFill.BackgroundTransparency = 0
						HPFill.BorderSizePixel = 0
						HPFill.ZIndex = 5
						HPFill.Parent = HPTrack
						table.insert(ThemeListeners, { type = "fill", obj = HPFill })

						-- HPテキスト
						local HPLabel = MakeInfoLabel(62, "HP: NaN / NaN")

						-- 内部状態
						local _renderConn  = nil
						local _hpConn      = nil
						local _posConn     = nil
						local _currentClone = nil

						-- カメラ固定CFrame（正面やや上から見下ろす）
						local CLONE_ORIGIN = CFrame.new(0, 0, 0)
						local CAMERA_CF = CFrame.lookAt(
							Vector3.new(0, 1.5, -8),
							Vector3.new(0, 1.5, 0)
						)

						-- Neck Motor6Dを探す
						local function FindNeckMotor(char)
							for _, v in ipairs(char:GetDescendants()) do
								if v:IsA("Motor6D") and v.Name == "Neck" then
									return v
								end
							end
							return nil
						end

						-- HP更新
						local function UpdateHP(hum)
							if _hpConn then _hpConn:Disconnect() end
							if not hum then
								HPLabel.Text = "HP: NaN / NaN"
								HPFill.Size = UDim2.new(0, 0, 1, 0)
								return
							end
							local function RefreshHP()
								local ok, hp, maxHp = pcall(function()
									return hum.Health, hum.MaxHealth
								end)
								if ok then
									local ratio = (maxHp > 0) and (hp / maxHp) or 0
									HPLabel.Text = string.format("HP: %.0f / %.0f", hp, maxHp)
									HPFill.Size = UDim2.new(math.clamp(ratio, 0, 1), 0, 1, 0)
								else
									HPLabel.Text = "HP: NaN / NaN"
									HPFill.Size = UDim2.new(0, 0, 1, 0)
								end
							end
							RefreshHP()
							_hpConn = hum.HealthChanged:Connect(RefreshHP)
						end

						-- 位置更新
						local function UpdatePos(rootPart)
							if _posConn then _posConn:Disconnect() end
							if not rootPart then
								PosLabel.Text = "Pos: --"
								return
							end
							local function RefreshPos()
								local ok, p = pcall(function() return rootPart.Position end)
								if ok then
									PosLabel.Text = string.format(
										"Pos: %.1f, %.1f, %.1f", p.X, p.Y, p.Z
									)
								else
									PosLabel.Text = "Pos: --"
								end
							end
							RefreshPos()
							_posConn = game:GetService("RunService").Heartbeat:Connect(function()
								if not rootPart or not rootPart.Parent then
									_posConn:Disconnect()
									return
								end
								RefreshPos()
							end)
						end

						-- クローンのクリーンアップ
						local function CleanupClone()
							if _renderConn then _renderConn:Disconnect(); _renderConn = nil end
							if _currentClone then _currentClone:Destroy(); _currentClone = nil end
						end

						-- キャラクターをViewportに配置してアニメーション同期を開始
						local function PlaceModel(targetCharacter)
							CleanupClone()
							if not targetCharacter then return end

							-- Archivable設定してクローン作成
							targetCharacter.Archivable = true
							local clone = targetCharacter:Clone()

							-- スクリプト類を削除
							for _, v in ipairs(clone:GetDescendants()) do
								if v:IsA("Script") or v:IsA("LocalScript") or v:IsA("ModuleScript") then
									v:Destroy()
								end
							end

							clone.Parent = WorldModel
							_currentClone = clone

							-- カメラ固定
							VPCam.CFrame = CAMERA_CF

							local targetHumanoid = targetCharacter:WaitForChild("Humanoid", 5)
							local cloneHumanoid  = clone:WaitForChild("Humanoid", 5)
							local targetRoot     = targetCharacter:WaitForChild("HumanoidRootPart", 5)
							local cloneRoot      = clone:WaitForChild("HumanoidRootPart", 5)

							if not (targetHumanoid and cloneHumanoid and targetRoot and cloneRoot) then return end

							-- Neck Motor6D取得
							local targetNeck = FindNeckMotor(targetCharacter)
							local cloneNeck  = FindNeckMotor(clone)

							-- Animator取得（なければ作成）
							local targetAnimator = targetHumanoid:FindFirstChildOfClass("Animator")
								or Instance.new("Animator", targetHumanoid)
							local cloneAnimator = cloneHumanoid:FindFirstChildOfClass("Animator")
								or Instance.new("Animator", cloneHumanoid)

							-- アニメーション同期用テーブル
							local activeTracks = {}

							_renderConn = game:GetService("RunService").RenderStepped:Connect(function()
								if not targetCharacter.Parent or not targetRoot.Parent or not cloneRoot.Parent then
									return
								end

								-- ① HumanoidRootPart: XZ固定・ヨー角のみ同期
								local targetRootCF = targetRoot.CFrame
								local _, targetYaw, _ = targetRootCF:ToEulerAnglesYXZ()
								cloneRoot.CFrame = CLONE_ORIGIN * CFrame.Angles(0, targetYaw, 0)

								-- ② Neck Transform同期
								if targetNeck and cloneNeck then
									cloneNeck.Transform = targetNeck.Transform
								end

								-- ③ アニメーション同期
								local playingTracks = targetAnimator:GetPlayingAnimationTracks()

								for _, track in ipairs(playingTracks) do
									local animId = track.Animation.AnimationId
									if not activeTracks[animId] then
										local cloneTrack = cloneAnimator:LoadAnimation(track.Animation)
										cloneTrack:Play()
										activeTracks[animId] = cloneTrack
									end
									local cTrack = activeTracks[animId]
									if cTrack then
										cTrack.TimePosition = track.TimePosition
										cTrack:AdjustWeight(track.WeightCurrent)
										cTrack:AdjustSpeed(track.Speed)
									end
								end

								-- 停止したトラックの処理
								for animId, cTrack in pairs(activeTracks) do
									local isPlaying = false
									for _, track in ipairs(playingTracks) do
										if track.Animation.AnimationId == animId then
											isPlaying = true
											break
										end
									end
									if not isPlaying then
										cTrack:Stop()
										activeTracks[animId] = nil
									end
								end
							end)
						end

						-- ViewportObject API
						local vpObj = {}

						function vpObj:SetTarget(target)
							-- target: Player または Model
							local model, name, userId, hum, rootPart

							local ok, isPlayer = pcall(function()
								return target:IsA("Player")
							end)

							if ok and isPlayer then
								name   = target.Name
								userId = tostring(target.UserId)
								model  = target.Character
							else
								name   = target.Name
								userId = "--"
								model  = target
							end

							NameLabel.Text = "Name: " .. (name or "--")
							IdLabel.Text   = "ID:   " .. (userId or "--")

							if model then
								PlaceModel(model)
								hum      = model:FindFirstChildOfClass("Humanoid")
								rootPart = model:FindFirstChild("HumanoidRootPart")
										 or model:FindFirstChildWhichIsA("BasePart")
							end

							UpdateHP(hum)
							UpdatePos(rootPart)
						end

						function vpObj:SetCamera(cframe)
							VPCam.CFrame = cframe
						end

						function vpObj:GetViewport()
							return VP
						end

						function vpObj:Clear()
							CleanupClone()
							if _hpConn  then _hpConn:Disconnect();  _hpConn  = nil end
							if _posConn then _posConn:Disconnect(); _posConn = nil end
							NameLabel.Text = "Name: --"
							IdLabel.Text   = "ID:   --"
							PosLabel.Text  = "Pos:  --"
							HPLabel.Text   = "HP: NaN / NaN"
							HPFill.Size    = UDim2.new(0, 0, 1, 0)
						end

						-- 初期ターゲットがあれば適用
						if Config.Target then
							vpObj:SetTarget(Config.Target)
						end

						return vpObj
					end

					-- --------------------------------------------------------
					--  Tab:AddMultiViewport(Config)
					--  Config: { Height, WindowRef }
					--  マルチドロップダウンでプレイヤーを複数選択し、
					--  選択されたプレイヤーごとにViewportを動的生成・削除する
					-- --------------------------------------------------------
					function Tab:AddMultiViewport(Config)
						Config = Config or {}
						local vpHeight  = Config.Height    or 80
						local WindowRef = Config.WindowRef  -- Notify用（省略可）

						local PlayersService = game:GetService("Players")

						-- 現在表示中のViewportを管理するテーブル
						-- { [playerName] = { vpObj, bgFrame, renderConn, hpConn, posConn, clone } }
						local _activeViewports = {}

						-- ---- 内部: 単一プレイヤー用Viewport生成 ----
						local function CreatePlayerViewport(player)
							if _activeViewports[player.Name] then return end  -- 重複防止

							-- 外枠
							local Bg = MakeHertaFrame(
								tabEntry.Page,
								UDim2.new(1, 0, 0, vpHeight),
								NextOrder()
							)

							-- ViewportFrame（左40%）
							local VP = Instance.new("ViewportFrame")
							VP.Size = UDim2.new(0.4, -4, 1, -4)
							VP.Position = UDim2.fromOffset(2, 2)
							VP.BackgroundColor3 = C_BG
							VP.BackgroundTransparency = 0.3
							VP.BorderSizePixel = 0
							VP.ZIndex = 3
							VP.Ambient       = Color3.fromRGB(200, 200, 200)
							VP.LightColor    = Color3.fromRGB(255, 255, 255)
							VP.LightDirection = Vector3.new(-1, -1, -1)
							VP.Parent = Bg
							table.insert(ThemeListeners, { type = "bg", obj = VP })

							local VPCam = Instance.new("Camera")
							VPCam.Name = "Camera"
							VP.CurrentCamera = VPCam
							VPCam.Parent = VP

							local WorldModel = Instance.new("WorldModel")
							WorldModel.Name = "WorldModel"
							WorldModel.Parent = VP

							-- 情報パネル（右60%）
							local InfoPanel = Instance.new("Frame")
							InfoPanel.Size = UDim2.new(0.6, -6, 1, -4)
							InfoPanel.Position = UDim2.new(0.4, 4, 0, 2)
							InfoPanel.BackgroundTransparency = 1
							InfoPanel.BorderSizePixel = 0
							InfoPanel.ZIndex = 3
							InfoPanel.Parent = Bg

							local function MakeInfoLbl(yOff, txt)
								local lbl = Instance.new("TextLabel")
								lbl.Size = UDim2.new(1, 0, 0, 13)
								lbl.Position = UDim2.fromOffset(2, yOff)
								lbl.BackgroundTransparency = 1
								lbl.BorderSizePixel = 0
								lbl.Font = Enum.Font.Code
								lbl.TextSize = 10
								lbl.TextXAlignment = Enum.TextXAlignment.Left
								lbl.TextColor3 = C_ACCENT_LT
								lbl.Text = txt
								lbl.ZIndex = 4
								lbl.Parent = InfoPanel
								table.insert(ThemeListeners, { type = "text_lt", obj = lbl })
								return lbl
							end

							local NameLabel = MakeInfoLbl(4,  "Name: " .. player.Name)
							local IdLabel   = MakeInfoLbl(19, "ID:   " .. tostring(player.UserId))
							local PosLabel  = MakeInfoLbl(34, "Pos:  --")

							local HPTrack = Instance.new("Frame")
							HPTrack.Size = UDim2.new(1, -4, 0, 7)
							HPTrack.Position = UDim2.fromOffset(2, 52)
							HPTrack.BackgroundColor3 = C_BG
							HPTrack.BackgroundTransparency = 0.3
							HPTrack.BorderSizePixel = 0
							HPTrack.ZIndex = 4
							HPTrack.Parent = InfoPanel
							table.insert(ThemeListeners, { type = "track", obj = HPTrack })

							local HPFill = Instance.new("Frame")
							HPFill.Size = UDim2.new(0, 0, 1, 0)
							HPFill.BackgroundColor3 = C_ACCENT
							HPFill.BackgroundTransparency = 0
							HPFill.BorderSizePixel = 0
							HPFill.ZIndex = 5
							HPFill.Parent = HPTrack
							table.insert(ThemeListeners, { type = "fill", obj = HPFill })

							local HPLabel = MakeInfoLbl(62, "HP: NaN / NaN")

							-- 接続管理
							local _renderConn = nil
							local _hpConn     = nil
							local _posConn    = nil
							local _currentClone = nil

							local CLONE_ORIGIN = CFrame.new(0, 0, 0)
							local CAMERA_CF = CFrame.lookAt(
								Vector3.new(0, 1.5, -8),
								Vector3.new(0, 1.5, 0)
							)

							local function FindNeckMotor(char)
								for _, v in ipairs(char:GetDescendants()) do
									if v:IsA("Motor6D") and v.Name == "Neck" then return v end
								end
								return nil
							end

							local function UpdateHP(hum)
								if _hpConn then _hpConn:Disconnect() end
								if not hum then
									HPLabel.Text = "HP: NaN / NaN"
									HPFill.Size = UDim2.new(0, 0, 1, 0)
									return
								end
								local function RefreshHP()
									local ok, hp, maxHp = pcall(function() return hum.Health, hum.MaxHealth end)
									if ok then
										local ratio = (maxHp > 0) and (hp / maxHp) or 0
										HPLabel.Text = string.format("HP: %.0f / %.0f", hp, maxHp)
										HPFill.Size = UDim2.new(math.clamp(ratio, 0, 1), 0, 1, 0)
									else
										HPLabel.Text = "HP: NaN / NaN"
										HPFill.Size = UDim2.new(0, 0, 1, 0)
									end
								end
								RefreshHP()
								_hpConn = hum.HealthChanged:Connect(RefreshHP)
							end

							local function UpdatePos(rootPart)
								if _posConn then _posConn:Disconnect() end
								if not rootPart then PosLabel.Text = "Pos: --"; return end
								local function RefreshPos()
									local ok, p = pcall(function() return rootPart.Position end)
									if ok then
										PosLabel.Text = string.format("Pos: %.1f, %.1f, %.1f", p.X, p.Y, p.Z)
									else
										PosLabel.Text = "Pos: --"
									end
								end
								RefreshPos()
								_posConn = game:GetService("RunService").Heartbeat:Connect(function()
									if not rootPart or not rootPart.Parent then
										_posConn:Disconnect(); return
									end
									RefreshPos()
								end)
							end

							local function CleanupClone()
								if _renderConn then _renderConn:Disconnect(); _renderConn = nil end
								if _currentClone then _currentClone:Destroy(); _currentClone = nil end
							end

							local function PlaceModel(targetCharacter)
								CleanupClone()
								if not targetCharacter then return end
								targetCharacter.Archivable = true
								local clone = targetCharacter:Clone()
								for _, v in ipairs(clone:GetDescendants()) do
									if v:IsA("Script") or v:IsA("LocalScript") or v:IsA("ModuleScript") then
										v:Destroy()
									end
								end
								clone.Parent = WorldModel
								_currentClone = clone
								VPCam.CFrame = CAMERA_CF

								local targetHumanoid = targetCharacter:WaitForChild("Humanoid", 5)
								local cloneHumanoid  = clone:WaitForChild("Humanoid", 5)
								local targetRoot     = targetCharacter:WaitForChild("HumanoidRootPart", 5)
								local cloneRoot      = clone:WaitForChild("HumanoidRootPart", 5)
								if not (targetHumanoid and cloneHumanoid and targetRoot and cloneRoot) then return end

								local targetNeck = FindNeckMotor(targetCharacter)
								local cloneNeck  = FindNeckMotor(clone)

								local targetAnimator = targetHumanoid:FindFirstChildOfClass("Animator")
									or Instance.new("Animator", targetHumanoid)
								local cloneAnimator = cloneHumanoid:FindFirstChildOfClass("Animator")
									or Instance.new("Animator", cloneHumanoid)

								local activeTracks = {}

								_renderConn = game:GetService("RunService").RenderStepped:Connect(function()
									if not targetCharacter.Parent or not targetRoot.Parent or not cloneRoot.Parent then return end
									local _, targetYaw, _ = targetRoot.CFrame:ToEulerAnglesYXZ()
									cloneRoot.CFrame = CLONE_ORIGIN * CFrame.Angles(0, targetYaw, 0)
									if targetNeck and cloneNeck then
										cloneNeck.Transform = targetNeck.Transform
									end
									local playingTracks = targetAnimator:GetPlayingAnimationTracks()
									for _, track in ipairs(playingTracks) do
										local animId = track.Animation.AnimationId
										if not activeTracks[animId] then
											local ct = cloneAnimator:LoadAnimation(track.Animation)
											ct:Play()
											activeTracks[animId] = ct
										end
										local ct = activeTracks[animId]
										if ct then
											ct.TimePosition = track.TimePosition
											ct:AdjustWeight(track.WeightCurrent)
											ct:AdjustSpeed(track.Speed)
										end
									end
									for animId, ct in pairs(activeTracks) do
										local isPlaying = false
										for _, track in ipairs(playingTracks) do
											if track.Animation.AnimationId == animId then isPlaying = true; break end
										end
										if not isPlaying then ct:Stop(); activeTracks[animId] = nil end
									end
								end)
							end

							-- キャラクターが存在すれば即時表示、なければ CharacterAdded を待つ
							local char = player.Character
							if char then
								PlaceModel(char)
								local hum      = char:FindFirstChildOfClass("Humanoid")
								local rootPart = char:FindFirstChild("HumanoidRootPart")
												 or char:FindFirstChildWhichIsA("BasePart")
								UpdateHP(hum)
								UpdatePos(rootPart)
							else
								player.CharacterAdded:Once(function(newChar)
									PlaceModel(newChar)
									local hum      = newChar:FindFirstChildOfClass("Humanoid")
									local rootPart = newChar:FindFirstChild("HumanoidRootPart")
													 or newChar:FindFirstChildWhichIsA("BasePart")
									UpdateHP(hum)
									UpdatePos(rootPart)
								end)
							end

							-- 管理テーブルに登録
							_activeViewports[player.Name] = {
								bg          = Bg,
								cleanup     = function()
									CleanupClone()
									if _hpConn  then _hpConn:Disconnect();  _hpConn  = nil end
									if _posConn then _posConn:Disconnect(); _posConn = nil end
									Bg:Destroy()
								end,
							}
						end

						-- ---- 内部: Viewport削除 ----
						local function RemovePlayerViewport(playerName, reason)
							local entry = _activeViewports[playerName]
							if not entry then return end
							entry.cleanup()
							_activeViewports[playerName] = nil
							if WindowRef then
								WindowRef:Notify(
									"Viewport 削除",
									playerName .. " - " .. (reason or "選択解除"),
									3
								)
							end
						end

						-- ---- プレイヤー名リスト取得 ----
						local function GetPlayerNames()
							local names = {}
							for _, p in ipairs(PlayersService:GetPlayers()) do
								table.insert(names, p.Name)
							end
							return names
						end

						-- ---- MultiDropdown ----
						local dd = Tab:AddMultiDropdown("プレイヤー選択", GetPlayerNames(), function(selected)
							-- 選択リストに追加されたプレイヤーのViewportを生成
							local selectedSet = {}
							for _, name in ipairs(selected) do
								selectedSet[name] = true
								if not _activeViewports[name] then
									local p = PlayersService:FindFirstChild(name)
									if p then CreatePlayerViewport(p) end
								end
							end
							-- 選択解除されたプレイヤーのViewportを削除
							for name in pairs(_activeViewports) do
								if not selectedSet[name] then
									RemovePlayerViewport(name, "選択解除")
								end
							end
						end)

						-- ---- プレイヤー入退室の自動更新 ----
						PlayersService.PlayerAdded:Connect(function(p)
							dd:Refresh(GetPlayerNames())
						end)

						PlayersService.PlayerRemoving:Connect(function(p)
							-- 退出プレイヤーのViewportを削除（通知付き）
							if _activeViewports[p.Name] then
								RemovePlayerViewport(p.Name, "退出")
							end
							-- ドロップダウンのリストを更新（退出プレイヤーを除外）
							local newNames = GetPlayerNames()
							dd:Refresh(newNames)
						end)

						-- 返却オブジェクト
						local mvObj = {}

						function mvObj:GetActiveViewports()
							local result = {}
							for name, entry in pairs(_activeViewports) do
								result[name] = entry
							end
							return result
						end

						function mvObj:RemoveViewport(playerName)
							RemovePlayerViewport(playerName, "手動削除")
							-- ドロップダウンの選択状態も解除
							local cur = dd:Get()
							local newSel = {}
							for _, n in ipairs(cur) do
								if n ~= playerName then table.insert(newSel, n) end
							end
							dd:Set(newSel)
						end

						function mvObj:ClearAll()
							for name in pairs(_activeViewports) do
								RemovePlayerViewport(name, "全削除")
							end
							dd:Clear()
						end

						return mvObj
					end

					-- --------------------------------------------------------
					--  Tab:AddParagraph(titleText, descText)
				-- --------------------------------------------------------
				function Tab:AddParagraph(pTitle, descText)

			local Bg = Instance.new("Frame")
			Bg.Size = UDim2.new(1, 0, 0, 40)
			Bg.BackgroundColor3 = C_BG
			Bg.BackgroundTransparency = 0.55
			Bg.BorderSizePixel = 0
			Bg.LayoutOrder = NextOrder()
			Bg.Parent = tabEntry.Page
			table.insert(ThemeListeners, { type = "bg", obj = Bg })

			local BgCorner = Instance.new("UICorner")
			BgCorner.CornerRadius = UDim.new(0, 4)
			BgCorner.Parent = Bg

			local TopLine = Instance.new("Frame")
			TopLine.Size = UDim2.new(1, 0, 0, 1)
			TopLine.BorderSizePixel = 0
			TopLine.BackgroundColor3 = C_ACCENT
			TopLine.Parent = Bg
			table.insert(ThemeListeners, { type = "headerline", obj = TopLine })

			local BottomLine = Instance.new("Frame")
			BottomLine.BorderSizePixel = 0
			BottomLine.BackgroundColor3 = C_ACCENT
			BottomLine.Parent = Bg
			table.insert(ThemeListeners, { type = "headerline", obj = BottomLine })

			local TitleLbl = Instance.new("TextLabel")
			TitleLbl.Size = UDim2.new(1, -7, 0, 15)
			TitleLbl.Position = UDim2.fromOffset(5, 1)
			TitleLbl.BackgroundTransparency = 1
			TitleLbl.Text = pTitle or ""
			TitleLbl.Font = Enum.Font.Code
			TitleLbl.TextSize = 10
			TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
			TitleLbl.TextColor3 = C_ACCENT_LT
			TitleLbl.Parent = Bg
			table.insert(ThemeListeners, { type = "text_lt", obj = TitleLbl })

			local Desc = Instance.new("TextLabel")
			Desc.Size = UDim2.new(1, -11, 0, 0)
			Desc.Position = UDim2.fromOffset(5, 17)
			Desc.BackgroundTransparency = 1
			Desc.AutomaticSize = Enum.AutomaticSize.Y
			Desc.TextWrapped = true
			Desc.TextYAlignment = Enum.TextYAlignment.Top
			Desc.TextXAlignment = Enum.TextXAlignment.Left
			Desc.Font = Enum.Font.Code
			Desc.TextSize = 9
			Desc.TextColor3 = C_ACCENT_MID
			Desc.Text = descText or ""
			Desc.Parent = Bg
			table.insert(ThemeListeners, { type = "text_mid", obj = Desc })

			local function UpdateSize()
				local H = 30 + Desc.TextBounds.Y + 10
				Bg.Size = UDim2.new(1, 0, 0, H)
				BottomLine.Position = UDim2.new(0, 0, 1, -1)
				BottomLine.Size = UDim2.new(1, 0, 0, 1)
			end

			Desc:GetPropertyChangedSignal("TextBounds"):Connect(UpdateSize)
			UpdateSize()

			local obj = {}
			function obj:SetTitle(v) TitleLbl.Text = tostring(v) end
			function obj:SetDesc(v)
				Desc.Text = tostring(v)
				UpdateSize()
			end
			return obj
		end

		return Tab
	end

	-- ----------------------------------------------------------
	--  通知スタック管理
	-- ----------------------------------------------------------
	local _NotifyStack  = {}   -- 現在表示中の通知リスト
	local NOTIFY_W      = 173
	local NOTIFY_H      = 48
	local NOTIFY_GAP    = 5    -- 通知間の隙間
	local NOTIFY_RIGHT  = 7   -- 画面右端からのマージン
	local NOTIFY_BOTTOM = 7   -- 画面下端からのマージン

	-- 全通知の位置を下から上に並べ直す
	local function _RealignNotifications()
		local count = #_NotifyStack
		for i, entry in ipairs(_NotifyStack) do
			-- 下からi番目（i=1が最下、countが最上）
			local slot = count - i  -- 0が最下段
			local targetY = -(NOTIFY_H + NOTIFY_GAP) * slot - NOTIFY_H - NOTIFY_BOTTOM
			TweenService:Create(
				entry.frame,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Position = UDim2.new(1, -(NOTIFY_W + NOTIFY_RIGHT), 1, targetY) }
			):Play()
		end
	end

	-- ----------------------------------------------------------
	--  Window:Notify(title, message, duration)
	-- ----------------------------------------------------------
	function Window:Notify(title, message, duration)

		duration = duration or 3

		local Notification = Instance.new("Frame")
		Notification.Size = UDim2.fromOffset(NOTIFY_W, NOTIFY_H)
		-- 画面外からスライドインする初期位置
		Notification.Position = UDim2.new(1, NOTIFY_RIGHT, 1, -NOTIFY_BOTTOM)
		Notification.BackgroundColor3 = C_BG
		Notification.BackgroundTransparency = 0.35
		Notification.BorderSizePixel = 0
		Notification.Parent = self._ScreenGui
		table.insert(ThemeListeners, { type = "bg", obj = Notification })

		local NCorner = Instance.new("UICorner")
		NCorner.CornerRadius = UDim.new(0, 6)
		NCorner.Parent = Notification

		local NStroke = Instance.new("UIStroke")
		NStroke.Color = C_ACCENT
		NStroke.Thickness = 1
		NStroke.Parent = Notification
		table.insert(ThemeListeners, { type = "stroke", obj = NStroke })

		local AccentLine = Instance.new("Frame")
		AccentLine.Size = UDim2.new(1, 0, 0, 1)
		AccentLine.BorderSizePixel = 0
		AccentLine.BackgroundColor3 = C_ACCENT
		AccentLine.Parent = Notification
		table.insert(ThemeListeners, { type = "headerline", obj = AccentLine })

		local TitleLbl = Instance.new("TextLabel")
		TitleLbl.Size = UDim2.new(1, -7, 0, 17)
		TitleLbl.Position = UDim2.fromOffset(5, 3)
		TitleLbl.BackgroundTransparency = 1
		TitleLbl.Text = title
		TitleLbl.Font = Enum.Font.Code
		TitleLbl.TextSize = 11
		TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
		TitleLbl.TextColor3 = C_ACCENT_LT
		TitleLbl.Parent = Notification
		table.insert(ThemeListeners, { type = "text_lt", obj = TitleLbl })

		local MsgLbl = Instance.new("TextLabel")
		MsgLbl.Size = UDim2.new(1, -7, 0, 24)
		MsgLbl.Position = UDim2.fromOffset(5, 21)
		MsgLbl.BackgroundTransparency = 1
		MsgLbl.Text = message
		MsgLbl.Font = Enum.Font.Code
		MsgLbl.TextSize = 9
		MsgLbl.TextXAlignment = Enum.TextXAlignment.Left
		MsgLbl.TextWrapped = true
		MsgLbl.TextColor3 = C_ACCENT_MID
		MsgLbl.Parent = Notification
		table.insert(ThemeListeners, { type = "text_mid", obj = MsgLbl })

		-- スタックに登録して位置を整列
		local entry = { frame = Notification }
		table.insert(_NotifyStack, entry)
		_RealignNotifications()

		-- 期限後にスライドアウトして除去
		task.delay(duration, function()
			-- 画面外へスライドアウト
			local curPos = Notification.Position
			local T = TweenService:Create(
				Notification,
				TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Position = UDim2.new(1, NOTIFY_RIGHT, curPos.Y.Scale, curPos.Y.Offset) }
			)
			T:Play()
			T.Completed:Wait()
			-- スタックから除去
			for i, e in ipairs(_NotifyStack) do
				if e == entry then
					table.remove(_NotifyStack, i)
					break
				end
			end
			if Notification then Notification:Destroy() end
			-- 残りの通知を下方に詳める
			_RealignNotifications()
		end)
	end

	-- 初期ロード時の開くアニメーション
	task.spawn(function()
		task.wait()  -- 1フレーム待機してGUIが確実に生成されてから実行
		CRTOpen()
	end)

	return Window
end

-- ============================================================
--  エントリーポイント
-- ============================================================
return HertaIX
