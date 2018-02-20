dep "provision ci", :keys, :host, :user, :buildkite_token do
  keys.default!((dependency.load_path.parent / "config/authorized_keys").read)
  user.default!("buildkite-agent")

  requires_when_unmet "public key in place".with(host, keys)
  requires_when_unmet "babushka bootstrapped".with(host)

  met? { false }

  meet do
    ssh("root@#{host}") do |h|
      h.babushka(
        "conversation:ci provisioned",
        keys: keys,
        user: user,
        buildkite_token: buildkite_token
      )
    end
  end
end

dep "ci prepared" do
  requires [
    "common:set.locale".with(locale_name: "en_AU"),
    "ruby.src".with(version: "2.4.2", patchlevel: "p198"),
  ]
end

dep "ci provisioned", :user, :keys, :buildkite_token do
  requires [
    "ci prepared",
    "localhost hosts entry",
    "lax host key checking",
    "tc common packages",
    "sharejs common packages",
    "counter common packages",
    "jobs common packages",
    "ci packages",
    "ci firewall rules",
    "buildkite-agent installed".with(buildkite_token: buildkite_token),
    "postgres access".with(username: user, flags: "-sdrw"),
    "docker-gc"
  ]
end

dep "ci packages" do
  requires [
    "ack-grep.bin",
    "silversearcher.bin",
    "chromedriver",
    "docker.bin",
    "docker-compose",
    "firefox.bin",
    "geckodriver",
    "nodejs.bin",
    "phantomjs",
    "python.bin",
    "redis-server.bin",
    "sasl.lib",
    "slack-cli.npm",
    "terraform",
    "tmux.bin",
    "ufw.bin",
    "xvfb.bin"
  ]
end

dep "ci firewall rules" do
  met? do
    shell? %q(ufw status | grep "Status: active")
  end

  meet do
    shell "ufw allow ssh/tcp"
    shell "ufw allow postgresql/tcp"
    shell "ufw --force enable"
  end
end

dep "phantomjs", :version do
  version.default!("2.1.1")

  def phantomjs_uri
    if Babushka.host.linux?
      "https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-#{version}-linux-x86_64.tar.bz2"
    elsif Babushka.host.osx?
      "https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-#{version}-macosx.zip"
    else
      unmeetable! "Not sure where to download a phantomjs binary for #{Babushka.base.host}."
    end
  end

  met? do
    in_path? "phantomjs >= #{version}"
  end

  meet do
    Babushka::Resource.extract phantomjs_uri do |_archive|
      shell "cp -r . /usr/local/phantomjs"
      shell "ln -fs /usr/local/phantomjs/bin/phantomjs /usr/local/bin"
    end
  end
end

dep "ack-grep.bin" do
  provides "ack"
end

dep "python.bin" do
  provides "python"
end

dep "xvfb.bin" do
  provides "Xvfb"
end

dep "firefox.bin", :version do
  version.default!("58.0")

  met? do
    in_path? "firefox >= #{version}"
  end
end

dep "geckodriver", :version do
  version.default!("0.19.1")

  def geckodriver_uri
    if Babushka.host.linux?
      "https://github.com/mozilla/geckodriver/releases/download/v#{version}/geckodriver-v#{version}-linux64.tar.gz"
    elsif Babushka.host.osx?
      "https://github.com/mozilla/geckodriver/releases/download/v#{version}/geckodriver-v#{version}-macos.tar.gz"
    else
      unmeetable! "Not sure where to download a geckodriver binary for #{Babushka.base.host}."
    end
  end

  def temp_archive
    "/tmp/geckodriver.tar.gz"
  end

  met? do
    in_path? "geckodriver >= #{version}"
  end

  meet do
    # Babushka::Resource.extract -> .get -> .download method uses curl to download and recursive calls
    # to follow redirects, ending with a invalid filename and a big URL. Calling wget and Babushka::Asset is simpler.
    # https://github.com/benhoskings/babushka/blob/937ed6fd117baa1ba2eda1a59d9e580fe6841097/lib/babushka/resource.rb#L30-L51
    shell "wget #{geckodriver_uri} -O #{temp_archive}"
    Babushka::Asset.for(temp_archive).extract do |_archive|
      shell "mv ./geckodriver /usr/local/bin"
    end
  end
end

dep "chromedriver", :version do
  version.default!("2.35")

  def chromedriver_uri
    if Babushka.host.linux?
      "https://chromedriver.storage.googleapis.com/#{version}/chromedriver_linux64.zip"
    elsif Babushka.host.osx?
      "https://chromedriver.storage.googleapis.com/#{version}/chromedriver_mac64.zip"
    else
      unmeetable! "Not sure where to download a chromedriver binary for #{Babushka.base.host}."
    end
  end

  met? do
    in_path? "chromedriver >= #{version}"
  end

  meet do
    Babushka::Resource.extract chromedriver_uri do |_archive|
      shell "mv ./chromedriver /usr/local/bin"
    end
  end
end

dep "terraform", :version do
  version.default!("0.10.2")

  met? do
    in_path? "terraform >= #{version}"
  end

  meet do
    Babushka::Resource.extract "https://releases.hashicorp.com/terraform/0.10.2/terraform_0.10.2_linux_amd64.zip" do
      shell "cp -r terraform /usr/local/bin/terraform"
    end
  end
end
