require 'spec_helper'

describe "inquiry_answers", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:group0) { cms_group }
  let!(:group1) { create :cms_group, name: "#{group0.name}/#{unique_id}" }
  let!(:group2) { create :cms_group, name: "#{group0.name}/#{unique_id}" }
  let!(:faq_node) { create :faq_node_page, cur_site: site, group_ids: [ group2.id ] }
  let!(:node) { create :inquiry_node_form, cur_site: site, faq: faq_node, group_ids: [ group1.id ] }

  let(:remote_addr) { "X.X.X.X" }
  let(:user_agent) { unique_id }
  let(:answer) do
    Inquiry::Answer.new(
      cur_site: site, cur_node: node, remote_addr: remote_addr, user_agent: user_agent, group_ids: [ group1.id ])
  end

  let(:name) { unique_id }
  let(:email) { "#{unique_id}@example.jp" }
  let(:email_confirmation) { email }
  let(:radio_value) { radio_column.select_options.sample }
  let(:select_value) { select_column.select_options.sample }
  let(:check_value) { Hash[check_column.select_options.map.with_index { |val, i| [i.to_s, val] }.sample(2)] }
  let(:same_as_name) { unique_id }
  let(:name_column) { node.columns[0] }
  let(:company_column) { node.columns[1] }
  let(:email_column) { node.columns[2] }
  let(:radio_column) { node.columns[3] }
  let(:select_column) { node.columns[4] }
  let(:check_column) { node.columns[5] }
  let(:same_as_name_column) { node.columns[6] }

  before do
    node.columns.create! attributes_for(:inquiry_column_name).reverse_merge({cur_site: site}).merge(question: 'enabled')
    node.columns.create! attributes_for(:inquiry_column_optional).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_email).reverse_merge({cur_site: site}).merge(question: 'enabled')
    node.columns.create! attributes_for(:inquiry_column_radio).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_select).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_check).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_same_as_name).reverse_merge({cur_site: site})
    node.reload
  end

  before do
    data = {}
    data[name_column.id] = [name]
    data[email_column.id] = [email, email]
    data[radio_column.id] = [radio_value]
    data[select_column.id] = [select_value]
    data[check_column.id] = [check_value]
    data[same_as_name_column.id] = [same_as_name]

    answer.set_data(data)
    answer.save!
  end

  context "when a site-admin creates faq/page from inquiry/answer" do
    let!(:user) { cms_user }
    let(:new_faq_name) { "faq-name-#{unique_id}" }
    let(:new_faq_answer_html) { "<p>faq-answer-#{unique_id}</p>" }

    before { login_user user, to: inquiry_answers_path(site: site, cid: node) }

    it do
      expect(page).to have_css(".list-item a", text: answer.data_summary)
      within ".list-item[data-id]" do
        click_on answer.data_summary
      end
      within ".nav-menu" do
        click_on I18n.t('inquiry.links.faq')
      end
      wait_for_all_ckeditors_ready
      within "form#item-form" do
        expect(page).to have_css('[name="item[question]"]', text: [name, email].join(','))

        fill_in "item[name]", with: new_faq_name
        fill_in_ckeditor "item[html]", with: new_faq_answer_html

        click_on I18n.t("ss.buttons.draft_save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Faq::Page.all.count).to eq 1
      Faq::Page.all.first.tap do |new_faq_page|
        expect(new_faq_page.site_id).to eq site.id
        expect(new_faq_page.name).to eq new_faq_name
        expect(new_faq_page.question).to eq "<p>#{[name, email].join(',')}</p>"
        expect(new_faq_page.html).to eq new_faq_answer_html
        expect(new_faq_page.state).to eq "closed"
      end
    end
  end

  context "when a user who is answer charge and faq editor creates faq/page from inquiry/answer" do
    let!(:role) do
      answer_charge_permissions = %w(read_private_cms_nodes read_private_inquiry_answers edit_private_inquiry_answers)
      faq_editor_permissions = %w(edit_private_cms_nodes read_private_faq_pages edit_private_faq_pages)
      create :cms_role, cur_site: site, name: unique_id, permissions: answer_charge_permissions + faq_editor_permissions
    end
    let!(:user) { create :cms_test_user, cur_site: site, cms_role_ids: [ role.id ], group_ids: [ group1.id, group2.id ] }
    let(:new_faq_name) { "faq-name-#{unique_id}" }
    let(:new_faq_answer_html) { "<p>faq-answer-#{unique_id}</p>" }

    before { login_user user, to: inquiry_answers_path(site: site, cid: node) }

    it do
      expect(page).to have_css(".list-item a", text: answer.data_summary)
      within ".list-item[data-id]" do
        click_on answer.data_summary
      end
      within ".nav-menu" do
        click_on I18n.t('inquiry.links.faq')
      end
      wait_for_all_ckeditors_ready
      within "form#item-form" do
        expect(page).to have_css('[name="item[question]"]', text: [name, email].join(','))

        fill_in "item[name]", with: new_faq_name
        fill_in_ckeditor "item[html]", with: new_faq_answer_html

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Faq::Page.all.count).to eq 1
      Faq::Page.all.first.tap do |new_faq_page|
        expect(new_faq_page.site_id).to eq site.id
        expect(new_faq_page.name).to eq new_faq_name
        expect(new_faq_page.question).to eq "<p>#{[name, email].join(',')}</p>"
        expect(new_faq_page.html).to eq new_faq_answer_html
        expect(new_faq_page.state).to eq "closed"
      end
    end
  end

  context "when a user who is just an answer charge tries to create faq/page from inquiry/answer" do
    let!(:role) do
      answer_charge_permissions = %w(read_private_cms_nodes read_private_inquiry_answers edit_private_inquiry_answers)
      create :cms_role, cur_site: site, name: unique_id, permissions: answer_charge_permissions
    end
    let!(:user) { create :cms_test_user, cur_site: site, cms_role_ids: [ role.id ], group_ids: [ group1.id ] }
    let(:new_faq_name) { "faq-name-#{unique_id}" }
    let(:new_faq_answer_html) { "<p>faq-answer-#{unique_id}</p>" }

    before { login_user user, to: inquiry_answers_path(site: site, cid: node) }

    it do
      expect(page).to have_css(".list-item a", text: answer.data_summary)
      within ".list-item[data-id]" do
        click_on answer.data_summary
      end
      within ".nav-menu" do
        expect(page).to have_no_link(I18n.t('inquiry.links.faq'))
      end
    end
  end
end
