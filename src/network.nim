import std/net
import std/tables
from std/strutils import split, find, parseInt

import unpack

const
  defaultHttpPort = 80
  defaultHttpsPort = 432
  maxSchemeLength = 16

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

proc buildRequest(host, path: string): string =
  result &= "GET /" & path & " HTTP/1.0\r\n" 
  result &= "Host: " & host & "\r\n\r\n"

proc getStatus(socket: Socket): Status =
  var line: string
  socket.readLine(line)

  [_, code, message] <- line.split(' ', 2)
  result = Status(code: parseInt(code), message: message)

proc makeConnection(s: Socket, host: string, ssl: bool) =
  var port: int
  if ssl:
    port = 443
    newContext().wrapSocket(s)
  else:
    port = 80

  s.connect(host, Port(port))

proc makeConnection(s: Socket, host: string, ssl: bool, port: int) =
  if ssl: newContext().wrapSocket(s)
  s.connect(host, Port(port))

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

proc sendRequest(s: Socket, url: string, ssl: bool) =
  var hostName: string

  [host, path] <- url.split('/')

  if ':' in host:
    [name, port] <- host.split(':')
    echo port
    hostName = name
    s.makeConnection(hostName, ssl, port.parseInt())
  else:
    hostName = host
    s.makeConnection(hostName, ssl)

  s.send(buildRequest(hostName, path))

proc requestHttp(url: string, https: bool = false): Response =
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

proc getScheme(url: string): (string, string) =
  let schemeEnd = find(url, "://", last=maxSchemeLength)

  if 0 > schemeEnd:
     result = ("https", url)
  else:
    result = (url[0..schemeEnd-1], url[schemeEnd+3..^1])

proc request*(fullUrl: string): string =
  let (scheme, url) = fullUrl.getScheme()
  var response: Response

  case (scheme):
    of "http": response = url.requestHttp(https = false)
    of "https": response = url.requestHttp(https = true)
  
  result = response.body.parseHtml
