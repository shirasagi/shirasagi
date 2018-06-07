FactoryBot.define do
  factory :mail_page_part_page, class: MailPage::Part::Page, traits: [:cms_part] do
    route "mail_page/page"
  end
end
