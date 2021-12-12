import std/net
import std/tables
from std/strutils import split, parseInt
from std/os import paramCount, commandLineParams

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

proc parseStatus(status: string): Status =
  [_, c, m] <- status.split(' ', 2)
  result = Status(code: c.parseInt, message: m)

proc parseHeaders(headers: seq[string]): Headers =
  for h in headers:
    [header, value] <- h.split(":")
    result[header] = value

proc buildRequest(host, path: string): string =
  result &= "GET /" & path & " HTTP/1.0\r\n" 
  result &= "Host: " & host & "\r\n\r\n"

proc requestHttp(url: string, https: bool = false): Response =
  let s = newSocket()
  [host, path] <- url.split('/', 1)

  s.connect(host, Port(80))
  s.send(buildRequest(host, path))
  
  var line: string

  s.readLine(line)
  let status = parseStatus(line)

  var headerStrings: seq[string]

  while true:
    s.readLine(line)
    if line == "\c\n": break
    headerStrings.add(line)

  let headers = parseHeaders(headerStrings)

  var body, buffer: string
  while s.recv(buffer, 1024) > 0: 
    body &= buffer

  result = Response(
    status: status, 
    headers: headers, 
    body: body
  )

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

proc main() =
  let 
    fullUrl = commandLineParams()[0]
    protocolAndUrl = fullUrl.split("://", 1)

  if protocolAndUrl.len != 2:
    echo "Invalid url."
    quit(QuitFailure)

  let 
    protocol = protocolAndUrl[0]
    url = protocolAndUrl[1]

  var response: Response

  case (protocol):
    of "http": response = url.requestHttp(https = false)
    of "https": response = url.requestHttp(https = true)
  
  echo response.body.parseHtml

main()
