dep 'counter.theconversation.edu.au system', :host_name, :app_user, :password, :key

dep 'counter.theconversation.edu.au app', :env, :app_root do
  requires [
    'cronjobs'.with(env),
    'geoip database'.with(app_root: app_root)
  ]
end

dep 'counter.theconversation.edu.au provisioned' do
  requires [
    'benhoskings:running.nginx',
    'benhoskings:postgres.managed',
  ]
end



dep 'counter.theconversation.edu.au dev' do
  requires [
    'geoip database'.with(app_root: '.'),
  ]
end
