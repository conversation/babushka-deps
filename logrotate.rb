meta :logrotate do
  accepts_value_for :renders
  accepts_value_for :as
  template do
    requires "logrotate.bin"

    def conf_dest
      %w[
        /usr/local/etc/logrotate.d
        /etc/logrotate.d
      ].detect do |path|
        path.p.exists?
      end / as
    end

    met? do
      Babushka::Renderable.new(conf_dest).from?(dependency.load_path.parent / renders)
    end

    meet do
      render_erb renders, to: conf_dest, sudo: true
    end
  end
end

dep "rack.logrotate", :username do
  renders "logrotate/rack.conf"
  as username
end
