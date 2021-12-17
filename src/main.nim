import sdl2
from network import request
from pixie as pix import nil

proc main(arg: string) =
  init(INIT_EVERYTHING)

  var
    window = createWindow("test", 0, 0, 800, 600, 0)
    render = window.createRenderer(-1, Renderer_Accelerated)

  render.setDrawColor(0, 0, 0, 0)
  render.present()
  delay(4000)


main("")

