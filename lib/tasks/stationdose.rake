namespace :stationdose do

  task :get_seeds do
    %x(heroku pg:backups capture)
    %x(curl -o latest.dump `heroku pg:backups public-url`)
    %x(pg_restore --verbose --clean --no-acl --no-owner -h localhost -d stationdoseadmin_development latest.dump)
    %x(rake db:data:dump)
  end
end
