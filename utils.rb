dep 'ssl cert in place', :template => 'benhoskings:nginx' do
  def names
    %w[key crt].map {|ext| "#{var(:domain)}.#{ext}" }
  end
  met? {
    names.all? {|name| (nginx_cert_path / name).exists? }
  }
  before {
    sudo "mkdir -p #{nginx_cert_path}"
  }
  meet {
    names.each {|name| sudo "cp '#{var(:cert_path) / name}' #{nginx_cert_path.to_s.end_with('/')}" }
  }
end
