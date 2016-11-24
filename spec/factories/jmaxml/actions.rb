FactoryGirl.define do
  trait :jmaxml_action_base do
    cur_site { cms_site }
    name { unique_id }
  end

  factory :jmaxml_action_publish_page, class: Jmaxml::Action::PublishPage, traits: [:jmaxml_action_base] do
    publish_state 'draft'
  end

  factory :jmaxml_action_switch_urgency, class: Jmaxml::Action::SwitchUrgency, traits: [:jmaxml_action_base]

  factory :jmaxml_action_send_mail, class: Jmaxml::Action::SendMail, traits: [:jmaxml_action_base] do
    sender_name { unique_id }
    sender_email { "#{sender_name}@example.jp" }
    signature_text { "--------\n#{sender_email}"}
  end
end
