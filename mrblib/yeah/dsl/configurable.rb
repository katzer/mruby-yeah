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
  # DSL methods to modify the server settings.
  module Configurable
    # Store a value referenced by a key.
    #
    # @param [ Object ] key The key to reference the value.
    # @param [ Object ] val The value to store.
    #
    # @return [ Void ]
    def set(key, val = nil)
      if key.is_a? Hash
        key.each { |k, v| settings[k] = v }
      else
        settings[key] = val
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
      Yeah.application.configure(*envs, blk)
    end

    # The server settings.
    #
    # @return [ Hash ]
    def settings
      Yeah.application.settings
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
      Yeah.application.middleware.each_value { |m| m << config }
    end
  end
end
