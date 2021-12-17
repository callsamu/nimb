import sdl2
import pixie as pix
from network import request

const
  rmask = uint32 0x000000ff
  gmask = uint32 0x0000ff00
  bmask = uint32 0x00ff0000
  amask = uint32 0xff000000

proc makeTexture(renderer: RendererPtr): TexturePtr =
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
  
  result = renderer.createTextureFromSurface(surface)
    
proc main(arg: string) =
  sdl2.init(INIT_EVERYTHING)

  var
    window = createWindow("test", 0, 0, 800, 600, 0)
    render = window.createRenderer(-1, Renderer_Accelerated)
    texture = render.makeTexture()
    evt: sdl2.Event

  render.setDrawColor(0, 0, 0, 0)
  render.clear()
  render.copy(texture, nil, nil)
  render.present()

  while true:
    while (sdl2.pollEvent(evt)):
      case evt.kind:
        of QuitEvent:
          destroyRenderer(render)
          destroyTexture(texture)
          destroy(window)
          return
        else: discard


main("")

