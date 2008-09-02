= Free Message Queue (FMQ)

Project website: http://fmq.rubyforge.org/

Project github repositiory: git://github.com/threez/fmq.git

== TODO:

* add client apis for other languages
* complete unit tests

== DESCRIPTION:

The project implements a queue system with a server and some client apis.

The server is a rack server that holds REST-named queues, so that the 
implemention can be changed rapidly. You can GET, POST, DELETE, HEAD queue 
messages using the normal HTTP requests. The system itself uses a configuration 
file (*config.ru*) to setup queues at startup or even at runtime. The queue 
implementations can be changed or you can develep own queues with ease. 

For an simple administration try out the integrated ajax based web interface.

The client apis are implemented using the HTTP protocol, so that you can 
use even curl to receive messages. A client library for ruby is implemented 
right now, other languages will follow.

The queue itself is a RESTful url like http://localhost:5884/myQueueName/
or http://localhost:5884/myApplication/myQueueName/. If you do a GET request 
to this url with a web browser you will receive one message from the queue.

== FEATURES/PROBLEMS:

* FIFO message store
* easy setup and maintenance of system (rack)
* using http for communication
* changeable queue implementation
* ruby client lib
* simple ajax admin interface
* implements a rack server stack

== SYNOPSIS:

After installing the gem you can start by creating a project:

  fmq create my_project_name
  
next step is to change to the folder and start the FMQ server:

  cd my_project_name
  rackup -p 5884

The server will start and host a admin interface on http://localhost:5884/admin/index.html.

== REQUIREMENTS:

* rack >= 0.4.0 (web server provider)

== INSTALL:

Just install the gem as you expect:

  sudo gem install fmq

== LICENSE:

(GNU GENERAL PUBLIC LICENSE, Version 3)

Copyright (c) 2008 Vincent Landgraf
