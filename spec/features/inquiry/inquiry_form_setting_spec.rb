require 'spec_helper'

describe "inquiry_form", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:edit_site_path) { edit_cms_site_path site.id }
  let(:faq_node) { create :faq_node_page, cur_site: site }
  let(:node) { create :inquiry_node_form, cur_site: site, faq: faq_node }
  let(:index_path) { inquiry_answers_path(site, node) }
  let(:layout) { create_cms_layout }
  let(:article_node) { create :article_node_page, layout_id: layout.id, filename: "node" }
  let(:article) do
    create(:article_page, layout_id: layout.id, contact_group_id: cms_group.id, contact_tel: "000-0000", cur_node: article_node)
  end
  let(:edit_article_path) { edit_article_page_path site.id, article_node, article }

  let(:remote_addr) { "X.X.X.X" }
  let(:user_agent) { unique_id }
  let(:answer) { Inquiry::Answer.new(cur_site: site, cur_node: node, remote_addr: remote_addr, user_agent: user_agent) }

  let(:name) { unique_id }
  let(:email) { "#{unique_id}@example.jp" }
  let(:email_confirmation) { email }
  let(:radio_value) { radio_column.select_options.sample }
  let(:select_value) { select_column.select_options.sample }
  let(:check_value) { Hash[check_column.select_options.map.with_index { |val, i| [i.to_s, val] }.sample(2)] }
  let(:name_column) { node.columns[0] }
  let(:company_column) { node.columns[1] }
  let(:email_column) { node.columns[2] }
  let(:radio_column) { node.columns[3] }
  let(:select_column) { node.columns[4] }
  let(:check_column) { node.columns[5] }

  before do
    node.columns.create! attributes_for(:inquiry_column_name).reverse_merge({cur_site: site}).merge(question: 'enabled')
    node.columns.create! attributes_for(:inquiry_column_optional).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_email).reverse_merge({cur_site: site}).merge(question: 'enabled')
    node.columns.create! attributes_for(:inquiry_column_radio).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_select).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_check).reverse_merge({cur_site: site})
    node.reload
  end

  before do
    data = {}
    data[name_column.id] = [name]
    data[email_column.id] = [email, email]
    data[radio_column.id] = [radio_value]
    data[select_column.id] = [select_value]
    data[check_column.id] = [check_value]

    answer.set_data(data)
    answer.save!
  end

  context "set inquiry form" do
    before { login_cms_user }

    it do
      visit article.full_url
      expect(page).to have_no_content I18n.t("contact.view.inquiry_form")

      visit edit_site_path
      find("#addon-ss-agents-addons-inquiry_setting").click
      select node.name, from: "item_inquiry_form_id"
      click_button I18n.t('ss.buttons.save')

      visit edit_article_path
      click_on I18n.t("ss.buttons.publish_save")

      visit article.full_url
      expect(page).to have_content I18n.t("contact.view.inquiry_form")

      click_on I18n.t("contact.view.inquiry_form")
      expect(current_path).to eq node.url
    end
  end
end
