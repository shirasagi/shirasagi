namespace :ss do
  task delete_access_tokens: :environment do
    puts "delete access tokens"
    SS::AccessToken.where(expiration_date: { '$lt' => Time.zone.now }).destroy
  end
end
