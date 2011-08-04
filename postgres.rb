dep 'read-only db permissions' do
  requires 'benhoskings:postgres access'
  met? { shell "psql #{var(:db_name)} -c 'SELECT id FROM messages LIMIT 1'" }
  meet { sudo %Q{psql #{var(:db_name)} -c 'GRANT SELECT ON ALL TABLES IN SCHEMA "public" TO "#{var(:username)}"'}, as: 'postgres' }
end
