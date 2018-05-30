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
  # DSL methods related to the router.
  module Routing
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
      Yeah.application.app.map(route, method, *data) do
        run ->(env) { Yeah.application.call(env, &blk) }
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

    # Add redirect from one URL to another one.
    #
    # @param [ Hash<String, String> ] pairs { url => redirect_to_url }
    #
    # @return [ Void ]
    def redirect(pairs)
      pairs.each { |url, to| get(url) { render redirect: to } }
    end

    # All registered routes with leading method.
    #
    # @return [ Array<String> ]
    def routes
      Yeah.application.routes.routes
    end
  end
end
