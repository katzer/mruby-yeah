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
  # Initializes Yeah! once it has been extended to main.
  #
  # @param [ Object ] obj The Object which has been extended.
  #
  # @return [ Void ]
  def self.extended(obj)
    obj._init_yeah!
  end

  # Store a value referenced by a key.
  #
  # @param [ Object ] key The key to reference the value.
  # @param [ Object ] val The value to store.
  #
  # @return [ Object] val
  def set(key, val = nil)
    if val
      server.options[key] = val
    else
      key.each { |k, v| server.options[k] = v }
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
  # @param [ Int ] method The HTTP method to match.
  #                       Defaults to: R3::GET
  # @param [ Proc ] &blk Code block to execute for.
  #
  # @return [ Void ]
  def route(route, method = R3::GET, &blk)
    app.map(route, method) do
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
    url = "http://#{server.options[:host]}:#{server.options[:port]}"

    puts "Starting application at #{url}\n"
    server.start
  end

  private

  # Initializes Yeah!
  #
  # @params See `Shelf::Builder`
  #
  # @return [ Void ]
  def _init_yeah!(*args, &blk)
    @_app = Shelf::Builder.new(*args, &blk)
    @_elf = Shelf::Server.new(port: 3000, app: app)
    app.run ->(_) { [200, {}, ['<h1>Yeah!</h1>']] }
  end

  # The Shelf app to server.
  #
  # @return [ Shelf::Builder ]
  def app
    @_app
  end

  # The Shelf handler to run.
  #
  # @return [ Shelf::Server ]
  def server
    @_elf
  end
end

extend Yeah

# Default entry point to mruby-cli generated apps.
#
def __main__(_)
  yeah!
end
