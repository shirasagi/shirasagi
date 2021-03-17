require 'spec_helper'

describe "history_cms_logs", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:node) do
    create(:article_node_page, filename: "docs", name: "article", group_ids: [cms_group.id], st_form_ids: [form.id])
  end
  let!(:item) { create :article_page, cur_node: node, group_ids: [cms_group.id] }
  let!(:edit_path) { edit_article_page_path(site: site, cid: node, id: item) }

  let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'entry', group_ids: [cms_group.id]) }
  let!(:column1) { create(:cms_column_file_upload, cur_site: site, cur_form: form, required: "optional", order: 1) }
  let!(:column2) { create(:cms_column_free, cur_site: site, cur_form: form, required: "optional", order: 2) }

  let(:logs_path) { history_cms_logs_path site.id }

  context "paste thumb file with entry form free" do
    before { login_cms_user }

    it do
      visit edit_path
      within 'form#item-form' do
        select form.name, from: 'item[form_id]'
        find('.btn-form-change').click
      end

      within ".column-value-palette" do
        wait_event_to_fire("ss:columnAdded") do
          click_on column2.name
        end
      end

      within ".column-value-cms-column-free" do
        wait_cbox_open do
          click_on I18n.t("cms.file")
        end
      end

      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        wait_cbox_close do
          click_on I18n.t('ss.buttons.attach')
        end
      end
      within ".column-value-cms-column-free" do
        expect(page).to have_css(".file-view", text: "keyvisual.jpg")
      end
      click_on I18n.t("ss.buttons.publish_save")
      wait_for_notice I18n.t("ss.notice.saved")

      visit logs_path
      expect(page).to have_css('.list-item', count: 3)

      visit edit_path
      within ".column-value-cms-column-free" do
        expect(page).to have_css(".file-view", text: "keyvisual.jpg")
        wait_for_ckeditor_event "item[column_values][][in_wrap][value]", "afterInsertHtml" do
          click_on I18n.t("sns.thumb_paste")
        end
      end
      click_on I18n.t("ss.buttons.publish_save")

      wait_for_cbox do
        click_on I18n.t("ss.buttons.ignore_alert")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      visit logs_path
      expect(page).to have_css('.list-item', count: 6)

      visit edit_path
      fill_in_ckeditor "item[column_values][][in_wrap][value]", with: ""
      click_on I18n.t("ss.buttons.publish_save")
      wait_for_notice I18n.t("ss.notice.saved")

      visit logs_path
      expect(page).to have_css('.list-item', count: 9)
    end
  end
end
