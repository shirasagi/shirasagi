FactoryGirl.define do
  factory :sns_message_thread, class: Sns::Message::Thread do
    cur_user { ss_user }
    member_ids { [ss_user.id] }
  end

  factory :sns_message_post, class: Sns::Message::Post do
    cur_user { ss_user }
    text 'text'
  end
end
