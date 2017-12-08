dep "geoip.bin" do
  installs do
    via :apt, "geoip-bin", "libgeoip-dev"
    otherwise "geoip"
  end
  provides "geoiplookup", "geoiplookup6"
end

dep "geoip database", :source, :app_root do
  # we download a cached copy of this database from our cloud files account to
  # avoid hitting usage limits on the upstream server. Don't forget to occasionally
  # update the cached version with a fresh file from http://dev.maxmind.com/geoip/legacy/geolite/
  source.default!("http://c10736763.r63.cf2.rackcdn.com/GeoLiteCity.dat.gz")
  app_root.default("~/current")
  def local_path
    app_root / "db" / File.basename(source.to_s.chomp(".gz"))
  end
  met? do
    local_path.p.exists?
  end
  meet do
    Babushka::Resource.get source do |download_path|
      shell "mkdir -p #{local_path.parent}"
      shell "gzip -dc #{download_path} > #{local_path}"
    end
  end
end

dep "as database", :source, :app_root do
  # we download a cached copy of this database from our cloud files account to
  # avoid hitting usage limits on the upstream server. Don't forget to occasionally
  # update the cached version with a fresh file from http://dev.maxmind.com/geoip/legacy/geolite/
  source.default!("http://c10736763.r63.cf2.rackcdn.com/GeoIPASNum.dat.gz")
  app_root.default("~/current")
  def local_path
    app_root / "db" / File.basename(source.to_s.chomp(".gz"))
  end
  met? do
    local_path.p.exists?
  end
  meet do
    Babushka::Resource.get source do |download_path|
      shell "mkdir -p #{local_path.parent}"
      shell "gzip -dc #{download_path} > #{local_path}"
    end
  end
end
