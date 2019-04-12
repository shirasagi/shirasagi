module SS::UserImportValidator
  extend ActiveSupport::Concern

  included do
    # sys_role_ids
    attr_accessor :imported_general_sys_roles
    validate :validate_imported_general_sys_roles, if: ->{ imported_general_sys_roles.present? }

    # group_ids
    attr_accessor :imported_group_keys, :imported_groups
    validate :validate_imported_groups, if: ->{ imported_group_keys.present? }

    # in_title_id
    attr_accessor :imported_gws_user_title_keys, :imported_gws_user_title
    validate :validate_imported_gws_user_title, if: ->{ imported_gws_user_title_keys.present? }
  end

  private

  def validate_imported_general_sys_roles
    imported_general_sys_roles.each do |role|
      next if role.general?
      errors.add :base, I18n.t("errors.messages.include_not_general_sys_roles", name: role.name)
    end
  end

  def validate_imported_groups
    imported_group_names = imported_groups.pluck(:name)
    imported_group_keys.each_with_index do |key, i|
      next if key == imported_group_names[i]
      errors.add :base, I18n.t("errors.messages.not_found_group", name: key)
    end
  end

  def validate_imported_gws_user_title
    return if imported_gws_user_title
    errors.add :base, I18n.t("errors.messages.not_found_user_title", code: imported_gws_user_title_keys)
  end
end
