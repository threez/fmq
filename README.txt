= Free Message Queue (FMQ)

Project website: http://fmq.rubyforge.org/

Project github repositiory: git://github.com/threez/fmq.git

== TODO:

* create full rdoc
* support of logging to file
* add client apis for other languages
* complete unit tests

== DESCRIPTION:

The project implements a queue system with a server and some client apis.

The server is a mongrel web server that holds REST-named queues. 
You can GET, POST, DELETE, HEAD queue messages using the normal HTTP requests. 
The system itself uses a configuration file (YAML) to setup queues at 
startup or even at runtime. The queue implementations can be changed using 
an easy plugin system right from your project directory.

For an simple administration and try out of the system, FMQ has an integrated ajax based web interface.

The client apis are implemented using the HTTP protocol, so that 
you can use even curl to receive messages. Ruby is implemented right now, other languages will follow.

The queue itself is an URL like http://localhost:5884/myQueueName/ 
or http://localhost:5884/myApplication/myQueueName/. If you do a GET request to 
this url with a web browser you will receive one message from the queue. The queue 
stores it’s internal data in an FIFO in system memory.

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
  fmq

The server will start and host a admin interface on http://localhost:5884/admin/index.

== REQUIREMENTS:

* mongrel (as webserver)

== INSTALL:

Just install the gem as you expect:

  sudo gem install fmq

== LICENSE:

(GNU GENERAL PUBLIC LICENSE, Version 3)

Copyright (c) 2008 Vincent Landgraf