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

module Yeah
  # DSL methods that are available from top level
  module DSL
    # Add a flag and a callback to invoke if flag is given later.
    #
    # @param [ String ] flag The name of the option value.
    #                        Possible values: object, string, int, float, bool
    # @param [ Symbol ] type The type of the option v
    # @param [ Object ] dval The value to use if nothing else given.
    # @param [ Proc ]   blk  The callback to be invoked.
    #
    # @return [ Void ]
    def on(opt, type = :object, dval = nil, &blk)
      parser.on(opt, type, dval, &blk)
    end

    # Same as `Yeah#opt` however is does exit after the block has been called.
    #
    # @return [ Void ]
    def on!(opt, type = :object, dval = nil, &blk)
      parser.on!(opt, type, dval, &blk)
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
        envs.each { |env| @initializers[env] = blk }
      else
        @initializers[:any] = blk
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
      routes << "#{R3.method_name(method)} #{route}"
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
        route(route, R3.method_code(method), *data, &blk)
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
      config = [Shelf::Static, { root: root, urls: ['/public'] }.merge(opts)]
      middleware.each_value { |m| m << config }
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

    # The instance of the server which is wraped by a (custom) handler.
    #
    # @return [ Shelf::Server ]
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
      @parser ||= OptParser.new
    end

    # The server settings.
    #
    # @return [ Hash ]
    def settings
      server.options
    end

    # All registered routes with leading method.
    #
    # @return [ Array<String> ]
    def routes
      @routes ||= []
    end
  end
end
