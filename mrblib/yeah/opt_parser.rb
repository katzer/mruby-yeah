#
# Copyright (c) 2016 by appPlant GmbH. All rights reserved.
#
# @APPPLANT_LICENSE_HEADER_START@
#
# This file contains Original Code and/or Modifications of Original Code
# as defined in and that are subject to the Apache License
# Version 2.0 (the 'License'). You may not use this file except in
# compliance with the License. Please obtain a copy of the License at
# http://opensource.org/licenses/Apache-2.0/ and read it before using this
# file.
#
# The Original Code and all software distributed under the License are
# distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
# EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
# INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
# Please see the License for the specific language governing rights and
# limitations under the License.
#
# @APPPLANT_LICENSE_HEADER_END@

module Yeah
  # Class for command-line option analysis.
  class OptParser
    # Initialize the parser and check for unknown options.
    #
    # @param [ Array<String> ] args List of command-line arguments.
    #
    # @return [ FF::OptParser ]
    def initialize(args = [])
      @args    = normalize_args(args)
      @opts    = {}
      @unknown = ->(opts) { raise "unknown option: #{opts.join ', '}" }
    end

    # List of all registered options.
    #
    # @return [ Array<String> ]
    attr_accessor :opts

    # Add a flag and a callback to invoke if flag is given later.
    #
    # @param [ String ] flag
    # @param [ Object ] default_value The value to use if nothing else given.
    # @param [ Proc ] blk
    #
    # @return [ Yeah::OptParser ] self
    def add(opt, default_value = nil, &blk)
      if opt == :unknown
        @unknown = blk
      else
        opts[opt.to_s] = [default_value, blk]
      end

      self
    end

    # Parse all given flag and invoke their callback.
    #
    # @param [ Array<String> ] args List of arguments to parse.
    # @param [ Bool] ignore_unknown
    #
    # @return [ Void ]
    def parse(args = nil, ignore_unknown = false)
      @args = normalize_args(args) if args

      @unknown.call(unknown_opts) if !ignore_unknown && unknown_opts.any?

      opts.each do |opt, opts|
        dval, blk = opts
        blk.call opt_value(opt, dval)
      end
    end

    # List of all unknown options.
    #
    # @return [ Array<String> ]
    def unknown_opts
      @args.reject { |opt| !opt.is_a?(String) || opt_given?(opt) }
    end

    # If the specified flag is given in args list.
    #
    # @param [ String ] name The (long) flag name.
    def flag_given?(flag)
      @args.any? do |arg|
        if flag.length == 1 || arg.length == 1
          true if arg[0] == flag[0]
        else
          arg == flag
        end
      end
    end

    # If the specified flag is given in args list.
    #
    # @param [ String ] name The (long) flag name.
    def opt_given?(flag)
      if flag.length == 1
        @opts.keys.any? { |opt| opt[0] == flag[0] }
      else
        @opts.include?(flag)
      end
    end

    # Extract the value of the specified options.
    # Raises an error if the option has been specified but without an value.
    #
    # @param [ String ] opt The options to look for.
    # @param [ Object ] default_value The default value to use for
    #                                 if the options has not been specified.
    #
    # @return [ Object ]
    def opt_value(opt, default_value = nil)
      index   = @args.index(opt)
      value   = @args[index + 1] if index

      return default_value unless value

      value if !value.is_a?(String) || value[0] != '-'
    end

    private

    # Removes all leading slashes or false friends from args.
    #
    # @param [ Array<String> ] args The arguments to normalize.
    #
    # @return [ Array<String> ]
    def normalize_args(args)
      args.map do |opt|
        if !opt.is_a?(String) || opt[0] != '-'
          opt
        else
          opt[1] == '-' ? opt[2..-1] : opt[1..-1]
        end
      end
    end
  end
end
