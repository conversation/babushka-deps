dep 'ssl cert in place', :nginx_prefix, :domain, :env, :cert_source, :template => 'nginx' do
  nginx_prefix.default!('/opt/nginx')
  cert_source.default('~/current/config/certs')

  def cert_name
    env == 'staging' ? '*.tc-dev.net' : domain
  end

  def source_file ext
    cert_source / "#{cert_name}.#{ext}"
  end

  def dest_file ext
    cert_path / "#{domain}.#{ext}"
  end

  met? {
    %w[key crt].all? {|ext|
      shell? "cmp '#{source_file(ext)}' '#{dest_file(ext)}'", :sudo => true
    }
  }
  meet {
    sudo "mkdir -p #{cert_path}"
    %w[key crt].all? {|ext|
      sudo "cp '#{source_file(ext)}' '#{dest_file(ext)}'"
      sudo "chmod 600 '#{dest_file(ext)}'"
    }
    restart_nginx
  }
end

dep 'public key' do
  met? { '~/.ssh/id_dsa.pub'.p.grep(/^ssh-dss/) }
  meet { log shell("ssh-keygen -t dsa -f ~/.ssh/id_dsa -N ''") }
end

dep 'secured ssh logins' do
  def ssh_conf_path file
    "/etc#{'/ssh' if Babushka.host.linux?}/#{file}_config"
  end
  requires 'sshd.bin'
  met? {
    output = raw_shell('ssh -o StrictHostKeyChecking=no -o PasswordAuthentication=no nonexistentuser@localhost').stderr
    if output.downcase['connection refused']
      log_ok "sshd doesn't seem to be running."
    elsif (auth_methods = output.scan(/Permission denied \((.*)\)\./).join.split(',')).empty?
      log_error "sshd returned unexpected output."
    else
      (auth_methods == %w[publickey]).tap {|result|
        log "sshd #{'only ' if result}accepts #{auth_methods.to_list} logins.", :as => (:ok if result)
      }
    end
  }
  meet {
    [
      'PasswordAuthentication',
      'ChallengeResponseAuthentication'
    ].each {|option|
      shell("sed -i'' -e 's/^[# ]*#{option}\\W*\\w*$/#{option} no/' #{ssh_conf_path(:sshd)}")
    }

    shell "/etc/init.d/ssh restart"
  }
end
