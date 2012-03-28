dep 'dw.theconversation.edu.au system', :app_user, :key

dep 'dw.theconversation.edu.au app', :env, :domain, :app_user, :app_root, :key do
  requires [
    'cronjobs'.with(env),
    'minutely.cronjob'.with(env), # Also hook in per-minute cron tasks on the DW.

    'benhoskings:rack app'.with(
      :env => env,
      :domain => domain,
      :username => app_user,
      :enable_https => 'yes'
    ),

    'benhoskings:db'.with(
      :username => app_user,
      :root => app_root,
      :env => env,
      :data_required => 'no',
      :require_db_deps => 'yes'
    )
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
    'postgres.managed',
    'socat.managed' # for DB tunnelling
  ]
end
