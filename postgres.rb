dep 'read-only db permissions', :db_name, :username, :check_table do
  check_table.default!('users')
  requires 'benhoskings:postgres access'.with(username)
  met? { shell? "psql #{db_name} -c 'SELECT id FROM #{check_table} LIMIT 1'", :sudo => username }
  meet { sudo %Q{psql #{db_name} -c 'GRANT SELECT ON ALL TABLES IN SCHEMA "public" TO "#{username}"'}, :as => 'postgres' }
end

dep 'postgres extension', :username, :db_name, :extension do
  requires 'benhoskings:existing postgres db'.with(username, db_name)

  def psql cmd
    shell("psql #{db_name} -t", :as => 'postgres', :input => cmd).strip
  end

  met? {
    psql(%{SELECT count(*) FROM pg_extension WHERE extname = '#{extension}'}).to_i > 0
  }
  meet {
    psql(%{CREATE EXTENSION "#{extension}"})
  }
end
