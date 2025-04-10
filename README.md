# Evo-GW

This is a project that will receive connections from evo, and will expose them to the PTRP main project.

- [About](#About)
- [Prerequisites](#Prerequisites)
- [Installation](#installation)
- [How to use](#how-to-use)

---

## About

The application is a web solution developed in **Ruby** and **Sinatra**, designed to intermediate communication between **time clocks** (initially from the Evo line) and **PTRP** through a **WebSocket server**. The system receives data from the time clocks, applies authentication and encryption, and securely forwards it to PTRP.

In addition to processing and forwarding received data, the application allows PTRP to send specific commands to the time clocks, enabling operations such as **user registration, listing, and deletion**.

The primary purpose of this gateway is to **overcome the lack of TLS support in time clocks**, which makes direct connection to PTRP unfeasible. By handling and adapting requests before forwarding them, the system ensures secure and functional communication, eliminating this limitation and enabling seamless integration.  

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

`cd /path/of/project`

**start the application and view the connection logs**

`docker compose up`

**start the application without displaying connection logs**

`docker compose up -d`

---

## How to use

### Connecting a client to the Websocket server in linux terminal

If you do not have the wscat tool installed on your host, use the command:

`npm install -g wscat`

After the wscat tool is installed use the command:

`wscat -c ws://localhost:4567`

In the terminal where the server is running,  
a log will be displayed confirming the client's connection to the websocket server.

`app-1  | 172.18.0.1 - - [11/Mar/2025:20:53:54 +0000] "GET / HTTP/1.1" -1 - 0.0048`  
`app-1  | Cliente conectado: 172.18.0.1`






