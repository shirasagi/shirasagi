module SS::UserImportValidator
  extend ActiveSupport::Concern

  included do
    attr_accessor :imported_general_sys_roles
    validate :validate_imported_general_sys_roles, if: ->{ imported_general_sys_roles.present? }
  end

  private

  def validate_imported_general_sys_roles
    imported_general_sys_roles.each do |role|
      next if role.general?
      errors.add :base, I18n.t("errors.messages.include_not_general_sys_roles", name: role.name)
    end
  end
end
