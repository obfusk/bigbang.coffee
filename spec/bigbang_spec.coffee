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

# ...

# FIXME: these tests might be to brittle; current margins based on
# tests w/ phantomjs, chromium, firefox; font settings WILL affect
# this test
describe 'measure_text', ->                                     # {{{1
  it 'calculates height and with of text', ->
    a = [$, 'Foo',  '1em', 'sans-serif']
    b = [$, 'Foo',  '2em', 'sans-serif']
    c = [$, 'Foo', '50px', 'serif']
    [aw,ah] = B.measure_text a...
    [bw,bh] = B.measure_text b...
    [cw,ch] = B.measure_text c...
    between aw, 26, 30; between ah, 17, 23
    between bw, 54, 58; between bh, 36, 43
    between cw, 76, 94; between ch, 57, 65
                                                                # }}}1

# vim: set tw=70 sw=2 sts=2 et fdm=marker :
