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
  Object.new.extend(Yeah::DSL::Middleware).instance_eval(&blk) if blk
  Yeah.application
ensure
  Yeah.application = nil
end

assert 'Yeah::DSL::Middleware' do
  assert_kind_of Module, Yeah::DSL::Middleware
end

assert 'Yeah::DSL::Middleware#middleware' do
  assert_kind_of Hash, build_app.middleware
end

assert 'Yeah::DSL::Middleware#use' do
  app = build_app { use Shelf::Head }.app

  app.run ->(_) { [200, {}, ['OK']] }

  _, _, body = app.call(env_for('/', 'HEAD'))

  assert_true body.empty?
end

assert 'Yeah::DSL::Middleware#use', 'with args' do
  app1 = build_app { use Shelf::Head }.app
  app2 = build_app { use Shelf::Head, 'arg' }.app

  assert_nothing_raised { app1.to_app }
  assert_raise(ArgumentError) { app2.to_app }
end
