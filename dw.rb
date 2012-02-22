dep 'system provisioned for dw.theconversation.edu.au', :host_name, :app_user, :password, :key do
  requires [
    'base system provisioned'.with(host_name, password, key),
    "#{app_user} packages",
    'benhoskings:running.nginx',
    'benhoskings:user auth setup'.with(app_user, password, key)
  ]
end

dep 'dw.theconversation.edu.au provisioned', :env, :app_root do
  requires [
    'dw.theconversation.edu.au packages',
    'cronjobs'.with(env),
    'minutely.cronjob'.with(env) # Also hook in per-minute cron tasks on the DW.
  ]
end

dep 'dw.theconversation.edu.au packages' do
  requires [
    'dw.theconversation.edu.au dev packages'
  ]
end

dep 'dw.theconversation.edu.au dev packages' do
  requires [
    'benhoskings:postgres.managed',
    'socat.managed' # for DB tunnelling
  ]
end
