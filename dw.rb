dep 'dw.theconversation.edu.au system', :app_user, :key

dep 'dw.theconversation.edu.au app', :env, :domain, :app_user, :app_root, :key do
  requires [
    'benhoskings:rack app'.with(
      :env => env,
      :domain => domain,
      :username => app_user
    ),

    'benhoskings:existing postgres db'.with(
      :username => app_user,
      :db_name => "tc_dw_#{env}"
    )
  ]
end

dep 'dw.theconversation.edu.au packages' do
  requires [
    'postgres'.with('9.2'),
    'curl.lib',
    'running.nginx',
    'dw.theconversation.edu.au common packages'
  ]
end

dep 'dw.theconversation.edu.au dev' do
  requires 'dw.theconversation.edu.au common packages'
end

dep 'dw.theconversation.edu.au common packages' do
  requires [
    'postgres.bin'.with('9.2'),
    'socat.bin' # for DB tunnelling
  ]
end
