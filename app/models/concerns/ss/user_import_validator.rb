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
    attr_accessor :imported_gws_group
    attr_accessor :imported_cms_groups
    attr_accessor :imported_group_keys, :imported_groups
    validate :validate_imported_groups, if: ->{ imported_group_keys.present? }

    # gws_main_group_id
    attr_accessor :imported_gws_main_group_key, :imported_gws_main_group
    validate :validate_imported_main_group, if: ->{ imported_gws_main_group_key.present? }

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
    if imported_gws_group
      imported_group_names = imported_groups.in_group(imported_gws_group).pluck(:name)
    elsif imported_cms_groups.present?
      imported_group_names = imported_groups.in(id: imported_cms_groups.pluck(:id)).pluck(:name)
    else
      imported_group_names = imported_groups.pluck(:name)
    end

    imported_group_keys.each do |key|
      next if imported_group_names.include?(key)
      errors.add :base, I18n.t("errors.messages.not_found_group", name: key)
    end

    if imported_cms_groups && imported_group_keys.find { |key| key.start_with?(*imported_cms_groups.pluck(:name)) }.blank?
      errors.add :group_ids, :blank
    end

    if imported_gws_group && imported_group_keys.find { |key| key.start_with?(imported_gws_group.name) }.blank?
      errors.add :group_ids, :blank
    end
  end

  def validate_imported_main_group
    return if imported_gws_main_group
    errors.add :base, I18n.t("errors.messages.not_found_main_group", name: imported_gws_main_group_key)
  end

  def validate_imported_gws_user_title
    return if imported_gws_user_title
    errors.add :base, I18n.t("errors.messages.not_found_user_title", code: imported_gws_user_title_key)
  end
end
