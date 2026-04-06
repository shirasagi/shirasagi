module MailPage::Addon
  module MailSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    PER_BATCH = 100

    included do
      field :mail_page_from_conditions, type: SS::Extensions::Lines, default: ""
      field :mail_page_to_conditions, type: SS::Extensions::Lines, default: ""
      field :mail_page_removal_state, type: String, default: "none"
      embeds_ids :mail_page_categories, class_name: "Category::Node::Base"
      field :arrival_days, type: Integer, default: 2

      validates :mail_page_removal_state, inclusion: { in: %w(none 1.day 1.week), allow_blank: true }

      permit_params :mail_page_from_conditions, :mail_page_to_conditions,
        :mail_page_removal_state, :arrival_days,
        mail_page_category_ids: []
    end

    def mail_page_removal_state_options
      I18n.t("mail_page.options.removal_state").map { |k, v| [v, k] }
    end

    def arrival_days
      value = self[:arrival_days].to_i
      (value < 1) ? 2 : value
    end

    def create_page_from_mail(mail)
      page = MailPage::Page.new
      page.site = self.site
      page.cur_node = self
      page.layout = self.page_layout || self.layout
      page.user_id = self.user_id
      page.group_ids = self.group_ids
      page.category_ids = self.mail_page_category_ids

      page.name = mail.subject
      page.html = mail_body_to_html(extract_body(mail))
      page.arrival_start_date = Time.zone.now
      page.arrival_close_date = page.arrival_start_date.advance(days: arrival_days)

      page.save!
    end

    def remove_expired_pages
      return if mail_page_removal_state.blank? || mail_page_removal_state == "none"

      duration = begin
        i, unit = mail_page_removal_state.split(".")
        d = i.to_i.send(unit)
        d.is_a?(ActiveSupport::Duration) ? d : nil
      rescue
        nil
      end
      return if duration.nil?

      cond = []
      cond << { filename: /^#{self.filename}\// }
      cond << { depth: self.depth + 1 }
      cond << { updated: { "$lt" => (Time.zone.now - duration) } }

      base_criteria = MailPage::Page.site(site).and(cond)
      all_ids = base_criteria.pluck(:id)
      all_ids.each_slice(PER_BATCH) do |ids|
        base_criteria.in(id: ids).each do |page|
          Rails.logger.warn("remove: #{page.name}(#{page.filename})")
          page.destroy
        end
      end
    end
  end
end
