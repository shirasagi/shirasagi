require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:node) do
    create :article_node_page, filename: "docs", name: "article", group_ids: [cms_group.id], st_form_ids: [form.id]
  end
  let!(:item) { create :article_page, cur_node: node, group_ids: [cms_group.id] }
  let!(:edit_path) { edit_article_page_path site.id, node, item }

  let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'entry', group_ids: [cms_group.id]) }
  let!(:column1) do
    create(:cms_column_file_upload, cur_site: site, cur_form: form, required: "optional", file_type: "video", order: 1)
  end
  let!(:column2) { create(:cms_column_free, cur_site: site, cur_form: form, required: "optional", order: 2) }

  context "attach file from upload" do
    before { login_cms_user }

    context "attach 4 files" do
      let(:files) { Array.new(3) { "#{Rails.root}/spec/fixtures/ss/logo.png" } }
      let(:add_file) { "#{Rails.root}/spec/fixtures/ss/ロゴ.png" }

      it "#edit" do
        visit edit_path

        ensure_addon_opened("#addon-cms-agents-addons-file")
        within "#addon-cms-agents-addons-file" do
          wait_cbox_open do
            click_on I18n.t("ss.buttons.upload")
          end
        end

        within_cbox do
          attach_file "item[in_files][]", files
          wait_cbox_close do
            click_button I18n.t("ss.buttons.attach")
          end
        end

        within '#selected-files' do
          expect(page).to have_selector('.file-view', count: 3)
          expect(page).to have_css('.name', text: 'logo.png')
        end

        within "#addon-cms-agents-addons-file" do
          wait_cbox_open do
            click_on I18n.t("ss.buttons.upload")
          end
        end

        within_cbox do
          attach_file "item[in_files][]", add_file
          wait_cbox_close do
            click_button I18n.t("ss.buttons.attach")
          end
        end

        within '#selected-files' do
          expect(page).to have_selector('.file-view', count: 4)
          expect(page).to have_css('.name', text: 'ロゴ.png')
        end

        within "form#item-form" do
          click_on I18n.t("ss.buttons.withdraw")
        end
        click_on I18n.t('ss.buttons.ignore_alert')

        within "#selected-files" do
          expect(page).to have_selector('.file-view', count: 4)
          expect(page).to have_css('.name', text: 'logo.png')
          expect(page).to have_css('.name', text: 'ロゴ.png')
        end
      end
    end

    context "attach 26 files" do
      let(:files) { Array.new(25) { "#{Rails.root}/spec/fixtures/ss/logo.png" } }
      let(:add_file) { "#{Rails.root}/spec/fixtures/ss/ロゴ.png" }

      it "#edit" do
        visit edit_path

        ensure_addon_opened("#addon-cms-agents-addons-file")
        within "#addon-cms-agents-addons-file" do
          wait_cbox_open do
            click_on I18n.t("ss.buttons.upload")
          end
        end

        within_cbox do
          attach_file "item[in_files][]", files
          wait_cbox_close do
            click_button I18n.t("ss.buttons.attach")
          end
        end

        within '#selected-files' do
          expect(page).to have_selector('.file-view', count: 25)
          expect(page).to have_css('.name', text: 'logo.png')
        end

        within "#addon-cms-agents-addons-file" do
          wait_cbox_open do
            click_on I18n.t("ss.buttons.upload")
          end
        end

        within_cbox do
          attach_file "item[in_files][]", add_file
          wait_cbox_close do
            click_button I18n.t("ss.buttons.attach")
          end
        end

        within '#selected-files' do
          expect(page).to have_selector('.file-view', count: 26)
          expect(page).to have_css('.name', text: 'ロゴ.png')
        end

        within "form#item-form" do
          click_on I18n.t("ss.buttons.withdraw")
        end
        click_on I18n.t('ss.buttons.ignore_alert')

        within "#selected-files" do
          expect(page).to have_selector('.file-view', count: 26)
          expect(page).to have_css('.name', text: 'logo.png')
          expect(page).to have_css('.name', text: 'ロゴ.png')
        end
      end
    end
  end

  context "attach file from user file" do
    before { login_cms_user }

    context "attach 4 files" do
      let(:files) { Array.new(3) { "#{Rails.root}/spec/fixtures/ss/logo.png" } }
      let(:add_file) { "#{Rails.root}/spec/fixtures/ss/ロゴ.png" }

      it "#edit" do
        visit edit_path

        ensure_addon_opened("#addon-cms-agents-addons-file")
        within "#addon-cms-agents-addons-file" do
          wait_cbox_open do
            click_on I18n.t("sns.user_file")
          end
        end

        within_cbox do
          attach_file "item[in_files][]", files
          wait_cbox_close do
            click_button I18n.t("ss.buttons.attach")
          end
        end

        within '#selected-files' do
          expect(page).to have_selector('.file-view', count: 3)
          expect(page).to have_css('.name', text: 'logo.png')
        end

        within "#addon-cms-agents-addons-file" do
          wait_cbox_open do
            click_on I18n.t("sns.user_file")
          end
        end

        within_cbox do
          attach_file "item[in_files][]", add_file
          wait_cbox_close do
            click_button I18n.t("ss.buttons.attach")
          end
        end

        within '#selected-files' do
          expect(page).to have_selector('.file-view', count: 4)
          expect(page).to have_css('.name', text: 'ロゴ.png')
        end

        within "form#item-form" do
          click_on I18n.t("ss.buttons.withdraw")
        end
        click_on I18n.t('ss.buttons.ignore_alert')

        within "#selected-files" do
          expect(page).to have_selector('.file-view', count: 4)
          expect(page).to have_css('.name', text: 'logo.png')
          expect(page).to have_css('.name', text: 'ロゴ.png')
        end
      end
    end

    context "attach 26 files" do
      let(:files) { Array.new(25) { "#{Rails.root}/spec/fixtures/ss/logo.png" } }
      let(:add_file) { "#{Rails.root}/spec/fixtures/ss/ロゴ.png" }

      it "#edit" do
        visit edit_path

        ensure_addon_opened("#addon-cms-agents-addons-file")
        within "#addon-cms-agents-addons-file" do
          wait_cbox_open do
            click_on I18n.t("sns.user_file")
          end
        end

        within_cbox do
          attach_file "item[in_files][]", files
          wait_cbox_close do
            click_button I18n.t("ss.buttons.attach")
          end
        end

        within '#selected-files' do
          expect(page).to have_selector('.file-view', count: 25)
          expect(page).to have_css('.name', text: 'logo.png')
        end

        within "#addon-cms-agents-addons-file" do
          wait_cbox_open do
            click_on I18n.t("sns.user_file")
          end
        end

        within_cbox do
          attach_file "item[in_files][]", add_file
          wait_cbox_close do
            click_button I18n.t("ss.buttons.attach")
          end
        end

        within '#selected-files' do
          expect(page).to have_selector('.file-view', count: 26)
          expect(page).to have_css('.name', text: 'ロゴ.png')
        end

        within "form#item-form" do
          click_on I18n.t("ss.buttons.withdraw")
        end
        click_on I18n.t('ss.buttons.ignore_alert')

        within "#selected-files" do
          expect(page).to have_selector('.file-view', count: 26)
          expect(page).to have_css('.name', text: 'logo.png')
          expect(page).to have_css('.name', text: 'ロゴ.png')
        end
      end
    end
  end

  context "with entry form" do
    before { login_cms_user }

    context "attach 4 files" do
      let(:files) { Array.new(3) { "#{Rails.root}/spec/fixtures/ss/logo.png" } }
      let(:add_file) { "#{Rails.root}/spec/fixtures/ss/ロゴ.png" }

      it "#edit" do
        visit edit_path

        within 'form#item-form' do
          wait_event_to_fire("ss:formActivated") do
            page.accept_confirm(I18n.t("cms.confirm.change_form")) do
              select form.name, from: 'in_form_id'
            end
          end
        end

        within ".column-value-palette" do
          wait_event_to_fire("ss:columnAdded") do
            click_on column1.name
          end
        end

        within ".column-value-cms-column-fileupload" do
          wait_cbox_open do
            click_on I18n.t("ss.buttons.upload")
          end
        end

        within_cbox do
          attach_file "item[in_files][]", files
          wait_cbox_close do
            click_button I18n.t("ss.buttons.attach")
          end
        end

        within '.column-value-cms-column-fileupload .column-value-files' do
          expect(page).to have_selector('.file-view', count: 1)
          expect(page).to have_css('.name', text: 'logo.png')
        end

        within ".column-value-cms-column-fileupload" do
          wait_cbox_open do
            click_on I18n.t("ss.buttons.upload")
          end
        end

        within_cbox do
          attach_file "item[in_files][]", add_file
          wait_cbox_close do
            click_button I18n.t("ss.buttons.attach")
          end
        end

        within '.column-value-cms-column-fileupload .column-value-files' do
          expect(page).to have_selector('.file-view', count: 1)
          expect(page).to have_no_css('.name', text: 'logo.png')
          expect(page).to have_css('.name', text: 'ロゴ.png')
        end

        within "form#item-form" do
          click_on I18n.t("ss.buttons.withdraw")
        end
        click_on I18n.t('ss.buttons.ignore_alert')
        wait_for_notice I18n.t('ss.notice.saved')

        within ".column-value-cms-column-fileupload" do
          expect(page).to have_selector('.file-view', count: 1)
          expect(page).to have_no_css('.name', text: 'logo.png')
          expect(page).to have_css('.name', text: 'ロゴ.png')
        end
      end
    end

    context "attach 25 files" do
      let(:files) { Array.new(25) { "#{Rails.root}/spec/fixtures/ss/logo.png" } }
      let(:add_file) { "#{Rails.root}/spec/fixtures/ss/ロゴ.png" }

      it "#edit" do
        visit edit_path

        within 'form#item-form' do
          wait_event_to_fire("ss:formActivated") do
            page.accept_confirm(I18n.t("cms.confirm.change_form")) do
              select form.name, from: 'in_form_id'
            end
          end
        end

        within ".column-value-palette" do
          wait_event_to_fire("ss:columnAdded") do
            click_on column1.name
          end
        end

        within ".column-value-cms-column-fileupload" do
          wait_cbox_open do
            click_on I18n.t("ss.buttons.upload")
          end
        end

        within_cbox do
          attach_file "item[in_files][]", files
          wait_cbox_close do
            click_button I18n.t("ss.buttons.attach")
          end
        end

        within '.column-value-cms-column-fileupload .column-value-files' do
          expect(page).to have_selector('.file-view', count: 1)
          expect(page).to have_css('.name', text: 'logo.png')
        end

        within ".column-value-cms-column-fileupload" do
          wait_cbox_open do
            click_on I18n.t("ss.buttons.upload")
          end
        end

        within_cbox do
          attach_file "item[in_files][]", add_file
          wait_cbox_close do
            click_button I18n.t("ss.buttons.attach")
          end
        end

        within '.column-value-cms-column-fileupload .column-value-files' do
          expect(page).to have_selector('.file-view', count: 1)
          expect(page).to have_no_css('.name', text: 'logo.png')
          expect(page).to have_css('.name', text: 'ロゴ.png')
        end

        within "form#item-form" do
          click_on I18n.t("ss.buttons.withdraw")
        end
        click_on I18n.t('ss.buttons.ignore_alert')
        wait_for_notice I18n.t('ss.notice.saved')

        within ".column-value-cms-column-fileupload" do
          expect(page).to have_selector('.file-view', count: 1)
          expect(page).to have_no_css('.name', text: 'logo.png')
          expect(page).to have_css('.name', text: 'ロゴ.png')
        end
      end
    end
  end
end
