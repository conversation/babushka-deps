meta :logrotate do
  accepts_value_for :renders
  accepts_value_for :as
  template {
    requires 'logrotate.bin'
    def conf_dest
      %w[
        /usr/local/etc/logrotate.d
        /etc/logrotate.d
      ].detect {|path|
        path.p.exists?
      } / as
    end
    met? {
      Babushka::Renderable.new(conf_dest).from?(dependency.load_path.parent / renders)
    }
    meet {
      render_erb renders, :to => conf_dest, :sudo => true
    }
  }
end

dep 'rack.logrotate', :username do
  renders "logrotate/rack.conf"
  as username
end
