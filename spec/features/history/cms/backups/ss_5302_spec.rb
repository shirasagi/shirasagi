require 'spec_helper'

describe "history_cms_backups", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:form) { create!(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
  let!(:col1) { create!(:cms_column_date_field, cur_site: site, cur_form: form, required: 'optional', order: 5) }
  let!(:node) { create :article_node_page, site: site, st_form_ids: [ form.id ], st_form_default: form }

  before do
    login_cms_user
  end

  it do
    visit article_pages_path(site: site, cid: node)
    click_on I18n.t("ss.links.new")
    wait_for_all_ckeditors_ready
    wait_for_all_turbo_frames

    within "form#item-form" do
      fill_in "item[name]", with: unique_id

      within ".column-value-cms-column-datefield" do
        fill_in_date "item[column_values][][in_wrap][date]", with: Time.zone.today
      end

      click_on I18n.t("ss.buttons.draft_save")
    end
    wait_for_notice I18n.t("ss.notice.saved")
    wait_for_all_ckeditors_ready
    wait_for_all_turbo_frames
    expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

    click_on I18n.t("ss.links.edit")
    wait_for_all_ckeditors_ready
    wait_for_all_turbo_frames
    within "form#item-form" do
      within ".column-value-cms-column-datefield" do
        fill_in_date "item[column_values][][in_wrap][date]", with: Time.zone.yesterday
      end
      click_on I18n.t("ss.buttons.draft_save")
    end
    wait_for_notice I18n.t("ss.notice.saved")
    wait_for_all_ckeditors_ready
    wait_for_all_turbo_frames
    expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

    expect(Article::Page.all.count).to eq 1
    page_item = Article::Page.all.first
    expect(page_item.backups.count).to eq 2
    page.scroll_to(find("#addon-history-agents-addons-backup"), align: :top)
    ensure_addon_opened "#addon-history-agents-addons-backup"
    within "#addon-history-agents-addons-backup" do
      wait_for_turbo_frame "#addon-history-agents-addons-backup-frame"

      latest_backup_item = page_item.backups.first
      within "[data-id='#{latest_backup_item.id}']" do
        click_link I18n.t('history.compare_backup_to_previsous')
      end
    end

    within ".history-backup" do
      within "[data-field-name='column_values'][data-column-name='#{col1.name}']" do
        expect(page).to have_css(".selected-history", text: I18n.l(Time.zone.yesterday, format: :long))
        expect(page).to have_css(".target-history", text: I18n.l(Time.zone.today, format: :long))
      end
    end
  end
end
