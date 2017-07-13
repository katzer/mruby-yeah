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

# rubocop:disable Style/ModuleLength

module Yeah
  # Initializes Yeah! once it has been extended to main.
  #
  # @param [ Object ] obj The Object which has been extended.
  #
  # @return [ Void ]
  def self.extended(obj)
    obj._init_yeah!
  end

  # Add a flag and a callback to invoke if flag is given later.
  #
  # @param [ String ] flag
  # @param [ Object ] default_value The value to use if nothing else given.
  # @param [ Proc ] blk
  #
  # @return [ Void ]
  def opt(opt, default_value = nil, &blk)
    parser.add(opt, default_value, &blk)
  end

  # Same as `Yeah#opt` however is does exit after the block has been called.
  #
  # @return [ Void ]
  def opt!(opt, default_value = nil)
    opt(opt, default_value) do |val|
      if parser.flag_given? opt.to_s
        puts yield(val)
        @dry_run = true
      end
    end
  end

  # Store a value referenced by a key.
  #
  # @param [ Object ] key The key to reference the value.
  # @param [ Object ] val The value to store.
  #
  # @return [ Void ]
  def set(key, val = nil)
    if key.is_a? Hash
      key.each { |k, v| server.options[k] = v }
    else
      server.options[key] = val
    end
  end

  # Same as `set :option, true`
  #
  # @param [ Object ] key The key to set to true.
  #
  # @return [ Void ]
  def enable(key)
    set(key, true)
  end

  # Same as `set :option, false`
  #
  # @param [ Object ] key The key to set to false.
  #
  # @return [ Void ]
  def disable(key)
    set(key, false)
  end

  # Run at startup in any or for given environment.
  #
  # @param [ String ] *envs Optional list of environments.
  # @param [ Proc ] blk The code to execute at startup.
  #
  # @return [ Void ]
  def configure(*envs, &blk)
    if envs.any?
      envs.each { |env| (@initializers ||= {})[env] = blk }
    else
      @initializers = { any: blk }
    end
  end

  # Delegate to the middleware chain of Shelf.
  #
  # @return [ Hash<String, Array> ]
  def middleware
    server.middleware
  end

  # Specifies middleware to use in a stack.
  #
  # @param [ Class ] middleware The middleware class.
  # @param [ Array ] *args Optional arguments used at initialization phase.
  #
  # @return [ Void ]
  def use(middleware, *args)
    app.use middleware, *args
  end

  # Add a route to match a request.
  #
  # @param [ String ] route The route to add for.
  # @param [ Int ] method   The HTTP method to match.
  #                         Defaults to: R3::GET
  # @param [ Object ] *data Additional data objects.
  # @param [ Proc ] &blk    Code block to execute for.
  #
  # @return [ Void ]
  def route(route, method = R3::GET, *data, &blk)
    app.map(route, method, *data) do
      run ->(env) { Yeah.render(env, &blk) }
    end
  end

  # Add a route to match request by a specfic HTTP method.
  #
  # @param [ String ] route The route to add for.
  # @param [ Object ] *data Additional data objects.
  # @param [ Proc ] &blk    Code block to execute for.
  #
  # @return [ Void ]
  %w[GET POST PUT DELETE PATCH HEAD OPTIONS].each do |method|
    define_method(method.downcase) do |route, *data, &blk|
      route(route, R3.method_code_for(method), *data, &blk)
    end
  end

  # Specify where to redirect '/'.
  #
  # @param [ String ] redirect_to The URL where to redirect to.
  # @param [ Int ] method The acceptable HTTP method for '/'.
  #                       Defaults to: 'GET'
  #
  # @return [ Void ]
  def root(url, method = R3::GET)
    route('/', method) { render redirect: url } unless url == '/'
  end

  # Add and configure Shelf::Static to serve assets from given root directory.
  # Default url is /public
  #
  # @param [ String ] root Path to the root dir.
  # @param [ Hash ] opts Additional options accepted by the middleware.
  #                      Defaults to: { urls: ['/public'] }
  #
  # @return [ Void ]
  def document_root(root, opts = {})
    use Shelf::Static, { root: root, urls: ['/public'] }.merge(opts)
  end

  # Specify where to place the logs.
  #
  # @param [ String ] dir The path of the log folder.
  # @param [ String ] out Optional name of the log file.
  # @param [ String ] err Optional name of the error log file.
  #
  # @return [ Void ]
  def log_folder(dir, out = nil, err = nil)
    @logs = [dir, out, err]
  end

  # Start the server.
  #
  # @return [ Void ]
  def yeah!(args = [])
    parser.parse(args) if @parser

    return if @dry_run

    Yeah.run_initializers(@initializers)

    url = "http://#{server.options[:host]}:#{server.options[:port]}"

    puts "Starting application in #{ENV['SHELF_ENV']} mode at #{url}"

    Yeah.redirect_to_log_folder(*@logs) if @logs

    @parser, @logs = nil

    server.start
  end

  # Initializes Yeah!
  #
  # @return [ Void ]
  def _init_yeah!
    @server = Shelf::Server.new(port: 3000, app: Shelf::Builder.new)

    app.use Shelf::QueryParser
    app.run ->(_) { [200, {}, ['<h1>Yeah!</h1>']] }
  end

  attr_reader :server

  # The Shelf app builder.
  #
  # @return [ Shelf::Builder ]
  def app
    server.app
  end

  # Lazy created opt parser.
  #
  # @return [ Yeah::OptParser ]
  def parser
    @parser ||= Yeah::OptParser.new
  end

  # The server settings.
  #
  # @return [ Hash ]
  def settings
    server.options
  end

  # @private
  def self.redirect_to_log_folder(dir, out, err)
    Dir.mkdir(dir) if Object.const_defined?(:Dir) && !Dir.exist?(dir)

    out ||= "#{Object.const_defined?(:ARGV) ? ARGV[0] : 'yeah'}.log"

    $stdout.close
    $stderr.close

    $stdout = File.new("#{dir}/#{out}", 'a+')
    $stderr = File.new("#{dir}/#{err || out}", 'a+')
  end

  # @private
  def self.render(env, &blk)
    data = env[Shelf::SHELF_R3_DATA]
    controller = (data[:controller] if data.is_a?(Hash)) || Controller
    controller.new(env, &blk).render
  end

  # @private
  def self.run_initializers(initializers)
    return unless initializers
    initializers[:any]&.call
    initializers[ENV['SHELF_ENV'].to_sym]&.call
  end
end

extend Yeah

# Default entry point to mruby-cli generated apps to run Yeah!
#
# @param [ Array<String> ] args ARGV
#
# @return [ Void ]
def __main__(args)
  yeah!(args[1..-1])
end

# rubocop:enable Style/ModuleLength
