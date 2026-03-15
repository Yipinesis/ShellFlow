local runService = game:GetService("RunService")

local ShellFlow = {
	client = {},
	server = {},
	logs = {},
}
local private = {
	keys = {},
}

local events = nil

local VERSION = "Prototype v0.4.0"

local function IsClient()
	return runService:IsClient()
end

local function sf_Check(eventName: string)
	local event = events:FindFirstChild(eventName)
	
	if not event then
		event = nil
	else
		local clientLimit = event:GetAttribute("ClientLimit")
		
		if clientLimit<=0 then
			event = nil
		else
			event:SetAttribute("ClientLimit", clientLimit-1)
		end
	end
	
	return event
end

local function timestamp()
	return os.clock()
end

local function generateSessionKey(userID: number)
	local key = (userID/584)*timestamp()*34
	return math.floor(key)
end

function ShellFlow.server.Init()
	if IsClient() then
		error("ShellFlow.server.Init() can only be run on the Server-Side", 2)
	end
	
	events = Instance.new("Folder")
	events.Name = "ShellFlowEvents"
	events.Parent = script
	
	local check = Instance.new("RemoteFunction")
	check.Parent = script
	check.Name = "SF_Check"
	
	check.OnServerInvoke = function(player: Player, eventName: string)
		local key = generateSessionKey(player.UserId)
		private.keys[eventName] = key
		return sf_Check(eventName), key
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
	
	print(key)
	
	if not event then
		error("Event '" .. eventName .. "' does not exist or the client doesn't have access", 2)
	end
	
	--print(math.floor((timestamp()-initTime)*1000000)/1000 .. "ms to read an event")
	
	return event, key
end

function ShellFlow.server.ReadKey(eventName: string)
	if IsClient() then
		error("ShellFlow.server.ReadKey() can only be run on the Server-Side", 2)
	end
	
	return private.keys[eventName]
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
