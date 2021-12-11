from os import paramCount, commandLineParams
from strutils import split

proc main() =
  assert paramCount() > 0

  let 
    fullUrl = commandLineParams()[0]
    protocolAndUrl = fullUrl.split("://", 1)

  if protocolAndUrl.len != 2:
    echo "Invalid url."
    quit(QuitFailure)

  let protocol, url = protocolAndUrl

  echo protocol, url
  #case (protocol):
  #  of "http": requestHttp(url: url, https: false)
  #  of "https": requestHttp(url: url, https: false)
