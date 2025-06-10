# Evo-GW

This is a project that will receive connections from evo and expose them to the main PTRP project.

- [About](#About)

- [Prerequisites](#Prerequisites)

- [Installation](#installation)

- [How to use](#how-to-use)

---

## About

The application is a web solution developed in **Ruby**, **Rack-app(DSL rack based on sinatra)** and redis and was designed to mediate communication between **face readers** and **PTRP** through a **WebSocket server**. Readers can send or receive commands from the websocket server and to manage this delivery, Redis, through the PUB/SUB service, creates exclusive channels for each reader that establishes a connection with the websocket server, allowing the command to be sent to a specific reader, enabling operations such as **user registration, listing, updating and deleting**.

The main objective of this gateway is to **overcome the lack of TLS support in facial readers**, which makes direct connection to the PTRP impossible. By processing and adapting requests before forwarding them, the system ensures secure and functional communication, eliminating this limitation and allowing integration between readers and the PTRP.

---

## Prerequisites

- **Docker**
- **docker compose**

---

## Installation

**cloning with ssh:**

- **`git@gitlab.pontogestor.com:pontogestor/evo-gw.git`**

**cloning with https:**

- **`https://gitlab.pontogestor.com/pontogestor/evo-gw.git`**

**start the application**

`cd /path/to/project`

**start the application and view the connection logs**

`docker compose up`

**start the application without displaying the connection logs**

`docker compose up -d`

**Checking the connection between a client and the websocket server**

- From the linux terminal:

`wscat -c ws://localhost:9292/pub/chat`

- By insomnia:

Create a tab for websoket requests and enter the following address in the URL:

`ws://localhost:9292/pub/chat`

---

## How to use

With one or more facial readers connected, it is possible to simulate commands by insomnia using the POST method. User registration commands, for example, require a body with an array containing id, name and password. To generate this data, there is a script in the project root for generating users using faker that can be changed for as many users as desired.

After starting the server, open another tab and type the following command:
`ruby mock_usuarios.rb`

A mock_usuarios.json file will be generated with the fake data

- Register and update users
  `http://localhost:9292/pub/chat/serial_number_of_the_reader/set_user_info`

and in the body, put one or more users that you want to register in the reader,

- List registered users
  `http://localhost:9292/pub/chat/serial_number_of_the_reader/user_list`

Since this is a search command, it does not need a body

- Clear all users from the reader
  `http://localhost:9292/pub/chat/serial_number_of_the_reader/clean_user`
  This command also does not need a body

## Unit tests

For testing, use the command in the root of the project:

`rspec`

To test specific directories use:
`rspec spec/../../.......`