--[[
	The reason I don't use string interpolation is because it is very slow.
	I'm already making this rather slow due to me using indexing vs 100 different elseif statements for the serialize function
	
	@TODO
	Unsupported DataTypes:
		CatalogSearchParams
		OverlapParams
		RaycastParams
		RaycastResult -- Unsure if I can even really support this due to it being created by doing WorldRoot:Raycast()
		Secret -- not sure how to even make this
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
local SerializeClass = {
	Advanced = {} -- basically for direct access without any of the checks
}

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

local function ExtractTypes<Type>(From : {[string] : Type?}, Path : string, DataType : string, Storage : {}?) : {[Type] : string}
	local Storage = Storage or setmetatable({}, {__mode = "k"}) -- I dont technically need it but as I don't know what people are going to do with this code better safe than sorry

	for i,v in next, From do
		if typeof(v) == DataType and not Storage[v] and type(i) == "string" and not Keywords[i] and not i:match("[a-Z_][a-Z_0-9]") then
			Storage[v] = Path.."."..i
		end
	end

	return Storage
end

local function Serialize(DataStructure : any, format : boolean?, indents : string, CyclicList : typeof(setmetatable({}, {__mode = "k"}))?)
	local DataHandler = Methods[typeof(DataStructure)]

	return DataHandler and DataHandler(DataStructure, format, indents, CyclicList) or "nil --[[ Unsupported Data Type | "..typeof(DataStructure).." ]]"
end

local function nanToString(int : number)
	return int == int and int or "0/0"
end

local function SerializeString(RawString : string)
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

local function SerializeNumber(num : number)
	return num ~= inf and num ~= neginf and num == num and num or num == inf and "math.huge" or num == neginf and "-math.huge" or "0/0"
end

local function SerializeInstance(obj : Instance)
	local ObjectParent = obj.Parent
	local ObjectClassName = obj.ClassName

	if ObjectParent then	
		local ObjectName = SerializeString(obj.Name)

		if ObjectClassName ~= "Model" and ObjectClassName ~= "Player" then
			local IsService, Output = pcall(FindService, game, ObjectClassName) -- Generation can and will break when presented with noncreatable Instances such as Path (which is created by PathService:CreateAsync())

			return (not IsService or not Output) and SerializeInstance(ObjectParent)..":WaitForChild("..ObjectName..")" or ServiceGeneration[ObjectClassName] or "game:GetService(\""..ObjectClassName.."\")"
		elseif ObjectClassName == "Model" then
			local Player = Players:GetPlayerFromCharacter(obj)

			return not Player and SerializeInstance(ObjectParent)..":WaitForChild("..ObjectName..")" or "game:GetService(\"Players\")".. (Player == LocalPlayer and ".LocalPlayer.Character" or ":WaitForChild("..ObjectName..").Character")
		end
		return "game:GetService(\"Players\")".. (obj == LocalPlayer and ".LocalPlayer" or ":WaitForChild("..ObjectName..")") 
	end

	return ObjectClassName == "DataModel" and "game" or "Instance.new(\""..ObjectClassName.."\", nil)"
end

local Vector3s = ExtractTypes(vector, "vector", "Vector3") do
	ExtractTypes(Vector3, "Vector3", "Vector3", Vector3s)
end

local function SerializeVector3(Vector : Vector3)
	return Vector3s[Vector] or "vector.create("..SerializeNumber(Vector.X)..", "..SerializeNumber(Vector.Y)..", "..SerializeNumber(Vector.Z)..")"
end

local function SerializeVector3int16(Vector : Vector3int16)
	return "Vector3int16.new("..Vector.X..", "..Vector.Y..", "..Vector.Z..")"
end

local function SerializeVector2(Vector : Vector2)
	return "Vector2.new("..SerializeNumber(Vector.X)..", "..SerializeNumber(Vector.Y)..")"
end

local function SerializeColor3(Color : Color3)
	return "Color3.new("..SerializeNumber(Color.R)..", "..SerializeNumber(Color.G)..", "..SerializeNumber(Color.B)..")"
end

local CFrames = ExtractTypes(CFrame, "CFrame", "CFrame")

local function SerializeCFrame(CFrame : CFrame)
	local Generation = CFrames[CFrame]

	if not Generation then
		local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = CFrame:GetComponents()

		return "CFrame.new("..SerializeNumber(x)..", "..SerializeNumber(y)..", "..SerializeNumber(z)..", "..SerializeNumber(R00)..", "..SerializeNumber(R01)..", "..SerializeNumber(R02)..", "..SerializeNumber(R10)..", "..SerializeNumber(R11)..", "..SerializeNumber(R12)..", "..SerializeNumber(R20)..", "..SerializeNumber(R21)..", "..SerializeNumber(R22)..")"
	end

	return Generation
end

local function SerializeColorSequenceKeypoint(KeyPoint : ColorSequenceKeypoint)
	return "ColorSequenceKeypoint.new("..SerializeNumber(KeyPoint.Time)..", "..SerializeColor3(KeyPoint.Value)..")"
end

local function SerializeNumberSequenceKeypoint(Keypoint : NumberSequenceKeypoint)
	return "NumberSequenceKeypoint.new("..SerializeNumber(Keypoint.Time)..", "..SerializeNumber(Keypoint.Value)..", "..SerializeNumber(Keypoint.Envelope)..")"
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
						return "["..SerializeString(Index).."] = "
					end
				end
				return Index.." = "
			end

			return "["..SerializeString(Index).."] = "
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
							return "["..SerializeString(Index).."] = "
						end
					end
					return Index.." = "
				end

				return "["..SerializeString(Index).."] = "
			end
			return "[\"\"] = "
		end

		return "["..IsKeyword.."] = "
	end

	return "["..(IndexType ~= "table" and Serialize(Index, nil, "") or "\"<Table> (table: "..(getmetatable(Index) == nil and tostring(Index):sub(8) or "@Metatable")..")\"").."] = "
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

DefaultMethods.CFrame = SerializeCFrame
DefaultMethods.Color3 = SerializeColor3

function DefaultMethods.ColorSequence(Sequence : ColorSequence)
	local Keypoints = Sequence.Keypoints
	local Size = #Keypoints
	local Serialized = ""

	for i = 1, Size-1 do
		Serialized ..= Serialized..SerializeColorSequenceKeypoint(Keypoints[i])..", "
	end

	return "ColorSequence.new({"..Serialized..SerializeColorSequenceKeypoint(Keypoints[Size]).."})"
end

DefaultMethods.ColorSequenceKeypoint = SerializeColorSequenceKeypoint

function DefaultMethods.Content(content : Content)
	local Uri = content.Uri

	return Uri and "Content.fromUri("..Uri..")" or "Content.none"
end

function DefaultMethods.DateTime(Date : DateTime)
	return "DateTime.fromUnixTimestampMillis("..Date.UnixTimestampMillis..")"
end

function DefaultMethods.DockWidgetPluginGuiInfo(Dock : DockWidgetPluginGuiInfo)
	local ArgumentFunction = tostring(Dock):gmatch(":([%w-]+)")

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

function DefaultMethods.Faces(Faces : Faces) : string
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
	return "FloatCurveKey.new("..SerializeNumber(CurveKey.Time)..", "..SerializeNumber(CurveKey.Value)..", Enum.KeyInterpolationMode."..CurveKey.Interpolation.Name..")"
end

function DefaultMethods.Font(Font : Font)
	return "Font.new("..SerializeString(Font.Family)..", Enum.FontWeight."..Font.Weight.Name..", Enum.FontStyle."..Font.Style.Name..")"
end

DefaultMethods.Instance = SerializeInstance

function DefaultMethods.NumberRange(Range : NumberRange)
	return "NumberRange.new("..SerializeNumber(Range.Min)..", "..SerializeNumber(Range.Max)..")"
end

function DefaultMethods.NumberSequence(Sequence : NumberSequence)
	local Keypoints = Sequence.Keypoints
	local Size = #Keypoints
	local Serialized = ""

	for i = 1, Size-1 do
		Serialized ..= Serialized..SerializeNumberSequenceKeypoint(Keypoints[i])..", "
	end

	return "NumberSequence.new({"..Serialized..SerializeNumberSequenceKeypoint(Keypoints[Size]).."})"
end

DefaultMethods.NumberSequenceKeypoint = SerializeNumberSequenceKeypoint

function DefaultMethods.PathWaypoint(Waypoint : PathWaypoint)
	return "PathWaypoint.new("..SerializeVector3(Waypoint.Position)..", Enum.PathWaypointAction."..Waypoint.Action.Name..", "..SerializeString(Waypoint.Label)..")"
end

function DefaultMethods.PhysicalProperties(Properties : PhysicalProperties)
	return "PhysicalProperties.new("..(nanToString(Properties.Density))..", "..nanToString(Properties.Friction)..", "..nanToString(Properties.Elasticity)..", "..nanToString(Properties.FrictionWeight)..", "..nanToString(Properties.ElasticityWeight)..")"
end

function DefaultMethods.RBXScriptConnection(Connection : RBXScriptConnection)
	return "(nil --[[ RBXScriptConnection | IsConnected: "..(Connection.Connected and "true" or "false").." ]])" -- Can't support this
end

function DefaultMethods.RBXScriptSignal(Signal : RBXScriptSignal) : string
	local SignalName = tostring(Signal):match("Signal (%a+)")

	return Signals[SignalName] or "(nil --[[ RBXScriptSignal | "..SignalName.." is not supported ]])"
end

function DefaultMethods.Random()
	return "(Random.new() --[[Random cant be supported because I cant get the seed]])"
end

function DefaultMethods.Ray(Ray : Ray)
	return "Ray.new("..SerializeVector3(Ray.Origin)..", "..SerializeVector3(Ray.Direction)..")"
end

function DefaultMethods.Rect(Rect : Rect)
	return "Rect.new("..SerializeVector2(Rect.Min)..", "..SerializeVector2(Rect.Max)..")"
end

function DefaultMethods.Region3(Region : Region3)
	local Center = Region.CFrame.Position
	local Size = Region.Size/2

	return "Region3.new("..SerializeVector3(Center - Size)..", "..SerializeVector3(Center + Size)..")"
end

function DefaultMethods.Region3int16(Region : Region3int16)
	return "Region3int16.new("..SerializeVector3int16(Region.Min)..", "..SerializeVector3int16(Region.Max)..")"
end

function DefaultMethods.RotationCurveKey(Curve : RotationCurveKey)
	return "RotationCurveKey.new("..SerializeNumber(Curve.Time)..", "..SerializeCFrame(Curve.Value)..", Enum.KeyInterpolationMode."..Curve.Interpolation.Name..")"
end

function DefaultMethods.SharedTable(Shared : SharedTable, format : boolean?, indents : string)
	local isreadonly = IsSharedFrozen(Shared)

	if SharedSize(Shared) ~= 0 then
		local stackindent = indents..(format and "\t" or "")
		local CurrentIndex = 1
		local Serialized = {}

		for i,v in Shared do
			Serialized[CurrentIndex] = (CurrentIndex ~= i and ValidateSharedTableIndex(i) or "")..Serialize(v, format, stackindent)
			CurrentIndex += 1	
		end

		local formatspace = format and "\n" or ""
		local Contents = formatspace..stackindent..concat(Serialized, (format and ",\n" or ", ")..stackindent)..formatspace..indents

		return not isreadonly and "SharedTable.new({"..Contents.."})" or "SharedTable.cloneAndFreeze(SharedTable.new({"..Contents.."}))"
	end
	return not isreadonly and "SharedTable.new()" or "SharedTable.cloneAndFreeze(SharedTable.new())"
end

function DefaultMethods.TweenInfo(Info : TweenInfo)
	return "TweenInfo.new("..SerializeNumber(Info.Time)..", Enum.EasingStyle."..Info.EasingStyle.Name..", Enum.EasingDirection."..Info.EasingDirection.Name..", "..Info.RepeatCount..", "..(Info.Reverses and "true" or "false")..", "..SerializeNumber(Info.DelayTime)..")"
end

function DefaultMethods.UDim(UDim : UDim)
	return "UDim.new("..SerializeNumber(UDim.Scale)..", "..UDim.Offset..")"
end

function DefaultMethods.UDim2(UDim2 : UDim2)
	local Width = UDim2.X
	local Height = UDim2.Y

	return "UDim2.new("..SerializeNumber(Width.Scale)..", "..Width.Offset..", "..SerializeNumber(Height.Scale)..", "..Height.Offset..")"
end

DefaultMethods.Vector2 = SerializeVector2

function DefaultMethods.Vector2int16(Vector : Vector2int16)
	return "Vector2int16.new("..Vector.X..", "..Vector.Y..")"
end

DefaultMethods.Vector3 = SerializeVector3

function DefaultMethods.Vector3int16(Vector : Vector3int16)
	return "Vector3int16.new("..Vector.X..", "..Vector.Y..", "..Vector.Z..")"
end

function DefaultMethods.boolean(bool : boolean)
	return bool and "true" or "false"
end

function DefaultMethods.buffer(buff : buffer)
	return "buffer.fromstring("..SerializeString(bufftostring(buff))..")"
end

DefaultMethods["function"] = function(Function : (...any?) -> ...any?, format : boolean?, indents : string)
	local IsGlobal = GlobalFunctions[Function]

	if not IsGlobal then
		if format then
			local tempindents = indents.."\t\t\t"
			local source, line, name, numparams, vargs = info(Function, "slna")
			local Serialized = "source = "..SerializeString(source)..",\n"..tempindents.."line = "..line..",\n"..tempindents.."what = "..(line ~= -1 and "\"Lua\"" or "\"C\"")..",\n"..tempindents.."name = "..name..",\n"..tempindents.."numparams = "..numparams..",\n"..tempindents.."vargs = "..(vargs and "true" or "false")..",\n"..tempindents.."function = "..tostring(Function)

			return "function()\n\t"..indents.."--[[\n\t\t"..indents.."info = {\n"..tempindents..Serialized.."\n\t\t"..indents.."}\n\t"..indents.."]]\n"..indents.."end" -- @TODO grab function from globals/add function info using the getinfo i made
		end

		return info(Function, "l") ~= -1 and "function() end" or "(nil --[[ CClosure ]])" -- shouldn't really ever be possible unless lego hax newcclosure
	end
	return IsGlobal
end

function DefaultMethods.table(tbl : {[any] : any}, format : boolean?, indents : string, CyclicList : typeof(setmetatable({}, {__mode = "k"}))?) : string
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
				Generation ..= Indents..(CurrentIndex ~= Index and ValidateIndex(Index) or "")..Serialize(Value, format, Indents, CyclicList)
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

DefaultMethods.number = SerializeNumber

DefaultMethods.string = SerializeString

function DefaultMethods.thread(thread : thread) -- planning on adding more to this
	return "coroutine.create(function() end)"
end

function DefaultMethods.userdata(userdata : any) -- planning on adding more to this later
	return getmetatable(userdata) ~= nil and "newproxy(true)" or "newproxy(false)"
end

local function Serializevargs(... : any) : string
	local generation = ""
	local tbl = {...}
	local arraysize = #tbl

	for i,v in tbl do
		generation ..= Serialize(v, true, "")..(i ~= arraysize and " " or "")

		if #generation > 100000 then -- output functions will trim the output
			break
		end
	end

	return generation
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

SerializeClass.Serialize = SerializeClass.Advanced.Serialize

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
			local Serialized = self.Advanced.Serialize(data, format)
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
function SerializeClass.OverrideMethod(Method : string, NewMethod : (DataStructure : any, format : boolean?, indents : string, CyclicList : {[{[any] : any?}] : boolean}) -> string)
	if DefaultMethods[Method] then
		if type(NewMethod) == "function" then
			Methods[Method] = NewMethod
		else
			warn(NewMethod, "is not a function", debug.traceback())
		end
	else
		warn(Method, "is not valid Method", debug.traceback())
	end
end

-- Safe Parallel
function SerializeClass.GetMethod(Method : string)
	return Methods[Method]
end

-- Safe Parallel
function SerializeClass.DefaultMethod(Method : string)
	Methods[Method] = nil
end

return setmetatable(SerializeClass, {
	__tostring = function()
		return "Serializer"
	end
})
