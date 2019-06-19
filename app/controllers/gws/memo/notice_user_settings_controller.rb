class Gws::Memo::NoticeUserSettingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::UserSettingFilter

  def permit_fields
    fields = []
    %w(schedule todo report workflow circular monitor board faq qna survey discussion announcement).each do |name|
      fields << "notice_#{name}_user_setting"
      fields << "notice_#{name}_email_user_setting"
    end
    fields.map(&:to_sym)
    fields << :send_notice_mail_address
  end

  def update
    @item.attributes = get_params
    render_update @item.update
  end
end
