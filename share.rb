dep 'sharejs.theconversation.edu.au system', :app_user, :key

dep 'sharejs.theconversation.edu.au app', :env, :domain, :app_user, :app_root, :key do
  requires [
    'benhoskings:user setup'.with(:key => key),

    "sharejs.upstart".with(app_user, 'theconversation.edu.au', env, "tc_#{env}")
  ]
end

dep 'sharejs.theconversation.edu.au packages' do
  requires [
    'postgres'.with('9.2'),
    'curl.lib',
    'running.nginx',
    'sharejs.theconversation.edu.au common packages'
  ]
end

dep 'sharejs.theconversation.edu.au dev' do
  requires [
    'sharejs.theconversation.edu.au common packages',
    'phantomjs', # for js testing
    'geoip database'.with(:app_root => '.')
  ]
end

dep 'sharejs.theconversation.edu.au common packages' do
  requires [
    'bundler.gem',
    'postgres.bin'.with('9.2'),
    "npm",
    "coffeescript.src"
  ]
end
