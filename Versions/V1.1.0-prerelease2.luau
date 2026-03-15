local runService = game:GetService("RunService")

local ShellFlow = {
	client = {},
	server = {},
	logs = {},
}
local private = {
	keys = {},
	eventHolders = {},
}

local events = nil

local VERSION = "Prototype v1.1.0-prerelease2"

local function IsClient()
	return runService:IsClient()
end

local function sf_Check(player: Player, eventName: string, key: number)
	local event = events:FindFirstChild(eventName)
	
	if not event then
		event = nil
	else
		local clientLimit = event:GetAttribute("ClientLimit")
		
		if clientLimit<=0 then
			event = nil
		else
			private.keys[eventName] = {}
			private.keys[eventName][tostring(player.UserId)] = key
			event:SetAttribute("ClientLimit", clientLimit-1)
		end
	end
	
	return event
end

local function timestamp()
	return os.clock()
end

local function generateSessionKey(player: Player)
	local key = math.random(1, 2147483647) * ((player.UserId * timestamp()) // 100)
	return key
end

function ShellFlow.server.Init()
	if IsClient() then
		print("ShellFlow.server.XXXXX functions can only be ran on: Scripts, Modules required from Scripts; no LocalScripts.")
		error("ShellFlow.server.Init() can only be run on the Server-Side", 2)
	end
	
	events = Instance.new("Folder")
	events.Name = "ShellFlowEvents"
	events.Parent = script
	
	local check = Instance.new("RemoteFunction")
	check.Parent = script
	check.Name = "SF_Check"
	
	check.OnServerInvoke = function(player: Player, eventName: string)
		local key = generateSessionKey(player)
		
		if not private.keys[eventName] then
			private.keys[eventName] = {}
		end
		
		private.keys[eventName][tostring(player.UserId)] = key
		
		local event = sf_Check(player, eventName, key)
		
		return event, key
	end
	
	print("ShellFlow " .. VERSION .. ": Initiated")
end

function ShellFlow.server.StoreEvent(eventName: string, eventType: string, clientLimit: number?) -- RemoteEvent, RemoteFunction, BindableEvent, BindableFunction
	if IsClient() then
		error("ShellFlow.server.StoreEvent() can only be run on the Server-Side", 2)
	end
	
	clientLimit = clientLimit or 1
	
	local event = nil
	if eventType == "RemoteEvent" then
		event = Instance.new("RemoteEvent")
	else
		error("Unable to store an event of type '" .. eventType .. "'", 2)
	end
	
	event:SetAttribute("ClientLimit", clientLimit)
	event.Name = eventName
	event.Parent = events
	
	--print(math.floor((timestamp()-initTime)*1000000)/1000 .. "ms to create an event")
	
	return event
end

function ShellFlow.server.RemovePlayerPermissions(eventName: string, player: Player)
	local event = events:FindFirstChild(eventName)
	if not event then
		return
	end
	
	if private.keys[eventName][tostring(player.UserId)] then
		local clientLimit = event:GetAttribute("ClientLimit")
		event:SetAttribute("ClientLimit", clientLimit+1)
		
		private.keys[eventName][tostring(player.UserId)] = nil
	end
end

function ShellFlow.server.ReadEvent(eventName: string)
	if IsClient() then
		error("ShellFlow.server.ReadEvent() can only be run on the Server-Side", 2)
	end
	
	local event = events:FindFirstChild(eventName)
	
	if not event then
		error("Event '" .. eventName .. "' does not exist.", 2)
	end
	
	return event
end

function ShellFlow.client.ReadEvent(eventName: string)
	if not IsClient() then
		error("ShellFlow.client.ReadEvent() can only be run on the Client-Side", 2)
	end
	
	local sf_Check: RemoteFunction? = script:FindFirstChild("SF_Check")
	if not sf_Check then
		error("Server hasn't been Initiated yet", 2)
	end
	
	local event, key = sf_Check:InvokeServer(eventName)
	
	--print(key)
	
	if not event then
		error("Event '" .. eventName .. "' does not exist or the client doesn't have access", 2)
	end
	
	--print(math.floor((timestamp()-initTime)*1000000)/1000 .. "ms to read an event")
	
	return event, key
end

function ShellFlow.server.ReadKey(eventName: string, player: Player)
	if IsClient() then
		error("ShellFlow.server.ReadKey() can only be run on the Server-Side", 2)
	end
	
	if not private.keys[eventName] then
		return nil, false
	end
	
	if not private.keys[eventName][tostring(player.UserId)] then
		return nil, false
	end
	
	local key = private.keys[eventName][tostring(player.UserId)]
	
	return key, true
end

function ShellFlow.server.Log(message: string, level: number)
	if IsClient() then
		error("ShellFlow.server.Log() can only be run on the Server-Side", 2)
	end
	
	local log = {}
	log[1] = os.date("*t")
	log[2] = message
	log[3] = level
	
	table.insert(ShellFlow.logs, log)
end

function ShellFlow.client.Log(message: string, level: number)
	if not IsClient() then
		error("ShellFlow.client.Log() can only be run on the Client-Side", 2)
	end

	local log = {}
	log[1] = os.date("*t")
	log[2] = message
	log[3] = level

	table.insert(ShellFlow.logs, log)
end

return ShellFlow
