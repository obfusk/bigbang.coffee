# --                                                            ; {{{1
#
# File        : bigbang_spec.coffee
# Maintainer  : Felix C. Stegerman <flx@obfusk.net>
# Date        : 2013-10-16
#
# Copyright   : Copyright (C) 2013  Felix C. Stegerman
# Licence     : GPLv2 or GPLv3 or LGPLv3 or EPLv1
#
# --                                                            ; }}}1

B = bigbang

# ...

# FIXME: these tests might be to brittle
describe 'measure_text', ->
  it 'calculates height and with of text', ->
    a = [$, 'Foo',  '1em', 'sans-serif']
    b = [$, 'Foo',  '2em', 'sans-serif']
    c = [$, 'Foo', '50px', 'serif']
    expect(B.measure_text a...).toEqual [28, 21]
    expect(B.measure_text b...).toEqual [56, 41]
    expect(B.measure_text c...).toEqual [87, 63]

# vim: set tw=70 sw=2 sts=2 et fdm=marker :
