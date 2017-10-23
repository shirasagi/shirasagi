namespace :ss do
  task :write_nginx_config => :environment do
    SS::Nginx::Configuration.write
  end
end
