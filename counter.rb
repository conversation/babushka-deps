dep 'system provisioned for counter.theconversation.edu.au', :host_name, :app_user, :password, :key do
  requires [
    'base system provisioned'.with(host_name, password, key),
    'benhoskings:running.nginx',
    'benhoskings:user auth setup'.with(app_user, password, key),
  ]
end

dep 'counter.theconversation.edu.au provisioned', :env, :app_root do
  requires [
    'counter.theconversation.edu.au packages',
    'cronjobs'.with(env),
    'geoip database'.with(app_root: app_root)
  ]
end

dep 'counter.theconversation.edu.au dev' do
  requires [
    'geoip database'.with(app_root: '.'),
    'counter.theconversation.edu.au dev packages'
  ]
end

dep 'counter.theconversation.edu.au packages' do
  requires [
    'counter.theconversation.edu.au dev packages'
  ]
end

dep 'counter.theconversation.edu.au dev packages' do
  requires [
    'benhoskings:postgres.managed',
    'geoip.managed', # for geoip-c
  ]
end
