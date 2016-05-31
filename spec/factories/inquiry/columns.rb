FactoryGirl.define do
  factory :inquiry_column_name, class: Inquiry::Column do
    name "お名前"
    input_type "text_field"
    required "required"
    html "<p>お名前を入力してくだ さい。</p>"
    order 10
  end

  factory :inquiry_column_optional, class: Inquiry::Column do
    name "企業・団体名"
    input_type "text_field"
    required "optional"
    html "<p>企業・団体名を入力してくだ さい。</p>"
    order 20
  end

  factory :inquiry_column_email, class: Inquiry::Column do
    name "メールアドレス"
    input_type "email_field"
    required "required"
    input_confirm "enabled"
    html "<p>半角 英数字記号で入力してください。<br />\nお問い合わせへの返信に利用させていただきます。</p>"
    order 30
  end

  factory :inquiry_column_radio, class: Inquiry::Column do
    name "性別"
    input_type "radio_button"
    required "optional"
    html "<p>性別を選択して ください。</p>"
    select_options %w(男性 女性)
    order 40
  end

  factory :inquiry_column_select, class: Inquiry::Column do
    name "年齢"
    input_type "select"
    required "optional"
    html "<p>年齢を選択してください。</p>"
    select_options %w(10代 20代 30代 40代 50代 60代 70代 80代)
    order 50
  end

  factory :inquiry_column_check, class: Inquiry::Column do
    name "お問い合わせ区分"
    input_type "check_box"
    required "optional"
    html "<p>お問い合わせ内容の区分を選択してください。</p>"
    select_options %w(市政について ご意見・ご要望 申請について その他)
    order 60
  end

  factory :inquiry_column_radio_contents, class: Inquiry::Column do
    name "内容"
    input_type "radio_button"
    required "optional"
    html "<p>このページの情報は役に立ちましたか？</p>"
    select_options %w(役に立った どちらかと言えば役に立った どちらかと言えば役に立たない 役に立たない)
    order 10
  end

  factory :inquiry_column_radio_findable, class: Inquiry::Column do
    name "見つけやすさ"
    input_type "radio_button"
    required "optional"
    html "<p>このページの情報は見つけやすかったですか？</p>"
    select_options %w(見つけやすかった どちらかと言えば見つけやすかった どちらかと言えば見つけにくかった 見つけにくかった)
    order 20
  end

  factory :inquiry_column_text_comment, class: Inquiry::Column do
    name "ご意見・ご要望"
    input_type "text_area"
    required "optional"
    html "<p>このページに関するご意見・ご要望がありましたらご記入ください。</p>"
    order 30
  end
end
