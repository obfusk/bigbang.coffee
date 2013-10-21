# <!--
###
# {{{1 -->
#
#     File        : bigbang.coffee
#     Maintainer  : Felix C. Stegerman <flx@obfusk.net>
#     Date        : 2013-10-21
#
#     Copyright   : Copyright (C) 2013  Felix C. Stegerman
#     Licence     : GPLv2 or GPLv3 or LGPLv3 or EPLv1
#
# <!-- }}}1
###
# -->

# graphical/evented functional programming for js/coffee
#
# Create graphical and evented programs (like games) in coffeescript
# or javascript using plain mathematical functions; inspired by the
# 2htdp library for racket.
#
# https://github.com/obfusk/bigbang.coffee
#
# License: GPLv2 or GPLv3 or LGPLv3 or EPLv1.

# underscore + exports
# --------------------

U = this._ || require 'underscore'
B = -> B.bigbang arguments...
if exports? then module.exports = B else this.bigbang = B


# requestAnimationFrame & polyfill
# --------------------------------

# requestAnimationFrame polyfill
B.polyRequestAnimationFrame = polyRequestAnimationFrame =       # {{{1
  (delay = 17) ->
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


# bigbang & stop_with
# -------------------

# <!-- {{{1 -->
#
# big bang: start a new universe whose behaviour is specified by the
# options and handler functions designated
#
#     bigbang
#       canvas:       element,
#       fps:          int,
#       world:        object,
#       on_tick:      ((world) -> new_world),
#       on_key:       ((world, key) -> new_world),
#       on_click:     ((world, x, y) -> new_world),
#       on:           { foo: ((world, ...) -> new_world), ... },
#       to_draw:      ((world) -> scene),
#       stop_when:    ((world) -> boolean),
#       last_picture: ((world) -> scene),
#       setup:        ((canvas, handlers) -> setup_value),
#       teardown:     ((canvas, handlers, setup_value) ->
#                         teardown_value)
#       on_stop:      ((world, teardown_value) -> ...),
#
# Options:
#
#   * `canvas` is the HTML5 canvas to draw on
#   * `fps` is the requested frame rate (defaults to 60)
#   * `world` is the object representing the initial world
#   * (optional) `on_tick` is called every clock tick to update the
#     world
#   * (optional) `on_key` is called every time a key is pressed to
#     update the world
#   * (optional) `on_click` is called every time the mouse is clicked
#     inside the canvas to update the world
#   * (optional) `on` contains handlers for user-defined events;
#     `setup` and `teardown` are used to connect handlers to elements
#     and events; when the user-defined event is triggered, the
#     appropriate function is called
#   * `to_draw` is called every time a new world needs to be drawn
#   * (optional) `stop_when` is called to determine if the universe
#     needs to stop
#   * (optional) `last_picture` is called instead of `to_draw` to draw
#     the last world
#   * (optional) `setup` is called before the universe starts; the
#     handlers are the internal event handlers for `on` which `setup`
#     is expected to connect to the appropriate elements and events
#   * (optional) `teardown` is called after the universe has ended,
#     before on_stop; the handlers are the same as passed to `setup`
#     and can be used to cancel the event handling
#   * (optional) `on_stop` is called after the universe has ended,
#     after teardown
#
# <!-- ... -->
#
# The canvas need not be an actual canvas: it can be any element you
# wish to "draw" the world with.  It can be (part of) the body of an
# event-driven page.  In this case, you will also have a different
# concept of "scene".
#
# To stop the world from `on_tick` or `on_key`, return
# `stop_with(new_world)` instead of `new_world`.
#
# For details on key press handling, see `handle_keys`.  If you want
# to use a different key press handling library, set the `handle_keys`
# option to a function with the same api as `handle_keys`.
#
# For details on mouse click handling, see `handle_click`.
#
# <!-- }}}1 -->
B.bigbang = (opts) ->                                           # {{{1
  world       = opts.world; fps = opts.fps || 60
  done        = opts.stop_when?(world) || false
  last        = +new Date
  changed     = false
  setup_value = null

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

  key   = (k) -> change opts.on_key(world, k) if opts.on_key
  click = (x,y) -> change opts.on_click(world, x, y) if opts.on_click

  handlers = {}
  for k, v of opts.on || {}
    do (k,v) -> handlers[k] = (args...) -> change v(world, args...)

  tick = (t) ->
    if t - last > 1000 / opts.fps
      last = t
      change opts.on_tick(world) if opts.on_tick
    if changed
      draw(); changed = false
    unless done
      anim tick
    else
      tv = opts.teardown? opts.canvas, handlers, setup_value
      opts.on_stop? world, tv

  hk            = opts.handle_keys  || handle_keys
  hc            = opts.handle_click || handle_click
  cancel_keys   = hk opts.canvas, key  , opts.$
  cancel_click  = hc opts.canvas, click, opts.$
  setup_value   = opts.setup? opts.canvas, handlers
  anim tick
                                                      #  <!-- }}}1 -->

# stop the universe; see bigbang
B.stop_with = stop_with = (w) -> new _Stop w

# wrapper class for stop_with
class _Stop
  constructor: (@world) ->
B._Stop = _Stop


# scene functions
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
    {w,h}             = measure_text $, string, fontsize, 'sans-serif'
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

# ... TODO: more scene and image functions ...


# keyboard functions
# ------------------

# <!-- {{{1 -->
#
# Handle key presses.  Listens to keydown on elem, calls f with the
# key_to_string'd key; returns a function that cancels the listening.
# the key presses handled are a-z, 0-9, and the keys in keycodes (with
# the exception of SHIFT); with and without shift; when alt, ctrl, or
# meta is pressed, the key press is ignored.
#
# Why only this limited set of key presses you ask?  Because of
# browser and keyboard layout inconsistencies.  For example, a German
# keyboard layout will result in incorrect results with chromium, and
# even less correct results with firefox.  The key presses currently
# handled seem to be the ones that work correctly in both firefox and
# chromium, for both US English and German keyboard layouts.  YMMV.
#
# <!-- }}}1 -->
B.handle_keys = handle_keys = (elem, f, $ = window.$) ->        # {{{1
  h = (e) ->
    if !e.altKey && !e.ctrlKey && !e.metaKey &&
        e.which != keycodes.SHIFT
      k = key_to_string e.which, e.shiftKey; f k if k
      k == null
    else
      true
  $(elem).on 'keydown', h
  -> $(elem).off 'keydown', h
                                                      #  <!-- }}}1 -->

# Turn keypress into something usable: a-z without shift is returned
# as "a"-"z"; A-Z with shift is returned as "A"-"Z"; 0-9 without shift
# is returned as "0"-"9"; 0-9 with shift is returned as
# "SHIFT_0".."SHIFT_9"; the other key codes are retured as the keys in
# keycodes, lowercase when without shift (e.g. "left"), uppercase when
# with shift (e.g. "HOME").
B.key_to_string = key_to_string = (which, shift) ->             # {{{1
  w = which; s = shift
  switch
    when keyranges.ALPHA.from <= w <= keyranges.ALPHA.to
      c = String.fromCharCode w
      if s then c else c.toLowerCase()
    when keyranges.NUM.from <= w <= keyranges.NUM.to
      c = String.fromCharCode w
      if s then "SHIFT_#{c}" else c
    else
      for k, v of keycodes
        if v == w
          return if s then k else k.toLowerCase()
      null
                                                      #  <!-- }}}1 -->

# key codes
B.keycodes = keycodes =
  BACKSPACE: 8, COMMA: 188, DELETE: 46, DOWN: 40, END: 35, ENTER: 13,
  ESCAPE: 27, HOME: 36, LEFT: 37, PAGE_DOWN: 34, PAGE_UP: 33,
  PERIOD: 190, RIGHT: 39, SHIFT: 16, SPACE: 32, TAB: 9, UP: 38

# key ranges
B.keyranges = keyranges =
  ALPHA: { from: 65, to: 90 }, NUM: { from: 48, to: 57 }, # ...


# mouse functions
# ---------------

# Handle mouse clicks.  Listens to click on elem, calls f with the
# {x,y}; returns a function that cancels the listening.
B.handle_click = handle_click = (elem, f, $ = window.$) ->
  h = (e) -> {x,y} = mouse_position e; f x, y; false
  $(elem).on 'keydown', h
  -> $(elem).off 'keydown', h

# relative mouse position; returns {x,y}
B.mouse_position = mouse_position =                             # {{{1
  (event, elem = event.target, $ = window.$, cache = {}) ->
    e            = $(elem)
    cache.left  ?= (e.outerWidth()  - e.width() ) / 2
    cache.top   ?= (e.outerHeight() - e.height()) / 2
    x: event.offsetX - cache.left, y: event.offsetY - cache.top
                                                      #  <!-- }}}1 -->


# miscellaneous functions
# -----------------------

# measure text height and width using a temporary hidden div;
# returns {w:width,h:height}
B.measure_text = measure_text = ($, text, size, family) ->      # {{{1
  c = measure_text.cache["#{size}|#{family}|#{text}"]
  return c if c
  d = $ '<div>'; d.text text
  d.css display: 'none', 'font-size': size, 'font-family': family
  $('body').append d
  w = d.width(); h = d.height()
  d.remove()
  measure_text.cache["#{size}|#{family}|#{text}"] = {w,h}
measure_text.cache = {}
                                                      #  <!-- }}}1 -->

# <!-- vim: set tw=70 sw=2 sts=2 et fdm=marker : -->
