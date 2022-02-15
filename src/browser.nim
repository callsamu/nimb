import sdl2
import pixie as pix
import layout, helpers

const 
  InterestYFactor = 2

type
  Browser* = ref object
    window*: WindowPtr
    renderer: RendererPtr
    screen: TexturePtr
    clip: sdl2.Rect
    w,h : int
    layout*: Layout
    scroll: float
    interestRegion: tuple[y1: float, y2: float]

proc newBrowser*(title: string, w, h: int): Browser =
  let 
    window = createWindow(title, 0, 0, cint w, cint h, 0)
    render = window.createRenderer(-1, 
      Renderer_Accelerated or Renderer_PresentVsync
    )
    clip = sdl2.rect(0, 0, cint w, cint h)

  render.setDrawColor(0, 0, 0, 0)
  result = Browser(
    window: window, 
    renderer: render, 
    clip: clip,
    w: w, h: h
  )

proc destroy*(self: Browser) =
  destroyRenderer(self.renderer)
  destroy(self.window)

proc renderRegion(self: Browser) =
  let 
    width = int self.w
    y1 = self.interestRegion.y1
    y1Vector = vec2(0, y1)
    y2 = self.interestRegion.y2
    height = int (y2 - y1)

  var image = pix.newImage(width, height)
  image.fill(rgba(255, 255, 255, 255))

  for (pos, span) in self.layout.display:
    let pos = pos - y1Vector
    if   pos.y < 0: continue
    elif pos.y > y2: break
    image.fillText(span.font, span.text, translate(pos))

  let 
    data = image.data[0].addr
    surface = imageToSurface(data, width, height)

  destroyTexture(self.screen)
  self.screen = self.renderer
    .createTextureFromSurface(surface)

proc isInInterestRegion(self: Browser): bool =
  let scrollY = self.scroll

  return self.interestRegion.y1 <= scrollY and
    scrollY + (float self.h) <= self.interestRegion.y2

proc computeInterestRegion(self: Browser) =
  let
    h = float(self.h * InterestYFactor)
    y1 = max(0, self.scroll - h)
    y2 = min(self.layout.height, self.scroll + h)

  self.interestRegion.y1 = y1
  self.interestRegion.y2 = y2

proc scroll*(self: Browser, dy: float) {.inline.} =
  let  scrollY = self.scroll + dy
  self.scroll = clamp(scrollY, 0, self.layout.height)

proc render*(self: Browser) =
  if not self.isInInterestRegion() or self.screen == nil:
    self.computeInterestRegion()
    self.renderRegion()

proc display*(self: Browser) =
  self.clip.y = cint self.scroll - self.interestRegion.y1
  self.renderer.copy(self.screen, addr self.clip, nil)
  self.renderer.present()
