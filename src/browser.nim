import sdl2
import pixie as pix
import layout, helpers

type
  Browser* = ref object
    window*: WindowPtr
    renderer: RendererPtr
    screen: TexturePtr
    layout*: Layout
    scroll*: float32

proc newBrowser*(title: string): Browser =
  let 
    window = createWindow(title, 0, 0, 800, 600, 0)
    render = window.createRenderer(-1, 
      Renderer_Accelerated or Renderer_PresentVsync
    )

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

  for (pos, span) in self.layout.display:
    let sPos = pos + scroll
    if sPos.y < 0: continue
    elif sPos.y > maxHeight.float: break

    image.fillText(
      span.font, 
      span.text,
      translate(sPos)
    )

  let 
    data = image.data[0].addr
    surface = imageToSurface(data, 800, 600)

  destroyTexture(self.screen)
  self.screen = self.renderer
    .createTextureFromSurface(surface)


proc display*(self: Browser) =
  self.renderer.clear()
  self.renderer.copy(self.screen, nil, nil)
  self.renderer.present()
 
