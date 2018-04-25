# MIT License
#
# Copyright (c) Sebastian Katzer 2017
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

MRuby::Gem::Specification.new('mruby-yeah') do |spec|
  spec.license = 'MIT'
  spec.authors = 'Sebastian Katzer'
  spec.summary = 'mruby on tiny rails'

  spec.add_dependency 'mruby-simplehttpserver', mgem: 'mruby-simplehttpserver'
  spec.add_dependency 'mruby-tiny-opt-parser',  mgem: 'mruby-tiny-opt-parser'
  spec.add_dependency 'mruby-object-ext',       core: 'mruby-object-ext'
  spec.add_dependency 'mruby-sprintf',          core: 'mruby-sprintf'
  spec.add_dependency 'mruby-print',            core: 'mruby-print'
  spec.add_dependency 'mruby-shelf',            mgem: 'mruby-shelf'
  spec.add_dependency 'mruby-exit',             core: 'mruby-exit'
end
