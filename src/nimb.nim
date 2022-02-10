import sdl2, os
import browser, layout
from network/net import request
   
proc main(url: string) =
  sdl2.init(INIT_EVERYTHING)

  var
    browser = newBrowser("brOwOser")
    evt: sdl2.Event
  
  browser.layout = newLayout(request(url), 800)

  while true:
    while (sdl2.pollEvent(evt)):
      case evt.kind:
        of QuitEvent:
          browser.destroy()
          return
        of KeyDown:
          case evt.key.keysym.scancode:
            of SDL_SCANCODE_UP:
              browser.scroll += 2.0
            of SDL_SCANCODE_DOWN:
              browser.scroll -= 2.0
            of SDL_SCANCODE_SPACE:
              browser.scroll -= 600.0
            else: discard
        else: discard
    browser.renderScreen()
    browser.display()

when isMainModule:
  if paramCount() <= 0:
    echo "Please, provide and URL"
  else:
    main(commandLineParams()[0])

