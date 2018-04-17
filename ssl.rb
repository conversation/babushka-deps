meta :ssl do
  def cert_dir
    "/etc/ssl/certs".p
  end

  def key_dir
    "/etc/ssl/private".p
  end

  def cert_name
    "STAR_#{domain.to_s.gsub('.', '_')}"
  end

  def dest_cert_path
    cert_dir / "#{cert_name}.pem"
  end

  def dest_key_path
    key_dir / "#{cert_name}.key"
  end
end

dep "ssl cert downloaded", :dnsimple_token, :domain, template: "ssl" do
  domain.default!("theconversation.com")

  met? do
    # We need to check the `dest_key_path` using sudo because it's in a private
    # directory.
    dest_cert_path.exists? && shell?("ls '#{dest_key_path}'", sudo: true)
  end

  meet do
    sudo "curl -H 'Authorization: Bearer #{dnsimple_token}' -H 'Accept: application/json' -s 'https://api.dnsimple.com/v2/4840/domains/#{domain}/certificates/44929/download' | jq -r '.data.server, .data.chain[0], .data.root' > #{dest_cert_path}"
    sudo "curl -H 'Authorization: Bearer #{dnsimple_token}' -H 'Accept: application/json' -s 'https://api.dnsimple.com/v2/4840/domains/#{domain}/certificates/44929/private_key' | jq -r '.data.private_key' > #{dest_key_path}"
  end
end

dep "ssl cert in place", :domain, :env, :cert_dir, template: "nginx" do
  cert_dir.default!("~/current/config/certs")

  def cert_path
    "/etc/ssl/certs".p
  end

  def key_path
    "/etc/ssl/private".p
  end

  def src_cert_path
    cert_dir / "#{domain}.crt"
  end

  def src_key_path
    cert_dir / "#{domain}.key"
  end

  def dest_cert_path
    cert_path / "#{domain}.crt"
  end

  def dest_key_path
    key_path / "#{domain}.key"
  end

  met? do
    # We need to check the `dest_key_path` using sudo because it's in a private
    # directory.
    dest_cert_path.exists? && shell?("ls '#{dest_key_path}'", sudo: true)
  end

  meet do
    sudo "ln -sf '#{src_cert_path}' '#{dest_cert_path}'"
    sudo "ln -sf '#{src_key_path}' '#{dest_key_path}'"
  end
end

dep "public key" do
  met? { "~/.ssh/id_dsa.pub".p.grep(/^ssh-dss/) }
  meet { log shell("ssh-keygen -t dsa -f ~/.ssh/id_dsa -N ''") }
end

dep "secured ssh logins" do
  def ssh_conf_path(file)
    "/etc#{'/ssh' if Babushka.host.linux?}/#{file}_config"
  end

  requires "sshd.bin"

  met? do
    output = raw_shell("ssh -o StrictHostKeyChecking=no -o PasswordAuthentication=no nonexistentuser@localhost").stderr
    if output.downcase["connection refused"]
      log_ok "sshd doesn't seem to be running."
    elsif (auth_methods = output.scan(/Permission denied \((.*)\)\./).join.split(",")).empty?
      log_error "sshd returned unexpected output."
    else
      (auth_methods == %w[publickey]).tap do |result|
        log "sshd #{'only ' if result}accepts #{auth_methods.to_list} logins.", as: (:ok if result)
      end
    end
  end

  meet do
    [
      "PasswordAuthentication",
      "ChallengeResponseAuthentication"
    ].each do |option|
      shell("sed -i'' -e 's/^[# ]*#{option}\\W*\\w*$/#{option} no/' #{ssh_conf_path(:sshd)}")
    end

    shell "systemctl restart ssh"
  end
end
