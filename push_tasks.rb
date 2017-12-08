dep "schema up to date.push", :ref, :remote, :env do
  def db_name
    config = YAML.load_file("config/database.yml".p)[env.to_s]
    config["database"] || config["url"]
  end

  def dump_schema_cmd
    pg_dump = "pg_dump #{db_name} --no-privileges --no-owner"
    # Dump the schema, and then the schema_migrations table including its contents.
    "#{pg_dump} --schema-only -T schema_migrations && #{pg_dump} -t schema_migrations"
  end

  def fetch_schema
    shell "ssh #{remote_host} '#{dump_schema_cmd}' > db/schema.sql.tmp"
  end

  def move_schema_into_place
    shell "mv db/schema.sql.tmp db/schema.sql"
  end
  setup do
    # We fetch to a temporary file first and move it into place on ssh
    # success, because a failed connection can result in an empty file.
    fetch_schema && move_schema_into_place
  end

  met? do
    Babushka::GitRepo.new(".").clean?
  end

  meet do
    shell "git add db/schema.sql && git commit db/schema.sql -m 'Update DB schema after deploying #{shell("git rev-parse --short #{ref}")}.'"
  end
end
