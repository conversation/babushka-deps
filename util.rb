require 'uri'

module Util
  def self.database_name(root, env)
    config = YAML.load_file(root / 'config/database.yml')
    raise "There is no database.yml file" unless config

    if database = config.dig(env.to_s, 'database')
      database
    elsif url = config.dig(env.to_s, 'url')
      URI.parse(url).path.gsub(/^\//, '')
    else
      raise "There is no database defined in database.yml"
    end
  end

  def self.minor_version(version)
    v = version.to_s.scan(/^\d+\.\d/).first.to_f
    # Special-case version 10.x as it is installed everywhere without the minor
    # version number.
    v >= 10 && v < 11 ? "10" : v.to_s
  end

  def self.up_to_date?(dependency, source_name, dest)
    source = dependency.load_path.parent / source_name
    Babushka::Renderable.new(dest).from?(source) && Babushka::Renderable.new(dest).clean?
  end
end
