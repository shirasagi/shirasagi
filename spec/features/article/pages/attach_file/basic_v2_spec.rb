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
  let!(:role) { create :cms_role, name: "role", permissions: permissions, cur_site: site }
  let(:user2) { create :cms_user, uid: unique_id, name: unique_id, group_ids: [cms_group.id], cms_role_ids: [role.id] }

  before do
    @save_file_upload_dialog = SS.file_upload_dialog
    SS.file_upload_dialog = :v2
  end

  after do
    SS.file_upload_dialog = @save_file_upload_dialog
  end

  context "attach file from upload" do
    before { login_cms_user }

    context "with cms addon file as editing file name" do
      it do
        visit edit_path
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames
        ensure_addon_opened("#addon-cms-agents-addons-file")
        within "form#item-form" do
          within "#addon-cms-agents-addons-file" do
            wait_for_cbox_opened do
              click_on I18n.t("ss.buttons.upload")
            end
          end
        end

        within_dialog do
          wait_event_to_fire "ss:tempFile:addedWaitingList" do
            attach_file "in_files", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
          end
          within first("form .index tbody tr") do
            fill_in "item[files][][name]", with: "modify.jpg"
          end
          wait_for_cbox_closed do
            within "form" do
              click_on I18n.t("ss.buttons.upload")
            end
          end
        end

        within "form#item-form" do
          within "#addon-cms-agents-addons-file" do
            within '.cms-addon-file-selected-files' do
              expect(page).to have_css('.name', text: 'modify.jpg')
            end
          end
        end

        expect(Cms::TempFile.all.count).to eq 1
        Cms::TempFile.all.first.tap do |file|
          expect(file.site_id).to eq site.id
          expect(file.user_id).to eq cms_user.id
          expect(file.node_id).to eq node.id
          expect(file.model).to eq "ss/temp_file"
          expect(file.name).to eq "modify.jpg"
          expect(file.filename).to eq "modify.jpg"
          expect(file.content_type).to eq "image/jpeg"
          expect(file.size).to be_within(1_000).of(File.size("#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"))
        end
      end
    end

    context "with entry form as editing file name" do
      it do
        visit edit_path
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        within 'form#item-form' do
          wait_for_event_fired("ss:formActivated") do
            page.accept_confirm(I18n.t("cms.confirm.change_form")) do
              select form.name, from: 'in_form_id'
            end
          end
        end

        within ".column-value-palette" do
          wait_for_event_fired("ss:columnAdded") do
            click_on column1.name
          end
        end
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames
        within ".column-value-cms-column-fileupload" do
          wait_for_cbox_opened do
            click_on I18n.t("ss.buttons.upload")
          end
        end
        within_dialog do
          wait_event_to_fire "ss:tempFile:addedWaitingList" do
            attach_file "in_files", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif"
          end
          within first("form .index tbody tr") do
            fill_in "item[files][][name]", with: "modify-1.gif"
          end
          wait_for_cbox_closed do
            within "form" do
              click_on I18n.t("ss.buttons.upload")
            end
          end
        end
        within "form#item-form" do
          within ".column-value-cms-column-fileupload" do
            expect(page).to have_css('.file-view', text: 'modify-1.gif')

            fill_in "item[column_values][][in_wrap][text]", with: ss_japanese_text
          end
        end

        within ".column-value-palette" do
          wait_for_event_fired("ss:columnAdded") do
            click_on column2.name
          end
        end
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames
        within "form#item-form" do
          ss_upload_file "#{Rails.root}/spec/fixtures/ss/logo.png", addon: ".column-value-cms-column-free"
          within ".column-value-cms-column-free" do
            expect(page).to have_css('.file-view', text: 'logo.png')
          end

          # 定型フォームに動画を添付すると Cms_Form.addSyntaxCheck を呼び出し、アクセシビリティチェックを登録する。
          # Cms_Form.addSyntaxCheck の呼び出しが完了する前に「公開保存」をクリックしてしまうと、
          # アクセシビリティチェックが実行されないので、警告ダイアログが表示されず、テストが失敗してしまう。
          # そこで、苦渋だが  wait_for_js_ready で Cms_Form.addSyntaxCheck の呼び出し完了を待機する。
          wait_for_js_ready

          click_on I18n.t("ss.buttons.publish_save")
        end
        wait_for_notice I18n.t('ss.notice.saved')
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        item.reload

        attached_file1 = item.column_values.where(column_id: column1.id).first.file
        # owner item
        expect(attached_file1.owner_item_type).to eq item.class.name
        expect(attached_file1.owner_item_id).to eq item.id
        # other
        expect(attached_file1.user_id).to eq cms_user.id

        attached_file2 = item.column_values.where(column_id: column2.id).first.files.first
        # owner item
        expect(attached_file2.owner_item_type).to eq item.class.name
        expect(attached_file2.owner_item_id).to eq item.id
        # other
        expect(attached_file2.user_id).to eq cms_user.id
      end
    end
  end

  context "attach file from user file" do
    let!(:file) do
      tmp_ss_file(
        SS::UserFile, model: SS::UserFile::FILE_MODEL, user: cms_user, basename: "logo-#{unique_id}.png",
        contents: "#{Rails.root}/spec/fixtures/ss/logo.png"
      )
    end

    before { login_cms_user }

    context "with cms addon file" do
      it do
        visit edit_path
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames
        ensure_addon_opened("#addon-cms-agents-addons-file")
        within "form#item-form" do
          within "#addon-cms-agents-addons-file" do
            wait_for_cbox_opened do
              click_on I18n.t("ss.buttons.select_from_list")
            end
          end
        end

        within_dialog do
          wait_for_event_fired "turbo:frame-load" do
            within "form.search" do
              check I18n.t("sns.user_file")
            end
          end
        end
        within_dialog do
          expect(page).to have_css('.file-view', text: file.name)
          wait_for_cbox_closed do
            click_on file.name
          end
        end
        within "form#item-form" do
          within '.cms-addon-file-selected-files' do
            expect(page).to have_css('.name', text: file.name)
          end
        end
        # CMS 共有ファイルや SNS ユーザーファイルを添付した場合、複製が作成されているはず
        expect(SS::File.ne(id: file.id).count).to eq 1
        Cms::TempFile.ne(id: file.id).first.tap do |intermediate_file|
          expect(intermediate_file.id).not_to eq file.id
          expect(intermediate_file.name).to eq file.name
          expect(intermediate_file.filename).to eq file.filename
          expect(intermediate_file.content_type).to eq file.content_type
          expect(intermediate_file.size).to eq file.size
          expect(intermediate_file.model).to eq "ss/temp_file"
          expect(intermediate_file.site_id).to eq site.id
          expect(intermediate_file.user_id).to eq cms_user.id
          expect(intermediate_file.node_id).to eq node.id
          expect(intermediate_file.owner_item_id).to be_blank
          expect(intermediate_file.owner_item_type).to be_blank
        end
        within "form#item-form" do
          click_on I18n.t("ss.buttons.publish_save")
        end
        wait_for_notice I18n.t('ss.notice.saved')

        item.reload
        expect(item.file_ids.length).to eq 1
        attached_file = item.files.first
        # copy is attached
        expect(attached_file.id).not_to eq file.id
        expect(attached_file.name).to eq file.name
        expect(attached_file.filename).to eq file.filename
        expect(attached_file.size).to eq file.size
        expect(attached_file.content_type).to eq file.content_type
        # owner item
        expect(attached_file.owner_item_type).to eq item.class.name
        expect(attached_file.owner_item_id).to eq item.id
        # other
        expect(attached_file.user_id).to eq cms_user.id
        expect(attached_file.model).to eq "article/page"

        # 記事ページに添付後もSNSユーザーファイルはそのまま残っているはず
        SS::UserFile.find(file.id).tap do |after_attached|
          expect(after_attached.model).to eq "ss/user_file"
          expect(after_attached.owner_item_id).to be_blank
          expect(after_attached.owner_item_type).to be_blank
        end
      end
    end

    context "with cms/upload_file in entry form" do
      it do
        visit edit_path
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        within 'form#item-form' do
          wait_for_event_fired("ss:formActivated") do
            page.accept_confirm(I18n.t("cms.confirm.change_form")) do
              select form.name, from: 'in_form_id'
            end
          end
        end

        within ".column-value-palette" do
          wait_for_event_fired("ss:columnAdded") do
            click_on column1.name
          end
        end
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames
        within ".column-value-cms-column-fileupload" do
          wait_for_cbox_opened do
            click_on I18n.t("ss.buttons.select_from_list")
          end
        end
        within_dialog do
          wait_for_event_fired "turbo:frame-load" do
            within "form.search" do
              check I18n.t("sns.user_file")
            end
          end
        end
        within_dialog do
          expect(page).to have_css('.file-view', text: file.name)
          wait_for_cbox_closed do
            click_on file.name
          end
        end
        within "form#item-form" do
          within ".column-value-cms-column-fileupload" do
            expect(page).to have_css('.file-view', text: file.name)

            fill_in "item[column_values][][in_wrap][text]", with: ss_japanese_text
          end
        end
        # CMS 共有ファイルや SNS ユーザーファイルを添付した場合、複製が作成されているはず
        expect(SS::File.ne(id: file.id).count).to eq 1
        Cms::TempFile.ne(id: file.id).first.tap do |intermediate_file|
          expect(intermediate_file.id).not_to eq file.id
          expect(intermediate_file.name).to eq file.name
          expect(intermediate_file.filename).to eq file.filename
          expect(intermediate_file.content_type).to eq file.content_type
          expect(intermediate_file.size).to eq file.size
          expect(intermediate_file.model).to eq "ss/temp_file"
          expect(intermediate_file.site_id).to eq site.id
          expect(intermediate_file.user_id).to eq cms_user.id
          expect(intermediate_file.node_id).to eq node.id
          expect(intermediate_file.owner_item_id).to be_blank
          expect(intermediate_file.owner_item_type).to be_blank
        end
        within "form#item-form" do
          # 定型フォームに動画を添付すると Cms_Form.addSyntaxCheck を呼び出し、アクセシビリティチェックを登録する。
          # Cms_Form.addSyntaxCheck の呼び出しが完了する前に「公開保存」をクリックしてしまうと、
          # アクセシビリティチェックが実行されないので、警告ダイアログが表示されず、テストが失敗してしまう。
          # そこで、苦渋だが  wait_for_js_ready で Cms_Form.addSyntaxCheck の呼び出し完了を待機する。
          wait_for_js_ready

          click_on I18n.t("ss.buttons.publish_save")
        end
        wait_for_notice I18n.t('ss.notice.saved')
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        item.reload

        attached_file = item.column_values.where(column_id: column1.id).first.file
        # basic
        expect(attached_file.id).not_to eq file.id
        expect(attached_file.name).to eq file.name
        expect(attached_file.filename).to eq file.filename
        expect(attached_file.size).to eq file.size
        expect(attached_file.content_type).to eq file.content_type
        # owner item
        expect(attached_file.owner_item_type).to eq item.class.name
        expect(attached_file.owner_item_id).to eq item.id
        # other
        expect(attached_file.user_id).to eq cms_user.id
        expect(attached_file.model).to eq "Article::Page"

        # 記事ページに添付後もSNSユーザーファイルはそのまま残っているはず
        SS::UserFile.find(file.id).tap do |after_attached|
          expect(after_attached.model).to eq "ss/user_file"
          expect(after_attached.owner_item_id).to be_blank
          expect(after_attached.owner_item_type).to be_blank
        end
      end
    end

    context "with cms/free in entry form" do
      it "#edit" do
        visit edit_path
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        within 'form#item-form' do
          wait_for_event_fired("ss:formActivated") do
            page.accept_confirm(I18n.t("cms.confirm.change_form")) do
              select form.name, from: 'in_form_id'
            end
          end
        end

        within ".column-value-palette" do
          wait_for_event_fired("ss:columnAdded") do
            click_on column2.name
          end
        end
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames
        within ".column-value-cms-column-free" do
          wait_for_cbox_opened do
            click_on I18n.t("ss.buttons.select_from_list")
          end
        end
        within_dialog do
          wait_for_event_fired "turbo:frame-load" do
            within "form.search" do
              check I18n.t("sns.user_file")
            end
          end
        end
        within_dialog do
          expect(page).to have_css('.file-view', text: file.name)
          wait_for_cbox_closed do
            click_on file.name
          end
        end
        within "form#item-form" do
          within ".column-value-cms-column-free" do
            expect(page).to have_css('.file-view', text: file.name)
          end
        end
        # CMS 共有ファイルや SNS ユーザーファイルを添付した場合、複製が作成されているはず
        expect(SS::File.ne(id: file.id).count).to eq 1
        Cms::TempFile.ne(id: file.id).first.tap do |intermediate_file|
          expect(intermediate_file.id).not_to eq file.id
          expect(intermediate_file.name).to eq file.name
          expect(intermediate_file.filename).to eq file.filename
          expect(intermediate_file.content_type).to eq file.content_type
          expect(intermediate_file.size).to eq file.size
          expect(intermediate_file.model).to eq "ss/temp_file"
          expect(intermediate_file.site_id).to eq site.id
          expect(intermediate_file.user_id).to eq cms_user.id
          expect(intermediate_file.node_id).to eq node.id
          expect(intermediate_file.owner_item_id).to be_blank
          expect(intermediate_file.owner_item_type).to be_blank
        end
        within "form#item-form" do
          # 定型フォームに動画を添付すると Cms_Form.addSyntaxCheck を呼び出し、アクセシビリティチェックを登録する。
          # Cms_Form.addSyntaxCheck の呼び出しが完了する前に「公開保存」をクリックしてしまうと、
          # アクセシビリティチェックが実行されないので、警告ダイアログが表示されず、テストが失敗してしまう。
          # そこで、苦渋だが  wait_for_js_ready で Cms_Form.addSyntaxCheck の呼び出し完了を待機する。
          wait_for_js_ready

          click_on I18n.t("ss.buttons.publish_save")
        end
        wait_for_notice I18n.t('ss.notice.saved')
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        item.reload

        attached_file = item.column_values.where(column_id: column2.id).first.files.first
        # basic
        expect(attached_file.id).not_to eq file.id
        expect(attached_file.name).to eq file.name
        expect(attached_file.filename).to eq file.filename
        expect(attached_file.size).to eq file.size
        expect(attached_file.content_type).to eq file.content_type
        # owner item
        expect(attached_file.owner_item_type).to eq item.class.name
        expect(attached_file.owner_item_id).to eq item.id
        # other
        expect(attached_file.user_id).to eq cms_user.id
        expect(attached_file.model).to eq "article/page"

        # 記事ページに添付後もSNSユーザーファイルはそのまま残っているはず
        SS::UserFile.find(file.id).tap do |after_attached|
          expect(after_attached.model).to eq "ss/user_file"
          expect(after_attached.owner_item_id).to be_blank
          expect(after_attached.owner_item_type).to be_blank
        end
      end
    end
  end

  context "attach file from cms file" do
    let!(:file) do
      tmp_ss_file(
        Cms::File, model: Cms::File::FILE_MODEL, user: cms_user, site: site,
        name: "#{unique_id}.png", basename: "logo-#{unique_id}.png",
        contents: "#{Rails.root}/spec/fixtures/ss/logo.png", group_ids: cms_user.group_ids
      )
    end

    context "with cms addon file" do
      context "when file is attached / saved on the modal dialog" do
        it do
          login_user(cms_user, to: edit_path)
          wait_for_all_ckeditors_ready
          wait_for_all_turbo_frames
          ensure_addon_opened("#addon-cms-agents-addons-file")
          within "form#item-form" do
            within "#addon-cms-agents-addons-file" do
              wait_for_cbox_opened do
                click_on I18n.t("ss.buttons.select_from_list")
              end
            end
          end

          within_dialog do
            wait_for_event_fired "turbo:frame-load" do
              within "form.search" do
                check I18n.t("cms.file")
              end
            end

            expect(page).to have_css('.file-view', text: file.name)
            wait_for_cbox_closed do
              click_on file.name
            end
          end

          within "form#item-form" do
            within '.cms-addon-file-selected-files' do
              expect(page).to have_css('.name', text: file.name)
            end
          end
          # CMS 共有ファイルや SNS ユーザーファイルを添付した場合、複製が作成されているはず
          expect(SS::File.ne(id: file.id).count).to eq 1
          Cms::TempFile.ne(id: file.id).first.tap do |intermediate_file|
            expect(intermediate_file.id).not_to eq file.id
            expect(intermediate_file.name).to eq file.name
            expect(intermediate_file.filename).to eq file.filename
            expect(intermediate_file.content_type).to eq file.content_type
            expect(intermediate_file.size).to eq file.size
            expect(intermediate_file.model).to eq "ss/temp_file"
            expect(intermediate_file.site_id).to eq site.id
            expect(intermediate_file.user_id).to eq cms_user.id
            expect(intermediate_file.node_id).to eq node.id
            expect(intermediate_file.owner_item_id).to be_blank
            expect(intermediate_file.owner_item_type).to be_blank
          end
          within "form#item-form" do
            click_on I18n.t("ss.buttons.publish_save")
          end
          wait_for_notice I18n.t('ss.notice.saved')

          item.reload
          expect(item.file_ids.length).to eq 1
          attached_file = item.files.first
          # copy is attached
          expect(attached_file.id).not_to eq file.id
          expect(attached_file.name).to eq file.name
          expect(attached_file.filename).to eq file.filename
          expect(attached_file.size).to eq file.size
          expect(attached_file.content_type).to eq file.content_type
          # owner item
          expect(attached_file.owner_item_type).to eq item.class.name
          expect(attached_file.owner_item_id).to eq item.id
          # other
          expect(attached_file.user_id).to eq cms_user.id
          expect(attached_file.model).to eq "article/page"

          # 記事ページに添付後もCMS共有ファイルはそのまま残っているはず
          Cms::File.find(file.id).tap do |after_attached|
            expect(after_attached.model).to eq "cms/file"
            expect(after_attached.owner_item_id).to be_blank
            expect(after_attached.owner_item_type).to be_blank
          end
        end
      end

      context "when a file uploaded by other user is attached" do
        it do
          login_user(user2, to: edit_path)
          wait_for_all_ckeditors_ready
          wait_for_all_turbo_frames
          ensure_addon_opened("#addon-cms-agents-addons-file")
          within "form#item-form" do
            within "#addon-cms-agents-addons-file" do
              wait_for_cbox_opened do
                click_on I18n.t("ss.buttons.select_from_list")
              end
            end
          end

          within_dialog do
            wait_for_event_fired "turbo:frame-load" do
              within "form.search" do
                check I18n.t("cms.file")
              end
            end

            wait_for_cbox_closed do
              click_on file.name
            end
          end
          within "form#item-form" do
            within '.cms-addon-file-selected-files' do
              expect(page).to have_css('.name', text: file.name)
            end
          end

          # CMS 共有ファイルや SNS ユーザーファイルを添付した場合、複製が作成されているはず
          expect(SS::File.ne(id: file.id).count).to eq 1
          Cms::TempFile.ne(id: file.id).first.tap do |intermediate_file|
            expect(intermediate_file.id).not_to eq file.id
            expect(intermediate_file.name).to eq file.name
            expect(intermediate_file.filename).to eq file.filename
            expect(intermediate_file.content_type).to eq file.content_type
            expect(intermediate_file.size).to eq file.size
            expect(intermediate_file.model).to eq "ss/temp_file"
            expect(intermediate_file.site_id).to eq site.id
            expect(intermediate_file.user_id).to eq user2.id
            expect(intermediate_file.node_id).to eq node.id
            expect(intermediate_file.owner_item_id).to be_blank
            expect(intermediate_file.owner_item_type).to be_blank
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
          expect(attached_file.name).to eq file.name
          expect(attached_file.filename).to eq file.filename
          expect(attached_file.size).to eq file.size
          expect(attached_file.content_type).to eq file.content_type
          # owner item
          expect(attached_file.owner_item_type).to eq item.class.name
          expect(attached_file.owner_item_id).to eq item.id
          # other
          expect(attached_file.user_id).to eq user2.id
          expect(attached_file.model).to eq "article/page"

          # 記事ページに添付後もCMS共有ファイルはそのまま残っているはず
          Cms::File.find(file.id).tap do |after_attached|
            expect(after_attached.model).to eq "cms/file"
            expect(after_attached.owner_item_id).to be_blank
            expect(after_attached.owner_item_type).to be_blank
          end
        end
      end
    end

    context "with cms/upload_file in entry form" do
      it "#edit" do
        login_user(cms_user, to: edit_path)
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        within 'form#item-form' do
          wait_for_event_fired("ss:formActivated") do
            page.accept_confirm(I18n.t("cms.confirm.change_form")) do
              select form.name, from: 'in_form_id'
            end
          end
        end

        within ".column-value-palette" do
          wait_for_event_fired("ss:columnAdded") do
            click_on column1.name
          end
        end
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames
        within ".column-value-cms-column-fileupload" do
          wait_for_cbox_opened do
            click_on I18n.t("ss.buttons.select_from_list")
          end
        end
        within_dialog do
          wait_for_event_fired "turbo:frame-load" do
            within "form.search" do
              check I18n.t("cms.file")
            end
          end
        end
        within_dialog do
          expect(page).to have_css('.file-view', text: file.name)
          wait_for_cbox_closed do
            click_on file.name
          end
        end
        within "form#item-form" do
          within ".column-value-cms-column-fileupload" do
            expect(page).to have_css('.file-view', text: file.name)

            fill_in "item[column_values][][in_wrap][text]", with: ss_japanese_text
          end
        end
        # CMS 共有ファイルや SNS ユーザーファイルを添付した場合、複製が作成されているはず
        expect(SS::File.ne(id: file.id).count).to eq 1
        Cms::TempFile.ne(id: file.id).first.tap do |intermediate_file|
          expect(intermediate_file.id).not_to eq file.id
          expect(intermediate_file.name).to eq file.name
          expect(intermediate_file.filename).to eq file.filename
          expect(intermediate_file.content_type).to eq file.content_type
          expect(intermediate_file.size).to eq file.size
          expect(intermediate_file.model).to eq "ss/temp_file"
          expect(intermediate_file.site_id).to eq site.id
          expect(intermediate_file.user_id).to eq cms_user.id
          expect(intermediate_file.node_id).to eq node.id
          expect(intermediate_file.owner_item_id).to be_blank
          expect(intermediate_file.owner_item_type).to be_blank
        end
        within "form#item-form" do
          # 定型フォームに動画を添付すると Cms_Form.addSyntaxCheck を呼び出し、アクセシビリティチェックを登録する。
          # Cms_Form.addSyntaxCheck の呼び出しが完了する前に「公開保存」をクリックしてしまうと、
          # アクセシビリティチェックが実行されないので、警告ダイアログが表示されず、テストが失敗してしまう。
          # そこで、苦渋だが  wait_for_js_ready で Cms_Form.addSyntaxCheck の呼び出し完了を待機する。
          wait_for_js_ready

          click_on I18n.t("ss.buttons.publish_save")
        end
        wait_for_notice I18n.t('ss.notice.saved')
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        item.reload

        attached_file = item.column_values.where(column_id: column1.id).first.file
        # basic
        expect(attached_file.id).not_to eq file.id
        expect(attached_file.name).to eq file.name
        expect(attached_file.filename).to eq file.filename
        expect(attached_file.size).to eq file.size
        expect(attached_file.content_type).to eq file.content_type
        # owner item
        expect(attached_file.owner_item_type).to eq item.class.name
        expect(attached_file.owner_item_id).to eq item.id
        # other
        expect(attached_file.user_id).to eq cms_user.id
        expect(attached_file.model).to eq "Article::Page"

        # 記事ページに添付後もCMS共有ファイルはそのまま残っているはず
        Cms::File.find(file.id).tap do |after_attached|
          expect(after_attached.model).to eq "cms/file"
          expect(after_attached.owner_item_id).to be_blank
          expect(after_attached.owner_item_type).to be_blank
        end
      end
    end

    context "with cms/free in entry form" do
      it "#edit" do
        login_user(cms_user, to: edit_path)
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        within 'form#item-form' do
          wait_for_event_fired("ss:formActivated") do
            page.accept_confirm(I18n.t("cms.confirm.change_form")) do
              select form.name, from: 'in_form_id'
            end
          end
        end

        within ".column-value-palette" do
          wait_for_event_fired("ss:columnAdded") do
            click_on column2.name
          end
        end
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames
        within ".column-value-cms-column-free" do
          wait_for_cbox_opened do
            click_on I18n.t("ss.buttons.select_from_list")
          end
        end
        within_dialog do
          wait_for_event_fired "turbo:frame-load" do
            within "form.search" do
              check I18n.t("cms.file")
            end
          end
        end
        within_dialog do
          expect(page).to have_css('.file-view', text: file.name)
          wait_for_cbox_closed do
            click_on file.name
          end
        end
        within "form#item-form" do
          within ".column-value-cms-column-free" do
            expect(page).to have_css('.file-view', text: file.name)
          end
        end
        # CMS 共有ファイルや SNS ユーザーファイルを添付した場合、複製が作成されているはず
        expect(SS::File.ne(id: file.id).count).to eq 1
        Cms::TempFile.ne(id: file.id).first.tap do |intermediate_file|
          expect(intermediate_file.id).not_to eq file.id
          expect(intermediate_file.name).to eq file.name
          expect(intermediate_file.filename).to eq file.filename
          expect(intermediate_file.content_type).to eq file.content_type
          expect(intermediate_file.size).to eq file.size
          expect(intermediate_file.model).to eq "ss/temp_file"
          expect(intermediate_file.site_id).to eq site.id
          expect(intermediate_file.user_id).to eq cms_user.id
          expect(intermediate_file.node_id).to eq node.id
          expect(intermediate_file.owner_item_id).to be_blank
          expect(intermediate_file.owner_item_type).to be_blank
        end
        within "form#item-form" do
          # 定型フォームに動画を添付すると Cms_Form.addSyntaxCheck を呼び出し、アクセシビリティチェックを登録する。
          # Cms_Form.addSyntaxCheck の呼び出しが完了する前に「公開保存」をクリックしてしまうと、
          # アクセシビリティチェックが実行されないので、警告ダイアログが表示されず、テストが失敗してしまう。
          # そこで、苦渋だが  wait_for_js_ready で Cms_Form.addSyntaxCheck の呼び出し完了を待機する。
          wait_for_js_ready

          click_on I18n.t("ss.buttons.publish_save")
        end
        wait_for_notice I18n.t('ss.notice.saved')
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        item.reload

        attached_file = item.column_values.where(column_id: column2.id).first.files.first
        # basic
        expect(attached_file.id).not_to eq file.id
        expect(attached_file.name).to eq file.name
        expect(attached_file.filename).to eq file.filename
        expect(attached_file.size).to eq file.size
        expect(attached_file.content_type).to eq file.content_type
        # owner item
        expect(attached_file.owner_item_type).to eq item.class.name
        expect(attached_file.owner_item_id).to eq item.id
        # other
        expect(attached_file.user_id).to eq cms_user.id
        expect(attached_file.model).to eq "article/page"

        # 記事ページに添付後もCMS共有ファイルはそのまま残っているはず
        Cms::File.find(file.id).tap do |after_attached|
          expect(after_attached.model).to eq "cms/file"
          expect(after_attached.owner_item_id).to be_blank
          expect(after_attached.owner_item_type).to be_blank
        end
      end
    end
  end

  context "attach file which size exceeds the limit" do
    let(:file_path) { "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg" }
    let(:basename) { ::File.basename(file_path) }
    let(:file_size_human) { ::File.size(file_path).to_fs(:human_size) }
    let!(:max) { create :ss_max_file_size, in_size_mb: 0 }
    let(:limit_human) { max.size.to_fs(:human_size) }

    before do
      login_cms_user
    end

    it do
      visit edit_path
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      ensure_addon_opened("#addon-cms-agents-addons-file")
      within "#addon-cms-agents-addons-file" do
        wait_for_cbox_opened do
          click_on I18n.t("ss.buttons.upload")
        end
      end

      within_dialog do
        wait_event_to_fire "ss:tempFile:addedWaitingList" do
          attach_file "in_files", file_path
        end
      end
      within_dialog do
        within first(".index tbody tr") do
          alert = I18n.t("errors.messages.too_large_file", filename: basename, size: file_size_human, limit: limit_human)
          expect(page).to have_css(".errors", text: alert)
        end
      end
      page.execute_script('$(".errors").html("");')

      # エラーが表示されているが、それでもアップロードしてみる。
      within_dialog do
        within "form" do
          click_on I18n.t("ss.buttons.upload")
        end
      end
      within_dialog do
        within first(".index tbody tr") do
          alert = I18n.t("errors.messages.too_large_file", filename: basename, size: file_size_human, limit: limit_human)
          expect(page).to have_css(".errors", text: alert)
        end
      end
    end
  end
end
