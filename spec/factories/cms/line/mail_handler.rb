FactoryBot.define do
  factory :cms_line_mail_handler, class: Cms::Line::MailHandler do
    site { cms_site }
    name { unique_id }
    filename { unique_id }
    from_conditions { ["#{unique_id}@example.jp"] }
    to_conditions { ["#{unique_id}@example.jp"] }
    deliver_condition_state { "multicast_with_no_condition" }
  end
end
