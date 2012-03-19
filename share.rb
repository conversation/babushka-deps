dep 'sharejs.theconversation.edu.au system', :app_user, :key

dep 'sharejs.theconversation.edu.au app', :env, :domain, :app_user, :app_root, :key do
  requires [
    'benhoskings:user setup'.with(:key => key),
    'ssl certificate'.with(env, domain, 'theconversation.edu.au'),

    "sharejs".with(username, env, "tc_#{env}")
  ]
end

dep 'sharejs.theconversation.edu.au packages' do
  requires [
    'benhoskings:running.nginx',
    'supervisor.managed',
    'theconversation.edu.au common packages'
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
    'postgres.managed',
    "npm",
    "coffeescript.src"
  ]
end
