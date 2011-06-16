dep 'dashboard db permissions' do
  requires 'benhoskings:postgres access'
  met? { shell "psql #{var(:dashboard_db)} -c 'SELECT id FROM messages LIMIT 1'" }
  meet { sudo %Q{psql #{var(:dashboard_db)} -c 'GRANT SELECT ON ALL TABLES IN SCHEMA "public" TO "#{var(:username)}"'}, as: 'postgres' }
end
