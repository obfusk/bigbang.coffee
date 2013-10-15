# <!-- {{{1 -->
#
#     File        : bigbang.coffee
#     Maintainer  : Felix C. Stegerman <flx@obfusk.net>
#     Date        : 2013-10-15
#
#     Copyright   : Copyright (C) 2013  Felix C. Stegerman
#     Licence     : GPLv2 or GPLv3 or LGPLv3 or EPLv1
#
# <!-- }}}1 -->

# ...
#
# https://github.com/obfusk/bigbang.coffee
#
# Licence: GPLv2 or GPLv3 or LGPLv3 or EPLv1.

# underscore + exports
# ---------------------------

U = this._ || require 'underscore'
B = -> B._call arguments...
if exports? then module.exports = B else this.bigbang = B


# requestAnimationFrame / polyfill
# ---------------------------

polyRequestAnimationFrame = (delay = 17) ->                     # {{{1
    console.warn 'polyfilling *RequestAnimationFrame ...'
    last = 0
    (cb) ->
      cur   = +new Date
      dt    = Math.max 0, delay - (cur - last)
      last  = cur + dt
      window.setTimeout (-> cb +new Date), dt
                                                                # }}}1

# NB: using prefixed versions of requestAnimationFrame only b/c
# requestAnimationFrame itself uses relative timestamps; also:
# webkitRequestAnimationFrame seems to pass floating point timestamps.
B.requestAnimationFrame = anim =
  window?.webkitRequestAnimationFrame ||
  window?.mozRequestAnimationFrame ||
  polyRequestAnimationFrame()


# main function + stop_with
# -----------

B._call = _call = (opts) ->                                     # {{{1
  world = opts.world; fps = opts.fps
  done  = opts.stop_when?(world) || false
  last  = +new Date

  draw = () ->
    f = if done && opts.on_stop then opts.on_stop else opts.on_draw
    f(world)(opts.canvas)

  change = (x) ->
    if x instanceof Stop
      world = x.world
      done  = true
    else
      world = x
      done  = true if opts.stop_when? world
    draw()

  key = (k) ->
    change opts.on_key(world, k) if opts.on_key

  tick = (t) ->
    if t - last > 1000/opts.fps
      last = t
      change opts.on_tick(world) if opts.on_tick
    anim tick unless done

  _handle_keys opts, key
  anim tick
                                                                # }}}1

B._handle_keys = _handle_keys = (opts, f) ->                    # {{{1
  $ = opts.$ || window.$
  $(opts.canvas).keydown (e) ->
    if !e.altKey && !e.ctrlKey && !e.metaKey &&
        e.which != keycodes.SHIFT
      k = _get_key e.which, e.shiftKey; f k if k
      k == null
    else
      true
                                                                # }}}1

# a-z, A-Z, 0-9, SHIFT_0..SHIFT_9, backspace..up, BACKSPACE..UP
B._get_key = _get_key = (w, s) ->                               # {{{1
  switch
    when keycodes.ALPHA.from <= w && w <= keycodes.ALPHA.to
      c = String.fromCharCode w
      if s then c else c.toLowerCase()
    when keycodes.NUM.from <= w && w <= keycodes.NUM.to
      c = String.fromCharCode w
      if s then "SHIFT_#{c}" else c
    else
      for k, v of keycodes
        if v == w
          return if s then k else k.toLowerCase()
      null
                                                                # }}}1

B.keycodes = keycodes =
 BACKSPACE: 8, COMMA: 188, DELETE: 46, DOWN: 40, END: 35, ENTER: 13,
 ESCAPE: 27, HOME: 36, LEFT: 37, PAGE_DOWN: 34, PAGE_UP: 33,
 PERIOD: 190, RIGHT: 39, SHIFT: 16, SPACE: 32, TAB: 9, UP: 38,
 ALPHA: { from: 65, to: 90 }, NUM: { from: 48, to: 57 }, # ...

B.stop_with = stop_with = (w) -> new Stop w

class Stop
  constructor: (@world) ->
B.Stop = Stop


# image functions
# -----------

# empty scene
B.empty_scene = empty_scene = (width, height) -> (canvas) ->
  canvas.width = width; canvas.height = height

# string with center at coordinates
B.place_text = place_text =                                     # {{{1
  (string, x, y, fontsize, colour, scene, $ = window.$) -> (canvas) ->
    scene canvas
    ctx = canvas.getContext '2d'
    ctx.save()
    ctx.font          = "#{fontsize} sans-serif"
    ctx.fillStyle     = colour
    ctx.textBaseline  = 'bottom'
    [w,h]             = measureText $, string, fontsize, 'sans-serif'
    ctx.fillText string, Math.round(x - w/2), Math.round(y + h/2)
    ctx.restore()
                                                                # }}}1

# image with center at coordinates
B.place_image = place_image = (image, x, y, scene) -> (canvas) ->
  scene canvas
  ctx = canvas.getContext '2d'
  x_  = x - Math.round(image.width  / 2)
  y_  = y - Math.round(image.height / 2)
  ctx.drawImage image, x_, y_


# miscellaneous functions
# -----------

B.measureText = measureText = ($, text, size, family) ->        # {{{1
  c = measureText.cache["#{size}|#{family}|#{text}"]
  return c if c
  d = $ '<div>'; d.text text
  d.css display: 'none', 'font-size': size, 'font-family': family
  $('body').append d
  w = d.width(); h = d.height()
  d.remove()
  measureText.cache["#{size}|#{family}|#{text}"] = [w,h]
measureText.cache = {}
                                                                # }}}1

# <!-- vim: set tw=70 sw=2 sts=2 et fdm=marker : -->
