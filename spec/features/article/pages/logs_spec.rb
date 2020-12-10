require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:node) do
    create_once :article_node_page, filename: "docs", name: "article",
                group_ids: [cms_group.id], st_form_ids: [form.id]
  end
  let!(:item) { create :article_page, cur_node: node, group_ids: [cms_group.id] }
  let!(:edit_path) { edit_article_page_path site.id, node, item }

  let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'entry', group_ids: [cms_group.id]) }
  let!(:column1) { create(:cms_column_file_upload, cur_site: site, cur_form: form, required: "optional", order: 1) }
  let!(:column2) { create(:cms_column_free, cur_site: site, cur_form: form, required: "optional", order: 2) }

  subject(:logs_path) { history_cms_logs_path site.id }

  context "attach file upload log" do
    before { login_cms_user }

    it do
      visit edit_path

      within "#addon-cms-agents-addons-file" do
        click_on I18n.t("ss.buttons.upload")
      end

      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        click_on I18n.t("ss.buttons.attach")
      end
      within "#addon-cms-agents-addons-file" do
        expect(page).to have_css(".file-view", text: "keyvisual.jpg")
      end
      click_on I18n.t("ss.buttons.publish_save")
      wait_for_notice I18n.t("ss.notice.saved")

      visit logs_path
      expect(page).to have_css('.list-item', count: 3)

      visit edit_path
      within "#addon-cms-agents-addons-file" do
        page.accept_alert do
          click_on I18n.t("ss.buttons.delete")
        end
      end
      click_on I18n.t("ss.buttons.publish_save")
      wait_for_notice I18n.t("ss.notice.saved")

      visit logs_path
      expect(page).to have_css('.list-item', count: 5)
    end
  end

  context "paste attach file into the text log" do
    before { login_cms_user }

    it do
      visit edit_path

      within "#addon-cms-agents-addons-file" do
        click_on I18n.t("ss.buttons.upload")
      end

      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        click_on I18n.t("ss.buttons.attach")
      end
      within "#addon-cms-agents-addons-file" do
        expect(page).to have_css(".file-view", text: "keyvisual.jpg")
      end
      click_on I18n.t("ss.buttons.publish_save")
      wait_for_notice I18n.t("ss.notice.saved")

      visit edit_path
      within "#addon-cms-agents-addons-file" do
        click_on I18n.t("sns.file_attach")
      end
      click_on I18n.t("ss.buttons.publish_save")
      wait_for_notice I18n.t("ss.notice.saved")

      visit logs_path
      expect(page).to have_css('.list-item', count: 5)

      visit edit_path
      fill_in_ckeditor "item[html]", with: ""
      click_on I18n.t("ss.buttons.publish_save")
      wait_for_notice I18n.t("ss.notice.saved")

      visit logs_path
      expect(page).to have_css('.list-item', count: 7)
    end
  end

  context "paste thumb file into the text log" do
    before { login_cms_user }

    it do
      visit edit_path

      within "#addon-cms-agents-addons-file" do
        click_on I18n.t("ss.buttons.upload")
      end

      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        click_on I18n.t("ss.buttons.attach")
      end
      within "#addon-cms-agents-addons-file" do
        expect(page).to have_css(".file-view", text: "keyvisual.jpg")
      end
      click_on I18n.t("ss.buttons.publish_save")
      wait_for_notice I18n.t("ss.notice.saved")

      visit edit_path
      within "#addon-cms-agents-addons-file" do
        click_on I18n.t("sns.thumb_paste")
      end
      click_on I18n.t("ss.buttons.publish_save")

      wait_for_cbox do
        click_on I18n.t("ss.buttons.ignore_alert")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      visit logs_path
      expect(page).to have_css('.list-item', count: 6)

      visit edit_path
      fill_in_ckeditor "item[html]", with: ""
      click_on I18n.t("ss.buttons.publish_save")
      wait_for_notice I18n.t("ss.notice.saved")

      visit logs_path
      expect(page).to have_css('.list-item', count: 9)
    end
  end

  context "with entry form file_upload" do
    before { login_cms_user }

    it do
      visit edit_path
      within 'form#item-form' do
        select form.name, from: 'item[form_id]'
        find('.btn-form-change').click
      end

      within ".column-value-palette" do
        click_on column1.name
      end

      within ".column-value-cms-column-fileupload" do
        click_on I18n.t("cms.file")
      end

      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        click_on I18n.t('ss.buttons.attach')
      end
      within ".column-value-cms-column-fileupload" do
        expect(page).to have_css(".file-view", text: "keyvisual.jpg")
      end
      click_on I18n.t("ss.buttons.publish_save")
      wait_for_cbox do
        click_on I18n.t("ss.buttons.ignore_alert")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      visit logs_path
      expect(page).to have_css('.list-item', count: 3)
    end
  end

  context "with entry form free" do
    before { login_cms_user }

    it do
      visit edit_path
      within 'form#item-form' do
        select form.name, from: 'item[form_id]'
        find('.btn-form-change').click
      end

      within ".column-value-palette" do
        click_on column2.name
      end

      within ".column-value-cms-column-free" do
        click_on I18n.t("cms.file")
      end
      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        click_on I18n.t('ss.buttons.attach')
      end
      within ".column-value-cms-column-free" do
        expect(page).to have_css(".file-view", text: "keyvisual.jpg")
      end
      click_on I18n.t("ss.buttons.publish_save")
      wait_for_notice I18n.t("ss.notice.saved")

      visit logs_path
      expect(page).to have_css('.list-item', count: 3)
    end
  end

  context "paste thumb file with entry form free" do
    before { login_cms_user }

    it do
      visit edit_path
      within 'form#item-form' do
        select form.name, from: 'item[form_id]'
        find('.btn-form-change').click
      end

      within ".column-value-palette" do
        click_on column2.name
      end

      within ".column-value-cms-column-free" do
        click_on I18n.t("cms.file")
      end

      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        click_on I18n.t('ss.buttons.attach')
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
        click_on I18n.t("sns.thumb_paste")
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
