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

  let!(:permissions) do
    permissions = Cms::Role.permission_names.select { |item| item =~ /_private_/ }
    permissions << "delete_cms_ignore_alert"
    permissions << "edit_cms_ignore_alert"
    permissions
  end
  let!(:role) { create :cms_role, name: "role", permissions: permissions, permission_level: 3, cur_site: site }
  let(:user2) { create :cms_user, uid: unique_id, name: unique_id, group_ids: [cms_group.id], cms_role_ids: [role.id] }

  context "attach file from upload" do
    before { login_cms_user }

    it "#edit" do
      visit edit_path

      ensure_addon_opened("#addon-cms-agents-addons-file")
      within "#addon-cms-agents-addons-file" do
        wait_for_cbox_opened do
          click_on I18n.t("ss.buttons.upload")
        end
      end

      within_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        click_button I18n.t("ss.buttons.save")
        expect(page).to have_css('.file-view', text: 'keyvisual.jpg')

        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif"
        wait_for_cbox_closed do
          click_button I18n.t("ss.buttons.attach")
        end
      end

      within '#selected-files' do
        expect(page).to have_no_css('.name', text: 'keyvisual.jpg')
        expect(page).to have_css('.name', text: 'keyvisual.gif')
      end
    end

    it "#edit file name" do
      visit edit_path
      ensure_addon_opened("#addon-cms-agents-addons-file")
      within "form#item-form" do
        within "#addon-cms-agents-addons-file" do
          wait_for_cbox_opened do
            click_on I18n.t("ss.buttons.upload")
          end
        end
      end

      within_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        click_button I18n.t("ss.buttons.save")
        expect(page).to have_css('.file-view', text: 'keyvisual.jpg')

        click_on I18n.t("ss.buttons.edit")
        fill_in "item[name]", with: "modify.jpg"
        click_button I18n.t("ss.buttons.save")
        expect(page).to have_css(".file-view", text: "modify.jpg")

        wait_for_cbox_closed do
          click_on "modify.jpg"
        end
      end

      within '#selected-files' do
        expect(page).to have_css('.name', text: 'modify.jpg')
      end
    end
  end

  context "attach file from user file" do
    before { login_cms_user }

    it do
      visit edit_path
      ensure_addon_opened("#addon-cms-agents-addons-file")
      within "form#item-form" do
        within "#addon-cms-agents-addons-file" do
          wait_for_cbox_opened do
            click_on I18n.t("sns.user_file")
          end
        end
      end

      within_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        click_button I18n.t("ss.buttons.save")
        expect(page).to have_css('.file-view', text: 'keyvisual.jpg')

        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif"
        wait_for_cbox_closed do
          click_button I18n.t("ss.buttons.attach")
        end
      end

      within "form#item-form" do
        within '#selected-files' do
          expect(page).to have_no_css('.name', text: 'keyvisual.jpg')
          expect(page).to have_css('.name', text: 'keyvisual.gif')
        end
        click_on I18n.t("ss.buttons.publish_save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      item.reload
      expect(item.file_ids.length).to eq 1
      attached_file = item.files.first
      # owner item
      expect(attached_file.owner_item_type).to eq item.class.name
      expect(attached_file.owner_item_id).to eq item.id
      # other
      expect(attached_file.user_id).to eq cms_user.id
    end
  end

  context "attach file from cms file" do
    context "with cms addon file" do
      context "when file is attached / saved on the modal dialog" do
        it do
          login_user(user2)

          visit edit_path
          ensure_addon_opened("#addon-cms-agents-addons-file")
          within "form#item-form" do
            within "#addon-cms-agents-addons-file" do
              wait_for_cbox_opened do
                click_on I18n.t("cms.file")
              end
            end
          end

          within_cbox do
            attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
            click_button I18n.t("ss.buttons.save")
            expect(page).to have_css('.file-view', text: 'keyvisual.jpg')

            attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif"
            wait_for_cbox_closed do
              click_button I18n.t("ss.buttons.attach")
            end
          end

          within "form#item-form" do
            within '#selected-files' do
              expect(page).to have_no_css('.name', text: 'keyvisual.jpg')
              expect(page).to have_css('.name', text: 'keyvisual.gif')
            end

            click_on I18n.t("ss.buttons.publish_save")
          end
          wait_for_notice I18n.t('ss.notice.saved')

          item.reload
          expect(item.file_ids.length).to eq 1
          attached_file = item.files.first
          # owner item
          expect(attached_file.owner_item_type).to eq item.class.name
          expect(attached_file.owner_item_id).to eq item.id
          # other
          expect(attached_file.user_id).to eq user2.id
        end
      end

      context "when a file uploaded by other user is attached" do
        let(:name) { unique_id }
        let(:file_name) { "#{unique_id}.jpg" }
        let!(:file) do
          # cms/file is created by cms_user
          tmp_ss_file(
            Cms::File,
            site: site, user: cms_user, model: "cms/file", name: name, basename: file_name,
            contents: "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg",
            group_ids: cms_user.group_ids
          )
        end

        it do
          login_user(user2)
          visit edit_path
          ensure_addon_opened("#addon-cms-agents-addons-file")
          within "form#item-form" do
            within "#addon-cms-agents-addons-file" do
              wait_for_cbox_opened do
                click_on I18n.t("cms.file")
              end
            end
          end

          within_cbox do
            wait_for_cbox_closed do
              click_on name
            end
          end

          within "form#item-form" do
            wait_for_ckeditor_event "item[html]", "afterInsertHtml" do
              within "#addon-cms-agents-addons-file" do
                within ".file-view" do
                  click_on I18n.t("sns.file_attach")
                end
              end
            end
            wait_for_ckeditor_event "item[html]", "afterInsertHtml" do
              within "#addon-cms-agents-addons-file" do
                within ".file-view" do
                  click_on I18n.t("sns.image_paste")
                end
              end
            end
            wait_for_ckeditor_event "item[html]", "afterInsertHtml" do
              within "#addon-cms-agents-addons-file" do
                within ".file-view" do
                  click_on I18n.t("sns.thumb_paste")
                end
              end
            end

            click_on I18n.t("ss.buttons.publish_save")
          end
          wait_for_notice I18n.t('ss.notice.saved')

          item.reload
          expect(item.file_ids.length).to eq 1

          file.reload
          attached_file = item.files.first
          # copy is attached
          expect(attached_file.id).not_to eq file.id
          expect(attached_file.name).to eq name
          expect(attached_file.filename).to eq file.filename
          expect(attached_file.size).to eq file.size
          expect(attached_file.content_type).to eq file.content_type
          # owner item
          expect(attached_file.owner_item_type).to eq item.class.name
          expect(attached_file.owner_item_id).to eq item.id
          # other
          expect(attached_file.user_id).to eq user2.id
        end
      end
    end

    context "with entry form" do
      it "#edit" do
        login_user(user2)

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
          wait_for_cbox_opened do
            click_on I18n.t("cms.file")
          end
        end
        within_cbox do
          attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
          click_button I18n.t("ss.buttons.save")
          expect(page).to have_css('.file-view', text: 'keyvisual.jpg')

          attach_file 'item[in_files][]', "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif"
          wait_for_cbox_closed do
            click_on I18n.t('ss.buttons.attach')
          end
        end
        within "form#item-form" do
          within ".column-value-cms-column-fileupload" do
            expect(page).to have_no_css('.column-value-files', text: 'keyvisual.jpg')
            expect(page).to have_css('.column-value-files', text: 'keyvisual.gif')

            fill_in "item[column_values][][in_wrap][text]", with: ss_japanese_text
          end
        end

        within ".column-value-palette" do
          wait_event_to_fire("ss:columnAdded") do
            click_on column2.name
          end
        end
        within ".column-value-cms-column-free" do
          wait_for_cbox_opened do
            click_on I18n.t("cms.file")
          end
        end
        within_cbox do
          attach_file 'item[in_files][]', "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf"
          click_button I18n.t("ss.buttons.save")
          expect(page).to have_css('.file-view', text: 'shirasagi.pdf')

          attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/logo.png"
          wait_for_cbox_closed do
            click_on I18n.t('ss.buttons.attach')
          end
        end
        within "form#item-form" do
          within ".column-value-cms-column-free" do
            expect(page).to have_no_css('.column-value-files', text: 'shirasagi.pdf')
            expect(page).to have_css('.column-value-files', text: 'logo.png')
          end

          # 定型フォームに動画を添付すると Cms_Form.addSyntaxCheck を呼び出し、アクセシビリティチェックを登録する。
          # Cms_Form.addSyntaxCheck の呼び出しが完了する前に「公開保存」をクリックしてしまうと、
          # アクセシビリティチェックが実行されないので、警告ダイアログが表示されず、テストが失敗してしまう。
          # そこで、苦渋だが  wait_for_ajax で Cms_Form.addSyntaxCheck の呼び出し完了を待機する。
          wait_for_ajax

          click_on I18n.t("ss.buttons.publish_save")
        end
        wait_for_notice I18n.t('ss.notice.saved')

        item.reload

        attached_file1 = item.column_values.where(column_id: column1.id).first.file
        # owner item
        expect(attached_file1.owner_item_type).to eq item.class.name
        expect(attached_file1.owner_item_id).to eq item.id
        # other
        expect(attached_file1.user_id).to eq user2.id

        attached_file2 = item.column_values.where(column_id: column2.id).first.files.first
        # owner item
        expect(attached_file2.owner_item_type).to eq item.class.name
        expect(attached_file2.owner_item_id).to eq item.id
        # other
        expect(attached_file2.user_id).to eq user2.id
      end
    end
  end

  context "attach file which size exceeds the limit" do
    let(:file_path) { "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg" }
    let(:basename) { ::File.basename(file_path) }
    let(:file_size_human) { ::File.size(file_path).to_s(:human_size) }
    let!(:max) { create :ss_max_file_size, in_size_mb: 0 }
    let(:limit_human) { max.size.to_s(:human_size) }

    before do
      login_cms_user
    end

    context "click save" do
      it do
        visit edit_path

        ensure_addon_opened("#addon-cms-agents-addons-file")
        within "#addon-cms-agents-addons-file" do
          wait_for_cbox_opened do
            click_on I18n.t("ss.buttons.upload")
          end
        end

        within_cbox do
          attach_file "item[in_files][]", file_path
          alert = I18n.t("errors.messages.too_large_file", filename: basename, size: file_size_human, limit: limit_human)
          page.accept_alert(/#{::Regexp.escape(alert)}/) do
            click_on I18n.t("ss.buttons.save")
          end

          expect(page).to have_no_css('.file-view', text: basename)
        end
      end
    end

    context "click attach" do
      it do
        visit edit_path

        ensure_addon_opened("#addon-cms-agents-addons-file")
        within "#addon-cms-agents-addons-file" do
          wait_for_cbox_opened do
            click_on I18n.t("ss.buttons.upload")
          end
        end

        within_cbox do
          attach_file "item[in_files][]", file_path
          alert = I18n.t("errors.messages.too_large_file", filename: basename, size: file_size_human, limit: limit_human)
          page.accept_alert(/#{::Regexp.escape(alert)}/) do
            click_on I18n.t("ss.buttons.attach")
          end

          expect(page).to have_no_css('.file-view', text: basename)
        end
      end
    end
  end
end
