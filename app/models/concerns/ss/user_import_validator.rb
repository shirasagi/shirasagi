module SS::UserImportValidator
  extend ActiveSupport::Concern

  included do
    # sys_role_ids
    attr_accessor :imported_sys_role_keys, :imported_sys_roles
    validate :validate_imported_sys_roles, if: ->{ imported_sys_role_keys.present? }

    # gws_role_ids
    attr_accessor :imported_gws_role_keys, :imported_gws_roles
    validate :validate_imported_gws_roles, if: ->{ imported_gws_role_keys.present? }

    # webmail_role_ids
    attr_accessor :imported_webmail_role_keys, :imported_webmail_roles
    validate :validate_imported_webmail_roles, if: ->{ imported_webmail_role_keys.present? }

    # group_ids
    attr_accessor :imported_group_keys, :imported_groups
    validate :validate_imported_groups, if: ->{ imported_group_keys.present? }

    # in_title_id
    attr_accessor :imported_gws_user_title_key, :imported_gws_user_title
    validate :validate_imported_gws_user_title, if: ->{ imported_gws_user_title_key.present? }
  end

  private

  def validate_imported_sys_roles
    imported_role_names = imported_sys_roles.pluck(:name)
    imported_sys_role_keys.each do |key|
      next if imported_role_names.include?(key)
      errors.add :base, I18n.t("errors.messages.not_found_sys_role", name: key)
    end

    # only import general sys roles
    imported_sys_roles.each do |role|
      next if role.general?
      errors.add :base, I18n.t("errors.messages.include_not_general_sys_roles", name: role.name)
    end
  end

  def validate_imported_gws_roles
    imported_role_names = imported_gws_roles.pluck(:name)
    imported_gws_role_keys.each do |key|
      next if imported_role_names.include?(key)
      errors.add :base, I18n.t("errors.messages.not_found_gws_role", name: key)
    end
  end

  def validate_imported_webmail_roles
    imported_role_names = imported_webmail_roles.pluck(:name)
    imported_webmail_role_keys.each do |key|
      next if imported_role_names.include?(key)
      errors.add :base, I18n.t("errors.messages.not_found_webmail_role", name: key)
    end
  end

  def validate_imported_groups
    imported_group_names = imported_groups.pluck(:name)
    imported_group_keys.each do |key|
      next if imported_group_names.include?(key)
      errors.add :base, I18n.t("errors.messages.not_found_group", name: key)
    end
  end

  def validate_imported_gws_user_title
    return if imported_gws_user_title
    errors.add :base, I18n.t("errors.messages.not_found_user_title", code: imported_gws_user_title_key)
  end
end
