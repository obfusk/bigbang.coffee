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

# graphical functional programming for js/coffee
#
# Create graphical programs (like games) in coffeescript or javascript
# using plain mathematical functions; inspired by the 2htdp library
# for racket.
#
# https://github.com/obfusk/bigbang.coffee
#
# License: GPLv2 or GPLv3 or LGPLv3 or EPLv1.

# underscore + exports
# --------------------

U = this._ || require 'underscore'
B = -> B._call arguments...
if exports? then module.exports = B else this.bigbang = B


# requestAnimationFrame & polyfill
# --------------------------------

# requestAnimationFrame polyfill
polyRequestAnimationFrame = (delay = 17) ->                     # {{{1
    console.warn 'polyfilling *RequestAnimationFrame ...'
    last = 0
    (cb) ->
      cur   = +new Date
      dt    = Math.max 0, delay - (cur - last)
      last  = cur + dt
      window.setTimeout (-> cb +new Date), dt
                                                      #  <!-- }}}1 -->

# NB: we use the prefixed versions of requestAnimationFrame b/c
# requestAnimationFrame itself uses relative timestamps; also good to
# know: webkitRequestAnimationFrame uses floating point timestamps.
B.requestAnimationFrame = anim =
  window?.webkitRequestAnimationFrame ||
  window?.mozRequestAnimationFrame ||
  polyRequestAnimationFrame()


# main function, keys, and stop_with
# ----------------------------------

# <!-- {{{1 -->
#
# big bang: start a new universe whose behaviour is specified by the
# options and handler functions designated
#
#     bigbang
#       canvas:       html5_canvas,
#       fps:          int,
#       world:        object,
#       on_tick:      ((world) -> new_world),
#       on_key:       ((world, key) -> new_world),
#       to_draw:      ((world) -> image),
#       stop_when:    ((world) -> boolean),
#       last_picture: ((world) -> image)
#
# ### Options
#
#   * `canvas` is the HTML5 canvas to draw on
#   * `fps` is the requested frame rate (defaults to 60)
#   * `world` is the object representing the initial world
#   * `on_tick` is called every clock tick to update the world
#     (optional)
#   * `on_key` is called every time a key is pressed to update the
#     world (optional)
#   * `to_draw` is called every time a new world needs to be drawn
#   * `stop_when` is called to determine if the universe needs to stop
#     (optional)
#   * `last_picture` is called instead of `to_draw` to draw the last
#     world (optional)
#
# <!-- ... -->
#
# To stop the world from `on_tick` or `on_key`, return
# `stop_with(new_world)` instead of `new_world`.
#
# ### Key presses
#
# The key pressed handled are a-z, 0-9 and the keys in keycodes, with
# and without shift.  a-z without shift is returned as "a"-"z"; A-Z
# with shift is returned as "A"-"Z"; 0-9 without shift is returned as
# "0"-"9"; 0-9 with shift is returned as "SHIFT_0".."SHIFT_9"; the
# other key codes are retured as the keys in keycodes, lowercase
# without shift (e.g. "left"), uppercase with shift (e.g. "HOME").
#
# <!-- }}}1 -->
B._call = _call = (opts) ->                                     # {{{1
  world   = opts.world; fps = opts.fps || 60
  done    = opts.stop_when?(world) || false
  last    = +new Date
  changed = false

  draw = () ->
    f = if done && opts.last_picture
      opts.last_picture
    else
      opts.to_draw
    f(world)(opts.canvas)

  change = (x) ->
    if x instanceof _Stop
      world = x.world
      done  = true
    else
      world = x
      done  = true if opts.stop_when? world
    cancel_keys?() if done
    changed = true

  key = (k) -> change opts.on_key(world, k) if opts.on_key

  tick = (t) ->
    if t - last > 1000 / opts.fps
      last = t
      change opts.on_tick(world) if opts.on_tick
    if changed
      draw(); changed = false
    anim tick unless done

  cancel_keys = _handle_keys opts, key
  anim tick
                                                      #  <!-- }}}1 -->

# key codes
B.keycodes = keycodes =
  BACKSPACE: 8, COMMA: 188, DELETE: 46, DOWN: 40, END: 35, ENTER: 13,
  ESCAPE: 27, HOME: 36, LEFT: 37, PAGE_DOWN: 34, PAGE_UP: 33,
  PERIOD: 190, RIGHT: 39, SHIFT: 16, SPACE: 32, TAB: 9, UP: 38,

# key ranges
B.keyranges = keyranges =
  ALPHA: { from: 65, to: 90 }, NUM: { from: 48, to: 57 }, # ...

# stop the universe; see bigbang
B.stop_with = stop_with = (w) -> new _Stop w

# wrapper class for stop_with
class _Stop
  constructor: (@world) ->
B._Stop = _Stop

# handle key presses
B._handle_keys = _handle_keys = (opts, f) ->                    # {{{1
  $ = opts.$ || window.$
  h = (e) ->
    if !e.altKey && !e.ctrlKey && !e.metaKey &&
        e.which != keycodes.SHIFT
      k = _get_key e.which, e.shiftKey; f k if k
      k == null
    else
      true
  $(opts.canvas).on 'keydown', h
  -> $(opts.canvas).off 'keydown', h
                                                      #  <!-- }}}1 -->

# turn key press into something usable
B._get_key = _get_key = (w, s) ->                               # {{{1
  switch
    when keyranges.ALPHA.from <= w && w <= keyranges.ALPHA.to
      c = String.fromCharCode w
      if s then c else c.toLowerCase()
    when keyranges.NUM.from <= w && w <= keyranges.NUM.to
      c = String.fromCharCode w
      if s then "SHIFT_#{c}" else c
    else
      for k, v of keycodes
        if v == w
          return if s then k else k.toLowerCase()
      null
                                                      #  <!-- }}}1 -->


# image functions
# ---------------

# empty scene
B.empty_scene = empty_scene = (width, height) -> (canvas) ->
  canvas.width = width; canvas.height = height

# text with center at coordinates
B.place_text = place_text =                                     # {{{1
  (string, x, y, fontsize, colour, scene, $ = window.$) -> (canvas) ->
    scene canvas
    ctx = canvas.getContext '2d'
    ctx.save()
    ctx.font          = "#{fontsize} sans-serif"
    ctx.fillStyle     = colour
    ctx.textBaseline  = 'bottom'
    [w,h]             = measureText $, string, fontsize, 'sans-serif'
    ctx.fillText string, Math.round(x - w / 2), Math.round(y + h / 2)
    ctx.restore()
                                                      #  <!-- }}}1 -->

# image with center at coordinates
B.place_image = place_image = (image, x, y, scene) -> (canvas) ->
  scene canvas
  ctx = canvas.getContext '2d'
  x_  = x - Math.round(image.width  / 2)
  y_  = y - Math.round(image.height / 2)
  ctx.drawImage image, x_, y_

# ... TODO: more image functions ...


# miscellaneous functions
# -----------------------

# measure text height and width using a temporary hidden div
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
                                                      #  <!-- }}}1 -->

# <!-- vim: set tw=70 sw=2 sts=2 et fdm=marker : -->
