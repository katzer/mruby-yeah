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
  # Responsible for building the middleware stack, setting up and executing the
  # booting process.
  class Application
    # To use Yeah.application.enable a.s.o.
    include DSL::Configurable

    # The instance of the server which is wraped by a (custom) handler.
    #
    # @return [ Shelf::Server ]
    attr_reader :server

    # The server settings.
    #
    # @return [ Hash ]
    def settings
      server.options
    end

    # Add the block to the list of initializers.
    #
    # @param [ Symbol ] envs  The environment of the initializer.
    #                         Defaults to: :default
    # @param [ Proc ]   block The code block to run for.
    #
    # @return [ Void ]
    def configure(*envs, &blk)
      if envs.any?
        envs.each { |env| @initializers[env.to_sym] = blk }
      else
        @initializers[:default] = blk
      end
    end

    # The Shelf app builder.
    #
    # @return [ Shelf::Builder ]
    def app
      server.app
    end

    # Delegate to the middleware chain of Shelf.
    #
    # @return [ Hash<String, Array> ]
    def middleware
      server.middleware
    end

    # The server routes.
    #
    # @return [ Yeah::Routing ]
    def routes
      @routes ||= Routing.new
    end

    # The command-line flags.
    #
    # @return [ Yeah::OptParsing ]
    def opts
      @opts ||= OptParsing.new
    end

    # Run the initializers and start the server.
    #
    # @param [ Array<String> ] args The command-line flags to parse.
    #
    # @return [ Void ]
    def run!(args = [])
      opts.parser.parse(args)

      url = "http://#{settings[:host]}:#{settings[:port]}"
      puts "Starting application in #{ENV['SHELF_ENV']} mode at #{url}"

      redirect_to_log_folder(*@logs) if @logs

      initialize!
      server.start
    end

    protected

    # Setup the shelf server and build instances.
    #
    # @param [ Hash<Symbol, Object> ] cfg The default configs for the server.
    #
    # @return [ Void ]
    def initialize(cfg = {})
      @server       = Shelf::Server.new({ port: 3000, app: Shelf::Builder.new }.merge(cfg))
      @initializers = {}

      app.use Shelf::QueryParser
      app.run ->(_) { [200, {}, ['<h1>Yeah!</h1>']] }
    end

    # Initialize the controller and invoke the action to render a response.
    #
    # @param [ Hash ] env A Shelf request.
    #
    # @return [ [status, headers, [body]] ] A Shelf response.
    def call(env, &blk)
      data = env[Shelf::SHELF_R3_DATA]

      if data.is_a?(Hash) && data.include?(:to)
        name, action = data[:to].split('#')
        name = "#{name.capitalize}Controller" unless name.end_with? 'Controller'

        data[:controller] = Object.const_get(name)
        data[:action]     = action
      end

      controller = (data[:controller] if data.is_a?(Hash)) || Controller
      controller.new(env, &blk).render
    end

    private

    # Redirect stdout and stderr to a file.
    #
    # @param [ String ] dir The path of the log folder.
    # @param [ String ] out Optional name of the log file.
    # @param [ String ] err Optional name of the error log file.
    #
    # @return [ Void ]
    def redirect_to_log_folder(dir, out, err)
      Dir.mkdir(dir) if Object.const_defined?(:Dir) && !Dir.exist?(dir)

      out ||= "#{Object.const_defined?(:ARGV) ? ARGV[0] : 'yeah'}.log"

      $stdout.close
      $stderr.close

      $stdout = File.new("#{dir}/#{out}", 'a+')
      $stderr = File.new("#{dir}/#{err || out}", 'a+')
    end

    # Run all initializers for the SHELF_ENV environment.
    #
    # @return [ Boolean ] false if already initialized.
    def initialize!
      dblock = @initializers[:default]
      eblock = @initializers[ENV['SHELF_ENV'].to_sym]

      instance_eval(&dblock) if dblock
      instance_eval(&eblock) if eblock

      @initializers = nil
    end
  end
end
