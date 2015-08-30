dep 'sharejs system', :app_user, :key, :env

dep 'sharejs env vars set', :domain

dep 'sharejs app', :env, :host, :domain, :app_user, :app_root, :key do
  requires [
    'user setup'.with(:key => key),

    "sharejs.upstart".with(app_user, env, app_root, "sharejs_#{env}")
  ]
end

dep 'sharejs packages' do
  requires [
    'postgres'.with('9.3'),
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
    "coffeescript.bin"
  ]
end
