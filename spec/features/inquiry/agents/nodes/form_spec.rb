require 'spec_helper'

describe "inquiry_agents_nodes_form", dbscope: :example do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let(:node) do
    create(
      :inquiry_node_form,
      cur_site: site,
      layout_id: layout.id,
      inquiry_captcha: 'disabled',
      notice_state: 'enabled',
      notice_content: 'enabled',
      notice_email: 'notice@example.jp',
      from_name: 'admin',
      from_email: 'admin@example.jp',
      reply_state: 'enabled',
      reply_subject: 'お問い合わせを受け付けました',
      reply_upper_text: '上部テキスト',
      reply_lower_text: '下部テキスト')
  end

  before do
    node.columns.create! attributes_for(:inquiry_column_name).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_optional).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_email).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_radio).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_select).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_check).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_upload_file).reverse_merge({cur_site: site})
    node.reload
  end

  before do
    ActionMailer::Base.deliveries = []
  end

  after do
    ActionMailer::Base.deliveries = []
  end

  context "when pc site is accessed" do
    let(:index_url) { ::URI.parse "http://#{site.domain}/#{node.filename}/" }

    it do
      visit index_url
      expect(status_code).to eq 200
      within 'div.inquiry-form' do
        within 'div.columns' do
          fill_in "item[1]", with: "シラサギ太郎"
          fill_in "item[2]", with: "株式会社シラサギ"
          fill_in "item[3]", with: "shirasagi@example.jp"
          fill_in "item[3_confirm]", with: "shirasagi@example.jp"
          choose "item_4_0"
          select "50代", from: "item[5]"
          check "item[6][2]"
          attach_file "item[7]", Rails.root.join("spec", "fixtures", "ss", "logo.png").to_s
        end
        click_button "確認画面へ"
      end

      expect(status_code).to eq 200
      within 'div.inquiry-form' do
        within 'div.columns' do
          expect(find('#item_1')['value']).to eq 'シラサギ太郎'
          expect(find('#item_2')['value']).to eq '株式会社シラサギ'
          expect(find('#item_3')['value']).to eq 'shirasagi@example.jp'
          expect(find('#item_4')['value']).to eq '男性'
          expect(find('#item_5')['value']).to eq '50代'
          expect(find('#item_6_2')['value']).to eq '申請について'
          expect(find('#item_7')['value']).to eq '1'
        end
        # within 'div.simple-captcha' do
        #   fill_in "answer[captcha]", with: "xxxx"
        # end
        within 'footer.send' do
          click_button "送信する"
        end
      end

      expect(status_code).to eq 200
      expect(find('div.inquiry-sent').text).to eq node.inquiry_sent_html.gsub(/<.*?>/, '')

      expect(Inquiry::Answer.site(site).count).to eq 1
      answer = Inquiry::Answer.first
      expect(answer.node_id).to eq node.id
      expect(answer.data.count).to eq 7
      expect(answer.data[0].value).to eq 'シラサギ太郎'
      expect(answer.data[0].confirm).to be_nil
      expect(answer.data[1].value).to eq '株式会社シラサギ'
      expect(answer.data[1].confirm).to be_nil
      expect(answer.data[2].value).to eq 'shirasagi@example.jp'
      expect(answer.data[2].confirm).to eq 'shirasagi@example.jp'
      expect(answer.data[3].value).to eq '男性'
      expect(answer.data[3].confirm).to be_nil
      expect(answer.data[4].value).to eq '50代'
      expect(answer.data[4].confirm).to be_nil
      expect(answer.data[5].values).to eq ['申請について']
      expect(answer.data[5].confirm).to be_nil
      expect(answer.data[6].values[0]).to eq 1
      expect(answer.data[6].values[1]).to eq 'logo.png'
      expect(answer.data[6].confirm).to be_nil

      expect(ActionMailer::Base.deliveries.count).to eq 2

      ActionMailer::Base.deliveries.first.tap do |notify_mail|
        expect(notify_mail.from.first).to eq 'admin@example.jp'
        expect(notify_mail.to.first).to eq 'notice@example.jp'
        expect(notify_mail.subject).to eq "[自動通知]#{node.name} - #{site.name}"
        expect(notify_mail.body.multipart?).to be_falsey
        expect(notify_mail.body.raw_source).to include("「#{node.name}」に入力がありました。")
        expect(notify_mail.body.raw_source).to include(inquiry_answer_path(site: site, cid: node, id: answer))
      end

      ActionMailer::Base.deliveries.last.tap do |reply_mail|
        expect(reply_mail.from.first).to eq 'admin@example.jp'
        expect(reply_mail.to.first).to eq 'shirasagi@example.jp'
        expect(reply_mail.subject).to eq 'お問い合わせを受け付けました'
        expect(reply_mail.body.multipart?).to be_falsey
        expect(reply_mail.body.raw_source).to include('上部テキスト')
        expect(reply_mail.body.raw_source).to include('下部テキスト')
      end
    end
  end

  context "when mobile site is accessed" do
    let(:index_url) { ::URI.parse "http://#{site.domain}#{site.mobile_location}/#{node.filename}/" }

    it do
      visit index_url
      expect(status_code).to eq 200
      # mobile モードの場合、form の action は /mobile/ で始まる
      expect(find('form')['action']).to start_with "#{site.mobile_location}/#{node.filename}/"
      within 'div.inquiry-form' do
        within 'div.columns' do
          fill_in "item[1]", with: "シラサギ太郎"
          fill_in "item[2]", with: "株式会社シラサギ"
          fill_in "item[3]", with: "shirasagi@example.jp"
          fill_in "item[3_confirm]", with: "shirasagi@example.jp"
          choose "item_4_0"
          select "50代", from: "item[5]"
          check "item[6][2]"
        end
        click_button "確認画面へ"
      end

      expect(status_code).to eq 200
      # mobile モードの場合、/mobile/ で始まるはず
      expect(current_path).to start_with "#{site.mobile_location}/#{node.filename}/"
      # mobile モードの場合、form の action は /mobile/ で始まる
      expect(find('form')['action']).to start_with "#{site.mobile_location}/#{node.filename}/"
      within 'div.inquiry-form' do
        within 'div.columns' do
          expect(find('#item_1')['value']).to eq 'シラサギ太郎'
          expect(find('#item_2')['value']).to eq '株式会社シラサギ'
          expect(find('#item_3')['value']).to eq 'shirasagi@example.jp'
          expect(find('#item_4')['value']).to eq '男性'
          expect(find('#item_5')['value']).to eq '50代'
          expect(find('#item_6_2')['value']).to eq '申請について'
        end
        # mobile モードの場合 <footer> タグが <div> タグに置換されているはず
        within 'div.tag-footer' do
          click_button "送信する"
        end
      end

      expect(status_code).to eq 200
      # mobile モードの場合、/mobile/ で始まるはず
      expect(current_path).to start_with "#{site.mobile_location}/#{node.filename}/"
      expect(find('div.inquiry-sent').text).to eq node.inquiry_sent_html.gsub(/<.*?>/, '')

      expect(Inquiry::Answer.site(site).count).to eq 1
      answer = Inquiry::Answer.first
      expect(answer.node_id).to eq node.id
      expect(answer.data.count).to eq 7
      expect(answer.data[0].value).to eq 'シラサギ太郎'
      expect(answer.data[0].confirm).to be_nil
      expect(answer.data[1].value).to eq '株式会社シラサギ'
      expect(answer.data[1].confirm).to be_nil
      expect(answer.data[2].value).to eq 'shirasagi@example.jp'
      expect(answer.data[2].confirm).to eq 'shirasagi@example.jp'
      expect(answer.data[3].value).to eq '男性'
      expect(answer.data[3].confirm).to be_nil
      expect(answer.data[4].value).to eq '50代'
      expect(answer.data[4].confirm).to be_nil
      expect(answer.data[5].values).to eq ['申請について']
      expect(answer.data[5].confirm).to be_nil

      expect(ActionMailer::Base.deliveries.count).to eq 2
    end
  end

  context "when input non-email to email field" do
    let(:index_url) { ::URI.parse "http://#{site.domain}/#{node.filename}/" }

    it do
      visit index_url
      expect(status_code).to eq 200

      within 'div.inquiry-form' do
        within 'div.columns' do
          fill_in "item[1]", with: "シラサギ太郎"
          fill_in "item[2]", with: "株式会社シラサギ"
          fill_in "item[3]", with: "<script>alert(\"hello\");</script>"
          fill_in "item[3_confirm]", with: "<script>alert(\"hello\");</script>"
        end
        click_button "確認画面へ"
      end

      expect(status_code).to eq 200
      within 'div.inquiry-form' do
        expect(page).to have_css(".errorExplanation li", text: "メールアドレスは有効な電子メールアドレスを入力してください。")
      end

      expect(Inquiry::Answer.site(site).count).to eq 0
      expect(ActionMailer::Base.deliveries.count).to eq 0
    end
  end
end
