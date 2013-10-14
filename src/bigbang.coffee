# <!-- {{{1 -->
#
#     File        : bigbang.coffee
#     Maintainer  : Felix C. Stegerman <flx@obfusk.net>
#     Date        : 2013-10-14
#
#     Copyright   : Copyright (C) 2013  Felix C. Stegerman
#     Licence     : GPLv2 or GPLv3 or LGPLv3 or EPLv1
#
# <!-- }}}1 -->

# ...
#
# https://github.com/obfusk/bigbang.coffee
#
# License: GPLv2 or EPLv1.

# underscore + exports
# ---------------------------

U = this._ || require 'underscore'
B = -> B._call arguments...
if exports? then module.exports = B else this.bigbang = B


# requestAnimationFrame / polyfill
# ---------------------------

polyRequestAnimationFrame = (delay = 17) ->
    console.warn 'polyfilling *RequestAnimationFrame ...'
    (cb) -> window.setTimeout (-> cb +new Date), delay

# NB: using prefixed versions of requestAnimationFrame only b/c
# requestAnimationFrame itself uses relative timestamps; also:
# webkitRequestAnimationFrame seems to pass floating point timestamps.
B.anim = anim = window?.webkitRequestAnimationFrame ||
                window?.mozRequestAnimationFrame ||
                polyRequestAnimationFrame()


# main function + stop_with
# -----------

# TODO: on_key, fp!?
B._call = _call = (opts) ->                                     # {{{1
  done  = false
  world = opts.world
  tick  = (t) ->
    x = opts.on_tick world
    if x instanceof Stop
      world = x.world
      done  = true
    else
      world = x
      done  = true if opts.stop_when? world
    f = (if done && opts.on_stop then opts.on_stop else opts.on_draw)
    f(world)(opts.canvas)
    anim tick unless done
  anim tick
                                                                # }}}1

B.stop_with = stop_with = (w) -> new Stop w

class Stop
  constructor: (@world) ->
B.Stop = Stop


# image functions
# -----------

# create an empty scene
B.empty_scene = empty_scene = (width, height) -> (canvas) ->
  canvas.width = width; canvas.height = height

# overlay images, first on top of second ...; all images are lined up
# on their centers
B.overlay = overlay = (images...) -> (canvas) ->
  ctx = canvas.getContext '2d'
  for i in U.clone(images).reverse()
    console.log 'image:', i
    x = Math.round((canvas.width  - i.width ) / 2)
    y = Math.round((canvas.height - i.height) / 2)
    ctx.drawImage i, x, y

# create an image that draws a string
B.text = text = (string, fontsize, colour, $ = window?.$) ->
  (canvas) ->
    ctx = canvas.getContext '2d'
    ctx.save()
    ctx.font      = "#{fontsize} sans-serif"
    ctx.fillStyle = colour
    [w,h]         = measureText $, string, fontsize, 'sans-serif'
    x             = Math.round((canvas.width  - w) /2)
    y             = Math.round((canvas.height + h) /2)
    ctx.fillText string, x, y
    ctx.restore()

# place image onto scene with center at coordinates
B.place_image = place_image = (image, x, y, scene) -> (canvas) ->
  scene canvas
  ctx = canvas.getContext '2d'
  x_  = x - Math.round(image.width / 2)
  y_  = y - Math.round(image.height / 2)
  ctx.drawImage image, x_, y_


# miscellaneous functions
# -----------

B.measureText = measureText = ($, text, size, family) ->
  d = $ '<div>'
  d.css display: 'none', 'font-size': size, 'font-family': family
  $('body').append d
  w = d.width(); h = d.height()
  d.remove()
  [w,h]

# <!-- vim: set tw=70 sw=2 sts=2 et fdm=marker : -->
