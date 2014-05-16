# coding: utf-8
namespace :ss do
  task :crypt => :environment  do
    puts "Crypt password ..."
    puts SS::Crypt.crypt(ENV["value"])
  end
  
  task :encrypt => :environment  do
    puts "Encrypt password ..."
    puts SS::Crypt.encrypt(ENV["value"])
  end
  
  namespace :user do
    task :create => :environment do
      puts "Create user ..."
      data = eval(ENV["data"])
      data[:in_password] = data[:password]
      data.delete(:password)
      item = SS::User.create data
      puts item.errors.empty? ? "  created  #{item.name}" : item.errors.full_messages.join("\n  ")
    end
  end
  
  namespace :site do
    task :create => :environment do
      puts "Create site ..."
      item = SS::Site.create eval(ENV["data"])
      puts item.errors.empty? ? "  created  #{item.name}" : item.errors.full_messages.join("\n  ")
    end
  end
end
