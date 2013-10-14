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


# console.log global ? this

# anim  = window.webkitRequestAnimationFrame ||
#         window.mozRequestAnimationFrame ||
#         throw Error 'no *RequestAnimationFrame'


# ...
# -----------

# ...
#
#     ...
B._call = _call = (opts) ->
  console.log opts

# <!-- vim: set tw=70 sw=2 sts=2 et fdm=marker : -->
