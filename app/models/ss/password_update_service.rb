class SS::PasswordUpdateService
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations
  extend SS::Translation

  attr_accessor :cur_user

  attribute :old_password, :string
  attribute :new_password, :string
  attribute :new_password_again, :string

  delegate :updated, :in_updated=, to: :cur_user

  validates :old_password, presence: true
  validates :new_password, presence: true
  validates :new_password_again, presence: true
  validate :validate_old_password
  validate :validate_new_password_again

  def update_password
    return if invalid?

    cur_user.in_password = new_password
    result = cur_user.save
    SS::Model.copy_errors(cur_user, self) unless result
    result
  end

  private

  def validate_old_password
    return if old_password.blank?
    return if SS::Crypt.crypt(old_password) == cur_user.password

    errors.add :old_password, :mismatch
  end

  def validate_new_password_again
    return if new_password.blank?
    return if new_password_again.blank?
    return if new_password == new_password_again

    attribute = self.class.human_attribute_name(:new_password_again)
    errors.add :new_password, I18n.t("errors.messages.confirmation", attribute: attribute)
  end
end
