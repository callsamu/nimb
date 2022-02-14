import sdl2
import pixie

const
  rmask = uint32 0x000000ff
  gmask = uint32 0x0000ff00
  bmask = uint32 0x00ff0000
  amask = uint32 0xff000000

proc imageToSurface*(data: ptr ColorRGBX, w, h: int): SurfacePtr =
  result = sdl2.createRGBSurfaceFrom(
    data, cint w, cint h, 
    cint 32, cint 4*w,
    rmask, gmask, bmask, amask
  )
