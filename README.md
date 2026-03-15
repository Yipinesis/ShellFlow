# ShellFlow: Roblox Networking API
ShellFlow is an API created inside Roblox Studio that acts as a Shell over RemoteEvents, allowing users to use RemoteEvents safely without having to worry about unexpected interruptions. ShellFlow keeps events hidden and secure with confirmation into an event, and confirmation outside an event; and it's extremely simple! I created this project a couple months ago, and I have just started working on it again, as I need it for my Roblox project.
## The Basics
First, we'll have to go over the basics. ShellFlow is currently in `V1.0.0` as of righting this, so expect things to not function correctly. However, if your version is in `V1.X.X`, then this guide should still be up to date; with less bugs. Anyway, enough blabbering. First, you'll have to go the
[ShellFlow](https://create.roblox.com/store/asset/103326929320392/ShellFlow-V110prerelease2) asset, then insert it into **ReplicatedStorage**.

![Image](Images/1.png)

Next, setup a Server script in **ServerScriptService**, and a Client script in **StarterPlayerScripts**.

![Image](Images/2.png)
![Image](Images/3.png)

------
Inside both scripts, we can require ShellFlow and *do some stuff*. Below listed are the scripts for both the Client and Server, creating a simple Server → Client messenger.
```lua
--- SERVER SCRIPT ---
-- Requiring ShellFlow
local shellFlow = require(game.ReplicatedStorage.ShellFlow)

-- Initialising the Server
shellFlow.server.Init()

-- Creating an event with parameters:
-- · "Name" is the identifier of the event, used to find the event...
-- · "Type" has to be "RemoteEvent", as other types aren't supported yet...
-- · "Client Limit" is a safety feature. Think of it as slots; how many clients have access to this event?
local event = shellFlow.server.StoreEvent("Event", "RemoteEvent", 1)

-- Fires the event to all clients
event:FireAllClients("Hello, World from the Server!")
```

```lua
--- CLIENT SCRIPT ---
-- Requiring ShellFlow
local shellFlow = require(game.ReplicatedStorage.ShellFlow)

-- Reading the event created from the Server
local event = shellFlow.client.ReadEvent("Event")

-- Linking the event instance to a function
event.OnClientEvent:Connect(function(message)
	print("SERVER SAID: " .. tostring(message))
end)
```
------
Hey! You've got yourself a neat messenger!
## Security Overview
ShellFlow automatically handles a ***lot*** of the security inside the module itself, but still needs some input from the user. If you look into the ShellFlow module enough, you can notice that ShellFlow creates a folder of events and keeps it within itself. Untrustworthy clients can just abuse the events from there, right?

You are completely correct. This is where session keys come in. Each time a client requests access to an event, it's given a special code that is needed to access events. Now, the server receiving the input from the client will request of the code from ShellFlow, then compare it to the client's session key. If it matches, then the code is executed. Otherwise, they're blocked.

Below, you can see a Client → Server messenger with session keys implemented too.

```lua
--- SERVER SCRIPT ---
-- Requiring ShellFlow
local shellFlow = require(game.ReplicatedStorage.ShellFlow)

-- Initialising the Server
shellFlow.server.Init()

-- Creating an event with a 1-client limit
local event = shellFlow.server.StoreEvent("Event", "RemoteEvent", 1)

-- Linking a function to the event with a sessionKey parameter
event.OnServerEvent:Connect(function(player, message, sessionKey)
  -- Reads the key; automatically sends player data too
	local key, accessToEvent = shellFlow.server.ReadKey("Event", player)

  -- Checks if the correct key matches with the key given by the player
	if sessionKey==key and accessToEvent then
    -- Success!
		print("CLIENT SAID: " .. tostring(message))
	else
    -- FAILURE.
    -- Increases the clientLimit, as this client is untrustworthy
		local clientLimit = event:GetAttribute("ClientLimit")
		event:SetAttribute("ClientLimit", clientLimit+1)

		print("LIAR!")
	end
end)
```

```lua
--- CLIENT SCRIPT ---
-- Requiring ShellFlow
local shellFlow = require(game.ReplicatedStorage.ShellFlow)

-- Reading the event created from the Server and grabbing the key
local event, key = shellFlow.client.ReadEvent("Event")

-- Linking the event instance to a function
event:FireServer("Hello, from the client!", key)
event:FireServer("Hello, from the EVIL client!", key+1)
```
------
As you can see from above, the client sends out 2 packages; 1 correct, and 1 wrong. If you run the code, the faulty package would be ignored for having the wrong session key. There's one more feature that I have yet to show you...
## External Logging
Yes, there is a logging system that doesn't take up all the space in the `Output`. Instead, all the logs are saved into a table, and is saved inside `ShellFlow.logs`. Logs are saved separately and are not merged. I'll see if I can fix this in the near future. Anyway, you can create a log using `ShellFlow.server.Log("Message", 1)` or `ShellFlow.client.Log("Message", 2)`. They'll bug out if the wrong version is used on the wrong viewer. Anyway, here's the full code without any comments, and with the logging system embedded.

```lua
--- SERVER SCRIPT ---
local shellFlow = require(game.ReplicatedStorage.ShellFlow)

shellFlow.server.Init()

local event = shellFlow.server.StoreEvent("Event", "RemoteEvent", 22)

local log = shellFlow.server.Log

log("Fired to Clients", 1)

event:FireAllClients("this is a passed down message")

event.OnServerEvent:Connect(function(player, message, sessionKey)
	log("OnServerEvent", 1)

	local key, accessToEvent = shellFlow.server.ReadKey(event.Name, player)
	
	print(sessionKey, key)
	if sessionKey==key and accessToEvent then
		log("Session Key Matched", 1)

		print("CLIENT SAID: " .. tostring(message))
	else
		log("Session Key Didn't match; untruthful client", 2)
		
		shellFlow.server.RemovePlayerPermissions(event.Name, player)
		
		print("LIAR!")
	end
end)

task.wait(3)

print(shellFlow.logs)
```

```lua
--- CLIENT SCRIPT ---
local player = game:GetService("Players").LocalPlayer

local shellFlow = require(game.ReplicatedStorage.ShellFlow)

local event, key = shellFlow.client.ReadEvent("Event")

event:FireServer("this is a passed down message", key)
event.OnClientEvent:Connect(function(message)
	print("SERVER SAID: " .. tostring(message))
end)
```
# API
## Server
### ShellFlow.server.Init()

Initializes the server. Run immediately after requiring the ShellFlow module.

```lua
local shellFlow = require(game.ReplicatedStorage.ShellFlow)
shellFlow.server.Init()
```

### ShellFlow.server.StoreEvent(EventName: string, EventType: string, ClientLimit: number?)

Stores and creates an event locally and universally.

```lua
local shellFlow = require(game.ReplicatedStorage.ShellFlow)
shellFlow.server.Init()

local event = shellFlow.server.StoreEvent("Messenger", "RemoteEvent")
```

### ShellFlow.server.RemovePlayerPermissions(eventName: string, player: Player)

Increments ClientLimit by 1 if the requested player is trusted, but gave the wrong ID. Doesn't do anything if an outsider attempts to run the event while not on the list.

```lua
event.OnServerEvent:Connect(function(player, message, sessionKey)
	local key, accessToEvent = shellFlow.server.ReadKey("Event", player)

	if sessionKey==key and accessToEvent then
		print("CLIENT SAID: " .. tostring(message))
	else
		shellFlow.server.RemovePlayerPermissions("Messenger", player)
	end
end)
```

### ShellFlow.server.ReadEvent(eventName: string)

Reads an event from the Server. Not too necessary or useful.

```lua
local shellFlow = require(game.ReplicatedStorage.ShellFlow)
shellFlow.server.Init()

shellFlow.server.StoreEvent("Messenger", "RemoteEvent")

local event = sshelLFlow.server.ReadEvent("Messenger")
```

### ShellFlow.server.ReadKey(eventName: string)

Fetches a key from the Server, typically to validate if a Client's session key is correct.

```lua
event.OnServerEvent:Connect(function(player, message, sessionKey)
	local key, accessToEvent = shellFlow.server.ReadKey("Event", player)

	if sessionKey==key and accessToEvent then
		print("CLIENT SAID: " .. tostring(message))
	else
		shellFlow.server.RemovePlayerPermissions("Messenger", player)
	end
end)
```

### ShellFlow.server.Log(message: string, level: number)

Creates a new log and saves it into `ShellFlow.logs`.

```lua
local shellFlow = require(game.ReplicatedStorage.ShellFlow)
shellFlow.server.Init()
shellFlow.server.Log("Initialized ShellFlow", 1)

local event = shellFlow.server.StoreEvent("Messenger", "RemoteEvent")
shellFlow.server.Log("Created 'Messenger' RemoteEvent", 1)

print(shellFlow.logs)
```

## Client

### ShellFlow.client.ReadEvent(eventName: string)

Reads an event from the Client, creates a session key, and adds the user into a trusted list.

```lua
local shellFlow = require(game.ReplicatedStorage.ShellFlow)

local event: RemoteEvent = shellFlow.client.ReadEvent("Messenger")

```

### ShellFlow.client.Log(message: string, level: number)

Creates a new log and saves it into `ShellFlow.logs`.

```lua
local shellFlow = require(game.ReplicatedStorage.ShellFlow)

local event: RemoteEvent = shellFlow.client.ReadEvent("Messenger")
shellFlow.client.Log("Fetched 'Messenger' RemoteEvent", 1)

print(shellFlow.logs)

```
