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

def env_for(path, method = 'GET')
  { 'REQUEST_METHOD' => method, 'PATH_INFO' => path }
end

def build_app(&blk)
  Object.new.extend(Yeah::DSL::OptParsing).instance_eval(&blk) if blk
  Yeah.application.opts.parser
ensure
  Yeah.application = nil
end

assert 'Yeah::DSL::OptParsing' do
  assert_kind_of Module, Yeah::DSL::OptParsing
end

assert 'Yeah#opt' do
  called = false
  parser = build_app { opt(:port, :int, 1) { called = true } }

  assert_true parser.valid_flag?('port')
  assert_equal({ port: 1 }, parser.parse([]))
  assert_true called

  called = false
  parser = build_app { opt(:port, 1) { called = true } }

  assert_true parser.valid_flag?('port')
  assert_equal({ port: 1 }, parser.parse([]))
  assert_true called
end
