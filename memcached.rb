dep "memcached" do
  requires "memcached configured"
end

dep "memcached configured" do
  requires "memcached.bin", "nc.bin"
  def current_settings
    Hash[
      shell("nc 127.0.0.1 11211", input: "stats\n").split("\n").
        collapse(/^STAT /).
        map {|l| l.strip.split(/\W/, 2) }
    ]
  end

  # on systems with >= 16Gb of RAM (like our production boxes), allocate lots of RAM to
  # memcached. Otherwise stick with something smaller
  def cache_size
    if installed_ram_kb >= 16_000_000
      4096
    else
      64
    end
  end

  def installed_ram_kb
    shell("cat /proc/meminfo").split("\n").
      collapse(/^MemTotal/).
      map { |l| l[/(\d+)/,1].to_i }.
      first
  end

  def megabytes_to_bytes(mb)
    mb.to_i * 1_048_576
  end

  def expected_settings
    # Some settings that we customise, and hence use to test whether
    # our config has been applied.
    {
      "limit_maxbytes" => megabytes_to_bytes(cache_size).to_s
    }
  end
  met? do
    current_settings.slice(*expected_settings.keys) == expected_settings
  end
  meet do
    render_erb "memcached/memcached.conf.erb", to: "/etc/memcached.conf"
    log_shell "Restarting memcached", "/etc/init.d/memcached restart"
    sleep 1 # Wait a moment for memcached to start.
  end
end
