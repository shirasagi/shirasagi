class Gws::Memo::NoticeUserSettingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::UserSettingFilter

  def permit_fields
    fields = []
    %w(schedule todo report workflow circular monitor board faq qna survey discussion announcement affair).each do |name|
      fields << "notice_#{name}_user_setting"
      fields << "notice_#{name}_email_user_setting"
    end
    fields.map(&:to_sym)
    fields << :send_notice_mail_addresses
  end

  def update
    @item.attributes = get_params
    render_update @item.save
  end
end
