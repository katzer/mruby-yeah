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

module Yeah
  # High-level DSL methods to interact with Shelf.
  module DSL
    # Initializes Yeah! once it has been extended to main.
    #
    # @param [ Object ] obj The Object which has been extended.
    #
    # @return [ Void ]
    def self.extended(obj)
      obj._init_yeah!
    end

    # Default entry point to mruby-cli generated apps.
    #
    def __main__(_)
      yeah!
    end

    # Store a value referenced by a key.
    #
    # @param [ Object ] key The key to reference the value.
    # @param [ Object ] val The value to store.
    #
    # @return [ Object] val
    def set(key, val)
      @_elf.options[key] = val
    end

    # Delegate to the middleware chain of Shelf.
    #
    # @return [ Hash<String, Array> ]
    def middleware
      @_elf.middleware
    end

    # Add a route to match a request.
    #
    # @param [ String ] route The route to add for.
    # @param [ Int ] method The HTTP method to match.
    #                       Defaults to: R3::GET
    # @param [ Proc ] &blk Code block to execute for.
    #
    # @return [ Void ]
    def route(route, method = R3::GET, &blk)
      @_app.map(route, method) do
        run ->(env) { Yeah::Response.new(env, &blk).render }
      end
    end

    # Add a route to match request by a specfic HTTP method.
    #
    # @param [ String ] route The route to add for.
    # @param [ Proc ] &blk Code block to execute for.
    #
    # @return [ Void ]
    %w[GET POST PUT DELETE PATCH HEAD OPTIONS].each do |method|
      define_method(method.downcase) do |route, &blk|
        route(route, R3.method_code_for(method), &blk)
      end
    end

    # Start the server.
    #
    # @return [ Void ]
    def yeah!
      url = "http://#{@_elf.options[:host]}:#{@_elf.options[:port]}"

      print '[INF] '.set_color(:green)
      puts "Starting application at #{url}\n"

      @_elf.start
    ensure
      @_elf.shutdown
    end

    private

    # Initializes Yeah!
    #
    # @params See `Shelf::Builder`
    #
    # @return [ Void ]
    def _init_yeah!(*args, &blk)
      @_app = Shelf::Builder.new(*args, &blk)
      @_elf = Shelf::Server.new(port: 3000, app: @_app)
      @_app.run ->(_) { [200, {}, ['<h1>Yeah!</h1>']] }
    end
  end

  # Helper methods to use to generate responses
  class Response
    # Calls the callback to generate a Shelf response.
    #
    # @param [ Hash ] env The shelf request.
    # @param [ Proc ] blk The app callback.
    #
    # @return [ Void ]
    def initialize(env, &blk)
      @env  = env

      args  = []
      params.each { |key, val| args << val if key.is_a? Symbol }

      res   = instance_exec(*args, &blk)
      @body = res unless @res
    end

    def request
      @env
    end

    def params
      @env[Shelf::SHELF_REQUEST_QUERY_HASH]
    end

    def logger
      @env[Shelf::SHELF_LOGGER]
    end

    def render(opts = nil)
      return @res if @res

      case opts
      when String
        opts = { plain: opts }
      when Integer
        opts = { status: opts }
      end

      status  = (opts[:status]  if opts) || 200
      headers = (opts[:headers] if opts) || {}

      body = @body || begin
        if opts.include? :plain
          headers[Shelf::CONTENT_TYPE] = Shelf::Mime.mime_type('.txt')
          opts[:plain].to_s
        elsif opts.include? :html
          headers[Shelf::CONTENT_TYPE] = Shelf::Mime.mime_type('.html')
          opts[:html].to_s
        elsif opts.include? :json
          headers[Shelf::CONTENT_TYPE] = Shelf::Mime.mime_type('.json')
          opts[:json].to_json
        else
          headers[Shelf::CONTENT_TYPE] = Shelf::Mime.mime_type('.txt')
          Shelf::Utils::HTTP_STATUS_CODES[status.to_i]
        end
      end

      body = [body] unless body.is_a? Array
      @res = [status, headers, body]
    end
  end
end

extend Yeah::DSL
