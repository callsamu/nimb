import sdl2
import pixie as pix
from network import request

const
  rmask = uint32 0x000000ff
  gmask = uint32 0x0000ff00
  bmask = uint32 0x00ff0000
  amask = uint32 0xff000000

type
  Browser = ref object
    window: WindowPtr
    renderer: RendererPtr
    screen: TexturePtr

proc newBrowser(title: string): Browser =
  let 
    window = createWindow(title, 0, 0, 800, 600, 0)
    render = window.createRenderer(-1, Renderer_Accelerated)

  render.setDrawColor(0, 0, 0, 0)
  result = Browser(window: window, renderer: render)

proc destroy(self: Browser) =
  destroyRenderer(self.renderer)
  destroy(self.window)

proc renderScreen(self: Browser) =
  var 
    image = pix.newImage(800, 600)
    ctx = newContext(image)

  ctx.fillStyle = pix.rgba(0, 0, 0, 255)
  ctx.fillRect(0, 0, 800, 600)
  ctx.fillStyle = pix.rgba(0, 0, 255, 255)
  ctx.fillRect(0, 0, 400, 300)

  var 
    data = ctx.image.data[0].addr
    surface: SurfacePtr

  surface = sdl2.createRGBSurfaceFrom(
    data, cint 800, cint 600, 
    cint 32, cint 4*800, rmask, 
    gmask, bmask, amask
  )
  
  self.screen = self.renderer
    .createTextureFromSurface(surface)

proc display(self: Browser) =
  self.renderer.clear()
  self.renderer.copy(self.screen, nil, nil)
  self.renderer.present()
    
proc main(arg: string) =
  sdl2.init(INIT_EVERYTHING)

  var
    browser = newBrowser("brOwOser")
    evt: sdl2.Event

  while true:
    while (sdl2.pollEvent(evt)):
      case evt.kind:
        of QuitEvent:
          browser.destroy()
          return
        else: discard
    browser.renderScreen()
    browser.display()


main("")

