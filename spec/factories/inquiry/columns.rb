FactoryGirl.define do
  factory :inquiry_column1, class: Inquiry::Column do
    name "お名前"
    input_type "text_field"
    required "required"
    html "<p>お名前を入力してくだ さい。</p>"
    order 10
  end

  factory :inquiry_column2, class: Inquiry::Column do
    name "企業・団体名"
    input_type "text_field"
    required "optional"
    html "<p>企業・団体名を入力してくだ さい。</p>"
    order 20
  end

  factory :inquiry_column3, class: Inquiry::Column do
    name "メールアドレス"
    input_type "email_field"
    required "required"
    html "<p>半角 英数字記号で入力してください。<br />\nお問い合わせへの返信に利用させていただきます。</p>"
    order 30
  end
end
