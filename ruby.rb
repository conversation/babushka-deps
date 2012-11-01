dep 'ruby 1.9.bin', :version, :patchlevel do
  version.default!('1.9.3')
  patchlevel.default!('p286')
  installs 'ruby1.9.1-full'
  provides "ruby >= #{version}#{patchlevel}", 'gem', 'irb'
end
