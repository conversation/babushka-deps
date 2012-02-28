dep 'ruby 1.9.managed', :version, :patchlevel do
  requires 'apt source'.with(:uri => 'http://apt.tc-dev.net/', :repo => 'main')

  version.default!('1.9.3')
  patchlevel.default!('p0')
  installs 'ruby1.9.1-full'
  provides "ruby == #{version}#{patchlevel}", 'gem', 'irb'
end
