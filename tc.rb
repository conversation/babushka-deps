dep 'tc system', :app_user, :key do
  requires [
    'benhoskings:user setup for provisioning'.with("dw.theconversation.edu.au", key), # For DW loads from psql on the counter machine
    'benhoskings:postgres access'.with(:username => "sharejs.theconversation.edu.au"), # For proper DB permissions when the data is restored

    # Temporary: for migrating the app username to theconversation.com.
    'benhoskings:postgres access'.with(:username => "theconversation.edu.au")
  ]
end

dep 'tc app', :env, :host, :domain, :app_user, :app_root, :key do
  def db_name
    YAML.load_file(app_root / 'config/database.yml')[env.to_s]['database']
  end

  requires [
    'delayed job'.with(env, app_user),
    'geoip database'.with(:app_root => app_root),
    'ssl cert in place'.with(:domain => domain, :cert_name => 'theconversation.edu.au'),
    'db restored'.with(
      :env => env,
      :app_user => app_user,
      :db_name => db_name,
      :app_root => app_root
    ),

    'db access'.with(
      :grant => 'ALL PRIVILEGES',
      :db_name => db_name,
      :schema => 'public',
      :username => app_user,
      :check_table => 'content'
    ),

    'schema access'.with(
      :username => app_user,
      :owner_name => 'sharejs.theconversation.edu.au',
      :db_name => db_name,
      :schema_name => 'sharejs',
      :check_table => 'sharejs.article_draft_snapshots'
    ),
    'db access'.with(
      :grant => 'SELECT',
      :db_name => db_name,
      :schema => 'sharejs',
      :username => app_user,
      :check_table => 'sharejs.article_draft_snapshots'
    ),

    'rails app'.with(
      :app_name => 'tc',
      :env => env,
      :listen_host => host,
      :domain => domain,
      :domain_aliases => 'theconversation.com',
      :username => app_user,
      :path => app_root,
      :proxy_host => 'localhost',
      :proxy_port => 9000,
      :data_required => 'yes'
    ),

    # For the dw.theconversation.edu.au -> backup.tc-dev.net psql/ssh connection.
    'db access'.with(
      :db_name => db_name,
      :username => 'dw.theconversation.edu.au',
      :check_table => 'content'
    ),

    'postgres replication monitoring'.with(:test_user => app_user)
  ]

  setup {
    if env == 'production'
      requires 'ssl cert in place'.with(:domain => 'theconversation.com', :cert_name => 'theconversation.com')
    end
  }
end

dep 'tc packages' do
  requires [
    'postgres'.with('9.2'),
    'running.nginx',
    'memcached.bin', # for fragment caching
    'tc common packages',
    'socat.bin' # for DB tunnelling
  ]
end

dep 'tc dev' do
  requires [
    'tc common packages',
    'pv.bin', # for db:production:pull (and it's awesome anyway)
    'phantomjs', # for js testing
    'geoip database'.with(:app_root => '.'),
    'submodules cloned',
    'npm packages installed'.with('vendor/sharejs')
  ]
end

dep 'submodules cloned' do
  met? {
    # Initalised and current submodules are listed with a leading ' '.
    shell('git submodule status').split("\n").all? {|l| l[/^ /] }
  }
  meet {
    shell('git submodule update --init')
  }
end

dep 'tc common packages' do
  requires [
    'bundler.gem',
    'curl.lib',
    'postgres.bin',
    'geoip.bin', # for geoip-c
    'aspell dictionary.lib',
    'coffeescript.src', # for barista
    'tidy.bin', # for upmark preprocessing in MarkdownController
    'imagemagick.bin', # for paperclip
    'libxml.lib', # for nokogiri
    'libxslt.lib' # for nokogiri
  ]
end
