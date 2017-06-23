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

def env_for(path, query = '')
  { 'REQUEST_METHOD' => 'GET', 'PATH_INFO' => path, 'QUERY_STRING' => query }
end

def build_app(&blk)
  app = Object.new.extend Yeah
  app.instance_eval(&blk) if blk
  app.app
end

class FooYeah
  def to_json
    '__json__'
  end
end

class Logger
  def initialize(*_); end
end

class MyController < Yeah::Controller
  def say_hello(name)
    render "Hello #{name.capitalize}"
  end
end

assert 'Yeah::Controller#render' do
  app = build_app { get('/hi') { 'Hi' } }
  assert_equal ['Hi'], app.call(env_for('/hi'))[2]
  assert_include app.call(env_for('/hi'))[1]['Content-Type'], 'text/plain'

  app = build_app { get('/hi') { render 'Hi' } }
  assert_equal ['Hi'], app.call(env_for('/hi'))[2]
  assert_include app.call(env_for('/hi'))[1]['Content-Type'], 'text/plain'

  app = build_app { get('/hi') { render plain: 'Hi' } }
  assert_equal ['Hi'], app.call(env_for('/hi'))[2]
  assert_include app.call(env_for('/hi'))[1]['Content-Type'], 'text/plain'

  app = build_app { get('/hi') { render html: 'Hi' } }
  assert_equal ['Hi'], app.call(env_for('/hi'))[2]
  assert_include app.call(env_for('/hi'))[1]['Content-Type'], 'text/html'

  app = build_app { get('/hi') { render json: FooYeah.new } }
  assert_equal ['__json__'], app.call(env_for('/hi'))[2]
  assert_equal 'application/json', app.call(env_for('/hi'))[1]['Content-Type']

  app = build_app { get('/hi') { render 404 } }
  assert_equal 404, app.call(env_for('/hi'))[0]

  app = build_app { get('/hi') { render status: 404 } }
  assert_equal 404, app.call(env_for('/hi'))[0]

  app = build_app { get('/hi') { render headers: { 'test' => 'test' } } }
  assert_include app.call(env_for('/hi'))[1], 'test'
  assert_equal 'test', app.call(env_for('/hi'))[1]['test']

  app = build_app { get('/hi') { render redirect: '/huhu' } }
  assert_equal 303, app.call(env_for('/hi'))[0]
  assert_include app.call(env_for('/hi'))[1]['Location'], '/huhu'
end

assert 'Yeah::Controller#request' do
  app = build_app { get('/hi') { request['PATH_INFO'] } }
  assert_equal ['/hi'], app.call(env_for('/hi'))[2]
end

assert 'Yeah::Controller#params' do
  app = build_app { get('/hi') { "Hi #{params['name']}" } }
  assert_equal ['Hi Ben'], app.call(env_for('/hi', 'name=Ben'))[2]
end

assert 'Yeah::Controller#args' do
  app = build_app { get('/hi/{name}') { |name| "Hi #{name}" } }
  assert_equal ['Hi Ben'], app.call(env_for('/hi/Ben'))[2]
end

assert 'Yeah::Controller#logger' do
  app = build_app do
    use Shelf::Logger, 101
    get('/log') { logger.class.to_s }
  end

  assert_equal ['Logger'], app.call(env_for('/log'))[2]
end

assert 'Yeah::Controller', 'controller+action' do
  app = build_app do
    get '/say_hello/{name}', controller: MyController, action: 'say_hello'
  end

  assert_equal ['Hello Ben'], app.call(env_for('/say_hello/ben'))[2]
end
