FactoryBot.define do
  factory :mail_page_node_base, class: MailPage::Node::Base, traits: [:cms_node] do
    route "mail_page/base"
  end

  factory :mail_page_node_page, class: MailPage::Node::Page, traits: [:cms_node] do
    route "mail_page/page"
  end
end
