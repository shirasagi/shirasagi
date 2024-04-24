module SS::Addon::SSO::User
  # extend SS::Addon
  extend ActiveSupport::Concern

  included do
    validate :validate_sso_password
  end

  private

  def validate_sso_password
    return true if self.in_password.blank?
    return true if !self.type_sso?

    self.errors.add :base, :unable_to_modify_sso_users_password
  end
end
