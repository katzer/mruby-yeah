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
  # Yeah.application.opts.draw do
  #   opt :port, :int, 5
  # end
  class OptParsing
    # Lazy created opt parser.
    #
    # @return [ Yeah::OptParser ]
    def parser
      @parser ||= ::OptParser.new
    rescue NameError
      raise NameError, 'Missing mruby-tiny-opt-parser mgem'
    end

    # Invokes the code block in the context of an anonymus class.
    #
    # @param [ Proc ] block The code to execute.
    #
    # @return [ Void ]
    def draw(&block)
      Class.new { include DSL::OptParsing }.new.instance_eval(&block)
    end
  end
end
