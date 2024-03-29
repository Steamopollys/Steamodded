----------------------------------------------
------------MOD DEBUG SOCKET------------------

function initializeSocketConnection()
	local socket = require("socket")
	client = socket.connect("localhost", 12345)
	if not client then
		print("Failed to connect to the debug server")
	end
end

-- message, logger in this order to preserve backward compatibility
function sendDebugMessage(message, logger)
    logger = logger or "DefaultLogger"
	sendMessage("DEBUG", logger, message)
end

function sendInfoMessage(message, logger)
	logger = logger or "DefaultLogger"
	-- the space after "INFO" is just to align the logs (debug : 5 letters, error, 5 letters, info: 4 letters)
	sendMessage("INFO ", logger, message)
end

function sendErrorMessage(message, logger)
    logger = logger or "DefaultLogger"
	sendMessage("ERROR", logger, message)
end

function sendMessage(level, logger, message)
    if client then
        client:send(level .. " :: " .. logger .. " :: " .. message)
    end
end

initializeSocketConnection()

-- Use the function to send messages
sendDebugMessage("Steamodded Debug Socket started !")

----------------------------------------------
------------MOD DEBUG SOCKET END--------------
