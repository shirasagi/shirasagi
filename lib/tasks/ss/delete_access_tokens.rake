namespace :ss do
  task delete_access_tokens: :environment do
    puts "delete access tokens"
    SS::AccessToken.where(expiration_date: { '$lt' => Time.zone.now }).destroy_all
  end

  task delete_sso_tokens: :environment do
    puts "delete sso tokens"
    SS::SSOToken.and_unavailable.destroy_all
  end
end
