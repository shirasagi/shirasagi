class Gws::Memo::NoticeUserSettingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::UserSettingFilter

  def permit_fields
    fields = []
    %w(schedule todo workload report workflow circular monitor board faq qna survey discussion announcement affair).each do |name|
      fields << "notice_#{name}_user_setting"
      fields << "notice_#{name}_email_user_setting"
    end
    fields.map(&:to_sym)
    fields << :send_notice_mail_addresses
  end

  def show
    raise "403" if !@cur_user.gws_role_permit_any?(@cur_site, :edit_gws_memo_notice_user_setting)
    render
  end

  def edit
    raise "403" if !@cur_user.gws_role_permit_any?(@cur_site, :edit_gws_memo_notice_user_setting)
    render
  end

  def update
    raise "403" if !@cur_user.gws_role_permit_any?(@cur_site, :edit_gws_memo_notice_user_setting)
    @item.attributes = get_params
    render_update @item.save
  end
end
