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
      notice_content: 'include_answers',
      notice_email: 'notice@example.jp',
      from_name: 'admin',
      from_email: 'admin@example.jp',
      reply_state: 'disabled',
      kintone_app_activation: 'enabled',
      kintone_app_api_token: unique_id,
      kintone_app_key: 1)
  end
  let(:index_url) { ::URI.parse "http://#{site.domain}/#{node.filename}/" }
  let(:kintone_domain) { "#{unique_id}.example.jp" }
  let(:kintone_url) { "https://#{kintone_domain}/k/v1/record.json" }

  before do
    ActionMailer::Base.deliveries = []
    WebMock.reset!
  end

  after do
    ActionMailer::Base.deliveries = []
    WebMock.reset!
  end

  context "when kintone_app_activation is enabled" do
    before do
      site.kintone_domain = kintone_domain
      site.save!
      site.reload

      node.columns.create! attributes_for(:inquiry_column_name).reverse_merge({cur_site: site, kintone_field_code: 'name'})
      node.columns.create! attributes_for(:inquiry_column_optional).reverse_merge({cur_site: site})
      node.columns.create! attributes_for(:inquiry_column_transfers).reverse_merge({cur_site: site})
      node.columns.create! attributes_for(:inquiry_column_email).reverse_merge({cur_site: site, kintone_field_code: 'email'})
      node.columns.create! attributes_for(:inquiry_column_radio).reverse_merge({cur_site: site, kintone_field_code: 'radio'})
      node.columns.create! attributes_for(:inquiry_column_select).reverse_merge({cur_site: site, kintone_field_code: 'select'})
      node.columns.create! attributes_for(:inquiry_column_check).reverse_merge({cur_site: site, kintone_field_code: 'check'})
      node.columns.create! attributes_for(:inquiry_column_upload_file).reverse_merge({cur_site: site})
      node.reload

      stub_request(:post, kintone_url).
        to_return(status: 200, body: { id: 100, revision: 1 }.to_json, headers: { 'Content-Type' => 'application/json'})
    end

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
          expect(find('#item_1')['value']).to eq 'シラサギ太郎'
          expect(find('#item_2')['value']).to eq '株式会社シラサギ'
          expect(find('#item_3')['value']).to eq 'キーワード'
          expect(find('#item_4')['value']).to eq 'shirasagi@example.jp'
          expect(find('#item_5')['value']).to eq '男性'
          expect(find('#item_6')['value']).to eq '50代'
          expect(find('#item_7_2')['value']).to eq '申請について'
          expect(find('#item_8')['value']).to eq '1'
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
      expect(answer.kintone_record_key).to eq '100'
      expect(answer.kintone_revision).to eq '1'
      expect(answer.kintone_update_error_message).to be_nil

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
        # inquiry_column_transfers
        expect(notify_mail.body.raw_source).to include("- " + node.columns[2].name)
        expect(notify_mail.body.raw_source).to include('キーワード')
        # inquiry_column_email
        expect(notify_mail.body.raw_source).to include("- " + node.columns[3].name)
        expect(notify_mail.body.raw_source).to include("shirasagi@example.jp")
        # inquiry_column_radio
        expect(notify_mail.body.raw_source).to include("- " + node.columns[4].name)
        expect(notify_mail.body.raw_source).to include("男性")
        # inquiry_column_select
        expect(notify_mail.body.raw_source).to include("- " + node.columns[5].name)
        expect(notify_mail.body.raw_source).to include("50代")
        # inquiry_column_check
        expect(notify_mail.body.raw_source).to include("- " + node.columns[6].name)
        expect(notify_mail.body.raw_source).to include("申請について")
        # inquiry_column_upload_file
        expect(notify_mail.body.raw_source).to include("- " + node.columns[7].name)
        expect(notify_mail.body.raw_source).to include("logo.png")
      end

      ActionMailer::Base.deliveries[1].tap do |notify_mail|
        expect(notify_mail.from.first).to eq 'admin@example.jp'
        expect(notify_mail.to.first).to eq 'transfers@example.jp'
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
        # inquiry_column_transfers
        expect(notify_mail.body.raw_source).to include("- " + node.columns[2].name)
        expect(notify_mail.body.raw_source).to include('キーワード')
        # inquiry_column_email
        expect(notify_mail.body.raw_source).to include("- " + node.columns[3].name)
        expect(notify_mail.body.raw_source).to include("shirasagi@example.jp")
        # inquiry_column_radio
        expect(notify_mail.body.raw_source).to include("- " + node.columns[4].name)
        expect(notify_mail.body.raw_source).to include("男性")
        # inquiry_column_select
        expect(notify_mail.body.raw_source).to include("- " + node.columns[5].name)
        expect(notify_mail.body.raw_source).to include("50代")
        # inquiry_column_check
        expect(notify_mail.body.raw_source).to include("- " + node.columns[6].name)
        expect(notify_mail.body.raw_source).to include("申請について")
        # inquiry_column_upload_file
        expect(notify_mail.body.raw_source).to include("- " + node.columns[7].name)
        expect(notify_mail.body.raw_source).to include("logo.png")
      end
    end

    context 'with kintone_guest_space_id' do
      let(:node) do
        create(
          :inquiry_node_form,
          cur_site: site,
          layout_id: layout.id,
          inquiry_captcha: 'enabled',
          notice_state: 'enabled',
          notice_content: 'include_answers',
          notice_email: 'notice@example.jp',
          from_name: 'admin',
          from_email: 'admin@example.jp',
          reply_state: 'disabled',
          kintone_app_activation: 'enabled',
          kintone_app_api_token: unique_id,
          kintone_app_key: 1,
          kintone_app_guest_space_id: 1)
      end
      let(:kintone_url) { "https://#{kintone_domain}/k/guest/1/v1/record.json" }

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
            expect(find('#item_1')['value']).to eq 'シラサギ太郎'
            expect(find('#item_2')['value']).to eq '株式会社シラサギ'
            expect(find('#item_3')['value']).to eq 'キーワード'
            expect(find('#item_4')['value']).to eq 'shirasagi@example.jp'
            expect(find('#item_5')['value']).to eq '男性'
            expect(find('#item_6')['value']).to eq '50代'
            expect(find('#item_7_2')['value']).to eq '申請について'
            expect(find('#item_8')['value']).to eq '1'
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
        expect(answer.kintone_record_key).to eq '100'
        expect(answer.kintone_revision).to eq '1'
        expect(answer.kintone_update_error_message).to be_nil

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
          # inquiry_column_transfers
          expect(notify_mail.body.raw_source).to include("- " + node.columns[2].name)
          expect(notify_mail.body.raw_source).to include('キーワード')
          # inquiry_column_email
          expect(notify_mail.body.raw_source).to include("- " + node.columns[3].name)
          expect(notify_mail.body.raw_source).to include("shirasagi@example.jp")
          # inquiry_column_radio
          expect(notify_mail.body.raw_source).to include("- " + node.columns[4].name)
          expect(notify_mail.body.raw_source).to include("男性")
          # inquiry_column_select
          expect(notify_mail.body.raw_source).to include("- " + node.columns[5].name)
          expect(notify_mail.body.raw_source).to include("50代")
          # inquiry_column_check
          expect(notify_mail.body.raw_source).to include("- " + node.columns[6].name)
          expect(notify_mail.body.raw_source).to include("申請について")
          # inquiry_column_upload_file
          expect(notify_mail.body.raw_source).to include("- " + node.columns[7].name)
          expect(notify_mail.body.raw_source).to include("logo.png")
        end

        ActionMailer::Base.deliveries[1].tap do |notify_mail|
          expect(notify_mail.from.first).to eq 'admin@example.jp'
          expect(notify_mail.to.first).to eq 'transfers@example.jp'
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
          # inquiry_column_transfers
          expect(notify_mail.body.raw_source).to include("- " + node.columns[2].name)
          expect(notify_mail.body.raw_source).to include('キーワード')
          # inquiry_column_email
          expect(notify_mail.body.raw_source).to include("- " + node.columns[3].name)
          expect(notify_mail.body.raw_source).to include("shirasagi@example.jp")
          # inquiry_column_radio
          expect(notify_mail.body.raw_source).to include("- " + node.columns[4].name)
          expect(notify_mail.body.raw_source).to include("男性")
          # inquiry_column_select
          expect(notify_mail.body.raw_source).to include("- " + node.columns[5].name)
          expect(notify_mail.body.raw_source).to include("50代")
          # inquiry_column_check
          expect(notify_mail.body.raw_source).to include("- " + node.columns[6].name)
          expect(notify_mail.body.raw_source).to include("申請について")
          # inquiry_column_upload_file
          expect(notify_mail.body.raw_source).to include("- " + node.columns[7].name)
          expect(notify_mail.body.raw_source).to include("logo.png")
        end
      end
    end
  end

  context "when kintone_domain is blank" do
    before do
      node.columns.create! attributes_for(:inquiry_column_name).reverse_merge({cur_site: site, kintone_field_code: 'name'})
      node.columns.create! attributes_for(:inquiry_column_optional).reverse_merge({cur_site: site})
      node.columns.create! attributes_for(:inquiry_column_transfers).reverse_merge({cur_site: site})
      node.columns.create! attributes_for(:inquiry_column_email).reverse_merge({cur_site: site, kintone_field_code: 'email'})
      node.columns.create! attributes_for(:inquiry_column_radio).reverse_merge({cur_site: site, kintone_field_code: 'radio'})
      node.columns.create! attributes_for(:inquiry_column_select).reverse_merge({cur_site: site, kintone_field_code: 'select'})
      node.columns.create! attributes_for(:inquiry_column_check).reverse_merge({cur_site: site, kintone_field_code: 'check'})
      node.columns.create! attributes_for(:inquiry_column_upload_file).reverse_merge({cur_site: site})
      node.reload

      stub_request(:post, kintone_url).
        to_return(status: 200, body: { id: 100, revision: 1 }.to_json, headers: { 'Content-Type' => 'application/json'})
    end

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
          expect(find('#item_1')['value']).to eq 'シラサギ太郎'
          expect(find('#item_2')['value']).to eq '株式会社シラサギ'
          expect(find('#item_3')['value']).to eq 'キーワード'
          expect(find('#item_4')['value']).to eq 'shirasagi@example.jp'
          expect(find('#item_5')['value']).to eq '男性'
          expect(find('#item_6')['value']).to eq '50代'
          expect(find('#item_7_2')['value']).to eq '申請について'
          expect(find('#item_8')['value']).to eq '1'
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
      expect(answer.kintone_record_key).to be_nil
      expect(answer.kintone_revision).to be_nil
      expect(answer.kintone_update_error_message).to be_present

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
        # inquiry_column_transfers
        expect(notify_mail.body.raw_source).to include("- " + node.columns[2].name)
        expect(notify_mail.body.raw_source).to include('キーワード')
        # inquiry_column_email
        expect(notify_mail.body.raw_source).to include("- " + node.columns[3].name)
        expect(notify_mail.body.raw_source).to include("shirasagi@example.jp")
        # inquiry_column_radio
        expect(notify_mail.body.raw_source).to include("- " + node.columns[4].name)
        expect(notify_mail.body.raw_source).to include("男性")
        # inquiry_column_select
        expect(notify_mail.body.raw_source).to include("- " + node.columns[5].name)
        expect(notify_mail.body.raw_source).to include("50代")
        # inquiry_column_check
        expect(notify_mail.body.raw_source).to include("- " + node.columns[6].name)
        expect(notify_mail.body.raw_source).to include("申請について")
        # inquiry_column_upload_file
        expect(notify_mail.body.raw_source).to include("- " + node.columns[7].name)
        expect(notify_mail.body.raw_source).to include("logo.png")
      end

      ActionMailer::Base.deliveries[1].tap do |notify_mail|
        expect(notify_mail.from.first).to eq 'admin@example.jp'
        expect(notify_mail.to.first).to eq 'transfers@example.jp'
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
        # inquiry_column_transfers
        expect(notify_mail.body.raw_source).to include("- " + node.columns[2].name)
        expect(notify_mail.body.raw_source).to include('キーワード')
        # inquiry_column_email
        expect(notify_mail.body.raw_source).to include("- " + node.columns[3].name)
        expect(notify_mail.body.raw_source).to include("shirasagi@example.jp")
        # inquiry_column_radio
        expect(notify_mail.body.raw_source).to include("- " + node.columns[4].name)
        expect(notify_mail.body.raw_source).to include("男性")
        # inquiry_column_select
        expect(notify_mail.body.raw_source).to include("- " + node.columns[5].name)
        expect(notify_mail.body.raw_source).to include("50代")
        # inquiry_column_check
        expect(notify_mail.body.raw_source).to include("- " + node.columns[6].name)
        expect(notify_mail.body.raw_source).to include("申請について")
        # inquiry_column_upload_file
        expect(notify_mail.body.raw_source).to include("- " + node.columns[7].name)
        expect(notify_mail.body.raw_source).to include("logo.png")
      end
    end
  end

  context "when kintone_app_activation is disabled" do
    let(:node) do
      create(
        :inquiry_node_form,
        cur_site: site,
        layout_id: layout.id,
        inquiry_captcha: 'enabled',
        notice_state: 'enabled',
        notice_content: 'include_answers',
        notice_email: 'notice@example.jp',
        from_name: 'admin',
        from_email: 'admin@example.jp',
        reply_state: 'disabled',
        kintone_app_activation: 'disabled',
        kintone_app_api_token: unique_id,
        kintone_app_key: 1)
    end

    before do
      site.kintone_domain = kintone_domain
      site.save!
      site.reload

      node.columns.create! attributes_for(:inquiry_column_name).reverse_merge({cur_site: site, kintone_field_code: 'name'})
      node.columns.create! attributes_for(:inquiry_column_optional).reverse_merge({cur_site: site})
      node.columns.create! attributes_for(:inquiry_column_transfers).reverse_merge({cur_site: site})
      node.columns.create! attributes_for(:inquiry_column_email).reverse_merge({cur_site: site, kintone_field_code: 'email'})
      node.columns.create! attributes_for(:inquiry_column_radio).reverse_merge({cur_site: site, kintone_field_code: 'radio'})
      node.columns.create! attributes_for(:inquiry_column_select).reverse_merge({cur_site: site, kintone_field_code: 'select'})
      node.columns.create! attributes_for(:inquiry_column_check).reverse_merge({cur_site: site, kintone_field_code: 'check'})
      node.columns.create! attributes_for(:inquiry_column_upload_file).reverse_merge({cur_site: site})
      node.reload

      stub_request(:post, kintone_url).
        to_return(status: 200, body: { id: 100, revision: 1 }.to_json, headers: { 'Content-Type' => 'application/json'})
    end

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
          expect(find('#item_1')['value']).to eq 'シラサギ太郎'
          expect(find('#item_2')['value']).to eq '株式会社シラサギ'
          expect(find('#item_3')['value']).to eq 'キーワード'
          expect(find('#item_4')['value']).to eq 'shirasagi@example.jp'
          expect(find('#item_5')['value']).to eq '男性'
          expect(find('#item_6')['value']).to eq '50代'
          expect(find('#item_7_2')['value']).to eq '申請について'
          expect(find('#item_8')['value']).to eq '1'
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
      expect(answer.kintone_record_key).to be_nil
      expect(answer.kintone_revision).to be_nil
      expect(answer.kintone_update_error_message).to be_nil

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
        # inquiry_column_transfers
        expect(notify_mail.body.raw_source).to include("- " + node.columns[2].name)
        expect(notify_mail.body.raw_source).to include('キーワード')
        # inquiry_column_email
        expect(notify_mail.body.raw_source).to include("- " + node.columns[3].name)
        expect(notify_mail.body.raw_source).to include("shirasagi@example.jp")
        # inquiry_column_radio
        expect(notify_mail.body.raw_source).to include("- " + node.columns[4].name)
        expect(notify_mail.body.raw_source).to include("男性")
        # inquiry_column_select
        expect(notify_mail.body.raw_source).to include("- " + node.columns[5].name)
        expect(notify_mail.body.raw_source).to include("50代")
        # inquiry_column_check
        expect(notify_mail.body.raw_source).to include("- " + node.columns[6].name)
        expect(notify_mail.body.raw_source).to include("申請について")
        # inquiry_column_upload_file
        expect(notify_mail.body.raw_source).to include("- " + node.columns[7].name)
        expect(notify_mail.body.raw_source).to include("logo.png")
      end

      ActionMailer::Base.deliveries[1].tap do |notify_mail|
        expect(notify_mail.from.first).to eq 'admin@example.jp'
        expect(notify_mail.to.first).to eq 'transfers@example.jp'
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
        # inquiry_column_transfers
        expect(notify_mail.body.raw_source).to include("- " + node.columns[2].name)
        expect(notify_mail.body.raw_source).to include('キーワード')
        # inquiry_column_email
        expect(notify_mail.body.raw_source).to include("- " + node.columns[3].name)
        expect(notify_mail.body.raw_source).to include("shirasagi@example.jp")
        # inquiry_column_radio
        expect(notify_mail.body.raw_source).to include("- " + node.columns[4].name)
        expect(notify_mail.body.raw_source).to include("男性")
        # inquiry_column_select
        expect(notify_mail.body.raw_source).to include("- " + node.columns[5].name)
        expect(notify_mail.body.raw_source).to include("50代")
        # inquiry_column_check
        expect(notify_mail.body.raw_source).to include("- " + node.columns[6].name)
        expect(notify_mail.body.raw_source).to include("申請について")
        # inquiry_column_upload_file
        expect(notify_mail.body.raw_source).to include("- " + node.columns[7].name)
        expect(notify_mail.body.raw_source).to include("logo.png")
      end
    end
  end

  context "when kintone_field_code is blank" do
    before do
      site.kintone_domain = kintone_domain
      site.save!
      site.reload

      node.columns.create! attributes_for(:inquiry_column_name).reverse_merge({cur_site: site})
      node.columns.create! attributes_for(:inquiry_column_optional).reverse_merge({cur_site: site})
      node.columns.create! attributes_for(:inquiry_column_transfers).reverse_merge({cur_site: site})
      node.columns.create! attributes_for(:inquiry_column_email).reverse_merge({cur_site: site})
      node.columns.create! attributes_for(:inquiry_column_radio).reverse_merge({cur_site: site})
      node.columns.create! attributes_for(:inquiry_column_select).reverse_merge({cur_site: site})
      node.columns.create! attributes_for(:inquiry_column_check).reverse_merge({cur_site: site})
      node.columns.create! attributes_for(:inquiry_column_upload_file).reverse_merge({cur_site: site})
      node.reload

      stub_request(:post, kintone_url).
        to_return(status: 200, body: { id: 100, revision: 1 }.to_json, headers: { 'Content-Type' => 'application/json'})
    end

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
          expect(find('#item_1')['value']).to eq 'シラサギ太郎'
          expect(find('#item_2')['value']).to eq '株式会社シラサギ'
          expect(find('#item_3')['value']).to eq 'キーワード'
          expect(find('#item_4')['value']).to eq 'shirasagi@example.jp'
          expect(find('#item_5')['value']).to eq '男性'
          expect(find('#item_6')['value']).to eq '50代'
          expect(find('#item_7_2')['value']).to eq '申請について'
          expect(find('#item_8')['value']).to eq '1'
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
      expect(answer.kintone_record_key).to be_nil
      expect(answer.kintone_revision).to be_nil
      expect(answer.kintone_update_error_message).to eq "update_kintone_record : update record is blank"

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
        # inquiry_column_transfers
        expect(notify_mail.body.raw_source).to include("- " + node.columns[2].name)
        expect(notify_mail.body.raw_source).to include('キーワード')
        # inquiry_column_email
        expect(notify_mail.body.raw_source).to include("- " + node.columns[3].name)
        expect(notify_mail.body.raw_source).to include("shirasagi@example.jp")
        # inquiry_column_radio
        expect(notify_mail.body.raw_source).to include("- " + node.columns[4].name)
        expect(notify_mail.body.raw_source).to include("男性")
        # inquiry_column_select
        expect(notify_mail.body.raw_source).to include("- " + node.columns[5].name)
        expect(notify_mail.body.raw_source).to include("50代")
        # inquiry_column_check
        expect(notify_mail.body.raw_source).to include("- " + node.columns[6].name)
        expect(notify_mail.body.raw_source).to include("申請について")
        # inquiry_column_upload_file
        expect(notify_mail.body.raw_source).to include("- " + node.columns[7].name)
        expect(notify_mail.body.raw_source).to include("logo.png")
      end

      ActionMailer::Base.deliveries[1].tap do |notify_mail|
        expect(notify_mail.from.first).to eq 'admin@example.jp'
        expect(notify_mail.to.first).to eq 'transfers@example.jp'
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
        # inquiry_column_transfers
        expect(notify_mail.body.raw_source).to include("- " + node.columns[2].name)
        expect(notify_mail.body.raw_source).to include('キーワード')
        # inquiry_column_email
        expect(notify_mail.body.raw_source).to include("- " + node.columns[3].name)
        expect(notify_mail.body.raw_source).to include("shirasagi@example.jp")
        # inquiry_column_radio
        expect(notify_mail.body.raw_source).to include("- " + node.columns[4].name)
        expect(notify_mail.body.raw_source).to include("男性")
        # inquiry_column_select
        expect(notify_mail.body.raw_source).to include("- " + node.columns[5].name)
        expect(notify_mail.body.raw_source).to include("50代")
        # inquiry_column_check
        expect(notify_mail.body.raw_source).to include("- " + node.columns[6].name)
        expect(notify_mail.body.raw_source).to include("申請について")
        # inquiry_column_upload_file
        expect(notify_mail.body.raw_source).to include("- " + node.columns[7].name)
        expect(notify_mail.body.raw_source).to include("logo.png")
      end
    end
  end

  context "when update_kintone_record is failed" do
    before do

      site.kintone_domain = kintone_domain
      site.save!
      site.reload

      node.columns.create! attributes_for(:inquiry_column_name).reverse_merge({cur_site: site, kintone_field_code: 'name'})
      node.columns.create! attributes_for(:inquiry_column_optional).reverse_merge({cur_site: site})
      node.columns.create! attributes_for(:inquiry_column_transfers).reverse_merge({cur_site: site})
      node.columns.create! attributes_for(:inquiry_column_email).reverse_merge({cur_site: site, kintone_field_code: 'email'})
      node.columns.create! attributes_for(:inquiry_column_radio).reverse_merge({cur_site: site, kintone_field_code: 'radio'})
      node.columns.create! attributes_for(:inquiry_column_select).reverse_merge({cur_site: site, kintone_field_code: 'select'})
      node.columns.create! attributes_for(:inquiry_column_check).reverse_merge({cur_site: site, kintone_field_code: 'check'})
      node.columns.create! attributes_for(:inquiry_column_upload_file).reverse_merge({cur_site: site})
      node.reload

      stub_request(:post, kintone_url).
        to_return(status: 500, body: {
          message: 'message', id: 'id', code: 'code', errors: { id: { messages: [unique_id] } }
        }.to_json, headers: { 'Content-Type' => 'application/json'})
    end

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
          expect(find('#item_1')['value']).to eq 'シラサギ太郎'
          expect(find('#item_2')['value']).to eq '株式会社シラサギ'
          expect(find('#item_3')['value']).to eq 'キーワード'
          expect(find('#item_4')['value']).to eq 'shirasagi@example.jp'
          expect(find('#item_5')['value']).to eq '男性'
          expect(find('#item_6')['value']).to eq '50代'
          expect(find('#item_7_2')['value']).to eq '申請について'
          expect(find('#item_8')['value']).to eq '1'
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
      expect(answer.kintone_record_key).to be_nil
      expect(answer.kintone_revision).to be_nil
      expect(answer.kintone_update_error_message).to include "500 [code] message(id)"

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
        # inquiry_column_transfers
        expect(notify_mail.body.raw_source).to include("- " + node.columns[2].name)
        expect(notify_mail.body.raw_source).to include('キーワード')
        # inquiry_column_email
        expect(notify_mail.body.raw_source).to include("- " + node.columns[3].name)
        expect(notify_mail.body.raw_source).to include("shirasagi@example.jp")
        # inquiry_column_radio
        expect(notify_mail.body.raw_source).to include("- " + node.columns[4].name)
        expect(notify_mail.body.raw_source).to include("男性")
        # inquiry_column_select
        expect(notify_mail.body.raw_source).to include("- " + node.columns[5].name)
        expect(notify_mail.body.raw_source).to include("50代")
        # inquiry_column_check
        expect(notify_mail.body.raw_source).to include("- " + node.columns[6].name)
        expect(notify_mail.body.raw_source).to include("申請について")
        # inquiry_column_upload_file
        expect(notify_mail.body.raw_source).to include("- " + node.columns[7].name)
        expect(notify_mail.body.raw_source).to include("logo.png")
      end

      ActionMailer::Base.deliveries[1].tap do |notify_mail|
        expect(notify_mail.from.first).to eq 'admin@example.jp'
        expect(notify_mail.to.first).to eq 'transfers@example.jp'
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
        # inquiry_column_transfers
        expect(notify_mail.body.raw_source).to include("- " + node.columns[2].name)
        expect(notify_mail.body.raw_source).to include('キーワード')
        # inquiry_column_email
        expect(notify_mail.body.raw_source).to include("- " + node.columns[3].name)
        expect(notify_mail.body.raw_source).to include("shirasagi@example.jp")
        # inquiry_column_radio
        expect(notify_mail.body.raw_source).to include("- " + node.columns[4].name)
        expect(notify_mail.body.raw_source).to include("男性")
        # inquiry_column_select
        expect(notify_mail.body.raw_source).to include("- " + node.columns[5].name)
        expect(notify_mail.body.raw_source).to include("50代")
        # inquiry_column_check
        expect(notify_mail.body.raw_source).to include("- " + node.columns[6].name)
        expect(notify_mail.body.raw_source).to include("申請について")
        # inquiry_column_upload_file
        expect(notify_mail.body.raw_source).to include("- " + node.columns[7].name)
        expect(notify_mail.body.raw_source).to include("logo.png")
      end
    end
  end
end
