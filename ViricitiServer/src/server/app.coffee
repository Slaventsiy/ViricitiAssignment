net             = require 'net'
Generator       = require './lib/Generator'
consul          = (require 'consul')()

sockets = []

server = net.createServer (socket) ->
  sockets.push socket
  console.log 'Client connected'

  socket.on 'close', () ->
    sockets.splice sockets.indexOf(socket), 1
    console.log 'Client disconnected'

  .on 'error', (error) ->
    console.log 'Server error: ' + error

# create a generator of data
persons = new Generator [ "first", "last", "gender", "birthday", "age", "ssn"]

# distribute data over the websockets
persons.on "data", (data) ->
  data.timestamp = Date.now()
  socket.write JSON.stringify(data) for socket in sockets

persons.start()

server.listen(1338, 'localhost')

personService =
  name: 'persons'
  tags: ['generator']
  address: '127.0.0.1'
  port: 1338

consul.agent.service.register personService, (err) ->
  if err
    console.log 'Service register error: ' + err