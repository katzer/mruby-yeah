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

assert 'Yeah::Application' do
  assert_kind_of Class, Yeah::Application
  assert_include Yeah::Application, Yeah::DSL::Configurable
end

assert 'Yeah::Application#server' do
  assert_kind_of Shelf::Server, Yeah::Application.new.server
end

assert 'Yeah::Application#app' do
  assert_kind_of Shelf::Builder, Yeah::Application.new.app
end

assert 'Yeah::Application#opts' do
  app = Yeah.application

  assert_kind_of Yeah::OptParsing, app.opts

  app.opts.draw { opt(:port, :int, 80) }

  assert_equal({ port: 80 }, app.opts.parser.parse)
ensure
  Yeah.application = nil
end

assert 'Yeah::Application#routes' do
  app = Yeah.application

  assert_kind_of Yeah::Routing, app.routes

  app.routes.draw { get('/ok') { 'OK' } }

  assert_kind_of Array, app.routes.routes
  assert_equal 'GET /ok', app.routes.routes.last

  assert_equal 200, app.app.call(env_for('/ok'))[0]
  assert_equal 404, app.app.call(env_for('/ko'))[0]
ensure
  Yeah.application = nil
end

assert 'Yeah::Application#run!' do
  app    = Yeah.application
  called = any_called = prod_called = dev_called = false

  ENV['SHELF_ENV'] = 'production'

  app.configure { any_called = true }
  app.configure(:production) { prod_called = true }

  app.server.class.define_method(:start) { called = true }

  app.run!

  assert_true  called
  assert_true  any_called
  assert_true  prod_called
  assert_false dev_called
ensure
  Yeah.application = nil
end
