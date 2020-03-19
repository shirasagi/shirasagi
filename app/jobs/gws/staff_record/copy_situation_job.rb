class Gws::StaffRecord::CopySituationJob < Gws::ApplicationJob
  # include Job::Gws::TaskFilter

  def perform(item_id)
    @cur_year = Gws::StaffRecord::Year.site(site).find(item_id)

    copy_groups
    copy_user_titles
    copy_users
  end

  private

  def copy_groups
    groups = Gws::Group.site(site)
    groups = groups.active
    groups.each do |group|
      copy_group(group)
    end
  end

  def copy_group(group)
    sr_group = Gws::StaffRecord::Group.new(
      cur_site: site, cur_user: user,
      year_id: @cur_year.id, name: group.trailing_name, order: group.order,
      readable_setting_range: @cur_year.readable_setting_range, readable_group_ids: @cur_year.readable_group_ids,
      readable_custom_group_ids: @cur_year.readable_custom_group_ids, readable_member_ids: @cur_year.readable_member_ids,
      group_ids: @cur_year.group_ids, custom_group_ids: @cur_year.custom_group_ids, user_ids: @cur_year.user_ids,
      permission_level: @cur_year.permission_level
    )
    sr_group.save!(context: :copy_situation)

    Rails.logger.info("#{sr_group.name}: 所属を作成しました。")
  end

  def copy_user_titles
    user_titles = Gws::UserTitle.site(site).active
    user_titles.each do |user_title|
      user_title.cur_site = site
      copy_user_title(user_title)
    end
  end

  def copy_user_title(user_title)
    sr_user_title = Gws::StaffRecord::UserTitle.new(
      cur_site: site, cur_user: user,
      year_id: @cur_year.id, code: user_title.code, name: user_title.name, order: user_title.order,
      remark: user_title.remark,
      group_ids: @cur_year.group_ids, custom_group_ids: @cur_year.custom_group_ids, user_ids: @cur_year.user_ids,
      permission_level: @cur_year.permission_level
    )
    sr_user_title.save!(context: :copy_situation)

    Rails.logger.info("#{sr_user_title.name_with_code}: 役職を作成しました。")
  end

  def copy_users
    users = Gws::User.site(site).and_enabled
    users.each do |user|
      user.cur_site = site
      copy_user(user)
    end
  end

  def copy_user(user)
    default_group = user.gws_default_group
    sr_user = Gws::StaffRecord::User.new(
      cur_site: site, cur_user: user,
      year_id: @cur_year.id, code: user.organization_uid.presence || user.uid, name: user.name, kana: user.kana,
      section_name: default_group.try(:trailing_name),
      title_ids: @cur_year.yearly_user_titles.in(code: user.titles.pluck(:code)).pluck(:id), tel_ext: user.tel_ext,
      charge_name: user.charge_name, charge_address: user.charge_address, charge_tel: user.charge_tel,
      divide_duties: user.divide_duties,
      readable_setting_range: @cur_year.readable_setting_range, readable_group_ids: @cur_year.readable_group_ids,
      readable_custom_group_ids: @cur_year.readable_custom_group_ids, readable_member_ids: @cur_year.readable_member_ids,
      group_ids: @cur_year.group_ids, custom_group_ids: @cur_year.custom_group_ids, user_ids: @cur_year.user_ids,
      permission_level: @cur_year.permission_level
    )
    sr_user.save!(context: :copy_situation)

    Rails.logger.info("#{sr_user.name_with_code}: 職員を作成しました。")
  end
end
