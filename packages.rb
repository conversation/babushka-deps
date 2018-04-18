dep "aptitude.bin"

dep "apt-transport-https.bin" do
  met? { "/usr/lib/apt/methods/https".p.exists? }
end

dep "aspell.bin"

dep "aspell dictionary.lib" do
  requires "aspell.bin"
  installs do
    on :linux, "aspell-en", "aspell-fr", "aspell-id", "aspell-es", "libaspell-dev"
    otherwise []
  end
end

dep "bundler.gem" do
  provides "bundle"
end

dep "collectd.bin" do
  met? do
    log_shell("checking for collectd", "which collectd")
  end

  meet do
    # specify the install command directly to prevent all the recommended packages being installed
    log_shell("installing collectd", "apt-get install collectd collectd-dev --no-install-recommends -y", sudo: true)
  end
end

dep "nodejs.bin", :version do
  version.default!("6.10")
  requires_when_unmet do
    on :apt, "keyed apt source".with(
      uri: "https://deb.nodesource.com/node_6.x",
      release: "xenial",
      repo: "main",
      key_sig: "68576280",
      key_uri: "https://deb.nodesource.com/gpgkey/nodesource.gpg.key"
    )
  end
  installs do
    via :apt, "nodejs"
    via :brew, "node"
  end
  provides "node ~> #{version}"
end

dep "slack-cli.npm", :version do
  version.default!("1.0.18")
  installs "slack-cli = #{version}"
  requires "nodejs.bin"
  provides "slackcli"
end

dep "yarn.npm", :version do
  version.default!("1.2.1")
  installs "yarn = #{version}"
  requires "nodejs.bin"
  provides "yarn = #{version}"
end

dep "coffeescript.bin", :version do
  version.default!("1.4.0")
  requires "nodejs.bin"
  provides "coffee >= #{version}"
end

dep "curl.lib" do
  installs do
    on :osx, [] # It's provided by the system.
    via :apt, "libcurl4-openssl-dev"
    otherwise "curl" # Assume it's part of curl.
  end
end

dep "fastly.gem" do
  provides []
end

dep "git-smart.gem" do
  provides %w[git-smart-log git-smart-merge git-smart-pull]
end

dep "htop.bin"

dep "imagemagick.bin" do
  provides %w[compare animate convert composite conjure import identify stream display montage mogrify]
end

dep "iotop.bin"

dep "jnettop.bin"

dep "libxml.lib" do
  installs do
    via :apt, "libxml2-dev"
  end
end

dep "libxslt.lib" do
  installs { via :apt, "libxslt1-dev" }
end

dep "edit.lib" do
  installs "libedit-dev"
end

dep "ffi.lib" do
  installs { via :apt, "libffi-dev" }
end

dep "host.bin"

dep "jq.bin"

dep "logrotate.bin"

dep "lsof.bin"

dep "man.bin"

dep "memcached.bin"

dep "nc.bin"

dep "nmap.bin"

dep "pcre.lib" do
  installs "libpcre3-dev"
end

dep "libtag.lib" do
  installs do
    via :apt, "libtag1-dev"
    via :brew, "taglib"
  end
end

dep "pngquant.bin"

dep "pv.bin"

dep "python-dateutil.lib"

dep "readline.lib" do
  installs do
    on :lenny, "libreadline5-dev"
    via :apt, "libreadline6-dev"
  end
end

dep "qt-dev.lib" do
  installs do
    on :apt, "libqt4-dev", "libqtwebkit-dev", "qt4-qmake"
  end
end

dep "raca.gem" do
  provides []
end

dep "rcconf.bin" do
  requires "whiptail.bin"
end

dep "redis-server.bin"

dep "rsyslog-gnutls.bin" do
  met? { "/usr/lib/rsyslog/lmnsd_gtls.so".p.exists? }
end

dep "s3cmd.bin" do
  requires "whiptail.bin"
end

dep "sasl.lib" do
  installs do
    via :brew, "libsasl2"
    via :apt, "libsasl2-dev"
  end
end

dep "selinux.lib" do
  installs "libselinux1-dev"
end

dep "silversearcher.bin" do
  provides "ag"
end

dep "sshd.bin" do
  installs do
    via :apt, "openssh-server"
  end
end

dep "ssl.lib" do
  installs do
    via :apt, "libssl-dev"
    via :yum, "openssl-devel"
  end
end

dep "tidy.bin"

dep "tmux.bin"

dep "traceroute.bin"

dep "tree.bin"

dep "trickle.bin"

dep "ufw.bin"

dep "unbound.bin" do
  met? do
    in_path?("unbound")
  end

  meet do
    env = "env DEBCONF_TERSE='yes' DEBIAN_PRIORITY='critical' DEBIAN_FRONTEND='noninteractive'"
    log_shell("installing unbound", "#{env} apt-get install -y -o Dpkg::Options::='--force-confold' unbound", sudo: true)
  end
end

dep "vim.bin"

dep "whiptail.bin"

dep "yaml.lib" do
  installs do
    via :brew, "libyaml"
    via :apt, "libyaml-dev"
  end
end

dep "zlib.lib" do
  installs do
    via :apt, "zlib1g-dev"
    via :yum, "zlib-devel"
  end
end
