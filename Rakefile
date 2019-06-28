#require "bundler/gem_tasks"
task :default => :spec

desc "git ci, git tag and git push"
task :release do
  load 'lib/zanzou/version.rb'
  sh "git diff HEAD"
  v = "v#{Zanzou::VERSION}"
  puts "release as #{v}? [y/N]"
  break unless $stdin.gets.chomp == "y"

  sh "gem build zanzou"  # First, make sure we can build gem
  sh "git ci -am '#{v}'"
  sh "git tag '#{v}'"
  sh "git push origin master --tags"
  sh "gem push zanzou-#{Zanzou::VERSION}.gem"
end
