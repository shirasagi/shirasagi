FactoryGirl.define do
  trait :jmaxml_action_base do
    cur_site { cms_site }
    name { unique_id }
  end

  factory :jmaxml_action_send_mail, class: Jmaxml::Action::SendMail, traits: [:jmaxml_action_base] do
    title_mail_text "\#{target_time} ころ地震がありました"
    upper_mail_text "\#{target_time} ころ地震がありました。\n\n各地の震度は下記の通りです。\n"
    loop_mail_text "\#{area_name}：\#{intensity_label}\n"
    lower_mail_text "下記のアドレスにアクセスし、安否情報を入力してください。\n\#{anpi_post_url}\n"
  end

  factory :jmaxml_action_publish_page,
          class: Jmaxml::Action::PublishPage, traits: [:jmaxml_action_base] do
    publish_state 'draft'
  end

  factory :jmaxml_action_switch_urgency,
          class: Jmaxml::Action::SwitchUrgency, traits: [:jmaxml_action_base]
end
