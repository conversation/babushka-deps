dep 'theconversation.org.uk system', :app_user, :key do
end

dep 'theconversation.org.uk app', :env, :host, :domain, :app_user, :app_root, :key do
  requires [
    'vhost enabled.nginx'.with(
      :type => 'static',
      :listen_host => host,
      :domain => domain,
      :path => app_root
    )
  ]
end

dep 'theconversation.org.uk packages' do
end

dep 'theconversation.org.uk dev' do
end
