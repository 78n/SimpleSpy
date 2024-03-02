-- anyways, this probably won't get much updates, maybe here and there.
-- not actually deprecated, just that my motivation is destroyed due to Hyperion coming to UWP.
-- my workflow for making Roblox scripts in 2024 (this isn't an actual script, I doubt there's a signals service in Roblox):
local Signals = game:GetService("Signals")
-- I want **exploits**
local Exploits = Signals:GetCategory("Exploits")
-- I want **desktop** exploits
local DesktopExploits = Exploits:GetPlatform("Desktop")
-- I want **free** desktop exploits
local FreeDesktopExploits = DesktopExploits:GetPrice("Free")
local fullyMotivated = false
local function becomeFullyMotivated()
	fullyMotivated = true
end
-- once one is released, I will probably become fully motivated.
FreeDesktopExploits.Released:Once(becomeFullyMotivated)
-- if not fully motivated,
while not fullyMotivated do
	-- I might try to make an update,
	if math.random(0, 1) == 1 then
		-- if I do get past thinking, I've won the motivation lottery,
		print("won the motivation lottery, trying something...")
		-- now I'll try to actually make it,
		trySomething()
		-- and I'll push my changes and go on...
		print("let us go on...")
		continue
	end
  -- if I don't, we mope...
	print("mope...")
end
-- this is probably rare, there's probably not going to be any free desktop exploits,
-- but in the case of that, I'll be motivated to try and use it
print("well, I'm fully motivated, I'm going to start (fully) scripting again...")
-- and if it works,
startScriptingAgain()
