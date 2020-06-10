require 'spec_helper'

describe "inquiry_agents_nodes_form", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let(:node) do
    create(
      :inquiry_node_form,
      cur_site: site,
      layout_id: layout.id,
      inquiry_captcha: 'disabled',
      notice_state: 'disabled',
      from_name: 'admin',
      from_email: 'admin@example.jp',
      reply_state: 'enabled',
      reply_subject: 'お問い合わせを受け付けました',
      reply_upper_text: '上部テキスト',
      reply_lower_text: '下部テキスト',
      reply_content_state: reply_content_state)
  end
  let(:index_url) { ::URI.parse "http://#{site.domain}/#{node.filename}/" }

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

  before do
    ActionMailer::Base.deliveries = []
  end

  after do
    ActionMailer::Base.deliveries = []
  end

  context "when reply_content_state is answer" do
    let(:reply_content_state) { "answer" }

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
        # within 'div.simple-captcha' do
        #   fill_in "answer[captcha]", with: "xxxx"
        # end
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

      expect(ActionMailer::Base.deliveries.count).to eq 1

      ActionMailer::Base.deliveries.last.tap do |reply_mail|
        expect(reply_mail.from.first).to eq 'admin@example.jp'
        expect(reply_mail.to.first).to eq 'shirasagi@example.jp'
        expect(reply_mail.subject).to eq 'お問い合わせを受け付けました'
        expect(reply_mail.body.multipart?).to be_falsey
        # upper
        expect(reply_mail.body.raw_source).to include('上部テキスト')
        # inquiry_column_name
        expect(reply_mail.body.raw_source).to include("- " + node.columns[0].name)
        expect(reply_mail.body.raw_source).to include("シラサギ太郎")
        # inquiry_column_optional
        expect(reply_mail.body.raw_source).to include("- " + node.columns[1].name)
        expect(reply_mail.body.raw_source).to include("株式会社シラサギ")
        # inquiry_column_transfers
        expect(reply_mail.body.raw_source).to include("- " + node.columns[2].name)
        expect(reply_mail.body.raw_source).to include('キーワード')
        # inquiry_column_email
        expect(reply_mail.body.raw_source).to include("- " + node.columns[3].name)
        expect(reply_mail.body.raw_source).to include("shirasagi@example.jp")
        # inquiry_column_radio
        expect(reply_mail.body.raw_source).to include("- " + node.columns[4].name)
        expect(reply_mail.body.raw_source).to include("男性")
        # inquiry_column_select
        expect(reply_mail.body.raw_source).to include("- " + node.columns[5].name)
        expect(reply_mail.body.raw_source).to include("50代")
        # inquiry_column_check
        expect(reply_mail.body.raw_source).to include("- " + node.columns[6].name)
        expect(reply_mail.body.raw_source).to include("申請について")
        # inquiry_column_upload_file
        expect(reply_mail.body.raw_source).to include("- " + node.columns[7].name)
        expect(reply_mail.body.raw_source).to include("logo.png")
        # static
        expect(reply_mail.body.raw_source).not_to include(I18n.t("inquiry.default_reply_content_static"))
        # lower
        expect(reply_mail.body.raw_source).to include('下部テキスト')
      end
    end
  end

  shared_examples "static reply" do
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
        # within 'div.simple-captcha' do
        #   fill_in "answer[captcha]", with: "xxxx"
        # end
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

      expect(ActionMailer::Base.deliveries.count).to eq 1

      ActionMailer::Base.deliveries.last.tap do |reply_mail|
        expect(reply_mail.from.first).to eq 'admin@example.jp'
        expect(reply_mail.to.first).to eq 'shirasagi@example.jp'
        expect(reply_mail.subject).to eq 'お問い合わせを受け付けました'
        expect(reply_mail.body.multipart?).to be_falsey
        # upper
        expect(reply_mail.body.raw_source).to include('上部テキスト')
        # inquiry_column_name
        expect(reply_mail.body.raw_source).not_to include("- " + node.columns[0].name)
        expect(reply_mail.body.raw_source).not_to include("シラサギ太郎")
        # inquiry_column_optional
        expect(reply_mail.body.raw_source).not_to include("- " + node.columns[1].name)
        expect(reply_mail.body.raw_source).not_to include("株式会社シラサギ")
        # inquiry_column_transfers
        expect(reply_mail.body.raw_source).not_to include("- " + node.columns[2].name)
        expect(reply_mail.body.raw_source).not_to include('キーワード')
        # inquiry_column_email
        expect(reply_mail.body.raw_source).not_to include("- " + node.columns[3].name)
        expect(reply_mail.body.raw_source).not_to include("shirasagi@example.jp")
        # inquiry_column_radio
        expect(reply_mail.body.raw_source).not_to include("- " + node.columns[4].name)
        expect(reply_mail.body.raw_source).not_to include("男性")
        # inquiry_column_select
        expect(reply_mail.body.raw_source).not_to include("- " + node.columns[5].name)
        expect(reply_mail.body.raw_source).not_to include("50代")
        # inquiry_column_check
        expect(reply_mail.body.raw_source).not_to include("- " + node.columns[6].name)
        expect(reply_mail.body.raw_source).not_to include("申請について")
        # inquiry_column_upload_file
        expect(reply_mail.body.raw_source).not_to include("- " + node.columns[7].name)
        expect(reply_mail.body.raw_source).not_to include("logo.png")
        # static
        expect(reply_mail.body.raw_source).to include(I18n.t("inquiry.default_reply_content_static"))
        # lower
        expect(reply_mail.body.raw_source).to include('下部テキスト')
      end
    end
  end

  context "when reply_content_state is static" do
    let(:reply_content_state) { "static" }

    it_behaves_like "static reply"
  end

  context "when reply_content_state is static" do
    let(:reply_content_state) { nil }

    it_behaves_like "static reply"
  end
end
