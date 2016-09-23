# required modules
_              = require "underscore"
async          = require "async"
http           = require "http"
express        = require "express"
path           = require "path"
methodOverride = require "method-override"
bodyParser     = require "body-parser"
socketio       = require "socket.io"
errorHandler   = require "error-handler"
net 					 = require "net"
fetch					 = require "node-fetch"

log       = require "./lib/log"
Generator = require "./lib/Generator"

app       = express()
server    = http.createServer app
io        = socketio.listen server

# collection of client sockets
sockets = []

persons = new net.Socket({objectMode: true});

check = (obj) ->
	return obj.age < 35 && obj.age > 25

connectToServer = (address = 'localhost', port = '8500') ->
	fetch "http://#{address}:#{port}/v1/catalog/service/persons"
	.then (res) ->
		return res.json()
	.then (service) ->
		console.log 'Got service: ', service[0].ServiceAddress, service[0].ServicePort
		persons.connect service[0].ServicePort, service[0].ServiceAddress, () ->
			log.info 'Connected'
#			We pass a check for the server to perform on the data before emitting it
			persons.write JSON.stringify([['obj'], 'return obj.age < 35 && obj.age > 25'])

connectToServer()

persons.on 'data', (data) ->
	parsedData = JSON.parse(data)
	parsedData.timestamp = Date.now()
	socket.emit "persons:create", parsedData for socket in sockets

persons.on 'error', (error) ->
	log.info 'Connection error: ' + error

persons.on 'close', (e) ->
	log.info 'Connection closed ' + e
	persons.setTimeout 5000, () ->
		log.info 'Trying to reconnect'
		connectToServer()


# websocket connection logic
io.on "connection", (socket) ->
	# add socket to client sockets
	sockets.push socket
	log.info "Socket connected, #{sockets.length} client(s) active"

	# disconnect logic
	socket.on "disconnect", ->
		# remove socket from client sockets
		sockets.splice sockets.indexOf(socket), 1
		log.info "Socket disconnected, #{sockets.length} client(s) active"

# express application middleware
app
	.use bodyParser.urlencoded extended: true
	.use bodyParser.json()
	.use methodOverride()
	.use express.static path.resolve __dirname, "../client"

# express application settings
app
	.set "view engine", "jade"
	.set "views", path.resolve __dirname, "./views"
	.set "trust proxy", true

# express application routess
app
	.get "/", (req, res, next) =>
		res.render "main"

# start the server
server.listen 3000
log.info "Listening on 3000"
