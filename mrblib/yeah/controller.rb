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
  # Helper methods to use to generate responses
  class Controller
    # Calls the callback to generate a Shelf response.
    #
    # @param [ Hash ] env     The shelf request.
    # @param [ Proc ] blk     The app callback.
    #
    # @return [ Void ]
    def initialize(env, &blk)
      @env  = env

      args  = []
      params.each { |key, val| args << val if key.is_a? Symbol }

      if blk
        res = instance_exec(*args, &blk)
      else
        data = env[Shelf::SHELF_R3_DATA]
        send(data[:action], *args)
      end

      @body = res unless @res
    end

    # The Shelf request object.
    #
    # @return [ Hash ]
    def request
      @env
    end

    # The query hash constructed by Shelf.
    #
    # @return [ Hash ]
    def params
      @env[Shelf::SHELF_REQUEST_QUERY_HASH]
    end

    # The Shelf logger if any.
    #
    # @return [ Object ]
    def logger
      @env[Shelf::SHELF_LOGGER]
    end

    # Render Shelf response.
    #
    # render 200
    # => [200, { Content-Type: 'text/plain', Content-Length: 2 }, ['OK']]

    # render 'OK'
    # => [200, { Content-Type: 'text/plain', Content-Length: 2 }, ['OK']]

    # render json: 'OK', status: 200, headers: {}
    # => [200, { Content-Type: 'application/json', ... }, ['OK']]
    #
    # @params [ Hash|String|Int ] opts Either the status code, the plain body
    #                                  or a hash with all attributes.
    #
    # @return [ Array ]
    def render(opts = {})
      return @res if @res

      case opts
      when String
        opts = { plain: opts }
      when Integer
        opts = { status: opts }
      end

      status  = opts[:status]  || 200
      headers = opts[:headers] || {}
      body    = []

      if opts.include? :redirect
        status = 303
        headers[Shelf::LOCATION] = opts[:redirect]
      else
        body, type = self.class.render_body(status, @body, opts)
        headers[Shelf::CONTENT_TYPE]   = type
        headers[Shelf::CONTENT_LENGTH] = body.bytesize
      end

      @res = [status, headers, [*body]]
    end

    # @private
    #
    # Search for key like :json or :plain in opts and render their value.
    #
    # @param [ Int ] status
    # @param [ String ] body
    # @param [ Hash ] opts
    #
    # @return [ Array<String, String> ] Body and its content type.
    def self.render_body(status, body, opts)
      return [body, Shelf::Mime.mime_type('.txt')] if body

      if opts.include? :plain
        [opts[:plain], Shelf::Mime.mime_type('.txt')]
      elsif opts.include? :html
        [opts[:html], Shelf::Mime.mime_type('.html')]
      elsif opts.include? :json
        [opts[:json].to_json, Shelf::Mime.mime_type('.json')]
      else
        [Shelf::Utils::HTTP_STATUS_CODES[status], Shelf::Mime.mime_type('.txt')]
      end
    end
  end
end
