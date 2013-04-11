dep 'sharejs system', :app_user, :key, :env

dep 'sharejs app', :env, :host, :domain, :app_user, :app_root, :key do
  requires [
    'benhoskings:user setup'.with(:key => key),

    "sharejs.upstart".with(app_user, 'theconversation.edu.au', env, "tc_#{env}")
  ]
end

dep 'sharejs packages' do
  requires [
    'postgres'.with('9.2'),
    'curl.lib',
    'running.nginx',
    'sharejs common packages'
  ]
end

dep 'sharejs dev' do
  requires [
    'sharejs common packages',
    'phantomjs' # for js testing
  ]
end

dep 'sharejs common packages' do
  requires [
    'bundler.gem',
    'postgres.bin',
    "npm",
    "coffeescript.src"
  ]
end
