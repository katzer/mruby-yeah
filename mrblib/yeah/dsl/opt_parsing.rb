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

module Yeah::DSL
  # DSL methods related to command-line parsing.
  module OptParsing
    # Add a flag and a callback to invoke if flag is given later.
    #
    # @param [ String ] flag The name of the option value.
    #                        Possible values: object, string, int, float, bool
    # @param [ Symbol ] type The type of the option v
    # @param [ Object ] dval The value to use if nothing else given.
    # @param [ Proc ]   blk  The callback to be invoked.
    #
    # @return [ Void ]
    def opt(opt, type = :object, dval = nil, &blk)
      if dval.nil? && !type.is_a?(Symbol)
        Yeah.application.opts.parser.on(opt, :object, type, &blk)
      else
        Yeah.application.opts.parser.on(opt, type, dval, &blk)
      end
    end

    # Same as `Yeah#opt` however is does exit after the block has been called.
    #
    # @return [ Void ]
    def opt!(opt, type = :object, dval = nil, &blk)
      if dval.nil? && !type.is_a?(Symbol)
        Yeah.application.opts.parser.on!(opt, :object, type, &blk)
      else
        Yeah.application.opts.parser.on!(opt, type, dval, &blk)
      end
    end
  end
end
