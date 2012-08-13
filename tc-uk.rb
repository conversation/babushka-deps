dep 'theconversation.org.uk system', :app_user, :key do
end

dep 'theconversation.org.uk app', :env, :domain, :app_user, :app_root, :key do
  requires [
    'vhost enabled.nginx'.with(
      :type => 'static',
      :domain => domain,
      :path => app_root,
      :enable_https => 'no',
      :force_https => 'no'
    )
  ]
end

dep 'theconversation.org.uk packages' do
end

dep 'theconversation.org.uk dev' do
end
