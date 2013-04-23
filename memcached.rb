dep 'memcached' do
  requires 'memcached configured'
end

dep 'memcached configured' do
  requires 'memcached.bin', 'nc.bin'
  def psql cmd
    shell("psql postgres -t", :as => 'postgres', :input => cmd).strip
  end
  def current_settings
    Hash[
      shell('nc 127.0.0.1 11211', :input => "stats\n").split("\n").
        collapse(/^STAT /).
        map {|l| l.strip.split(/\W/, 2) }
    ]
  end
  def expected_settings
    # Some settings that we customise, and hence use to test whether
    # our config has been applied.
    {
      'limit_maxbytes' => '1073741824' # 1GB
    }
  end
  met? {
    current_settings.slice(*expected_settings.keys) == expected_settings
  }
  meet {
    render_erb "memcached/memcached.conf.erb", :to => "/etc/memcached.conf"
    log_shell "Restarting memcached", "/etc/init.d/memcached restart"
    sleep 1 # Wait a moment for memcached to start.
  }
end
