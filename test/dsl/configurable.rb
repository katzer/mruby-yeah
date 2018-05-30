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
  Object.new.extend(Yeah::DSL::Configurable).instance_eval(&blk) if blk
  Yeah.application
ensure
  Yeah.application = nil
end

assert 'Yeah::DSL::Configurable' do
  assert_kind_of Module, Yeah::DSL::Configurable
end

assert 'Yeah::DSL::Configurable#set', 'single key-value pair' do
  app = build_app { set :port, 80 }
  assert_equal 80, app.server.options[:port]
end

assert 'Yeah::DSL::Configurable#set', 'map' do
  app = build_app { set port: 80 }
  assert_equal 80, app.server.options[:port]
end

assert 'Yeah::DSL::Configurable#enable' do
  app = build_app { enable :logging }
  assert_true app.server.options[:logging]
end

assert 'Yeah::DSL::Configurable#disable' do
  app = build_app { disable :logging }
  assert_false app.server.options[:logging]
end

assert 'Yeah::DSL::Configurable#settings' do
  app = build_app { set port: 80 }
  assert_equal 80, app.settings[:port]
end

assert 'Yeah::DSL::Configurable#document_root' do
  app = build_app { document_root '/i/dont/exist' }.app
  app = Shelf::Server.new.build_app(app)

  status, headers, = app.call(env_for('/public/i/dont/exist/app.js'))
  assert_equal 404, status
  assert_equal 'pass', headers['X-Cascade']
end

assert 'Yeah::DSL::Configurable#document_root', 'with opts' do
  app = build_app { document_root '/i/dont/exist', urls: ['/'] }.app
  app = Shelf::Server.new.build_app(app)

  status, headers, = app.call(env_for('/i/dont/exist/app.js'))
  assert_equal 404, status
  assert_equal 'pass', headers['X-Cascade']
end

assert 'Yeah::DSL::Configurable#configure' do
  app        = build_app
  any_called = prod_called = dev_called = false

  ENV['SHELF_ENV'] = 'production'

  app.configure { any_called = true }
  app.configure(:production) { prod_called = true }

  app.initialize!

  assert_true  any_called
  assert_true  prod_called
  assert_false dev_called
end
