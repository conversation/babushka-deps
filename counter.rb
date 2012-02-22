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
