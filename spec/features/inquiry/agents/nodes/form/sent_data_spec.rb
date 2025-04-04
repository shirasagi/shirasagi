require 'spec_helper'

describe "inquiry_agents_nodes_form", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
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
    node.columns.create! attributes_for(:inquiry_column_number).reverse_merge({cur_site: site})
    node.reload
  end

  context "show_sent_data disabled" do
    let(:node) do
      create(
        :inquiry_node_form,
        cur_site: site,
        layout_id: layout.id,
        inquiry_captcha: 'disabled',
        notice_state: 'disabled',
        inquiry_show_sent_data: "disabled")
    end

    it do
      visit index_url
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
          fill_in "item[9]", with: "123"
        end
        click_button I18n.t('inquiry.confirm')
      end
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
          expect(find("[name='item[9]']")['value']).to eq '123'
        end
        within 'footer.send' do
          click_button I18n.t('inquiry.submit')
        end
      end
      expect(page).to have_css(".inquiry-sent")
      expect(page).to have_no_css(".columns")
    end
  end

  context "show_sent_data enabled" do
    let(:node) do
      create(
        :inquiry_node_form,
        cur_site: site,
        layout_id: layout.id,
        inquiry_captcha: 'disabled',
        notice_state: 'disabled',
        inquiry_show_sent_data: "enabled")
    end

    it do
      visit index_url
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
          fill_in "item[9]", with: "123"
        end
        click_button I18n.t('inquiry.confirm')
      end
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
          expect(find("[name='item[9]']")['value']).to eq '123'
        end
        within 'footer.send' do
          click_button I18n.t('inquiry.submit')
        end
      end
      expect(page).to have_css(".inquiry-sent")
      within ".columns" do
        expect(page).to have_css(".fields", text: 'シラサギ太郎')
        expect(page).to have_css(".fields", text: '株式会社シラサギ')
        expect(page).to have_css(".fields", text: 'キーワード')
        expect(page).to have_css(".fields", text: 'shirasagi@example.jp')
        expect(page).to have_css(".fields", text: '男性')
        expect(page).to have_css(".fields", text: '50代')
        expect(page).to have_css(".fields", text: '申請について')
        expect(page).to have_css(".fields", text: 'logo.png')
        expect(page).to have_css(".fields", text: '123')
      end

      expect(Inquiry::SavedParams.count).to eq 1
      sent_data = Inquiry::SavedParams.first
      visit "#{current_path}?sent_data=#{sent_data.token}"
      within ".columns" do
        expect(page).to have_css(".fields", text: 'シラサギ太郎')
        expect(page).to have_css(".fields", text: '株式会社シラサギ')
        expect(page).to have_css(".fields", text: 'キーワード')
        expect(page).to have_css(".fields", text: 'shirasagi@example.jp')
        expect(page).to have_css(".fields", text: '男性')
        expect(page).to have_css(".fields", text: '50代')
        expect(page).to have_css(".fields", text: '申請について')
        expect(page).to have_css(".fields", text: 'logo.png')
        expect(page).to have_css(".fields", text: '123')
      end

      Inquiry::DeleteInquiryTempFilesJob.perform_now
      expect(Inquiry::SavedParams.count).to eq 1

      # expiration
      Timecop.travel(1.day.from_now) do
        visit "#{current_path}?sent_data=#{sent_data.token}"
        expect(page).to have_no_css(".columns")

        Inquiry::DeleteInquiryTempFilesJob.perform_now
        expect(Inquiry::SavedParams.count).to eq 0
      end
    end
  end
end
