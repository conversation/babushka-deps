dep "ruby.src", :version, :patchlevel do
  def version_group
    version.to_s.scan(/^\d\.\d/).first
  end

  def filename
    if version.to_s >= "2.1.0"
      "ruby-#{version}.tar.gz"
    else
      "ruby-#{version}-#{patchlevel}.tar.gz"
    end
  end

  requires_when_unmet "curl.lib", "ffi.lib", "readline.lib", "ssl.lib", "yaml.lib", "zlib.lib"

  source "http://cache.ruby-lang.org/pub/ruby/#{version_group}/#{filename}"
  provides "ruby == #{version}#{patchlevel}", "gem", "irb"
  configure_args "--disable-install-doc",
    "--with-readline-dir=#{Babushka.host.pkg_helper.prefix}",
    "--with-libyaml-dir=#{Babushka.host.pkg_helper.prefix}"
  build do
    log_shell "build", "make -j#{Babushka.host.cpus}"
  end
  postinstall do
    # The ruby <1.9.3 installer skips bin/* when the build path contains a dot-dir.
    shell "cp bin/* #{prefix / 'bin'}", sudo: Babushka::SrcHelper.should_sudo?
  end
end
