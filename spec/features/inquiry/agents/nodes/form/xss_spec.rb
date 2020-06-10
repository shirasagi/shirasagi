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
      notice_state: 'enabled',
      notice_content: 'link_only',
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

  context "when input non-email to email field" do
    let(:index_url) { ::URI.parse "http://#{site.domain}/#{node.filename}/" }

    it do
      visit index_url
      expect(status_code).to eq 200

      within 'div.inquiry-form' do
        within 'div.columns' do
          fill_in "item[1]", with: "シラサギ太郎"
          fill_in "item[2]", with: "株式会社シラサギ"
          fill_in "item[4]", with: "<script>alert(\"hello\");</script>"
          fill_in "item[4_confirm]", with: "<script>alert(\"hello\");</script>"
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
