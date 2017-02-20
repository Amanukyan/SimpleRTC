var app = require('express')();
var http = require('http').Server(app);
var io = require('socket.io')(http);

app.get('/', function(req, res){
  res.send('RTC server');
});

http.listen(3000, function(){
  console.log('Listening on *:3000');
});



io.on('connection', function(clientSocket){
  console.log('A user connected');

  clientSocket.on('disconnect', function(){
    console.log('User disconnected');
  });


  clientSocket.on("signalingMessage", function(message){
    console.log('recieved signalingMessage');
    console.log(message);
    io.emit("signalingMessage", message)
  });

  clientSocket.on("startType", function(clientNickname){
    console.log("test");
  });

});