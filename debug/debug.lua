----------------------------------------------
------------MOD DEBUG SOCKET------------------

function initializeSocketConnection()
	local socket = require("socket")
	client = socket.connect("localhost", 12345)
	if not client then
		print("Failed to connect to the debug server")
	end
end

function sendDebugMessage(message)
	if client then
		client:send(message .. "\n")
	end
end

initializeSocketConnection()

-- Use the function to send messages
sendDebugMessage("Steamodded Debug Socket started !")

----------------------------------------------
------------MOD DEBUG SOCKET END--------------
