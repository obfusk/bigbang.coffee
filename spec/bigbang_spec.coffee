# --                                                            ; {{{1
#
# File        : bigbang_spec.coffee
# Maintainer  : Felix C. Stegerman <flx@obfusk.net>
# Date        : 2014-04-03
#
# Copyright   : Copyright (C) 2014  Felix C. Stegerman
# Licence     : LGPLv3+
#
# --                                                            ; }}}1

B     = bigbang
anim  = B.polyRequestAnimationFrame()

between = (x, m, n) ->
  expect(x).toBeGreaterThan m
  expect(x).toBeLessThan n

describe 'polyRequestAnimationFrame', ->                        # {{{1
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

# NB: reliance on $._data may break in future
describe 'bigbang', ->                                          # {{{1
  canvas = log = pix = null
  trig = (t, f) -> (as...) ->
    e = $.Event t; f e, as...; canvas.trigger e
  key = trig 'keydown', (e, which, shift = false) ->
    e.which = which; e.shiftKey = shift
  click = trig 'click', (e, ox, oy) -> e.offsetX = ox; e.offsetY = oy
  foo = trig 'foo', (e, x) -> e.x = x
  bar = trig 'bar', (e, x, y) -> e.x = x; e.y = y
  beforeEach ->
    canvas  = $('<canvas>').css width: '400px', height: '300px'
    log     = []
    pix     = []
  it 'can count from 0 to 9; ticking, checking and drawing',    # {{{2
    (done) ->
      w = 0
      t = (n) -> log.push ['t',n]; n + 1
      q = (n) -> log.push ['q',n]; n == 9
      d = (n) -> (c) -> c.push n
      s = (n) ->
        expect(n).toBe 9
        expect(log).toEqual [['q',0],['t',0],['q',1],['t',1],
                             ['q',2],['t',2],['q',3],['t',3],
                             ['q',4],['t',4],['q',5],['t',5],
                             ['q',6],['t',6],['q',7],['t',7],
                             ['q',8],['t',8],['q',9]]
        expect(pix).toEqual [0..9]
        done()
      bigbang
        canvas: pix, world: w, on_tick: t, stop_when: q, to_draw: d,
        on_stop: s, animate: anim
                                                                # }}}2
  it 'takes ~2 secs to do 40 ticks at 20 fps', (done) ->        # {{{2
    w = 0
    t = (n) -> n + 1
    q = (n) -> n == 40
    d = (n) -> (c) -> null
    s = (n) ->
      between Math.round((+new Date - t1) / 100), 18, 25
      done()
    t1 = +new Date
    bigbang
      canvas: pix, world: w, on_tick: t, stop_when: q, to_draw: d,
      on_stop: s, animate: anim, fps: 20
                                                                # }}}2
  it 'can stop_with', (done) ->                                 # {{{2
    w = 0
    t = (n) ->
      log.push ['t',n]
      if n == 6 then B.stop_with 99 else n + 1
    d = (n) -> (c) -> c.push n
    s = (n) ->
      expect(n).toBe 99
      expect(log).toEqual [['t',0],['t',1],['t',2],['t',3],
                           ['t',4],['t',5],['t',6]]
      expect(pix).toEqual [0..6].concat [99]
      done()
    bigbang
      canvas: pix, world: w, on_tick: t, to_draw: d, on_stop: s,
      animate: anim
                                                                # }}}2
  it 'uses last_draw', (done) ->                                # {{{2
    w = 0
    t = (n) -> if n == 6 then B.stop_with 99 else n + 1
    d = (n) -> (c) -> c.push n
    l = (n) -> (c) -> c.push -n
    s = (n) ->
      expect(n).toBe 99
      expect(pix).toEqual [0..6].concat [-99]
      done()
    bigbang
      canvas: pix, world: w, on_tick: t, to_draw: d, last_draw: l,
      on_stop: s, animate: anim
                                                                # }}}2
  it 'handles keys and cleans up', (done) ->                    # {{{2
    w = 0
    d = (n) -> (c) -> pix.push n
    k = (n, k) ->
      log.push [n,k]
      if k == 'space' then B.stop_with 99 else n + 1
    s = (n) ->
      expect(n).toBe 99
      expect(log).toEqual [[0,'a'],[1,'z'],[2,'TAB'],[3,'space']]
      expect(pix).toEqual [0,1,2,3,99]
      expect($._data canvas[0], 'events').not.toBeDefined()
      done()
    bigbang
      canvas: canvas, world: w, to_draw: d, on_key: k, on_stop: s,
      animate: anim
    key 65; key -1; key 90; key 9, true; key 32; key 48
                                                                # }}}2
  it 'handles clicks and cleans up', (done) ->                  # {{{2
    w = 0
    d = (n) -> (c) -> pix.push n
    c = (n, x, y) ->
      log.push [n,x,y]
      if _.isEqual [x,y], [37,42] then B.stop_with 99 else n + 1
    s = (n) ->
      expect(n).toBe 99
      expect(log).toEqual [[0,10,7],[1,7,10],[2,100,100],[3,37,42]]
      expect(pix).toEqual [0,1,2,3,99]
      expect($._data canvas[0], 'events').not.toBeDefined()
      done()
    bigbang
      canvas: canvas, world: w, to_draw: d, on_click: c, on_stop: s,
      animate: anim
    click 10, 7; click 7, 10; click 100, 100; click 37, 42
                                                                # }}}2
  it 'handles on; uses setup, teardown', (done) ->              # {{{2
    w = 0
    d = (n) -> (c) -> pix.push n
    f = (n, x) ->
      log.push ['f',n,x]
      if x == 'bye' then B.stop_with 99 else n + 1
    g = (n, x, y) -> log.push ['g',n,x,y]; n * 2
    o = foo: f, bar: g
    u = (c,hs) ->
      h_foo = (e) -> hs.foo e.x
      h_bar = (e) -> hs.bar e.x, e.y
      canvas.on 'foo', h_foo
      canvas.on 'bar', h_bar
      log.push ['u']; {h_foo,h_bar}
    t = (c, hs, sv) ->
      events = _.keys($._data canvas[0], 'events').sort()
      expect(events).toEqual ['bar', 'foo']
      canvas.off 'foo', sv.h_foo
      canvas.off 'bar', sv.h_bar
      log.push ['t',_.keys(sv).sort()]; 'teardown'
    s = (n, tv) ->
      expect(n).toBe 99
      expect(tv).toBe 'teardown'
      expect(log).toEqual [['u'],
                           ['f',0,'hi'],['g',1,'2','OK'],
                           ['g',2,37,'y'],['f',4,'bye'],
                           ['t',['h_bar','h_foo']]]
      expect(pix).toEqual [0,1,2,4,99]
      expect($._data canvas[0], 'events').not.toBeDefined()
      done()
    bigbang
      canvas: canvas, world: w, to_draw: d, on: o, setup: u,
      teardown: t, on_stop: s, animate: anim
    foo 'hi'; bar '2', 'OK'; bar 37, 'y'; foo 'bye'; bar 'NO', 'NO'
                                                                # }}}2
                                                                # }}}1

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

describe 'handle_keys', ->                                      # {{{1
  elem = log = fake$ = null
  event = (f, which, shift = false, g = null) ->
    c = B.handle_keys elem, ((k) -> f(c)(k)), fake$
    e = $.Event 'keydown'; e.which = which; e.shiftKey = shift; g? e
    elem.trigger e
  beforeEach ->
    elem  = $('<div>').css width: '400px', height: '300px'
    log   = []
    fake$ = (x) ->
      on:   (e,h) -> log.push ['on' ,x,e]; $(x).on  e, h
      off:  (e,h) -> log.push ['off',x,e]; $(x).off e, h
  it 'passes "a" when a is pressed', (done) ->
    f = (c) -> (k) -> expect(k).toBe 'a'; done()
    event f, 65
  it 'passes "Z" when z+shift is pressed', (done) ->
    f = (c) -> (k) -> expect(k).toBe 'Z'; done()
    event f, 90, true
  it 'passes "1" when a is pressed', (done) ->
    f = (c) -> (k) -> expect(k).toBe '1'; done()
    event f, 49
  it 'passes "SHIFT_8" when z+shift is pressed', (done) ->
    f = (c) -> (k) -> expect(k).toBe 'SHIFT_8'; done()
    event f, 56, true
  it 'passes "space" when space is pressed', (done) ->
    f = (c) -> (k) -> expect(k).toBe 'space'; done()
    event f, 32
  it 'passes "LEFT" when left+shift is pressed', (done) ->
    f = (c) -> (k) -> expect(k).toBe 'LEFT'; done()
    event f, 37, true
  it 'is triggered quickly', (done) ->
    called = false
    f = (c) -> (k) -> called = true
    setTimeout (-> expect(called).toBe true; done()), 50
    event f, 65
  it 'ignores keydown when which = -1', (done) ->
    called = false
    f = (c) -> (k) -> called = true
    setTimeout (-> expect(called).toBe false; done()), 50
    event f, -1
  it 'ignores keydown when altKey = true', (done) ->
    called = false
    f = (c) -> (k) -> called = true
    setTimeout (-> expect(called).toBe false; done()), 50
    event f, 32, false, (e) -> e.altKey = true
  it 'calls on and off properly', (done) ->
    f = (c) -> (k) ->
      expect(log.length).toBe 1
      c()
      expect(log.length).toBe 2
      expect(log).toEqual [['on' , elem, 'keydown'],
                           ['off', elem, 'keydown']]
      done()
    event f, 65
                                                                # }}}1

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

describe 'handle_click', ->                                     # {{{1
  elem = log = fake$ = null
  event = (f, ox, oy) ->
    c = B.handle_click elem, ((x,y) -> f(c)(x,y)), fake$
    e = $.Event 'click'; e.offsetX = ox; e.offsetY = oy
    elem.trigger e
  beforeEach ->
    elem  = $('<div>').css
      width: '400px', height: '300px', border: '10px solid red'
    log   = []
    fake$ = (x) ->
      on:   (e,h) -> log.push ['on' ,x,e]; $(x).on  e, h
      off:  (e,h) -> log.push ['off',x,e]; $(x).off e, h
  it 'passes "{x:10,y:20}" when (20,30) is clicked w/ 10px border',
    (done) ->
      f = (c) -> (x,y) -> expect({x,y}).toEqual {x:10,y:20}; done()
      event f, 20, 30
  it 'calls on and off properly', (done) ->
    f = (c) -> (x,y) ->
      expect(log.length).toBe 1
      c()
      expect(log.length).toBe 2
      expect(log).toEqual [['on' , elem, 'click'],
                           ['off', elem, 'click']]
      done()
    event f, 10, 10
                                                                # }}}1

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
