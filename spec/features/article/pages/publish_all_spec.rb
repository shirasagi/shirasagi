require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let!(:now) { Time.zone.now.change(sec: 0) }
  let!(:site) { cms_site }
  let!(:admin) { cms_user }

  let!(:contact_group1) { create(:contact_group, name: "#{site.groups.first.name}/#{unique_id}") }
  let(:contact) { contact_group1.contact_groups.where(main_state: "main").first }
  let!(:user1) { create(:cms_test_user, group_ids: [ contact_group1.id ], cms_role_ids: admin.cms_role_ids) }

  let!(:layout) { create_cms_layout }
  let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'entry') }
  let!(:node) { create(:article_node_page, cur_site: site, layout: layout, st_form_ids: [ form.id ]) }

  let!(:column1) do
    create(:cms_column_free, cur_site: site, cur_form: form, order: 10)
  end
  let!(:column2) do
    layout = <<~LIQUID_HTML
      {% if value.file %}
        <p>{{ value.html }}</p>
      {% endif %}
    LIQUID_HTML
    create(:cms_column_file_upload, cur_site: site, cur_form: form, order: 20, file_type: "attachment", layout: layout)
  end

  let!(:file1) do
    tmp_ss_file Cms::TempFile, cur_user: user1, site: site, node: node, contents: "#{Rails.root}/spec/fixtures/ss/logo.png"
  end
  let!(:file2) do
    tmp_ss_file Cms::TempFile, cur_user: user1, site: site, node: node, contents: "#{Rails.root}/spec/fixtures/ss/logo.png"
  end

  let!(:item_master) do
    Timecop.freeze(now - 1.year - 1.month) do
      html = <<~HTML
        <p><span style="font-size:130%;"><strong>対象となる方</strong></span></p>
        <p>&nbsp;</p>
      HTML
      create(
        :article_page, cur_site: site, cur_user: user1, cur_node: node, layout: layout, state: "public", released_type: "fixed",
        column_values: [
          column1.value_type.new(column: column1, value: html),
          column2.value_type.new(column: column2, file_id: file1.id, file_label: unique_id)
        ],
        contact_state: "show", contact_group_relation: "related", contact_group: contact_group1,
        contact_group_contact_id: contact.id, group_ids: user1.group_ids
      )
    end
  end
  let!(:item_branch) do
    Timecop.freeze(now - 1.month) do
      release_date = now.beginning_of_day
      close_date = release_date + 1.year - 1.second

      html = <<~HTML
        <p><span style="font-size:130%;"><strong>対象となる方</strong></span></p>
        <p>&nbsp;</p>
      HTML
      column_values = [
        column1.value_type.new(column: column1, value: html),
        column2.value_type.new(column: column2, file_id: file2.id, file_label: unique_id)
      ]

      create(
        :article_page, cur_site: site, cur_user: user1, cur_node: node, layout: layout, master: item_master,
        state: "closed", released_type: "fixed", release_date: release_date, close_date: close_date,
        released: item_master.released, first_released: item_master.first_released, column_values: column_values,
        contact_state: "show", contact_group_relation: "related", contact_group: contact_group1,
        contact_group_contact_id: contact.id, group_ids: user1.group_ids
      )
    end
  end

  context "when master is published all" do
    it do
      login_user user1, to: article_pages_path(site: site, cid: node)
      wait_for_js_ready
      expect(page).to have_css(".list-item[data-id='#{item_master.id}']", text: item_master.name)
      expect(page).to have_css(".list-item[data-id='#{item_branch.id}']", text: item_branch.name)

      first(".list-item[data-id='#{item_master.id}'] [type='checkbox']").click
      within ".list-head-action" do
        click_on I18n.t('ss.links.make_them_public')
      end

      within "form" do
        within "[data-id='#{item_master.id}']" do
          expect(page).to have_css("[type='checkbox']")
          expect(page).to have_css(".list-item-error", text: I18n.t("errors.messages.branch_is_already_existed"))
        end
        expect(page).to have_no_css("[data-id='#{item_branch.id}']")
        click_on I18n.t('ss.buttons.make_them_public')
      end
      wait_for_notice I18n.t("ss.notice.published")

      Article::Page.find(item_master.id).tap do |published_master|
        expect(published_master.name).to eq item_master.name
        expect(published_master.filename).to eq item_master.filename
        expect(published_master.updated).to eq item_master.updated
        expect(published_master.released).to eq item_master.released
        expect(published_master.first_released).to be_present
        expect(published_master.first_released).to eq item_master.first_released
        expect(published_master.column_values.count).to eq item_master.column_values.count
        expect(published_master.contact_state).to eq item_master.contact_state
        expect(published_master.contact_group_relation).to eq item_master.contact_group_relation
        expect(published_master.contact_group_id).to eq item_master.contact_group_id
        expect(published_master.contact_group_contact_id).to eq item_master.contact_group_contact_id
        expect(published_master.state).to eq item_master.state
        expect(published_master.group_ids).to eq item_master.group_ids
      end

      Article::Page.find(item_branch.id).tap do |branch_after|
        expect(branch_after.site_id).to eq item_branch.site_id
        expect(branch_after.name).to eq item_branch.name
        expect(branch_after.filename).to eq item_branch.filename
        expect(branch_after.updated).to eq item_branch.updated
        expect(branch_after.released).to eq item_branch.released
        expect(branch_after.first_released).to be_present
        expect(branch_after.first_released).to eq item_branch.first_released
        expect(branch_after.column_values.count).to eq item_branch.column_values.count
        expect(branch_after.contact_state).to eq item_branch.contact_state
        expect(branch_after.contact_group_relation).to eq item_branch.contact_group_relation
        expect(branch_after.contact_group_id).to eq item_branch.contact_group_id
        expect(branch_after.contact_group_contact_id).to eq item_branch.contact_group_contact_id
        expect(branch_after.state).to eq item_branch.state
        expect(branch_after.group_ids).to eq item_branch.group_ids
      end
    end
  end

  context "when branch is published all" do
    it do
      login_user user1, to: article_pages_path(site: site, cid: node)
      wait_for_js_ready
      expect(page).to have_css(".list-item[data-id='#{item_master.id}']", text: item_master.name)
      expect(page).to have_css(".list-item[data-id='#{item_branch.id}']", text: item_branch.name)

      first(".list-item[data-id='#{item_branch.id}'] [type='checkbox']").click
      within ".list-head-action" do
        click_on I18n.t('ss.links.make_them_public')
      end

      within "form" do
        within "[data-id='#{item_branch.id}']" do
          expect(page).to have_css("[type='checkbox']")
          expect(page).to have_no_css(".list-item-error")
        end
        expect(page).to have_no_css("[data-id='#{item_master.id}']")
        click_on I18n.t('ss.buttons.make_them_public')
      end
      wait_for_notice I18n.t("ss.notice.published")

      Article::Page.find(item_master.id).tap do |published_master|
        expect(published_master.name).to eq item_branch.name
        expect(published_master.filename).to eq item_master.filename
        expect(published_master.updated.in_time_zone).to be_within(30.seconds).of(Time.zone.now)
        expect(published_master.released).to eq item_branch.released
        expect(published_master.first_released).to be_present
        expect(published_master.first_released).to eq item_branch.first_released
        expect(published_master.column_values.count).to eq item_branch.column_values.count
        expect(published_master.contact_state).to eq item_branch.contact_state
        expect(published_master.contact_group_relation).to eq item_branch.contact_group_relation
        expect(published_master.contact_group_id).to eq item_branch.contact_group_id
        expect(published_master.contact_group_contact_id).to eq item_branch.contact_group_contact_id
        expect(published_master.state).to eq "public"
        expect(published_master.group_ids).to eq item_master.group_ids
      end

      expect { Article::Page.find(item_branch.id) }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end
end
