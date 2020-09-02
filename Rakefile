desc 'Copy docs'
task :cpdocs do
  sh 'cp -r doc/* ./ && mv src/bigbang.html index.html'
  sh %q{sed -r 's!\.\./(docco\.css)!\1!g' -i index.html}
end
