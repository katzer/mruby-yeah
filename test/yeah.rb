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

def env_for(path, method = 'GET')
  { 'REQUEST_METHOD' => method, 'PATH_INFO' => path }
end

def build_app(&blk)
  app = Object.new.extend Yeah
  app.instance_eval(&blk) if blk
  app
end

assert 'Yeah' do
  assert_kind_of Module, Yeah
end

assert 'Yeah::VERSION' do
  assert_true Yeah.const_defined? :VERSION
end

assert 'Yeah#app' do
  assert_kind_of Shelf::Builder, build_app.app
end

assert 'Yeah#server' do
  assert_kind_of Shelf::Server, build_app.server
end

assert 'Yeah#set', 'single key-value pair' do
  app = build_app { set :port, 80 }
  assert_equal 80, app.server.options[:port]
end

assert 'Yeah#set', 'map' do
  app = build_app { set port: 80 }
  assert_equal 80, app.server.options[:port]
end

assert 'Yeah#enable' do
  app = build_app { enable :logging }
  assert_true app.server.options[:logging]
end

assert 'Yeah#disable' do
  app = build_app { disable :logging }
  assert_false app.server.options[:logging]
end

assert 'Yeah#settings' do
  app = build_app { set port: 80 }
  assert_equal 80, app.settings[:port]
end

assert 'Yeah#middleware' do
  app = build_app { set port: 80 }
  assert_kind_of Hash, app.middleware
end

assert 'Yeah#use' do
  app = build_app { use Shelf::Head }.app

  app.run ->(_) { [200, {}, ['OK']] }

  _, _, body = app.call(env_for('/', 'HEAD'))

  assert_true body.empty?
end

assert 'Yeah#use', 'with args' do
  app1 = build_app { use Shelf::Head }.app
  app2 = build_app { use Shelf::Head, 'arg' }.app

  assert_nothing_raised { app1.to_app }
  assert_raise(ArgumentError) { app2.to_app }
end

assert 'Yeah#route' do
  app = build_app { route('/test') { 'OK' } }.app
  assert_equal 200, app.call(env_for('/test'))[0]
  assert_equal 405, app.call(env_for('/test', 'POST'))[0]

  app = build_app { route('/test', R3::POST) { 'OK' } }.app
  assert_equal 405, app.call(env_for('/test'))[0]
  assert_equal 200, app.call(env_for('/test', 'POST'))[0]
end

assert 'Yeah', 'http method helpers' do
  app = build_app { post('/test') { 'OK' } }

  assert_true app.respond_to? :get
  assert_true app.respond_to? :post
  assert_true app.respond_to? :put
  assert_true app.respond_to? :delete
  assert_true app.respond_to? :patch
  assert_true app.respond_to? :head
  assert_true app.respond_to? :options

  assert_equal 200, app.app.call(env_for('/test', 'POST'))[0]
end

assert 'Yeah#root' do
  app = build_app do
    root '/ok'
    get('/ok') { 'OK' }
  end.app

  status, headers, = app.call(env_for('/'))

  assert_equal 303, status
  assert_equal '/ok', headers[Shelf::LOCATION]

  status, = app.call(env_for('/', 'POST'))

  assert_equal 405, status
end

assert 'Yeah#document_root' do
  app = build_app { document_root '/i/dont/exist' }.app

  status, headers, = app.call(env_for('/public/i/dont/exist/app.js'))
  assert_equal 404, status
  assert_equal 'pass', headers['X-Cascade']
end

assert 'Yeah#document_root', 'with opts' do
  app = build_app { document_root '/i/dont/exist', urls: ['/'] }.app

  status, headers, = app.call(env_for('/i/dont/exist/app.js'))
  assert_equal 404, status
  assert_equal 'pass', headers['X-Cascade']
end

assert 'Yeah#yeah!' do
  app    = build_app
  called = any_called = prod_called = dev_called = false

  ENV['SHELF_ENV'] = 'production'

  app.configure { any_called = true }
  app.configure(:production) { prod_called = true }

  app.server.class.define_method(:start) { called = true }
  app.yeah!

  assert_true  called
  assert_true  any_called
  assert_true  prod_called
  assert_false dev_called
end
