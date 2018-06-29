FactoryBot.define do
  factory :mail_page_page, class: MailPage::Page, traits: [:cms_page] do
    route "mail_page/page"
    keywords { "#{unique_id} #{unique_id}" }
    description { unique_id.to_s }
    arrival_start_date { Time.zone.now }
    arrival_close_date { arrival_start_date.advance(days: 2) }
  end
end
