namespace :ss do
  task delete_access_tokens: :environment do
    puts "delete access tokens"
    SS::DeleteAccessTokensJob.perform_now
  end

  task delete_sso_tokens: :environment do
    puts "delete sso tokens"
    SS::DeleteSSOTokensJob.perform_now
  end
end
