require 'spec_helper'

describe "inquiry_agents_nodes_form", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let(:inquiry_sent_html) do
    html = []
    html << '<script>alert("danger0");</script>'
    html << '<p>お問い合わせを受け付けました。</p>'
    html << '<a href="http://danger.example.jp/path/to/malware0.html">危険なリンク0</a>'
    html.join
  end
  let(:reply_upper_text) do
    text = []
    text << '<script>alert("danger1");</script>'
    text << '上部テキスト'
    text << '<a href="http://danger.example.jp/path/to/malware1.html">危険なリンク1</a>'
    text.join
  end
  let(:reply_lower_text) do
    text = []
    text << '<script>alert("danger2");</script>'
    text << '下部テキスト'
    text << '<a href="http://danger.example.jp/path/to/malware2.html">危険なリンク2</a>'
    text.join
  end
  let(:reply_content_static) do
    text = []
    text << '<script>alert("danger3");</script>'
    text << '問い合わせを受け付けました。'
    text << '<a href="http://danger.example.jp/path/to/malware.html">危険なリンク3</a>'
    text.join
  end
  let(:node) do
    create(
      :inquiry_node_form,
      cur_site: site,
      layout_id: layout.id,
      inquiry_captcha: 'disabled',
      inquiry_sent_html: inquiry_sent_html,
      notice_state: 'enabled',
      notice_content: 'include_answers',
      notice_email: 'notice@example.jp',
      from_name: 'admin',
      from_email: 'admin@example.jp',
      reply_state: 'enabled',
      reply_subject: 'お問い合わせを受け付けました',
      reply_upper_text: reply_upper_text,
      reply_lower_text: reply_lower_text,
      reply_content_state: reply_content_state,
      reply_content_static: reply_content_static)
  end
  let(:answer_for_name) do
    "<script>alert(\"hello1\");</script>シラサギ太郎<a href=\"http://danger.example.jp/path/to/malware1.html\">危険なリンク1</a>"
  end
  let(:answer_for_optional) do
    "<script>alert(\"hello2\");</script>株式会社シラサギ<a href=\"http://danger.example.jp/path/to/malware2.html\">危険なリンク2</a>"
  end

  before do
    node.columns.create! attributes_for(:inquiry_column_name).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_optional).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_transfers).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_email).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_radio).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_select).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_check).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_upload_file).reverse_merge({cur_site: site})
    node.reload
  end
  let(:index_url) { ::URI.parse "http://#{site.domain}/#{node.filename}/" }

  before do
    ActionMailer::Base.deliveries = []
  end

  after do
    ActionMailer::Base.deliveries = []
  end

  context "when xss answer is given" do
    let(:reply_content_state) { "answer" }

    it do
      visit index_url

      within 'div.inquiry-form' do
        within 'div.columns' do
          fill_in "item[1]", with: answer_for_name
          fill_in "item[2]", with: answer_for_optional
          fill_in "item[4]", with: "shirasagi@example.jp"
          fill_in "item[4_confirm]", with: "shirasagi@example.jp"
        end
        click_button I18n.t('inquiry.confirm')
      end

      within 'footer.send' do
        click_button I18n.t('inquiry.submit')
      end
      expect(page).to have_css(".inquiry-sent", text: "お問い合わせを受け付けました。")

      expect(Inquiry::Answer.site(site).count).to eq 1
      answer = Inquiry::Answer.first

      expect(ActionMailer::Base.deliveries.count).to eq 2

      ActionMailer::Base.deliveries.first.tap do |notify_mail|
        expect(notify_mail.from.first).to eq 'admin@example.jp'
        expect(notify_mail.to.first).to eq 'notice@example.jp'
        expect(notify_mail.subject).to eq "[自動通知]#{node.name} - #{site.name}"
        expect(notify_mail.body.multipart?).to be_falsey
        expect(notify_mail.body.raw_source).to include("「#{node.name}」に入力がありました。")
        expect(notify_mail.body.raw_source).to include(inquiry_answer_path(site: site, cid: node, id: answer))
        # inquiry_column_name
        expect(notify_mail.body.raw_source).to include("- " + node.columns[0].name)
        expect(notify_mail.body.raw_source).to include("シラサギ太郎")
        # inquiry_column_optional
        expect(notify_mail.body.raw_source).to include("- " + node.columns[1].name)
        expect(notify_mail.body.raw_source).to include("株式会社シラサギ")
        # inquiry_column_email
        expect(notify_mail.body.raw_source).to include("- " + node.columns[3].name)
        expect(notify_mail.body.raw_source).to include("shirasagi@example.jp")
        # no tags
        expect(notify_mail.body.raw_source).not_to include('<script')
        expect(notify_mail.body.raw_source).not_to include('<a')
      end

      ActionMailer::Base.deliveries.last.tap do |reply_mail|
        expect(reply_mail.from.first).to eq node.from_email
        expect(reply_mail.to.first).to eq 'shirasagi@example.jp'
        expect(reply_mail.subject).to eq node.reply_subject
        expect(reply_mail.body.multipart?).to be_falsey
        # upper
        expect(reply_mail.body.raw_source).to include('上部テキスト')
        # inquiry_column_name
        expect(reply_mail.body.raw_source).to include("- " + node.columns[0].name)
        expect(reply_mail.body.raw_source).to include("シラサギ太郎")
        # inquiry_column_optional
        expect(reply_mail.body.raw_source).to include("- " + node.columns[1].name)
        expect(reply_mail.body.raw_source).to include("株式会社シラサギ")
        # inquiry_column_email
        expect(reply_mail.body.raw_source).to include("- " + node.columns[3].name)
        expect(reply_mail.body.raw_source).to include("shirasagi@example.jp")
        # lower
        expect(reply_mail.body.raw_source).to include('下部テキスト')
        # no tags
        expect(reply_mail.body.raw_source).not_to include('<script')
        expect(reply_mail.body.raw_source).not_to include('<a')
      end

      login_cms_user
      visit node_nodes_path(site.id, node)
      click_on I18n.t("inquiry.answer")
      click_on answer.data_summary
      within "#addon-basic" do
        expect(page).to have_css(".answer-state", text: answer.label(:state))
      end
      # alert が表示されていなければ、クリックして一覧へ戻れるはず
      click_on I18n.t('ss.links.back_to_index')
      expect(page).to have_content(answer.data_summary)
    end
  end

  context "when xss answer is given" do
    let(:reply_content_state) { "static" }

    it do
      visit index_url

      within 'div.inquiry-form' do
        within 'div.columns' do
          fill_in "item[1]", with: answer_for_name
          fill_in "item[2]", with: answer_for_optional
          fill_in "item[4]", with: "shirasagi@example.jp"
          fill_in "item[4_confirm]", with: "shirasagi@example.jp"
        end
        click_button I18n.t('inquiry.confirm')
      end

      within 'footer.send' do
        click_button I18n.t('inquiry.submit')
      end
      expect(page).to have_css(".inquiry-sent", text: "お問い合わせを受け付けました。")

      expect(Inquiry::Answer.site(site).count).to eq 1
      answer = Inquiry::Answer.first

      expect(ActionMailer::Base.deliveries.count).to eq 2

      ActionMailer::Base.deliveries.first.tap do |notify_mail|
        expect(notify_mail.from.first).to eq 'admin@example.jp'
        expect(notify_mail.to.first).to eq 'notice@example.jp'
        expect(notify_mail.subject).to eq "[自動通知]#{node.name} - #{site.name}"
        expect(notify_mail.body.multipart?).to be_falsey
        # no tags
        expect(notify_mail.body.raw_source).not_to include('<script')
        expect(notify_mail.body.raw_source).not_to include('<a')
      end

      ActionMailer::Base.deliveries.last.tap do |reply_mail|
        expect(reply_mail.from.first).to eq node.from_email
        expect(reply_mail.to.first).to eq 'shirasagi@example.jp'
        expect(reply_mail.subject).to eq node.reply_subject
        expect(reply_mail.body.multipart?).to be_falsey
        # no tags
        expect(reply_mail.body.raw_source).not_to include('<script')
        expect(reply_mail.body.raw_source).not_to include('<a')
      end
    end
  end

  context "when input non-email to email field" do
    let(:reply_content_state) { "static" }

    it do
      visit index_url

      within 'div.inquiry-form' do
        within 'div.columns' do
          page.execute_script("document.querySelector('#item_4').type = 'text';")
          page.execute_script("document.querySelector('#item_4_confirm').type = 'text';")

          fill_in "item[1]", with: "シラサギ太郎"
          fill_in "item[2]", with: "株式会社シラサギ"
          fill_in "item[4]", with: "<script>alert(\"hello\");</script>"
          fill_in "item[4_confirm]", with: "<script>alert(\"hello\");</script>"
        end
        click_button I18n.t('inquiry.confirm')
      end

      within 'div.inquiry-form' do
        expect(page).to have_css(".errorExplanation li", text: "メールアドレスは有効な電子メールアドレスを入力してください。")
      end

      expect(Inquiry::Answer.site(site).count).to eq 0
      expect(ActionMailer::Base.deliveries.count).to eq 0
    end
  end
end
