net             = require 'net'
Generator       = require './lib/Generator'
consul          = (require 'consul')()

sockets = []
#check = Function()

server = net.createServer (socket) ->
  sockets.push socket
  console.log 'Client connected'
  if sockets.length == 1
    persons.start()

  socket.on 'close', () ->
    sockets.splice sockets.indexOf(socket), 1
    if sockets.length == 0
      persons.stop()
    console.log 'Client disconnected'

  socket.on 'data', (data) ->
    parsedData = JSON.parse(data)
    socket.check = Function(parsedData[0], parsedData[1])

  .on 'error', (error) ->
    console.log 'Server error: ' + error

# create a generator of data
persons = new Generator [ "first", "last", "gender", "birthday", "age", "ssn"]

# distribute data over the websockets
persons.on "data", (data) ->
  data.timestamp = Date.now()
  for socket in sockets
    do (socket) ->
      if socket.check && !socket.check(data)
        return
      socket.write JSON.stringify(data)

server.listen(1338, 'localhost')

personService =
  name: 'persons'
  tags: ['generator']
  address: '127.0.0.1'
  port: 1338

consul.agent.service.register personService, (err) ->
  if err
    console.log 'Service register error: ' + err