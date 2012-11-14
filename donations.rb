dep 'donate.theconversation.edu.au system', :app_user, :key

dep 'donate.theconversation.edu.au app', :env, :host, :domain, :app_user, :app_root, :key do
  def db_name
    YAML.load_file(app_root / 'config/database.yml')[env.to_s]['database']
  end

  requires [
    'delayed job'.with(env, app_user),

    'benhoskings:self signed cert.nginx'.with(
      :country => 'AU',
      :state => 'VIC',
      :city => 'Melbourne',
      :organisation => 'The Conversation',
      :domain => domain,
      :email => 'dev@theconversation.edu.au'
    ),

    'rails app'.with(
      :app_name => 'donate',
      :env => env,
      :listen_host => host,
      :domain => domain,
      :username => app_user,
      :path => app_root,
      :data_required => 'yes'
    )
  ]
end

dep 'donate.theconversation.edu.au packages' do
  requires [
    'postgres'.with('9.2'),
    'curl.lib',
    'running.nginx',
    'donate.theconversation.edu.au common packages'
  ]
end

dep 'donate.theconversation.edu.au dev' do
  requires 'donate.theconversation.edu.au common packages'
end

dep 'donate.theconversation.edu.au common packages' do
  requires [
    'bundler.gem',
    'postgres.bin'.with('9.2'),
    'libxml.lib', # for nokogiri
    'libxslt.lib', # for nokogiri
    'coffeescript.src' # for barista
  ]
end
