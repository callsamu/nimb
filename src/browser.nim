import sdl2
import pixie as pix
import layout

type
  Browser* = ref object
    window*: WindowPtr
    renderer: RendererPtr
    screen: TexturePtr
    layout*: Layout
    scroll*: float32

const
  rmask = uint32 0x000000ff
  gmask = uint32 0x0000ff00
  bmask = uint32 0x00ff0000
  amask = uint32 0xff000000

proc newBrowser*(title: string): Browser =
  let 
    window = createWindow(title, 0, 0, 800, 600, 0)
    render = window.createRenderer(-1, Renderer_Accelerated)

  render.setDrawColor(0, 0, 0, 0)
  result = Browser(window: window, renderer: render)

proc destroy*(self: Browser) =
  destroyRenderer(self.renderer)
  destroy(self.window)

proc renderScreen*(self: Browser) =
  var image = pix.newImage(800, 600)

  let 
    maxHeight = self.window.getSize().y
    scroll = vec2(0, self.scroll)

  image.fill(rgba(255, 255, 255, 255))

  for (pos, span) in self.layout:
    let sPos = pos + scroll
    if sPos.y < 0: continue
    elif sPos.y > maxHeight.float: break

    image.fillText(
      span.font, 
      span.text,
      translate(sPos)
    )

  var 
    data = image.data[0].addr
    surface: SurfacePtr

  surface = sdl2.createRGBSurfaceFrom(
    data, cint 800, cint 600, 
    cint 32, cint 4*800, rmask, 
    gmask, bmask, amask
  )
  
  destroyTexture(self.screen)
  self.screen = self.renderer
    .createTextureFromSurface(surface)


proc display*(self: Browser) =
  self.renderer.clear()
  self.renderer.copy(self.screen, nil, nil)
  self.renderer.present()
 
