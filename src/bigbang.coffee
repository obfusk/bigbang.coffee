# <!--
###
# {{{1 -->
#
#     File        : bigbang.coffee
#     Maintainer  : Felix C. Stegerman <flx@obfusk.net>
#     Date        : 2020-09-02
#
#     Copyright   : Copyright (C) 2020  Felix C. Stegerman
#     Licence     : LGPLv3+
#     Version     : v0.2.1
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
# License: LGPLv3+.

# underscore + exports
# --------------------

U = this._ || require 'underscore'
B = -> B.bigbang arguments...
if exports? then module.exports = B else this.bigbang = B


# requestAnimationFrame & polyfill
# --------------------------------

# requestAnimationFrame polyfill; the default delay is 17 milliseconds
# (ca. 60 fps)
B.polyRequestAnimationFrame = polyRequestAnimationFrame =       # {{{1
  (opts = {}) ->
    console.warn 'polyfilling *RequestAnimationFrame ...' if opts.warn
    delay = opts.delay || 17; next = 0
    (cb) ->
      cur   = +new Date
      dt    = Math.max 0, delay - (cur - next)
      next  = cur + dt
      window.setTimeout (-> cb +new Date), dt
                                                      #  <!-- }}}1 -->

# NB: we use the prefixed versions of requestAnimationFrame b/c
# requestAnimationFrame itself uses relative timestamps; also good to
# know: webkitRequestAnimationFrame uses floating point timestamps.
B.requestAnimationFrame = requestAnimationFrame =
  window?.requestAnimationFrame ||
  window?.webkitRequestAnimationFrame ||
  window?.mozRequestAnimationFrame ||
  polyRequestAnimationFrame warn: true


# bigbang & stop_with
# -------------------

# <!-- {{{1 -->
#
# big bang: start a new universe whose behaviour is specified by the
# options and handler functions designated
#
#     bigbang
#       world:        object,
#       canvas:       element|object,
#       to_draw:      ((world) -> scene),
#       on_tick:      ((world, time) -> new_world),
#       fps:          int,
#       queue:        boolean|int,
#       animate:      requestAnimationFrame-like-function,
#       on_key:       ((world, key) -> new_world),
#       on_click:     ((world, x, y) -> new_world),
#       on:           { foo: ((world, ...) -> new_world), ... },
#       stop_when:    ((world) -> boolean),
#       last_draw:    ((world) -> scene),
#       setup:        ((canvas, handlers) -> setup_value),
#       teardown:     ((canvas, handlers, setup_value) ->
#                       teardown_value),
#       on_stop:      ((world, teardown_value) -> ...)
#     -> {get_world,get_done}
#
# Options:
#
#   * `world` is the object representing the initial world
#   * `canvas` is the HTML5 canvas (or equivalent) to draw on
#   * `to_draw` is called every time a new world needs to be drawn
#
#   * (optional) `on_tick`
#     - when passed, the universe is in "clock mode": all changes are
#     queued (unless `queue` is `false`) and drawing happens every
#     actual clock tick (usually approx. 60 fps); `on_tick` is called
#     every "virtual" clock tick (as determined by `fps`)
#     - otherwise, events are processed immediately (by updating the
#     world and re-drawing the scene)
#   * (optional) `fps` is the requested frame rate; defaults to 60
#   * (optional) `queue` when set to `false`, disables queueing in
#     "clock mode"; when set to an `int`, restricts the queue size to
#     that number of items (e.g. to draw every actual tick and ignore
#     all but the last world, set this to `1`)
#   * (optional) `animate` the requestAnimationFrame-like function to
#     use as the clock in "clock mode"
#   * (optional) `on_key` is called every time a key is pressed to
#     update the world
#   * (optional) `on_click` is called every time the mouse is clicked
#     inside the canvas to update the world
#   * (optional) `on` contains handlers for user-defined events;
#     `setup` and `teardown` are used to connect handlers to elements
#     and events; when the user-defined event is triggered, the
#     appropriate function is called
#   * (optional) `stop_when` is called to determine if the universe
#     needs to stop
#   * (optional) `last_draw` is called instead of `to_draw` to draw
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
# Returns:
#
#   * `get_world` is a function that returns the current world
#   * `get_done` is a function that returns whether the universe is
#     stopped
#
# <!-- ... -->
#
# The canvas need not be an actual canvas: it can be any element you
# wish to "draw" the world with.  It can be (part of) the body of an
# event-driven page.  In this case, you will also have a different
# concept of "scene".  For more on "scenes", see `mk_scene`.
#
# To stop the world from `on_tick` etc., return `stop_with(new_world)`
# instead of `new_world`.
#
# For details on key press handling, see `handle_keys`.  If you want
# to use a different key press handling library, set the `handle_keys`
# option to a function with the same api as `handle_keys`.
#
# For details on mouse click handling, see `handle_click`.
#
# <!-- }}}1 -->
B.bigbang = (opts) ->                                           # {{{1
  tickless      = !opts.on_tick
  queue         = opts.queue ? true
  anim          = opts.animate || requestAnimationFrame
  world         = opts.world
  delay         = 1000 / (opts.fps || 60)
  delay_margin  = delay / 17                                    #  ???
  done          = opts.stop_when?(world) || false
  next          = +new Date + delay
  changes       = []
  setup_value   = null

  if tickless && (opts.queue? || opts.fps || opts.animate)
    throw new Error 'queue, fps and animate require on_tick'

  draw = (w,d) ->
    f = if d && opts.last_draw then opts.last_draw else opts.to_draw
    draw_scene(f w) opts.canvas

  draw_changes = ->
    for {world:w,done:d} in changes
      draw w, d
    changes = []

  change = (f, args...) ->
    return if done || !U.isFunction f
    x = f world, args...
    if x instanceof _Stop
      world = x.world
      done  = true
    else
      world = x
      done  = true if opts.stop_when? world
    if !tickless && queue
      changes.shift() if changes.length == queue  # != true is OK
      changes.push {world,done}
    else
      draw world, done
      finish() if done

  s = +new Date

  tick = (t) ->
    if t >= next - delay_margin
      next += delay; change opts.on_tick, t
    draw_changes() if queue
    if done
      finish() if queue
    else
      anim tick

  key   = (k) -> change opts.on_key, k
  click = (x,y) -> change opts.on_click, x, y

  handlers = {}
  for k, v of opts.on || {}
    do (k,v) -> handlers[k] = (args...) -> change v, args...

  finish = ->
    cancel_keys?(); cancel_click?()
    tv = opts.teardown? opts.canvas, handlers, setup_value
    opts.on_stop? world, tv

  hk            = opts.handle_keys  || handle_keys
  hc            = opts.handle_click || handle_click
  cancel_keys   = opts.on_key   && hk opts.canvas, key  , opts.$
  cancel_click  = opts.on_click && hc opts.canvas, click, opts.$
  setup_value   = opts.setup? opts.canvas, handlers

  draw world, done
  anim tick unless tickless

  world: (-> world), done: (-> done)
                                                      #  <!-- }}}1 -->

# stop the universe; see bigbang
B.stop_with = stop_with = (w) -> new _Stop w

# wrapper class for stop_with
class _Stop
  constructor: (@world) ->
B._Stop = _Stop


# abstract scene functions
# ------------------------

# make a scene
#
# A "scene" is a function that takes a "canvas" and "draws" on it.
#
# A "non-recursive scene" is a "scene" that also takes a second
# argument specifying whether any "lower scene" should also be drawn
# by it and has a property `lower_scene` that holds the "lower scene".
# This allows `draw_scene` to draw multiple scenes using iteration
# instead of recursion.
#
# `mk_scene` takes a "non-recursive (lower) scene" and a "regular
# scene" and turns the "regular scene" into a "non-recursive scene"
# that draws the "lower scene" when needed.
B.mk_scene = mk_scene = (scene, f) ->
  g = (canvas, draw_lower = true) -> scene? canvas if draw_lower; f canvas
  g.lower_scene = scene; g

# draw a scene
B.draw_scene = draw_scene = (scene) -> (canvas) ->
  if (s = scene).lower_scene
    scenes = [scene]; scenes.push s while s = s.lower_scene
    scenes.reverse(); s canvas, false for s in scenes; null
  else
    scene canvas


# HTML5 canvas scene functions
# ----------------------------

# empty scene
B.empty_scene = empty_scene = (width, height) -> mk_scene null, (canvas) ->
  canvas.width = width; canvas.height = height

# text with center at coordinates
B.place_text = place_text =                                     # {{{1
  (string, x, y, fontsize, colour, scene, $ = window.$) -> \
  mk_scene scene, (canvas) ->
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
B.place_image = place_image = (image, x, y, scene) ->
  mk_scene scene, (canvas) ->
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
  $(elem).on 'click', h
  -> $(elem).off 'click', h

# relative mouse position; returns {x,y}
B.mouse_position = mouse_position =
  (event, elem = event.target, $ = window.$, cache = {}) ->
    e            = $(elem)
    cache.left  ?= (e.outerWidth()  - e.width() ) / 2
    cache.top   ?= (e.outerHeight() - e.height()) / 2
    x: event.offsetX - cache.left, y: event.offsetY - cache.top


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
