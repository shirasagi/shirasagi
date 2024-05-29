# アクセストークンの掃除
class SS::DeleteAccessTokensJob < SS::ApplicationJob
  def perform
    SS::AccessToken.where(expiration_date: { '$lt' => Time.zone.now }).destroy_all
  end
end
