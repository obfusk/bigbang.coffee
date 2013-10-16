desc 'Build'
task :build do
  sh 'coffee -c src/bigbang.coffee'
end

desc 'Build tests'
task :build_tests do
  sh 'coffee -c spec/bigbang_spec.coffee'
end

desc 'Run specs'
task :spec => [:build, :build_tests] do
  sh 'cd test && rake jasmine:ci'
end

desc 'Run jasmine'
task :jasmine => [:build, :build_tests] do
  sh 'cd test && rake jasmine'
end

desc 'Generate docs'
task :docs do
  sh 'docco -o doc src/*.coffee'
end

desc 'Cleanup'
task :clean do
  sh 'rm -rf doc/ node_modules/ spec/*.js src/*.js'
end

desc 'Update Pages'
task :pages do
  sh 'rake clean && rake docs'
  sh 'git checkout gh-pages'
  sh 'rake cpdocs'
  sh 'git add .'
  sh 'git status'
  puts 'press enter to continue ...'; $stdin.readline
  sh 'git commit -m ...'
  sh 'git checkout master'
end
