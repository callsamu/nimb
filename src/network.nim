import std/net, std/tables, std/uri
from std/strutils import split, find, parseInt

import unpack

type 
  Headers = Table[string, string]
  Status  = object
    code: int 
    message: string
  Response = object
    status: Status
    headers: Headers
    body: string

proc parseHeaders(headers: seq[string]): Headers =
  for h in headers:
    [header, value] <- h.split(":")
    result[header] = value

proc getStatus(socket: Socket): Status =
  var line: string
  socket.readLine(line)

  [_, code, message] <- line.split(' ', 2)
  result = Status(code: parseInt(code), message: message)

proc getResponse(s: Socket): Response =
  let status = s.getStatus()

  var 
    buffer, body: string
    headerLines: seq[string]

  while true:
    s.readLine(buffer)
    if buffer == "\c\n": break
    headerLines.add(buffer)
  let headers = parseHeaders(headerLines)

  while s.recv(buffer, 1024) > 0: 
    body &= buffer

  result = Response(
    status: status, 
    headers: headers, 
    body: body
  )

proc buildRequest(host, path: string): string =
  result &= "GET /" & path & " HTTP/1.0\r\n" 
  result &= "Host: " & host & "\r\n\r\n"

proc makeConnection(s: Socket, url: URI, ssl: SslContext = nil) =
  if ssl != nil:
    ssl.wrapSocket(s)
  s.connect(url.hostName, Port(url.port.parseInt))

proc sendRequest(s: Socket, url: URI, ssl: bool) =
  if ssl: s.makeConnection(url, newContext()) 
  else: s.makeConnection(url)

  s.send(buildRequest(url.hostName, url.path))

proc requestHttp(url: URI, https: bool = false): Response =
  let s = newSocket()
  s.sendRequest(url, https)
  result = s.getResponse()

proc parseHtml(html: string): string =
  var 
    inTag, inHead, closing = false
    currentTag: string

  for c in html:
    case c:
      of '<': 
        inTag = true
        currentTag = ""
      of '/':
        closing = true
        continue
      of '>':
        inTag = false
        if currentTag == "head":
          inHead = not inHead
      else:
        if not inTag:
          if not inHead:
            result &= c
        else:
          currentTag &= c
    closing = false

proc request*(url: string): string =
  var 
    url = parseUri(url)
    response: Response

  case (url.scheme):
    of "http": 
      if url.port == "": url.port = "8000"
      response = url.requestHttp(https = false)
    of "https": 
      if url.port == "": url.port = "432"
      response = url.requestHttp(https = true)
  
  result = response.body.parseHtml
