dep 'ssl cert in place', :nginx_prefix, :domain, :cert_path, :template => 'benhoskings:nginx' do
  nginx_prefix.default('/opt/nginx')
  cert_path.default('~/current/config/dollhouse/assets/certs')
  def names
    %w[key crt].map {|ext| "#{domain}.#{ext}" }
  end
  met? {
    names.all? {|name| (cert_path / name).exists? }
  }
  before {
    sudo "mkdir -p #{cert_path}"
  }
  meet {
    names.each {|name| sudo "cp '#{cert_path / name}' #{cert_path.to_s.end_with('/')}" }
  }
end
