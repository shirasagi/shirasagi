module MailPage::Addon
  module MailSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :mail_page_from_conditions, type: SS::Extensions::Lines, default: ""
      field :mail_page_to_conditions, type: SS::Extensions::Lines, default: ""
      field :arrival_days, type: Integer, default: 2

      permit_params :mail_page_from_conditions, :mail_page_to_conditions, :arrival_days
    end

    def arrival_days
      value = self[:arrival_days].to_i
      (value < 1) ? 2 : value
    end

    def create_page_from_mail(mail)
      body = mail.text_part ? mail.text_part.decoded : mail.decoded

      page = MailPage::Page.new
      page.site = self.site
      page.cur_node = self
      page.layout = self.page_layout || self.layout
      page.user_id = self.user_id
      page.group_ids = self.group_ids

      page.name = mail.subject
      page.html = body.gsub(/(\r\n?)|(\n)/, "<br />")
      page.mail_page_original_mail = mail.to_s
      page.arrival_start_date = Time.zone.now
      page.arrival_close_date = page.arrival_start_date.advance(days: arrival_days)

      page.save!
    end
  end
end
