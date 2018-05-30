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
  Object.new.extend(Yeah::DSL::Routing).instance_eval(&blk) if blk
  Yeah.application.app
ensure
  Yeah.application = nil
end

assert 'Yeah::DSL::Routing' do
  assert_kind_of Module, Yeah::DSL::Routing
end

assert 'Yeah::DSL::Routing#route' do
  app = build_app { route('/test') { 'OK' } }
  assert_equal 200, app.call(env_for('/test'))[0]
  assert_equal 405, app.call(env_for('/test', 'POST'))[0]

  app = build_app { route('/test', R3::POST) { 'OK' } }
  assert_equal 405, app.call(env_for('/test'))[0]
  assert_equal 200, app.call(env_for('/test', 'POST'))[0]
end

assert 'Yeah', 'http method helpers' do
  app = build_app { post('/test') { 'OK' } }

  assert_equal 200, app.call(env_for('/test', 'POST'))[0]
end

assert 'Yeah::DSL::Routing#root' do
  app = build_app do
    root '/ok'
    get('/ok') { 'OK' }
  end

  status, headers, = app.call(env_for('/'))

  assert_equal 303, status
  assert_equal '/ok', headers['Location']

  status, = app.call(env_for('/', 'POST'))

  assert_equal 405, status
end

assert 'Yeah::DSL::Routing#redirect' do
  app = build_app { redirect '/' => '/index.html' }
  app = Shelf::Server.new.build_app(app)

  status, headers, = app.call(env_for('/'))
  assert_equal 303, status
  assert_equal '/index.html', headers['Location']
end
