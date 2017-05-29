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

ENV['MRUBY_CONFIG']  ||= File.expand_path('build_config.rb')
ENV['MRUBY_VERSION'] ||= 'head'

file :mruby do
  if ENV['MRUBY_VERSION'] == 'head'
    sh 'git clone --depth 1 git://github.com/mruby/mruby.git'
  else
    sh "curl -L --fail --retry 3 --retry-delay 1 https://github.com/mruby/mruby/archive/#{ENV['MRUBY_VERSION']}.tar.gz -s -o - | tar zxf -" # rubocop:disable LineLength
    mv "mruby-#{ENV['MRUBY_VERSION']}", 'mruby'
  end
end

Rake::Task[:mruby].invoke

namespace :mruby do
  Dir.chdir('mruby') { load 'Rakefile' }
end

desc 'compile binary'
task compile: 'mruby:all'

desc 'test'
task test: 'mruby:test'

desc 'cleanup'
task clean: 'mruby:clean'

desc 'cleanup all'
task cleanall: 'mruby:deep_clean'
