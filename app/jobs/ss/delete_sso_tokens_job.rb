# SSOトークンの掃除
class SS::DeleteSSOTokensJob < SS::ApplicationJob
  def perform
    SS::SSOToken.and_unavailable.destroy_all
  end
end
