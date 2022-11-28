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
  let(:new_article_node_path) { new_article_page_path site.id, article_node }

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

    group = article.contact_group
    group.contact_groups = [{ contact_email: unique_email, main_state: "main" }]
    group.save!
  end

  context "set inquiry form" do
    before { login_cms_user }

    it do
      visit article.url
      expect(page).to have_no_content I18n.t("contact.view.inquiry_form")

      visit edit_site_path
      within "form#item-form" do
        ensure_addon_opened "#addon-ss-agents-addons-inquiry_setting"
        select node.name, from: "item_inquiry_form_id"
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      visit edit_article_path
      within "form#item-form" do
        click_on I18n.t("ss.buttons.publish_save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      visit article.url
      expect(page).to have_content I18n.t("contact.view.inquiry_form")

      click_on I18n.t("contact.view.inquiry_form")
      expect(current_path).to eq node.url
    end
  end

  context "replace email" do
    before { login_cms_user }

    it do
      cms_group.contact_groups = [{ contact_email: unique_email, main_state: "main" }]
      cms_group.save!

      visit new_article_node_path
      within "form#item-form" do
        ensure_addon_opened "#addon-contact-agents-addons-page"
        expect(find("#item_contact_email").value).to eq cms_group.contact_email
      end

      visit edit_article_path
      within "form#item-form" do
        ensure_addon_opened "#addon-contact-agents-addons-page"

        wait_cbox_open { click_link I18n.t("contact.apis.contacts.index") }
      end
      wait_for_cbox do
        within "[data-group-id='#{cms_group.id}']" do
          wait_cbox_close { click_on I18n.t("contact.buttons.select") }
        end
      end
      within "form#item-form" do
        expect(find("#item_contact_email").value).to eq cms_group.contact_email
      end
    end
  end

  context "do not replace email" do
    before { login_cms_user }

    it do
      cms_group.contact_groups = [{ contact_email: unique_email, main_state: "main" }]
      cms_group.save!

      visit edit_site_path
      within "form#item-form" do
        ensure_addon_opened "#addon-ss-agents-addons-inquiry_setting"
        select node.name, from: "item_inquiry_form_id"
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      site.reload
      expect(site.inquiry_form_id).to eq node.id

      visit new_article_node_path
      within "form#item-form" do
        ensure_addon_opened "#addon-contact-agents-addons-page"
        expect(find("#item_contact_email").value).not_to eq cms_group.contact_email
      end

      visit edit_article_path
      within "form#item-form" do
        ensure_addon_opened "#addon-contact-agents-addons-page"

        wait_cbox_open { click_on I18n.t("contact.apis.contacts.index") }
      end
      wait_for_cbox do
        within "[data-group-id='#{cms_group.id}']" do
          wait_cbox_close { click_on I18n.t("contact.buttons.select") }
        end
      end
      within "form#item-form" do
        expect(find("#item_contact_email").value).not_to eq cms_group.contact_email
      end
    end
  end
end
