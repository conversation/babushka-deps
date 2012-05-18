dep 'dw.theconversation.edu.au system', :app_user, :key

dep 'dw.theconversation.edu.au app', :env, :domain, :app_user, :app_root, :key do
  requires [
    'cronjobs'.with(env),
    'minutely.cronjob'.with(env), # Also hook in per-minute cron tasks on the DW.

    'benhoskings:rack app'.with(
      :env => env,
      :domain => domain,
      :username => app_user,
      :enable_https => 'no'
    ),

    'benhoskings:existing postgres db'.with(
      :username => app_user,
      :db_name => "tc_dw_#{env}"
    )
  ]
end

dep 'dw.theconversation.edu.au packages' do
  requires [
    'curl.lib',
    'benhoskings:running.nginx',
    'dw.theconversation.edu.au common packages'
  ]
end

dep 'dw.theconversation.edu.au dev' do
  requires 'dw.theconversation.edu.au common packages'
end

dep 'dw.theconversation.edu.au common packages' do
  requires [
    'postgres.bin',
    'socat.bin' # for DB tunnelling
  ]
end
