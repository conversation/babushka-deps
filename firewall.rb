dep "firewall rules" do
  requires "ufw.bin"

  met? do
    shell? %q(ufw status | grep "Status: active")
  end

  meet do
    shell "ufw allow ssh/tcp"
    shell "ufw allow http/tcp"
    shell "ufw allow https/tcp"

    # Allow postgres connections from docker.
    shell "ufw allow in on docker_gwbridge proto tcp from 172.16.0.0/12 to any port 5432"

    # Allow postgres connections from VLAN.
    shell "ufw allow in on eth1 proto tcp from 10.30.0.0/15 to any port 5432"

    # Allow collectd connections from docker.
    shell "ufw allow in on docker_gwbridge proto any from 172.16.0.0/12 to any port 8125"

    shell "ufw --force enable"
  end
end
