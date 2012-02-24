dep 'dw.theconversation.edu.au system', :host_name, :app_user, :password, :key

dep 'dw.theconversation.edu.au app', :env, :app_root do
  requires [
    'cronjobs'.with(env),
    'minutely.cronjob'.with(env) # Also hook in per-minute cron tasks on the DW.
  ]
end

dep 'dw.theconversation.edu.au packages' do
  requires [
    'benhoskings:running.nginx',
    'dw.theconversation.edu.au common packages'
  ]
end

dep 'dw.theconversation.edu.au dev' do
  requires 'dw.theconversation.edu.au common packages'
end

dep 'dw.theconversation.edu.au common packages' do
  requires [
    'benhoskings:postgres.managed',
    'socat.managed' # for DB tunnelling
  ]
end
