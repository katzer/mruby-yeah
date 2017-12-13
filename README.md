
<p align="center">
    <img src="logo.png">
</p>

<p align="center">
    <a href="https://travis-ci.org/katzer/mruby-yeah">
        <img src="https://travis-ci.org/katzer/mruby-yeah.svg?branch=master" alt="Build Status" />
    </a>
    <a href="https://codebeat.co/projects/github-com-katzer-mruby-yeah-master">
        <img src="https://codebeat.co/badges/828229e5-c07a-4fc6-ba2a-7afc824685c5" alt="codebeat badge" />
    </a>
    <a href="https://ci.appveyor.com/project/katzer/mruby-yeah/branch/master">
        <img src="https://ci.appveyor.com/api/projects/status/yud3nsyo5tqnvgxx/branch/master?svg=true" alt="Build Status" />
    </a>
</p>

__Yeah!__ is a DSL for quickly creating [shelf applications][shelf] in [mruby][mruby] with minimal effort:

```ruby
# mrblib/your-mrbgem.rb

set port: 3000                                        |   opt(:port) { |port| set port: port }
                                                      |
get '/hi/{name}' do |name|                            |   get '/hi' do
  "Hi #{name}"                                        |     "Hi #{params['name'].join(' and ')}"
end                                                   |   end
```

```sh
$ your-mrbgem &                                       |   $ your-mrbgem --port 8080 & 
Starting application at http://localhost:3000         |   Starting application at http://localhost:8080
                                                      |
$ curl 'localhost:3000/hi/Ben'                        |   $ curl 'localhost:8080/hi?name=Tom&name=Jerry'
Hi Ben                                                |   Hi Tom and Jerry
```

## Installation

Add the line below to your `build_config.rb`:

```ruby
MRuby::Build.new do |conf|
  # ... (snip) ...
  conf.gem 'mruby-yeah'
end
```

Or add this line to your aplication's `mrbgem.rake`:

```ruby
MRuby::Gem::Specification.new('your-mrbgem') do |spec|
  # ... (snap) ...
  spec.add_dependency 'mruby-yeah'
end
```

## Routes

In Yeah!, a route is an HTTP method paired with a URL-matching pattern. Each route is associated with a block:

```ruby
post '/' do
  .. create something ..
end
```

Routes are matched in the order they are defined. The first route that matches the request is invoked.

Routes with trailing slashes are __not__ different from the ones without:

```ruby
get '/foo' do
  # Does match "GET /foo/"
end
```

Use `root` to specify the default entry point:

```ruby
# Redirect "GET /" to "GET /public/index.html"
root '/public/index.html'
```

Route patterns may include named parameters, accessible via the `params` hash:

```ruby
# matches "GET /hello/foo" and "GET /hello/bar"
get '/hello/{name}' do
  # params[:name] is 'foo' or 'bar'
  "Hello #{params[:name]}!"
end
```

You can also access named parameters via block parameters:

```ruby
# matches "GET /hello/foo" and "GET /hello/bar"
get '/hello/{name}' do |name|
  # params[:name] is 'foo' or 'bar'
  # name stores params[:name]
  "Hello #{name}!"
end
```

Routes may also utilize query parameters:

```ruby
# matches "GET /posts?title=foo&author=bar"
get '/posts' do
  title  = params['title']
  author = params['author']
end
```

Route matching with Regular Expressions:

```ruby
get '/blog/post/{id:\\d+}' |id|
  post = Post.find(id)
end
```

Support for regular expression requires __mruby-regexp-pcre__ to be installed before mruby-yeah!

Routes can also be defined to match any HTTP method:

```ruby
# matches "GET /" and "PUT /" and ...
route '/', R3::ANY do
  request[Shelf::REQUEST_METHOD]
end
```

## Response

Each routing block is invoked within the scope of an instance of `Yeah::Controller`. The class provides access to methods like `request`, `params`, `logger` and `render`.

- `request` returns the Shelf request and is basically a hash.

```ruby
get '/' do
  request # => { 'REQUEST_METHOD' => 'GET', 'REQUEST_PATH' => '/', 'User-Agent' => '...' }
end
```

- `params` returns the query params and named URL params. Query params are accessible by string keys and named params by symbol.

```ruby
# "GET /blogs/b1/posts/p1?blog_id=b2"
get '/blogs/{blog_id}/posts/{post_id}' do
  params # => { 'blog_id' => 'b2', blog_id: 'b1', post_id: 'p1' }
end
```

- `logger` returns the query params and named URL params. Query params are accessible by string keys and named params by symbol. Dont forget to include the required middleware!

```ruby
use Shelf::Logger

get '/' do
  logger # => <Logger:0x007fae54987308>
end
```

- `render` returns a well-formed shelf response. The method allows varoius kind of invokation:

```ruby
get '/500' do                     |   get '/yeah' do
  render 500                      |     render html: '<h1>Yeah!</h1>'
end                               |   end
                                  |
get '/say_hi' do                  |   post '/api/stats' do
  render 'Hi'                     |     render json: Stats.create(params), status: 201, headers: {...}
end                               |   end
                                  |
get '/say_hello' do               |   def '/' do
  'Hello'                         |     render redirect: 'public/index.html'
end                               |   end
```

## Controller

Instead of a code block to execute a route also accepts an controller and an action similar to Rails.

```ruby
class GreetingsController < Yeah::Controller
  def greet(name)
    render "Hello #{name.capitalize}"
  end
end

get 'greet/{name}', controller: GreetingsController, action: 'greet'
```

## Command Line Arguments

Yeah! ships with a small opt parser. Each option is associated with a block:

```ruby
# matches "your-mrbgem --port 80" or "your-mrbgem -p 80"
opt :port, 8080 do |port|
  # port is 80
  set :port, port
end
```

Opts can have a default value. The block will be invoked in any case either with the command-line value, its default value or just _nil_.

Sometimes however it is intended to only print out some meta informations for a single given option and then exit without starting the server:

```ruby
# matches "your-mrbgem --version" or "your-mrbgem -v"
opt! :version do
  # prints 'v1.0.0' on STDOUT and exit
  'v1.0.0'
end
```

## Configuration

Run once, at startup, in any environment:

```ruby
configure do
  # setting one option
  set :option, 'value'
  # setting multiple options
  set a: 1, b: 2
  # same as `set :option, true`
  enable :option
  # same as `set :option, false`
  disable :option
end
```

Run only when the environment (`SHELF_ENV` environment variable) is set to `production`:

```ruby
configure :production do
  ...
end
```

Run only when the environment is set to either `development` or `test`:

```ruby
configure :development, :test do
  ...
end
```

You can access those options via `settings`:

```ruby
configure do
  set :foo, 'bar'
end

get '/' do
  settings[:foo] # => 'bar'
end
```

## Shelf Middleware

Sinatra rides on [Shelf][shelf], a minimal standard interface for mruby web frameworks. One of Shelf's most interesting capabilities for application developers is support for "middleware" -- components that sit between the server and your application monitoring and/or manipulating the HTTP request/response to provide various types of common functionality.

Sinatra makes building Rack middleware pipelines a cinch via a top-level `use` method:

```ruby
use Shelf::CatchError
use MyCustomMiddleware

get '/hello' do
  'Hello World'
end
```

The semantics of `use` are identical to those defined for the [Shelf::Builder][builder] DSL. For example, the use method accepts multiple/variable args as well as blocks:

```ruby
use Shelf::Static, urls: ['/public'], root: ENV['DOCUMENT_ROOT']
```

Shelf is distributed with a variety of standard middleware for logging, debugging, and URL routing. Yeah! uses many of these components automatically based on configuration so you typically don't have to use them explicitly.

## Server

Yeah! works with any Shelf-compatible web server. Right now this is only mruby-simplehttpserver:

```ruby
set :server, 'simplehttpserver' # => Default
```

However its possible to register handlers for other servers. See [here][server] for more info.

## Good to know

By default Yeah! extends _Object_ and works out-of-the-box for mruby-cli projects. However often it might be necessary to start Yeah! manually:

```ruby
class App
  include Yeah

  opt :port { |port| set :port, port }

  get '/' { 'It Works!' }

  def initialize
    _init_yeah!
  end
end

App.new.yeah! ['-p', 8080]
```

## Development

Clone the repo:
    
    $ git clone https://github.com/katzer/mruby-yeah.git && cd mruby-yeah/

Compile the source:

    $ rake compile

Run the tests:

    $ rake test

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/katzer/mruby-yeah.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Authors

- Sebastián Katzer, Fa. appPlant GmbH

## License

The mgem is available as open source under the terms of the [MIT License][license].

Made with :yum: from Leipzig

© 2017 [appPlant GmbH][appplant]

[shelf]: https://github.com/katzer/mruby-shelf
[mruby]: https://github.com/mruby/mruby
[builder]: https://github.com/katzer/mruby-shelf/blob/master/mrblib/shelf/builder.rb
[server]: https://github.com/katzer/mruby-shelf#handler
[license]: http://opensource.org/licenses/MIT
[appplant]: www.appplant.de
