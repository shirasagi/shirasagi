namespace :ss do
  task :write_nginx_config => :environment do
    conf = SS::Nginx::Config.new.write
    puts "Nginx config written."
    puts "- #{conf.virtual_conf}"
  end
end
