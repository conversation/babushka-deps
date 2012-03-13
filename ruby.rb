dep 'ruby 1.9.managed', :version, :patchlevel do
  requires 'our apt source'

  version.default!('1.9.3')
  patchlevel.default!('p0')
  installs 'ruby1.9.1-full'
  provides "ruby == #{version}#{patchlevel}", 'gem', 'irb'

  met? {
    in_path? 'ruby 1.9.3p0'
  }
end
