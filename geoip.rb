dep 'geoip.bin' do
  installs {
    via :apt, 'geoip-bin', 'libgeoip-dev'
    otherwise 'geoip'
  }
  provides 'geoiplookup', 'geoiplookup6', 'geoipupdate'
end

dep 'geoip database', :source, :app_root do
  source.default!('http://c10736763.r63.cf2.rackcdn.com/GeoLiteCity.dat.gz')
  app_root.default('~/current')
  def local_path
    app_root / 'db' / File.basename(source.to_s.chomp('.gz'))
  end
  met? {
    local_path.p.exists?
  }
  meet {
    Babushka::Resource.get source do |download_path|
      shell "mkdir -p #{local_path}"
      shell "gzip -dc #{download_path} > #{local_path}"
    end
  }
end
