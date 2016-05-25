FactoryGirl.define do
  factory :inquiry_node_base, class: Inquiry::Node::Base, traits: [:cms_node] do
    cur_site { cms_site }
    route "inquiry/base"
  end

  factory :inquiry_node_form, class: Inquiry::Node::Form, traits: [:cms_node] do
    cur_site { cms_site }
    route "inquiry/form"
    from_email "from@example.jp"
    notice_email "notice@example.jp"
    inquiry_html '<p>下記事項を入力の上、確認画面へのボタンを押してください。</p>'
    inquiry_sent_html '<p>お問い合わせを受け付けました。</p>'
    reply_subject 'シラサギ市へのお問い合わせを受け付けました。'
    reply_upper_text '以下の内容でお問い合わせを受け付けま した。'
    reply_lower_text '以上。'
  end
end
