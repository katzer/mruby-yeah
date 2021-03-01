# MIT License
#
# Copyright (c) 2017 Sebastian Katzer
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

ENV['MRUBY_CONFIG']  ||= File.expand_path('build_config.rb')
ENV['MRUBY_VERSION'] ||= 'stable'

file :mruby do
  case ENV['MRUBY_VERSION']&.downcase
  when 'head', 'master'
    sh(*%w[git clone --depth 1 git://github.com/mruby/mruby.git])
  when 'stable'
    sh(*%w[git clone --depth 1 git://github.com/mruby/mruby.git -b stable])
  else
    sh "curl -L --fail --retry 3 --retry-delay 1 https://github.com/mruby/mruby/archive/#{ENV['MRUBY_VERSION']}.tar.gz -s -o - | tar zxf -" # rubocop:disable Layout/LineLength
    mv "mruby-#{ENV['MRUBY_VERSION']}", 'mruby'
  end
end

desc 'compile binary'
task compile: 'mruby' do
  sh(*%w[rake -f mruby/Rakefile all])
end

desc 'run mtests'
task test: 'mruby' do
  sh(*%w[rake -f mruby/Rakefile test])
end

desc 'cleanup target build folder'
task :clean do
  sh(*%w[rake -f mruby/Rakefile clean]) if Dir.exist? 'mruby'
end

desc 'cleanup all build folders'
task :cleanall do
  sh(*%w[rake -f mruby/Rakefile deep_clean]) if Dir.exist? 'mruby'
end
