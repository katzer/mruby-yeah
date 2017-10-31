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

  include Yeah::DSL

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

    @parser, @logs, @initializers = nil
    server.start
  end

  # Initializes Yeah!
  #
  # @return [ Void ]
  def _init_yeah!
    @server       = Shelf::Server.new(port: 3000, app: Shelf::Builder.new)
    @initializers = {}

    app.use Shelf::QueryParser
    app.run ->(_) { [200, {}, ['<h1>Yeah!</h1>']] }
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
