module Gws::ReadableSettingHelper
  extend ActiveSupport::Concern

  def set_default_readable_setting
    return if @item.blank?

    setting = intepret_readable_setting_config || default_readable_setting

    @item.readable_setting_range = setting[:setting_range]
    @item.readable_group_ids = setting[:group_ids]
    @item.readable_member_ids = setting[:user_ids]
    if @item.class.readable_setting_included_custom_groups?
      @item.readable_custom_group_ids = setting[:custom_group_ids]
    end
  end

  def default_readable_setting
    setting = { setting_range: "select" }
    setting[:group_ids] = [ @cur_group.id ] if @cur_group.present?
    setting
  end

  def intepret_readable_setting_config(setting_config = nil)
    setting_config ||= SS.config.gws.readable_setting
    return if setting_config.blank?

    setting_range = setting_config["setting_range"].to_s
    case setting_range
    when 'public', "private"
      { setting_range: setting_range }
    when "select"
      setting = { setting_range: "select" } #select
      setting[:group_ids] = setting_config["group_ids"].try do |ids|
        ids.map do |id|
          if id.numeric?
            id.to_i
          elsif id == "cur_site" && @cur_site.present?
            @cur_site.id
          elsif id == "cur_group" && @cur_group.present?
            @cur_group.id
          end
        end.compact
      end
      setting[:user_ids] = setting_config["user_ids"].try do |ids|
        ids.map do |id|
          if id.numeric?
            id.to_i
          elsif id == "cur_user" && @cur_user.present?
            @cur_user.id
          end
        end.compact
      end
      setting[:custom_group_ids] = setting_config["custom_group_ids"].try do |ids|
        ids.map { |id| id.numeric? ? id.to_i : nil }.compact
      end

      setting
    else
      nil
    end
  end
end
