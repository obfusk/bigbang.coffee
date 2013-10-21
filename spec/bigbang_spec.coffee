# --                                                            ; {{{1
#
# File        : bigbang_spec.coffee
# Maintainer  : Felix C. Stegerman <flx@obfusk.net>
# Date        : 2013-10-21
#
# Copyright   : Copyright (C) 2013  Felix C. Stegerman
# Licence     : GPLv2 or GPLv3 or LGPLv3 or EPLv1
#
# --                                                            ; }}}1

B = bigbang

between = (x, m, n) ->
  expect(x).toBeGreaterThan m
  expect(x).toBeLessThan n

describe 'polyRequestAnimationFrame', ->                        # {{{1
  anim = B.polyRequestAnimationFrame()
  it 'calls back w/ approx. 60 fps', (done) ->
    i = 0; ts = []
    f = (t) ->
      ts.push t; ++i
      if i == 50 then end() else anim f
    end = ->
      expect(i).toBe 50
      expect(ts.length).toBe 50
      between ts[49] - ts[0], 800, 900  # ~60 fps; 17ms * 50 = 850ms
      done()
    anim f
                                                                # }}}1

describe 'bigbang', ->
  # ...

describe 'empty_scene', ->
  it 'sets width and height', ->
    x = {}; B.empty_scene(800, 600)(x)
    expect(x.width).toBe 800
    expect(x.height).toBe 600

describe 'place_text', ->                                       # {{{1
  log = scene = canvas = ctx = null
  beforeEach ->
    log     = []
    scene   = (c) -> log.push c
    canvas  = getContext: -> ctx
    ctx     =
      save:     -> log.push 'save'
      restore:  -> log.push 'restore'
      fillText: (s,x,y) -> this._fillText = {s,x,y}
    B.place_text('Foo', 100, 200, '1em', 'red', scene)(canvas)
  it 'calls scene, saves, and restores', ->
    expect(log).toEqual [canvas, 'save', 'restore']
  it 'sets font', ->
    expect(ctx.font).toBe '1em sans-serif'
  it 'sets fillStyle', ->
    expect(ctx.fillStyle).toBe 'red'
  it 'sets textBaseline', ->
    expect(ctx.textBaseline).toBe 'bottom'
  it 'calls fillText w/ appropriate arguments', ->
    {w,h} = B.measure_text $, 'Foo', '1em', 'sans-serif'
    expect(ctx._fillText.s).toBe 'Foo'
    expect(ctx._fillText.x).toBe Math.round(100 - w / 2)
    expect(ctx._fillText.y).toBe Math.round(200 + h / 2)
                                                                # }}}1

describe 'place_image', ->                                      # {{{1
  i   = width: 100, height: 200
  log = scene = canvas = ctx = null
  beforeEach ->
    log     = []
    scene   = (c) -> log.push c
    canvas  = getContext: -> ctx
    ctx     = drawImage: (i,x,y) -> this._drawImage = {i,x,y}
    B.place_image(i, 300, 400, scene)(canvas)
  it 'calls scene', ->
    expect(log).toEqual [canvas]
  it 'calls drawImage w/ appropriate arguments', ->
    expect(ctx._drawImage).toEqual { i, x: 250, y: 300 }
                                                                # }}}1

# ...

describe 'handle_keys', ->
  # ...

describe 'key_to_string', ->                                    # {{{1
  it 'converts to a', ->
    expect(B.key_to_string 65, false).toBe 'a'
  it 'converts to z', ->
    expect(B.key_to_string 90, false).toBe 'z'
  it 'converts to A', ->
    expect(B.key_to_string 65, true).toBe 'A'
  it 'converts to Z', ->
    expect(B.key_to_string 90, true).toBe 'Z'
  it 'converts to space', ->
    expect(B.key_to_string 32, false).toBe 'space'
  it 'converts to SPACE', ->
    expect(B.key_to_string 32, true).toBe 'SPACE'
                                                                # }}}1

describe 'handle_click', ->
  # ...

describe 'mouse_position', ->                                   # {{{1
  elem = null
  beforeEach ->
    elem = $('<div>').css
      width: '400px', height: '300px'
      margin: '10px', padding: '20px', border: '30px solid red'
    $('body').append elem
  afterEach ->
    elem.remove()
  it 'handles padding and border', (done) ->
    elem.on 'click', (e) ->
      expect(B.mouse_position e).toEqual x: 5, y: 10
      done()
    e = $.Event 'click'; e.offsetX = 55; e.offsetY = 60
    elem.trigger e
                                                                # }}}1

# FIXME: these tests might be to brittle; current margins based on
# tests w/ phantomjs, chromium, firefox; font settings WILL affect
# this test
describe 'measure_text', ->                                     # {{{1
  it 'calculates height and with of text', ->
    a = [$, 'Foo',  '1em', 'sans-serif']
    b = [$, 'Foo',  '2em', 'sans-serif']
    c = [$, 'Foo', '50px', 'serif']
    {w:aw,h:ah} = B.measure_text a...
    {w:bw,h:bh} = B.measure_text b...
    {w:cw,h:ch} = B.measure_text c...
    between aw, 26, 30; between ah, 17, 23
    between bw, 54, 58; between bh, 36, 43
    between cw, 76, 94; between ch, 57, 65
                                                                # }}}1

# vim: set tw=70 sw=2 sts=2 et fdm=marker :
