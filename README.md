
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


## Usage

TODO


## Sample

```ruby

opt! :help do
  <<-usage

usage: iss [options...]
Options:
-e, --environment The environment to run the server with.
-p, --port        The port number to start the local server on.
                  Defaults to: 3000
-s, --server      The server to use for.
-h, --help        This help text
-v, --version     Show version number
usage
end

opt! :version do
  YourGem::VERSION
end

opt :port, 3000 do |port|
  set :port, port
end

opt :server, 'simplehttpserver' do |server|
  set :server, server
end

opt :environment, 'development' do |env|
  ENV['SHELF_ENV'] = env
end

use Shelf::Static, urls: ['/public'], root: ENV['DOCUMENT_ROOT']

get '/' do
  render redirect: 'public/index.html'
end

get '/api/reports/{report_id}/results' |report_id|
  render json: Report.find(report_id).results
end
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


## Development

Clone the repo:
    
    $ git clone https://github.com/katzer/mruby-yeah.git && cd mruby-yeah/

Compile the source:

    $ rake compile

Run the tests:

    $ rake test


## Authors

- Sebastián Katzer, Fa. appPlant GmbH


## License

The mgem is available as open source under the terms of the [MIT License][license].

Made with :yum: from Leipzig

© 2017 [appPlant GmbH][appplant]


[shelf]: https://github.com/katzer/mruby-shelf
[mruby]: https://github.com/mruby/mruby
[license]: http://opensource.org/licenses/MIT
[appplant]: www.appplant.de