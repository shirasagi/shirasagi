require 'spec_helper'

describe "inquiry_agents_nodes_form", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let(:node) do
    create(
      :inquiry_node_form,
      cur_site: site,
      layout_id: layout.id,
      inquiry_captcha: 'enabled',
      notice_state: 'enabled',
      notice_content: 'link_only',
      notice_emails: ['notice@example.jp'],
      from_name: 'admin',
      from_email: 'admin@example.jp',
      reply_state: 'disabled')
  end

  before do
    site.mobile_state = "enabled"
    site.save!
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
          fill_in 'item[3]', with: 'キーワード'
          fill_in "item[4]", with: "shirasagi@example.jp"
          fill_in "item[4_confirm]", with: "shirasagi@example.jp"
          choose "item_5_0"
          select "50代", from: "item[6]"
          check "item[7][2]"
          attach_file "item[8]", Rails.root.join("spec", "fixtures", "ss", "logo.png").to_s
        end
        click_button I18n.t('inquiry.confirm')
      end

      expect(status_code).to eq 200
      within 'div.inquiry-form' do
        within 'div.columns' do
          expect(find("[name='item[1]']")['value']).to eq 'シラサギ太郎'
          expect(find("[name='item[2]']")['value']).to eq '株式会社シラサギ'
          expect(find("[name='item[3]']")['value']).to eq 'キーワード'
          expect(find("[name='item[4]']")['value']).to eq 'shirasagi@example.jp'
          expect(find("[name='item[5]']")['value']).to eq '男性'
          expect(find("[name='item[6]']")['value']).to eq '50代'
          expect(find("[name='item[7][2]']")['value']).to eq '申請について'
          expect(find("[name='item[8]']")['value']).to eq '1'
        end
        within 'div.simple-captcha' do
          fill_in "answer[captcha_answer]", with: SS::Captcha.first.captcha_text
        end
        within 'footer.send' do
          click_button I18n.t('inquiry.submit')
        end
      end

      expect(status_code).to eq 200
      expect(find('div.inquiry-sent').text).to eq node.inquiry_sent_html.gsub(/<.*?>/, '')

      expect(Inquiry::Answer.site(site).count).to eq 1
      answer = Inquiry::Answer.first
      expect(answer.node_id).to eq node.id
      expect(answer.data.count).to eq 8
      expect(answer.data[0].value).to eq 'シラサギ太郎'
      expect(answer.data[0].confirm).to be_nil
      expect(answer.data[1].value).to eq '株式会社シラサギ'
      expect(answer.data[1].confirm).to be_nil
      expect(answer.data[2].value).to eq 'キーワード'
      expect(answer.data[2].confirm).to be_nil
      expect(answer.data[3].value).to eq 'shirasagi@example.jp'
      expect(answer.data[3].confirm).to eq 'shirasagi@example.jp'
      expect(answer.data[4].value).to eq '男性'
      expect(answer.data[4].confirm).to be_nil
      expect(answer.data[5].value).to eq '50代'
      expect(answer.data[5].confirm).to be_nil
      expect(answer.data[6].values).to eq %w(申請について)
      expect(answer.data[6].confirm).to be_nil
      expect(answer.data[7].values[0]).to eq 1
      expect(answer.data[7].values[1]).to eq 'logo.png'
      expect(answer.data[7].confirm).to be_nil

      expect(ActionMailer::Base.deliveries.count).to eq 2

      ActionMailer::Base.deliveries.first.tap do |notify_mail|
        expect(notify_mail.from.first).to eq 'admin@example.jp'
        expect(notify_mail.to.first).to eq 'notice@example.jp'
        expect(notify_mail.subject).to eq "[自動通知]#{node.name} - #{site.name}"
        expect(notify_mail.body.multipart?).to be_falsey
        expect(notify_mail.body.raw_source).to include("「#{node.name}」に入力がありました。")
        expect(notify_mail.body.raw_source).to include(inquiry_answer_path(site: site, cid: node, id: answer))
        # inquiry_column_name
        expect(notify_mail.body.raw_source).not_to include("- " + node.columns[0].name)
        expect(notify_mail.body.raw_source).not_to include("シラサギ太郎")
        # inquiry_column_optional
        expect(notify_mail.body.raw_source).not_to include("- " + node.columns[1].name)
        expect(notify_mail.body.raw_source).not_to include("株式会社シラサギ")
        # inquiry_column_transfers
        expect(notify_mail.body.raw_source).not_to include("- " + node.columns[2].name)
        expect(notify_mail.body.raw_source).not_to include('キーワード')
        # inquiry_column_email
        expect(notify_mail.body.raw_source).not_to include("- " + node.columns[3].name)
        expect(notify_mail.body.raw_source).not_to include("shirasagi@example.jp")
        # inquiry_column_radio
        expect(notify_mail.body.raw_source).not_to include("- " + node.columns[4].name)
        expect(notify_mail.body.raw_source).not_to include("男性")
        # inquiry_column_select
        expect(notify_mail.body.raw_source).not_to include("- " + node.columns[5].name)
        expect(notify_mail.body.raw_source).not_to include("50代")
        # inquiry_column_check
        expect(notify_mail.body.raw_source).not_to include("- " + node.columns[6].name)
        expect(notify_mail.body.raw_source).not_to include("申請について")
        # inquiry_column_upload_file
        expect(notify_mail.body.raw_source).not_to include("- " + node.columns[7].name)
        expect(notify_mail.body.raw_source).not_to include("logo.png")
      end

      ActionMailer::Base.deliveries[1].tap do |notify_mail|
        expect(notify_mail.from.first).to eq 'admin@example.jp'
        expect(notify_mail.to.first).to eq 'transfers@example.jp'
        expect(notify_mail.subject).to eq "[自動通知]#{node.name} - #{site.name}"
        expect(notify_mail.body.multipart?).to be_falsey
        expect(notify_mail.body.raw_source).to include("「#{node.name}」に入力がありました。")
        expect(notify_mail.body.raw_source).to include(inquiry_answer_path(site: site, cid: node, id: answer))
        # inquiry_column_name
        expect(notify_mail.body.raw_source).not_to include("- " + node.columns[0].name)
        expect(notify_mail.body.raw_source).not_to include("シラサギ太郎")
        # inquiry_column_optional
        expect(notify_mail.body.raw_source).not_to include("- " + node.columns[1].name)
        expect(notify_mail.body.raw_source).not_to include("株式会社シラサギ")
        # inquiry_column_transfers
        expect(notify_mail.body.raw_source).not_to include("- " + node.columns[2].name)
        expect(notify_mail.body.raw_source).not_to include('キーワード')
        # inquiry_column_email
        expect(notify_mail.body.raw_source).not_to include("- " + node.columns[3].name)
        expect(notify_mail.body.raw_source).not_to include("shirasagi@example.jp")
        # inquiry_column_radio
        expect(notify_mail.body.raw_source).not_to include("- " + node.columns[4].name)
        expect(notify_mail.body.raw_source).not_to include("男性")
        # inquiry_column_select
        expect(notify_mail.body.raw_source).not_to include("- " + node.columns[5].name)
        expect(notify_mail.body.raw_source).not_to include("50代")
        # inquiry_column_check
        expect(notify_mail.body.raw_source).not_to include("- " + node.columns[6].name)
        expect(notify_mail.body.raw_source).not_to include("申請について")
        # inquiry_column_upload_file
        expect(notify_mail.body.raw_source).not_to include("- " + node.columns[7].name)
        expect(notify_mail.body.raw_source).not_to include("logo.png")
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
          fill_in 'item[3]', with: 'キーワード'
          fill_in "item[4]", with: "shirasagi@example.jp"
          fill_in "item[4_confirm]", with: "shirasagi@example.jp"
          choose "item_5_0"
          select "50代", from: "item[6]"
          check "item[7][2]"
        end
        click_button I18n.t('inquiry.confirm')
      end

      expect(status_code).to eq 200
      # mobile モードの場合、/mobile/ で始まるはず
      expect(current_path).to start_with "#{site.mobile_location}/#{node.filename}/"
      # mobile モードの場合、form の action は /mobile/ で始まる
      expect(find('form')['action']).to start_with "#{site.mobile_location}/#{node.filename}/"
      within 'div.inquiry-form' do
        within 'div.columns' do
          expect(find("[name='item[1]']")['value']).to eq 'シラサギ太郎'
          expect(find("[name='item[2]']")['value']).to eq '株式会社シラサギ'
          expect(find("[name='item[3]']")['value']).to eq 'キーワード'
          expect(find("[name='item[4]']")['value']).to eq 'shirasagi@example.jp'
          expect(find("[name='item[5]']")['value']).to eq '男性'
          expect(find("[name='item[6]']")['value']).to eq '50代'
          expect(find("[name='item[7][2]']")['value']).to eq '申請について'
        end
        within 'div.simple-captcha' do
          fill_in "answer[captcha_answer]", with: SS::Captcha.first.captcha_text
        end
        # mobile モードの場合 <footer> タグが <div> タグに置換されているはず
        within 'div.tag-footer' do
          click_button I18n.t('inquiry.submit')
        end
      end

      expect(status_code).to eq 200
      # mobile モードの場合、/mobile/ で始まるはず
      expect(current_path).to start_with "#{site.mobile_location}/#{node.filename}/"
      expect(find('div.inquiry-sent').text).to eq node.inquiry_sent_html.gsub(/<.*?>/, '')

      expect(Inquiry::Answer.site(site).count).to eq 1
      answer = Inquiry::Answer.first
      expect(answer.node_id).to eq node.id
      expect(answer.data.count).to eq 8
      expect(answer.data[0].value).to eq 'シラサギ太郎'
      expect(answer.data[0].confirm).to be_nil
      expect(answer.data[1].value).to eq '株式会社シラサギ'
      expect(answer.data[1].confirm).to be_nil
      expect(answer.data[2].value).to eq 'キーワード'
      expect(answer.data[2].confirm).to be_nil
      expect(answer.data[3].value).to eq 'shirasagi@example.jp'
      expect(answer.data[3].confirm).to eq 'shirasagi@example.jp'
      expect(answer.data[4].value).to eq '男性'
      expect(answer.data[4].confirm).to be_nil
      expect(answer.data[5].value).to eq '50代'
      expect(answer.data[5].confirm).to be_nil
      expect(answer.data[6].values).to eq %w(申請について)
      expect(answer.data[6].confirm).to be_nil

      expect(ActionMailer::Base.deliveries.count).to eq 2
    end
  end

  context "captcha" do
    let(:index_url) { ::URI.parse "http://#{site.domain}/#{node.filename}/" }

    it "fail to pass capctcha with blank" do
      visit index_url
      expect(status_code).to eq 200
      within 'div.inquiry-form' do
        within 'div.columns' do
          fill_in "item[1]", with: "シラサギ太郎"
          fill_in "item[2]", with: "株式会社シラサギ"
          fill_in 'item[3]', with: 'キーワード'
          fill_in "item[4]", with: "shirasagi@example.jp"
          fill_in "item[4_confirm]", with: "shirasagi@example.jp"
          choose "item_5_0"
          select "50代", from: "item[6]"
          check "item[7][2]"
        end
        click_button I18n.t('inquiry.confirm')
      end

      expect(status_code).to eq 200
      within 'div.inquiry-form' do
        within 'div.columns' do
          expect(find("[name='item[1]']")['value']).to eq 'シラサギ太郎'
          expect(find("[name='item[2]']")['value']).to eq '株式会社シラサギ'
          expect(find("[name='item[3]']")['value']).to eq 'キーワード'
          expect(find("[name='item[4]']")['value']).to eq 'shirasagi@example.jp'
          expect(find("[name='item[5]']")['value']).to eq '男性'
          expect(find("[name='item[6]']")['value']).to eq '50代'
          expect(find("[name='item[7][2]']")['value']).to eq '申請について'
        end
        within 'div.simple-captcha' do
          fill_in "answer[captcha_answer]", with: ""
        end
        within 'footer.send' do
          click_button I18n.t('inquiry.submit')
        end
      end

      expect(page).to have_content I18n.t('mongoid.attributes.inquiry/answer.captcha')
    end

    it "fail to pass capctcha with wrong number" do
      visit index_url
      expect(status_code).to eq 200
      within 'div.inquiry-form' do
        within 'div.columns' do
          fill_in "item[1]", with: "シラサギ太郎"
          fill_in "item[2]", with: "株式会社シラサギ"
          fill_in 'item[3]', with: 'キーワード'
          fill_in "item[4]", with: "shirasagi@example.jp"
          fill_in "item[4_confirm]", with: "shirasagi@example.jp"
          choose "item_5_0"
          select "50代", from: "item[6]"
          check "item[7][2]"
        end
        click_button I18n.t('inquiry.confirm')
      end

      expect(status_code).to eq 200
      within 'div.inquiry-form' do
        within 'div.columns' do
          expect(find("[name='item[1]']")['value']).to eq 'シラサギ太郎'
          expect(find("[name='item[2]']")['value']).to eq '株式会社シラサギ'
          expect(find("[name='item[3]']")['value']).to eq 'キーワード'
          expect(find("[name='item[4]']")['value']).to eq 'shirasagi@example.jp'
          expect(find("[name='item[5]']")['value']).to eq '男性'
          expect(find("[name='item[6]']")['value']).to eq '50代'
          expect(find("[name='item[7][2]']")['value']).to eq '申請について'
        end
        within 'div.simple-captcha' do
          fill_in "answer[captcha_answer]", with: "0000"
        end
        within 'footer.send' do
          click_button I18n.t('inquiry.submit')
        end
      end

      expect(page).to have_content I18n.t('mongoid.attributes.inquiry/answer.captcha')
    end
  end
end
