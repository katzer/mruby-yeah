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

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

assert 'Yeah::OptParser#opt_given?' do
  parser = Yeah::OptParser.new ['--help', '-v']
  parser.add 'help'
  parser.add 'version'

  assert_true parser.opt_given? 'help'
  assert_true parser.opt_given? 'v'
  assert_false parser.opt_given? 'other'
end

assert 'Yeah::OptParser#unknown_opts' do
  parser = Yeah::OptParser.new ['help']
  parser.add 'help'
  assert_true parser.unknown_opts.empty?

  parser = Yeah::OptParser.new ['--help']
  parser.add 'help'
  assert_true parser.unknown_opts.empty?

  parser = Yeah::OptParser.new ['-h']
  parser.add 'help'
  assert_true parser.unknown_opts.empty?

  parser = Yeah::OptParser.new ['-?']
  parser.add 'help'
  assert_include parser.unknown_opts, '?'
end

assert 'Yeah::OptParser#opt_value' do
  parser = Yeah::OptParser.new ['--port', 8000, '--ip', '0.0.0.0', '-v']

  assert_equal 8000, parser.opt_value('port')
  assert_equal '0.0.0.0', parser.opt_value('ip')
  assert_nil parser.opt_value('v')
  assert_equal '1.0.0', parser.opt_value('v', '1.0.0')
end

assert 'Yeah::OptParser#parse', 'unknown flag' do
  parser = Yeah::OptParser.new
  opts   = nil
  port   = nil

  parser.add(:unknown) { |flags| opts = flags || [] }

  parser.parse(['--port', 8000], true)
  assert_nil opts

  parser.parse(['--port', 8000])
  assert_equal ['port'], parser.unknown_opts
  assert_equal parser.unknown_opts, opts

  parser.add(:port, 80) { |p| port = p }
  parser.parse(['--port'])
  assert_equal 80, port
  parser.parse(['--port', 8080])
  assert_equal 8080, port
end
