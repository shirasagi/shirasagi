namespace :ss do
  task crypt: :environment do
    puts SS::Crypto.crypt(ENV["value"])
  end

  task encrypt: :environment do
    puts SS::Crypto.encrypt(ENV["value"])
  end
end
