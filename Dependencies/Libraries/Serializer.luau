--[[
	The reason I don't use string interpolation is because it is very slow.
	I'm already making this rather slow due to me using indexing vs 100 different elseif statements for the serialize function

	Scripted by: https://github.com/78n
	License: https://creativecommons.org/licenses/by-nc/4.0/
]]

local env = {
	bit32 = bit32,
	buffer = buffer,
	coroutine = coroutine,
	debug = debug,
	math = math,
	os = os,
	string = string,
	table = table,
	utf8 = utf8,
	Content = Content,
	Axes = Axes,
	BrickColor = BrickColor,
	CatalogSearchParams = CatalogSearchParams,
	CFrame = CFrame,
	Color3 = Color3,
	ColorSequence = ColorSequence,
	ColorSequenceKeypoint = ColorSequenceKeypoint,
	DateTime = DateTime,
	DockWidgetPluginGuiInfo = DockWidgetPluginGuiInfo,
	Faces = Faces,
	FloatCurveKey = FloatCurveKey,
	Font = Font,
	Instance = Instance,
	NumberRange = NumberRange,
	NumberSequence = NumberSequence,
	NumberSequenceKeypoint = NumberSequenceKeypoint,
	OverlapParams = OverlapParams,
	PathWaypoint = PathWaypoint,
	PhysicalProperties = PhysicalProperties,
	Random = Random,
	Ray = Ray,
	RaycastParams = RaycastParams,
	Rect = Rect,
	Region3 = Region3,
	Region3int16 = Region3int16,
	RotationCurveKey = RotationCurveKey,
	SharedTable = SharedTable,
	task = task,
	TweenInfo = TweenInfo,
	UDim = UDim,
	UDim2 = UDim2,
	Vector2 = Vector2,
	Vector2int16 = Vector2int16,
	Vector3 = Vector3,
	vector = vector,
	Vector3int16 = Vector3int16
}

local Signals = {
	GraphicsQualityChangeRequest = "game.GraphicsQualityChangeRequest",
	AllowedGearTypeChanged = "game.AllowedGearTypeChanged",
	ScreenshotSavedToAlbum = "game.ScreenshotSavedToAlbum",
	UniverseMetadataLoaded = "game.UniverseMetadataLoaded",
	ScreenshotReady = "game.ScreenshotReady",
	ServiceRemoving = "game.ServiceRemoving",
	ServiceAdded = "game.ServiceAdded",
	ItemChanged = "game.ItemChanged",
	CloseLate = "game.CloseLate",
	Loaded = "game.Loaded",
	Close = "game.Close",

	RobloxGuiFocusedChanged = "game:GetService(\"RunService\").RobloxGuiFocusedChanged",
	PostSimulation = "game:GetService(\"RunService\").PostSimulation",
	RenderStepped = "game:GetService(\"RunService\").RenderStepped",
	PreSimulation = "game:GetService(\"RunService\").PreSimulation",
	PreAnimation = "game:GetService(\"RunService\").PreAnimation",
	PreRender = "game:GetService(\"RunService\").PreRender",
	Heartbeat = "game:GetService(\"RunService\").Heartbeat",
	Stepped = "game:GetService(\"RunService\").Stepped"
}

local ServiceGeneration = {
	Workspace = "workspace",
	Lighting = "game.lighting",
	GlobalSettings = "settings()",
	Stats = "stats()",
	UserSettings = "UserSettings()",
	PluginManagerInterface = "PluginManager()",
	DebuggerManager = "DebuggerManager()"
}

local IsSharedFrozen = SharedTable.isFrozen
local SharedSize = SharedTable.size

local bufftostring = buffer.tostring
local fromstring = buffer.fromstring
local readu8 = buffer.readu8

local isfrozen = table.isfrozen
local concat = table.concat

local FindService = game.FindService
local info = debug.info

local inf = math.huge
local neginf = -inf

local IsStudio = game:GetService("RunService"):IsStudio()

local DefaultMethods = {}
local Methods = setmetatable({}, {__index = DefaultMethods})

local Advanced = {}
local SerializeClass = setmetatable({}, {
	__index = {
		Advanced = setmetatable({}, {
			__index = Advanced
		})
	}
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer do
	if not LocalPlayer then
		Players:GetPropertyChangedSignal("LocalPlayer"):Once(function() -- Technically a "memory leak" but at this point if you really manage to join before your localplayer even exists you deserve it
			Players = Players.LocalPlayer
		end)
	end
end

local SpecialCases = {
	[7] = "\\a",
	[8] = "\\b",
	[9] = "\\t",
	[10] = "\\n",
	[11] = "\\v",
	[12] = "\\f",
	[13] = "\\r"
}

local Keywords = {
	["local"] = "\"local\"",
	["function"] = "\"function\"",
	["type"] = "\"type\"",
	["typeof"] = "\"typeof\"",
	["and"] = "\"and\"",
	["break"] = "\"break\"",
	["not"] = "\"not\"",
	["or"] = "\"or\"",
	["else"] = "\"else\"",
	["elseif"] = "\"elseif\"",
	["if"] = "\"if\"",
	["then"] = "\"then\"",
	["until"] = "\"until\"",
	["repeat"] = "\"repeat\"",
	["while"] = "\"while\"",
	["do"] = "\"do\"",
	["for"] = "\"for\"",
	["in"] = "\"in\"",
	["end"] = "\"end\"",
	["return"] = "\"return\"",
	["export"] = "\"export\"",
	["continue"] = "\"continue\"",
	["true"] = "\"true\"",
	["false"] = "\"false\"",
	["nil"] = "\"nil\""
}

local ReadableCharacters = table.create(94) do
	for i = 32, 126 do
		ReadableCharacters[i] = string.char(i)
	end
	ReadableCharacters[34], ReadableCharacters[92] = "\\\"", "\\\\"
end

local Enums = {} do
	for i,v in Enum:GetEnums() do
		Enums[v] = "Enum."..tostring(v)
	end
end

local GlobalFunctions = setmetatable({
	[assert] = "assert",
	[error] = "error",
	[getfenv] = "getfenv",
	[getmetatable] = "getmetatable",
	[ipairs] = "ipairs",
	[loadstring] = "loadstring",
	[newproxy] = "newproxy",
	[next] = "next",
	[pairs] = "pairs",
	[pcall] = "pcall",
	[print] = "print",
	[rawequal] = "rawequal",
	[rawget] = "rawget",
	[rawlen] = "rawlen",
	[rawset] = "rawset",
	[select] = "select",
	[setfenv] = "setfenv",
	[setmetatable] = "setmetatable",
	[tonumber] = "tonumber",
	[tostring] = "tostring",
	[unpack] = "unpack",
	[xpcall] = "xpcall",
	[collectgarbage] = "collectgarbage",
	[delay] = "delay",
	[gcinfo] = "gcinfo",
	[PluginManager] = "PluginManager",
	[require] = "require",
	[settings] = "settings",
	[spawn] = "spawn",
	[tick] = "tick",
	[time] = "time",
	[UserSettings] = "UserSettings",
	[wait] = "wait",
	[warn] = "warn",
	[Delay] = "Delay",
	[ElapsedTime] = "ElapsedTime",
	[elapsedTime] = "elapsedTime",
	[printidentity] = "printidentity",
	[Spawn] = "Spawn",
	[Stats] = "Stats",
	[stats] = "stats",
	[Version] = "Version",
	[version] = "version",
	[Wait] = "Wait"
}, {
	__call = function(self, Path : string, tbl : {[string] : any})
		local Visited = setmetatable({}, {__mode = "k"})

		local function LookUp(Path : string, tbl : {[string] : any})
			if not Visited[tbl] then
				Visited[tbl] = true

				for i,v in next, tbl do
					if type(i) == "string" and not Keywords[i] and not i:match("[a-Z_][a-Z_0-9]") then
						local ValueType = type(v)

						if ValueType == "function" or ValueType == "table" then
							local NewPath = Path.."."..i

							if ValueType == "function" then
								self[v] = NewPath
							else
								LookUp(NewPath, v)
							end
						end
					end
				end
			end
		end

		LookUp(Path, tbl)
	end
})

for i,v in env do
	GlobalFunctions(i, v)
end

local function ExtractTypes<Type>(From : {[any] : any}, Path : string, DataType : string, Storage : {}?) : {[Type] : string}
	local Storage = Storage or setmetatable({}, {__mode = "k"}) -- I dont technically need it but as I don't know what people are going to do with this code better safe than sorry

	for i,v in next, From do
		if typeof(v) == DataType and not Storage[v] and type(i) == "string" and not Keywords[i] and not i:match("[a-Z_][a-Z_0-9]") then
			Storage[v] = Path.."."..i
		end
	end

	return Storage
end

local function Serialize(DataStructure : any, format : boolean?, indents : string, CyclicList : typeof(setmetatable({}, {__mode = "k"}))?, InComment : boolean?)
	local DataHandler = Methods[typeof(DataStructure)]

	return DataHandler and DataHandler(DataStructure, format, indents, CyclicList, InComment) or "nil --["..(not InComment and "" or "=").."[ Unsupported Data Type | "..typeof(DataStructure).." ]"..(not InComment and "" or "=").."]"
end

local function islclosure(Function : (...any?) -> (...any?))
	return info(Function, "l") ~= -1
end

local function nanToString(int : number)
	return int == int and int or "0/0"
end

local function ValidateSharedTableIndex(Index : string)
	local IsKeyword = type(Index) == "number" and Index or Keywords[Index]

	if not IsKeyword then
		if #Index ~= 0 then
			local IndexBuffer = fromstring(Index)
			local FirstByte = readu8(IndexBuffer, 0)

			if FirstByte >= 97 and FirstByte <= 122 or FirstByte >= 65 and FirstByte <= 90 or FirstByte == 95 then
				for i = 1, #Index-1 do
					local Byte = readu8(IndexBuffer, i)

					if not ((Byte >= 97 and Byte <= 122) or (Byte >= 65 and Byte <= 90) or Byte == 95 or (Byte >= 48 and Byte <= 57)) then
						return "["..DefaultMethods.string(Index).."] = "
					end
				end

				return Index.." = "
			end

			return "["..DefaultMethods.string(Index).."] = "
		end

		return "[\"\"] = "
	end

	return "["..IsKeyword.."] = "
end

local function ValidateIndex(Index : any)
	local IndexType = type(Index)
	local IsNumber = IndexType == "number"

	if IsNumber or IndexType == "string" then
		local IsKeyword = (IsNumber and Index or Keywords[Index])

		if not IsKeyword then
			if #Index ~= 0 then
				local IndexBuffer = fromstring(Index)
				local FirstByte = readu8(IndexBuffer, 0)

				if FirstByte >= 97 and FirstByte <= 122 or FirstByte >= 65 and FirstByte <= 90 or FirstByte == 95 then
					local IndexLength = #Index

					for i = 1, IndexLength-1 do
						local Byte = readu8(IndexBuffer, i)

						if not ((Byte >= 97 and Byte <= 122) or (Byte >= 65 and Byte <= 90) or Byte == 95 or (Byte >= 48 and Byte <= 57)) then
							return "["..DefaultMethods.string(Index).."] = "
						end
					end
					
					return Index.." = "
				end

				return "["..DefaultMethods.string(Index).."] = "
			end

			return "[\"\"] = "
		end

		return "["..IsKeyword.."] = "
	end

	return "["..(IndexType ~= "table" and Serialize(Index, false, "") or "\"<Table> (table: "..(getmetatable(Index) == nil and tostring(Index):sub(8) or "@Metatable")..")\"").."] = "
end

function DefaultMethods.Axes(Axes : Axes)
	return "Axes.new("..concat({
		Axes.X and "Enum.Axis.X" or nil,
		Axes.Y and "Enum.Axis.Y" or nil,
		Axes.Z and "Enum.Axis.Z" or nil
	},", ")..")"
end

function DefaultMethods.BrickColor(Color : BrickColor)
	return "BrickColor.new("..Color.Number..")"
end

local CFrames = ExtractTypes(CFrame, "CFrame", "CFrame")
function DefaultMethods.CFrame(CFrame : CFrame)
	local Generation = CFrames[CFrame]

	if not Generation then
		local SerializeNumber = DefaultMethods.number
		local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = CFrame:GetComponents()

		return "CFrame.new("..SerializeNumber(x)..", "..SerializeNumber(y)..", "..SerializeNumber(z)..", "..SerializeNumber(R00)..", "..SerializeNumber(R01)..", "..SerializeNumber(R02)..", "..SerializeNumber(R10)..", "..SerializeNumber(R11)..", "..SerializeNumber(R12)..", "..SerializeNumber(R20)..", "..SerializeNumber(R21)..", "..SerializeNumber(R22)..")"
	end

	return Generation
end

local DefaultCatalogSearchParams = CatalogSearchParams.new()
function DefaultMethods.CatalogSearchParams(Params : CatalogSearchParams, format : boolean?, indents : string)
	if DefaultCatalogSearchParams ~= Params then
		local formatspace = format and "\n"..indents or " "
		local SerializeString = DefaultMethods.string
		local SearchKeyword = Params.SearchKeyword
		local MinPrice = Params.MinPrice
		local MaxPrice = Params.MaxPrice
		local SortType = Params.SortType
		local SortAggregation = Params.SortAggregation
		local CategoryFilter = Params.CategoryFilter
		local SalesTypeFilter = Params.SalesTypeFilter
		local BundleTypes = Params.BundleTypes
		local AssetTypes = Params.AssetTypes
		local CreatorName = Params.CreatorName
		local CreatorType = Params.CreatorType
		local CreatorId = Params.CreatorId
		local Limit = Params.Limit

		return "(function(Param : CatalogSearchParams)"..formatspace..(SearchKeyword ~= "" and "\tParam.SearchKeyword = "..SerializeString(SearchKeyword)..formatspace or "")..(MinPrice ~= 0 and "\tParam.MinPrice = "..MinPrice..formatspace or "")..(MaxPrice ~= 2147483647 and "\tParam.MaxPrice = "..MaxPrice..formatspace or "")..(SortType ~= Enum.CatalogSortType.Relevance and "\tParam.SortType = Enum.CatalogSortType."..SortType.Name..formatspace or "")..(SortAggregation ~= Enum.CatalogSortAggregation.AllTime and "\tParam.SortAggregation = Enum.CatalogSortAggregation."..SortAggregation.Name..formatspace or "")..(CategoryFilter ~= Enum.CatalogCategoryFilter.None and "\tParam.CategoryFilter = Enum.CatalogCategoryFilter."..CategoryFilter.Name..formatspace or "")..(SalesTypeFilter ~= Enum.SalesTypeFilter.All and "\tParam.SalesTypeFilter = Enum.SalesTypeFilter."..SalesTypeFilter.Name..formatspace or "")..(#BundleTypes > 0 and "\tParam.BundleTypes = "..DefaultMethods.table(BundleTypes, false, "")..formatspace or "")..(#AssetTypes > 0 and "\tParam.AssetTypes = "..DefaultMethods.table(AssetTypes, false, "")..formatspace or "")..(Params.IncludeOffSale and "\tParams.IncludeOffSale = true"..formatspace or "")..(CreatorName ~= "" and "\tParams.CreatorName = "..SerializeString(CreatorName)..formatspace or "")..(CreatorType ~= Enum.CreatorTypeFilter.All and "\tParam.CreatorType = Enum.CreatorTypeFilter."..CreatorType.Name..formatspace or "")..(CreatorId ~= 0 and "\tParams.CreatorId = "..CreatorId..formatspace or "")..(Limit ~= 30 and "\tParams.Limit = "..Limit..formatspace or "").."\treturn Params"..formatspace.."end)(CatalogSearchParams.new())"
	end

	return "CatalogSearchParams.new()"
end

function DefaultMethods.Color3(Color : Color3)
	local SerializeNumber = DefaultMethods.number

	return "Color3.new("..SerializeNumber(Color.R)..", "..SerializeNumber(Color.G)..", "..SerializeNumber(Color.B)..")"
end

function DefaultMethods.ColorSequence(Sequence : ColorSequence)
	local SerializeColorSequenceKeypoint = DefaultMethods.ColorSequenceKeypoint
	local Keypoints = Sequence.Keypoints
	local Size = #Keypoints
	local Serialized = ""

	for i = 1, Size-1 do
		Serialized ..= Serialized..SerializeColorSequenceKeypoint(Keypoints[i])..", "
	end

	return "ColorSequence.new({"..Serialized..SerializeColorSequenceKeypoint(Keypoints[Size]).."})"
end

function DefaultMethods.ColorSequenceKeypoint(KeyPoint : ColorSequenceKeypoint)
	return "ColorSequenceKeypoint.new("..DefaultMethods.number(KeyPoint.Time)..", "..DefaultMethods.Color3(KeyPoint.Value)..")"
end

function DefaultMethods.Content(content : Content)
	local Uri = content.Uri

	return Uri and "Content.fromUri("..Uri..")" or "Content.none"
end

function DefaultMethods.DateTime(Date : DateTime)
	return "DateTime.fromUnixTimestampMillis("..Date.UnixTimestampMillis..")"
end

function DefaultMethods.DockWidgetPluginGuiInfo(Dock : DockWidgetPluginGuiInfo)
	local ArgumentFunction = tostring(Dock):gmatch(":([%w%-]+)")

	return "DockWidgetPluginGuiInfo.new(Enum.InitialDockState."..ArgumentFunction()..", "..(ArgumentFunction() == "1" and "true" or "false")..", "..(ArgumentFunction() == "1" and "true" or "false")..", "..ArgumentFunction()..", "..ArgumentFunction()..", "..ArgumentFunction()..", "..ArgumentFunction()..")"
end

function DefaultMethods.Enum(Enum : Enum)
	return "Enums."..tostring(Enum)
end

function DefaultMethods.EnumItem(Item : EnumItem)
	return Enums[Item.EnumType].."."..Item.Name
end

function DefaultMethods.Enums()
	return "Enums"
end

function DefaultMethods.Faces(Faces : Faces)
	return "Faces.new("..concat({
		Faces.Top and "Enum.NormalId.Top" or nil,
		Faces.Bottom and "Enum.NormalId.Bottom" or nil,
		Faces.Left and "Enum.NormalId.Left" or nil,
		Faces.Right and "Enum.NormalId.Right" or nil,
		Faces.Back and "Enum.NormalId.Back" or nil,
		Faces.Front and "Enum.NormalId.Front" or nil,
	}, ", ")..")"
end

function DefaultMethods.FloatCurveKey(CurveKey : FloatCurveKey)
	local SerializeNumber = DefaultMethods.number

	return "FloatCurveKey.new("..SerializeNumber(CurveKey.Time)..", "..SerializeNumber(CurveKey.Value)..", Enum.KeyInterpolationMode."..CurveKey.Interpolation.Name..")"
end

function DefaultMethods.Font(Font : Font)
	return "Font.new("..DefaultMethods.string(Font.Family)..", Enum.FontWeight."..Font.Weight.Name..", Enum.FontStyle."..Font.Style.Name..")"
end

function DefaultMethods.Instance(obj : Instance)
	local ObjectParent = obj.Parent
	local ObjectClassName = obj.ClassName

	if ObjectParent then
		local ObjectName = DefaultMethods.string(obj.Name)

		if ObjectClassName ~= "Model" and ObjectClassName ~= "Player" then
			local IsService, Output = pcall(FindService, game, ObjectClassName) -- Generation can and will break when presented with noncreatable Instances such as Path (which is created by PathService:CreateAsync())

			return (not IsService or not Output) and DefaultMethods.Instance(ObjectParent)..":WaitForChild("..ObjectName..")" or ServiceGeneration[ObjectClassName] or "game:GetService(\""..ObjectClassName.."\")"
		elseif ObjectClassName == "Model" then
			local Player = Players:GetPlayerFromCharacter(obj)

			return not Player and DefaultMethods.Instance(ObjectParent)..":WaitForChild("..ObjectName..")" or "game:GetService(\"Players\")".. (Player == LocalPlayer and ".LocalPlayer.Character" or ":WaitForChild("..ObjectName..").Character")
		end
		
		return "game:GetService(\"Players\")".. (obj == LocalPlayer and ".LocalPlayer" or ":WaitForChild("..ObjectName..")") 
	end

	return ObjectClassName == "DataModel" and "game" or "Instance.new(\""..ObjectClassName.."\", nil)"
end

function DefaultMethods.NumberRange(Range : NumberRange)
	local SerializeNumber = DefaultMethods.number

	return "NumberRange.new("..SerializeNumber(Range.Min)..", "..SerializeNumber(Range.Max)..")"
end

function DefaultMethods.NumberSequence(Sequence : NumberSequence)
	local SerializeNumberSequenceKeypoint = DefaultMethods.NumberSequenceKeypoint
	local Keypoints = Sequence.Keypoints
	local Size = #Keypoints
	local Serialized = ""

	for i = 1, Size-1 do
		Serialized ..= Serialized..SerializeNumberSequenceKeypoint(Keypoints[i])..", "
	end

	return "NumberSequence.new({"..Serialized..SerializeNumberSequenceKeypoint(Keypoints[Size]).."})"
end

local DefaultOverlapParams = OverlapParams.new()
function DefaultMethods.OverlapParams(Params : OverlapParams, format : boolean?, indents : string)
	if DefaultOverlapParams ~= Params then
		local formatspace = format and "\n"..indents or " "
		local FilterDescendantsInstances = Params.FilterDescendantsInstances
		local FilterType = Params.FilterType
		local CollisionGroup = Params.CollisionGroup

		return "(function(Param : OverlapParams)"..formatspace..(#FilterDescendantsInstances > 0 and "\tParam.FilterDescendantsInstances = "..DefaultMethods.table(FilterDescendantsInstances, false, "")..formatspace or "")..(FilterType ~= Enum.RaycastFilterType.Exclude and "\tParam.FilterType = Enum.RaycastFilterType."..FilterType.Name..formatspace or "")..(CollisionGroup ~= "Default" and "\tParam.CollisionGroup = "..DefaultMethods.string(CollisionGroup)..formatspace or "")..(Params.RespectCanCollide and "\tParam.RespectCanCollide = true"..formatspace or "")..(Params.BruteForceAllSlow and "\tParam.BruteForceAllSlow = true"..formatspace or "").."\treturn Params"..formatspace.."end)(OverlapParams.new())"
	end

	return "OverlapParams.new()"
end

function DefaultMethods.NumberSequenceKeypoint(Keypoint : NumberSequenceKeypoint)
	local SerializeNumber = DefaultMethods.number

	return "NumberSequenceKeypoint.new("..SerializeNumber(Keypoint.Time)..", "..SerializeNumber(Keypoint.Value)..", "..SerializeNumber(Keypoint.Envelope)..")"
end

function DefaultMethods.PathWaypoint(Waypoint : PathWaypoint)
	return "PathWaypoint.new("..DefaultMethods.Vector3(Waypoint.Position)..", Enum.PathWaypointAction."..Waypoint.Action.Name..", "..DefaultMethods.string(Waypoint.Label)..")"
end

function DefaultMethods.PhysicalProperties(Properties : PhysicalProperties)
	return "PhysicalProperties.new("..(nanToString(Properties.Density))..", "..nanToString(Properties.Friction)..", "..nanToString(Properties.Elasticity)..", "..nanToString(Properties.FrictionWeight)..", "..nanToString(Properties.ElasticityWeight)..")"
end

function DefaultMethods.RBXScriptConnection(Connection : RBXScriptConnection, _, _, _, InComment : boolean?)
	local CommentSeperator = not InComment and "" or "="

	return "(nil --["..CommentSeperator.."[ RBXScriptConnection | IsConnected: "..(Connection.Connected and "true" or "false").." ]"..CommentSeperator.."])" -- Can't support this
end

function DefaultMethods.RBXScriptSignal(Signal : RBXScriptSignal, _, _, _, InComment : boolean?)
	local CommentSeperator = not InComment and "" or "="
	local SignalName = tostring(Signal):match("Signal (%a+)")

	return Signals[SignalName] or "(nil --["..CommentSeperator.."[ RBXScriptSignal | "..SignalName.." is not supported ]"..CommentSeperator.."])"
end

function DefaultMethods.Random(_, _, _, _, InComment : boolean?) -- Random cant be supported because I cant get the seed
	local CommentSeperator = not InComment and "" or "="

	return "Random.new(--["..CommentSeperator.."[ <Seed> ]"..CommentSeperator.."])"
end

function DefaultMethods.Ray(Ray : Ray)
	local SerializeVector3 = DefaultMethods.Vector3

	return "Ray.new("..SerializeVector3(Ray.Origin)..", "..SerializeVector3(Ray.Direction)..")"
end

local DefaultRaycastParams = RaycastParams.new()
function DefaultMethods.RaycastParams(Params : RaycastParams, format : boolean?, indents : string)
	if DefaultRaycastParams ~= Params then
		local formatspace = format and "\n"..indents or " "
		local FilterDescendantsInstances = Params.FilterDescendantsInstances
		local FilterType = Params.FilterType
		local CollisionGroup = Params.CollisionGroup

		return "(function(Param : RaycastParams)"..formatspace..(#FilterDescendantsInstances > 0 and "\tParam.FilterDescendantsInstances = "..DefaultMethods.table(FilterDescendantsInstances, false, "")..formatspace or "")..(FilterType ~= Enum.RaycastFilterType.Exclude and "\tParam.FilterType = Enum.RaycastFilterType."..FilterType.Name..formatspace or "")..(Params.IgnoreWater and "\tParam.IgnoreWater = true"..formatspace or "")..(CollisionGroup ~= "Default" and "\tParam.CollisionGroup = "..DefaultMethods.string(CollisionGroup)..formatspace or "")..(Params.RespectCanCollide and "\tParam.RespectCanCollide = true"..formatspace or "")..(Params.BruteForceAllSlow and "\tParam.BruteForceAllSlow = true"..formatspace or "").."\treturn Params"..formatspace.."end)(RaycastParams.new())"
	end

	return "RaycastParams.new()"
end

function DefaultMethods.Rect(Rect : Rect)
	local SerializeVector2 = DefaultMethods.Vector2

	return "Rect.new("..SerializeVector2(Rect.Min)..", "..SerializeVector2(Rect.Max)..")"
end

function DefaultMethods.Region3(Region : Region3)
	local SerializeVector3 = DefaultMethods.Vector3
	local Center = Region.CFrame.Position
	local Size = Region.Size/2

	return "Region3.new("..SerializeVector3(Center - Size)..", "..SerializeVector3(Center + Size)..")"
end

function DefaultMethods.Region3int16(Region : Region3int16)
	local SerializeVector3int16 = DefaultMethods.Vector3int16

	return "Region3int16.new("..SerializeVector3int16(Region.Min)..", "..SerializeVector3int16(Region.Max)..")"
end

function DefaultMethods.RotationCurveKey(Curve : RotationCurveKey)
	return "RotationCurveKey.new("..DefaultMethods.number(Curve.Time)..", "..DefaultMethods.CFrame(Curve.Value)..", Enum.KeyInterpolationMode."..Curve.Interpolation.Name..")"
end

function DefaultMethods.SharedTable(Shared : SharedTable, format : boolean?, indents : string, _, InComment : boolean?)
	local isreadonly = IsSharedFrozen(Shared)

	if SharedSize(Shared) ~= 0 then
		local stackindent = indents..(format and "\t" or "")
		local CurrentIndex = 1
		local Serialized = {}

		for i,v in Shared do
			Serialized[CurrentIndex] = (CurrentIndex ~= i and ValidateSharedTableIndex(i) or "")..Serialize(v, format, stackindent, nil, InComment)
			CurrentIndex += 1	
		end

		local formatspace = format and "\n" or ""
		local Contents = formatspace..stackindent..concat(Serialized, (format and ",\n" or ", ")..stackindent)..formatspace..indents

		return not isreadonly and "SharedTable.new({"..Contents.."})" or "SharedTable.cloneAndFreeze(SharedTable.new({"..Contents.."}))"
	end

	return not isreadonly and "SharedTable.new()" or "SharedTable.cloneAndFreeze(SharedTable.new())"
end

function DefaultMethods.TweenInfo(Info : TweenInfo)
	return "TweenInfo.new("..DefaultMethods.number(Info.Time)..", Enum.EasingStyle."..Info.EasingStyle.Name..", Enum.EasingDirection."..Info.EasingDirection.Name..", "..Info.RepeatCount..", "..(Info.Reverses and "true" or "false")..", "..DefaultMethods.number(Info.DelayTime)..")"
end

function DefaultMethods.UDim(UDim : UDim)
	return "UDim.new("..DefaultMethods.number(UDim.Scale)..", "..UDim.Offset..")"
end

function DefaultMethods.UDim2(UDim2 : UDim2)
	local Width = UDim2.X
	local Height = UDim2.Y
	
	local WidthScale = Width.Scale
	local WidthOffset = Width.Offset
	
	local HeightScale = Height.Scale
	local HeightOffset = Height.Offset
	
	if WidthScale == 0 and HeightScale == 0 then
		return "UDim2.fromOffset("..WidthOffset..", "..HeightOffset..")"
	end

	local SerializeNumber = DefaultMethods.number

	if WidthOffset == 0 and HeightOffset == 0 then
		return "UDim2.fromScale("..SerializeNumber(WidthScale)..", "..SerializeNumber(HeightScale)..")"
	end

	return "UDim2.new("..SerializeNumber(WidthScale)..", "..WidthOffset..", "..SerializeNumber(HeightScale)..", "..HeightOffset..")"
end

function DefaultMethods.Vector2(Vector : Vector2)
	local SerializeNumber = DefaultMethods.number

	return "Vector2.new("..SerializeNumber(Vector.X)..", "..SerializeNumber(Vector.Y)..")"
end

function DefaultMethods.Vector2int16(Vector : Vector2int16)
	return "Vector2int16.new("..Vector.X..", "..Vector.Y..")"
end

local Vector3s = ExtractTypes(vector, "vector", "Vector3") do
	ExtractTypes(Vector3, "Vector3", "Vector3", Vector3s)
end

function DefaultMethods.Vector3(Vector : Vector3)
	local SerializeNumber = DefaultMethods.number

	return Vector3s[Vector] or "vector.create("..SerializeNumber(Vector.X)..", "..SerializeNumber(Vector.Y)..", "..SerializeNumber(Vector.Z)..")"
end

function DefaultMethods.Vector3int16(Vector : Vector3int16)
	return "Vector3int16.new("..Vector.X..", "..Vector.Y..", "..Vector.Z..")"
end

function DefaultMethods.boolean(bool : boolean)
	return bool and "true" or "false"
end

function DefaultMethods.buffer(buff : buffer)
	return "buffer.fromstring("..DefaultMethods.string(bufftostring(buff))..")"
end

DefaultMethods["function"] = function(Function : (...any?) -> ...any?, format : boolean?, indents : string, _, InComment : boolean?)
	local IsGlobal = GlobalFunctions[Function]

	if not IsGlobal then
		if format then
			local SerializeString = DefaultMethods.string
			
			local CommentSeperator = not InComment and "" or "="
			local tempindents = indents.."\t\t\t"
			local newlineindent = ",\n"..tempindents
			local source, line, name, numparams, vargs = info(Function, "slna")
			
			return "function()"..(line ~= -1 and "" or " --["..CommentSeperator.."[ CClosure ]"..CommentSeperator.."]").."\n\t"..indents.."--["..CommentSeperator.."[\n\t\t"..indents.."info = {\n"..tempindents.."source = "..SerializeString(source)..newlineindent.."line = "..line..newlineindent.."what = "..(line ~= -1 and "\"Lua\"" or "\"C\"")..newlineindent.."name = "..SerializeString(name)..newlineindent.."numparams = "..numparams..newlineindent.."vargs = "..(vargs and "true" or "false")..newlineindent.."function = "..tostring(Function).."\n\t\t"..indents.."}\n\t"..indents.."]"..CommentSeperator.."]\n"..indents.."end"
		end

		return islclosure(Function) and "function() end" or "function() --["..(not InComment and "" or "=").."[ CClosure ]"..(not InComment and "" or "=").."] end" -- shouldn't really ever be possible unless lego hax newcclosure
	end

	return IsGlobal
end

function DefaultMethods.table(tbl : {[any] : any}, format : boolean?, indents : string, CyclicList : typeof(setmetatable({}, {__mode = "k"}))?, InComment : boolean?)
	local CyclicList = CyclicList or setmetatable({}, {__mode = "k"})

	if not CyclicList[tbl] then
		CyclicList[tbl] = true 
		local isreadonly = isfrozen(tbl)
		local Index, Value = next(tbl)

		if Index ~= nil then
			local Indents = indents..(format and "\t" or "")
			local Ending = (format and ",\n" or ", ")
			local formatspace = format and "\n" or ""
			local Generation = "{"..formatspace

			local CurrentIndex = 1

			repeat
				Generation ..= Indents..(CurrentIndex ~= Index and ValidateIndex(Index) or "")..Serialize(Value, format, Indents, CyclicList, InComment)
				Index, Value = next(tbl, Index)
				Generation ..= Index ~= nil and Ending or formatspace..indents.."}"
				CurrentIndex += 1
			until Index == nil

			return not isreadonly and Generation or "table.freeze("..Generation..")"
		end

		return not isreadonly and "{}" or "table.freeze({})"
	else
		return "*** cycle table reference detected ***"
	end
end

DefaultMethods["nil"] = function()
	return "nil"
end

function DefaultMethods.number(num : number)
	return num ~= inf and num ~= neginf and num == num and tostring(num) or num == inf and "math.huge" or num == neginf and "-math.huge" or "0/0"
end

function DefaultMethods.string(RawString : string)
	local RawStringBuffer = fromstring(RawString)
	local SerializedString = ""
	local Lastunicode = false

	for i = 0, #RawString-1 do
		local Byte = readu8(RawStringBuffer, i)

		if (Byte >= 32 and Byte <= 126) then
			local IsNumber = (Byte >= 48 and Byte <= 57)

			SerializedString ..= Lastunicode and IsNumber and "\"..\""..(Byte-48) or not IsNumber and ReadableCharacters[Byte] or Byte-48
			Lastunicode = false
		else
			local IsUnicode = Byte < 7 or Byte > 13

			SerializedString ..= IsUnicode and "\\"..Byte or SpecialCases[Byte]
			Lastunicode = IsUnicode
		end
	end

	return "\""..SerializedString.."\""
end

function DefaultMethods.thread(thread : thread)
	return "coroutine.create(function() end)"
end

function DefaultMethods.userdata(userdata : any)
	return getmetatable(userdata) ~= nil and "newproxy(true)" or "newproxy(false)"
end

local function Serializevargs(... : any)
	local tbl = table.pack(...) -- Thank you https://github.com/sown0000 for pointing out that nils arent printed
	local GenerationSize = 0

	for i,v in tbl do
		local Generation = Serialize(v, true, "")
		tbl[i] = Generation
		GenerationSize += #Generation

		if GenerationSize > 100000 then -- output functions will trim the generation
			break
		end
	end

	return unpack(tbl, 1, tbl.n)
end

-- Safe parallel
function SerializeClass.SetGlobalFunctions(env : {[any] : any})
	assert(type(env) == "table", "table expected, got "..typeof(env))
	table.clear(GlobalFunctions)

	for i,v in next, env do
		GlobalFunctions(i, v)
	end
end

-- Safe parallel
function SerializeClass.AppendGlobalFunctions(env : {[any] : any})
	assert(type(env) == "table", "table expected, got "..typeof(env))

	for i,v in next, env do
		GlobalFunctions(i, v)
	end
end

-- Safe Parallel
function SerializeClass.Advanced.Serialize(DataStructure : any?, format : boolean?)
	return Serialize(DataStructure, format, "")
end

-- Safe Parallel
function SerializeClass.Advanced.SerializeKnown(DataType : string, DataStructure : any?, format : boolean?)
	return Methods[DataType](DataStructure, format, "")
end

-- Safe Parallel
function SerializeClass.SerializeKnown(DataType : string, DataStructure : any?, format : boolean?)
	local SerializeMethod = DefaultMethods[DataType]

	if SerializeMethod then
		return SerializeMethod(DataStructure, format, "")
	end
	warn(DataType, "was not found as a method")
end

-- Safe parallel
SerializeClass.Serialize = SerializeClass.Advanced.Serialize

-- Safe parallel
function SerializeClass.print(... : any?)
	print(Serializevargs(...))
end

-- Safe Parallel
function SerializeClass.warn(... : any?)
	warn(Serializevargs(...))
end

-- Unsafe Parallel
function SerializeClass:output(data : any?, format : boolean?)
	if IsStudio then
		local ScriptEditor = game:GetService("ScriptEditorService")
		local Storage = game:FindFirstChild("Serialized_Storage") or (function() : Folder
			local Folder = Instance.new("Folder", game)
			Folder.Name = "Serialized_Storage"
			return Folder
		end)()

		function self:output(data : any?, format : boolean?)
			local Serialized = self.Serialize(data, format)
			local DisplayScript = Instance.new("LocalScript", Storage)
			DisplayScript.Name = "Serialized_"..math.floor(os.clock())

			ScriptEditor:UpdateSourceAsync(DisplayScript, function()
				return Serialized
			end)

			ScriptEditor:OpenScriptDocumentAsync(DisplayScript)
		end
		self:output(data, format)
	else
		warn(debug.traceback("Cannot display output when not in studio:"))
	end
end

-- Safe Parallel
function SerializeClass:OverrideMethod(Method : string, NewMethod : (DataStructure : any, format : boolean?, indents : string, CyclicList : {[{[any] : any?}] : boolean}) -> string)
	if type(NewMethod) == "function" then
		Methods[Method] = NewMethod
	else
		self.RemoveMethod(Method)
	end
end

-- Safe Parallel
function SerializeClass.GetMethod(Method : string)
	return Methods[Method]
end

-- Safe Parallel
function SerializeClass.RemoveMethod(Method : string)
	Methods[Method] = nil
end

return setmetatable({}, {
	__index = SerializeClass,
	__tostring = function()
		return "Serializer"
	end,
	__metatable = "This metatable is locked"
})
