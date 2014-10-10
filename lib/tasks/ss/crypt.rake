namespace :ss do
  task :crypt => :environment  do
    puts SS::Crypt.crypt(ENV["value"])
  end

  task :encrypt => :environment  do
    puts SS::Crypt.encrypt(ENV["value"])
  end
end
