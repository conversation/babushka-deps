dep 'papertrail config' do
  requires [
    'rsyslog-gnutls.bin',
    'papertrail cert'
  ]

  def papertrail_config_src; 'papertrail/papertrail.conf' end
  def papertrail_config_dest; '/etc/rsyslog.d/22-papertrail.conf'; end

  met? { Util.up_to_date?(dependency, papertrail_config_src, papertrail_config_dest) }
  meet { render_erb(papertrail_config_src, to: papertrail_config_dest) }
  after { Util.restart_service('rsyslog') }
end

dep 'papertrail cert' do
  def papertrail_cert_src; 'papertrail/papertrail-bundle.pem' end
  def papertrail_cert_dest; '/etc/papertrail-bundle.pem'; end

  met? { Util.up_to_date?(dependency, papertrail_cert_src, papertrail_cert_dest) }
  meet { render_erb(papertrail_cert_src, to: papertrail_cert_dest) }
end
