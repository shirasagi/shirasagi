require 'spec_helper'
require 'fileutils'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:node) do
    create :article_node_page, filename: "docs", name: "article", group_ids: [cms_group.id], st_form_ids: [form.id]
  end
  let!(:item) { create :article_page, cur_node: node, group_ids: [cms_group.id] }
  let!(:edit_path) { edit_article_page_path site.id, node, item }

  let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'entry', group_ids: [cms_group.id]) }
  let!(:column1) { create(:cms_column_free, cur_site: site, cur_form: form, required: "optional", order: 1) }
  let!(:column2) { create(:cms_column_file_upload, cur_site: site, cur_form: form, required: "optional", order: 2) }
  let!(:column3) { create(:cms_column_file_upload, cur_site: site, cur_form: form, file_type: 'image', required: "optional", order: 3) }

  let(:before_csv) { "#{Rails.root}/spec/fixtures/ss/replace_file/before_csv.csv" }
  let(:after_csv) { "#{Rails.root}/spec/fixtures/ss/replace_file/after_csv.csv" }

  let(:before_image) { "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif" }
  let(:after_image) { "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg" }

  context "replace file" do
    context "in cms addon file" do
      before { login_cms_user }

      it "replace" do
        visit edit_path

        # original file upload
        within "form#item-form" do
          within "#addon-cms-agents-addons-file" do
            click_on I18n.t("ss.buttons.upload")
          end
        end

        wait_for_cbox do
          attach_file "item[in_files][]", before_csv
          click_button I18n.t("ss.buttons.attach")
          wait_for_ajax
        end
        click_on I18n.t("ss.buttons.publish_save")
        wait_for_notice I18n.t('ss.notice.saved')

        file = item.class.find(item.id).attached_files.first

        # open replace file dialog
        within "#addon-cms-agents-addons-file" do
          expect(page).to have_css('.file-view', text: file.name)
          click_on I18n.t("ss.buttons.replace_file")
        end

        wait_for_cbox do
          expect(page).to have_css('.tab-name', text: I18n.t("ss.buttons.replace_file"))
          expect(page).to have_css('.tab-name', text: I18n.t("ss.buttons.file_histories"))
        end
        expect(SS::ReplaceTempFile.count).to eq 0

        # upload file and confirmation (cancel)
        within "form#ajax-form" do
          attach_file "item[in_file]", after_csv
          click_button "確認画面へ"
          wait_for_ajax
        end

        temp_file = SS::ReplaceTempFile.first
        expect(SS::ReplaceTempFile.count).to eq 1
        expect(temp_file.filename).not_to eq file.filename
        expect(temp_file.name).not_to eq file.name
        expect(temp_file.state).to eq "closed"

        within "form#ajax-form" do
          expect(page).to have_css('.file-view.before', text: file.humanized_name)
          expect(page).to have_css('.file-view.after', text: temp_file.humanized_name)
          click_on I18n.t("ss.buttons.cancel")
        end

        # upload file and confirmation
        within "form#ajax-form" do
          attach_file "item[in_file]", after_csv
          click_button "確認画面へ"
          wait_for_ajax
        end

        temp_file = SS::ReplaceTempFile.first
        expect(SS::ReplaceTempFile.count).to eq 1
        expect(temp_file.filename).not_to eq file.filename
        expect(temp_file.name).not_to eq file.name
        expect(temp_file.state).to eq "closed"

        # replace file and
        within "form#ajax-form" do
          expect(page).to have_css('.file-view.before', text: file.humanized_name)
          expect(page).to have_css('.file-view.after', text: temp_file.humanized_name)
          fill_in "item[name]", with: "replaced"
          click_button "差し替え保存"
        end
        wait_for_notice "差し替え保存しました。"

        expect(SS::ReplaceTempFile.count).to eq 0

        replaced_page = item.class.find(item.id)
        expect(replaced_page.attached_files.size).to eq 1

        replaced_file = replaced_page.attached_files.first
        expect(replaced_file.filename).to eq "before_csv.csv"
        expect(replaced_file.name).to eq "replaced"
        expect(replaced_file.state).to eq "public"
        expect(::FileUtils.cmp(replaced_file.path, after_csv)).to be true

        # history files
        expect(replaced_file.history_files.size).to eq 1
        history_file = replaced_file.history_files.first

        expect(history_file.filename).to eq "before_csv.csv"
        expect(history_file.name).to eq "before_csv.csv"
        expect(history_file.state).to eq "closed"
        expect(::FileUtils.cmp(history_file.path, before_csv)).to be true
      end
    end

    context "in entry form free column" do
      before { login_cms_user }

      it "replace" do
        visit edit_path

        within 'form#item-form' do
          select form.name, from: 'item[form_id]'
          find('.btn-form-change').click
        end

        within ".column-value-palette" do
          click_on column1.name
        end

        within ".column-value-cms-column-free" do
          click_on I18n.t("ss.buttons.upload")
        end
        wait_for_cbox do
          attach_file "item[in_files][]", before_csv
          click_button I18n.t("ss.buttons.attach")
          wait_for_ajax
        end
        click_on I18n.t("ss.buttons.publish_save")
        wait_for_notice I18n.t('ss.notice.saved')

        file = item.class.find(item.id).attached_files.first

        # open replace file dialog
        within ".column-value-cms-column-free" do
          expect(page).to have_css('.file-view', text: file.name)
          click_on I18n.t("ss.buttons.replace_file")
        end

        wait_for_cbox do
          expect(page).to have_css('.tab-name', text: I18n.t("ss.buttons.replace_file"))
          expect(page).to have_css('.tab-name', text: I18n.t("ss.buttons.file_histories"))
        end
        expect(SS::ReplaceTempFile.count).to eq 0

        # upload file and confirmation (cancel)
        within "form#ajax-form" do
          attach_file "item[in_file]", after_csv
          click_button "確認画面へ"
          wait_for_ajax
        end

        temp_file = SS::ReplaceTempFile.first
        expect(SS::ReplaceTempFile.count).to eq 1
        expect(temp_file.filename).not_to eq file.filename
        expect(temp_file.name).not_to eq file.name
        expect(temp_file.state).to eq "closed"

        within "form#ajax-form" do
          expect(page).to have_css('.file-view.before', text: file.humanized_name)
          expect(page).to have_css('.file-view.after', text: temp_file.humanized_name)
          click_on I18n.t("ss.buttons.cancel")
        end

        # upload file and confirmation
        within "form#ajax-form" do
          attach_file "item[in_file]", after_csv
          click_button "確認画面へ"
          wait_for_ajax
        end

        temp_file = SS::ReplaceTempFile.first
        expect(SS::ReplaceTempFile.count).to eq 1
        expect(temp_file.filename).not_to eq file.filename
        expect(temp_file.name).not_to eq file.name
        expect(temp_file.state).to eq "closed"

        # replace file and
        within "form#ajax-form" do
          expect(page).to have_css('.file-view.before', text: file.humanized_name)
          expect(page).to have_css('.file-view.after', text: temp_file.humanized_name)
          fill_in "item[name]", with: "replaced"
          click_button "差し替え保存"
        end
        wait_for_notice "差し替え保存しました。"

        expect(SS::ReplaceTempFile.count).to eq 0

        replaced_page = item.class.find(item.id)
        expect(replaced_page.attached_files.size).to eq 1

        replaced_file = replaced_page.attached_files.first
        expect(replaced_file.filename).to eq "before_csv.csv"
        expect(replaced_file.name).to eq "replaced"
        expect(replaced_file.state).to eq "public"
        expect(::FileUtils.cmp(replaced_file.path, after_csv)).to be true

        # history files
        expect(replaced_file.history_files.size).to eq 1
        history_file = replaced_file.history_files.first

        expect(history_file.filename).to eq "before_csv.csv"
        expect(history_file.name).to eq "before_csv.csv"
        expect(history_file.state).to eq "closed"
        expect(::FileUtils.cmp(history_file.path, before_csv)).to be true
      end
    end

    context "in entry form upload column" do
      before { login_cms_user }

      it "replace" do
        visit edit_path

        within 'form#item-form' do
          select form.name, from: 'item[form_id]'
          find('.btn-form-change').click
        end

        within ".column-value-palette" do
          click_on column2.name
        end

        within ".column-value-cms-column-fileupload" do
          fill_in "item[column_values][][in_wrap][file_label]", with: "label"
          click_on I18n.t("ss.buttons.upload")
        end
        wait_for_cbox do
          attach_file "item[in_files][]", before_csv
          click_button I18n.t("ss.buttons.attach")
          wait_for_ajax
        end
        click_on I18n.t("ss.buttons.publish_save")
        wait_for_notice I18n.t('ss.notice.saved')

        file = item.class.find(item.id).attached_files.first

        # open replace file dialog
        within ".column-value-cms-column-fileupload" do
          expect(page).to have_css('.file-view', text: file.name)
          click_on I18n.t("ss.buttons.replace_file")
        end

        wait_for_cbox do
          expect(page).to have_css('.tab-name', text: I18n.t("ss.buttons.replace_file"))
          expect(page).to have_css('.tab-name', text: I18n.t("ss.buttons.file_histories"))
        end
        expect(SS::ReplaceTempFile.count).to eq 0

        # upload file and confirmation (cancel)
        within "form#ajax-form" do
          attach_file "item[in_file]", after_csv
          click_button "確認画面へ"
          wait_for_ajax
        end

        temp_file = SS::ReplaceTempFile.first
        expect(SS::ReplaceTempFile.count).to eq 1
        expect(temp_file.filename).not_to eq file.filename
        expect(temp_file.name).not_to eq file.name
        expect(temp_file.state).to eq "closed"

        within "form#ajax-form" do
          expect(page).to have_css('.file-view.before', text: file.humanized_name)
          expect(page).to have_css('.file-view.after', text: temp_file.humanized_name)
          click_on I18n.t("ss.buttons.cancel")
        end

        # upload file and confirmation
        within "form#ajax-form" do
          attach_file "item[in_file]", after_csv
          click_button "確認画面へ"
          wait_for_ajax
        end

        temp_file = SS::ReplaceTempFile.first
        expect(SS::ReplaceTempFile.count).to eq 1
        expect(temp_file.filename).not_to eq file.filename
        expect(temp_file.name).not_to eq file.name
        expect(temp_file.state).to eq "closed"

        # replace file and
        within "form#ajax-form" do
          expect(page).to have_css('.file-view.before', text: file.humanized_name)
          expect(page).to have_css('.file-view.after', text: temp_file.humanized_name)
          fill_in "item[name]", with: "replaced"
          click_button "差し替え保存"
        end
        wait_for_notice "差し替え保存しました。"

        expect(SS::ReplaceTempFile.count).to eq 0

        replaced_page = item.class.find(item.id)
        expect(replaced_page.attached_files.size).to eq 1

        replaced_file = replaced_page.attached_files.first
        expect(replaced_file.filename).to eq "before_csv.csv"
        expect(replaced_file.name).to eq "replaced"
        expect(replaced_file.state).to eq "public"
        expect(::FileUtils.cmp(replaced_file.path, after_csv)).to be true

        # history files
        expect(replaced_file.history_files.size).to eq 1
        history_file = replaced_file.history_files.first

        expect(history_file.filename).to eq "before_csv.csv"
        expect(history_file.name).to eq "before_csv.csv"
        expect(history_file.state).to eq "closed"
        expect(::FileUtils.cmp(history_file.path, before_csv)).to be true
      end
    end

    context "in entry form upload image column" do
      before { login_cms_user }

      it "replace" do
        visit edit_path

        within 'form#item-form' do
          select form.name, from: 'item[form_id]'
          find('.btn-form-change').click
        end

        within ".column-value-palette" do
          click_on column3.name
        end

        within ".column-value-cms-column-fileupload" do
          fill_in "item[column_values][][in_wrap][file_label]", with: "label"
          click_on I18n.t("ss.buttons.upload")
        end
        wait_for_cbox do
          attach_file "item[in_files][]", before_image
          click_button I18n.t("ss.buttons.attach")
          wait_for_ajax
        end
        click_on I18n.t("ss.buttons.publish_save")
        wait_for_notice I18n.t('ss.notice.saved')

        file = item.class.find(item.id).attached_files.first

        # open replace file dialog
        within ".column-value-cms-column-fileupload" do
          expect(page).to have_css('.file-view', text: file.name)
          click_on I18n.t("ss.buttons.replace_file")
        end

        wait_for_cbox do
          expect(page).to have_css('.tab-name', text: I18n.t("ss.buttons.replace_file"))
          expect(page).to have_css('.tab-name', text: I18n.t("ss.buttons.file_histories"))
        end
        expect(SS::ReplaceTempFile.count).to eq 0

        # upload file and confirmation (cancel)
        within "form#ajax-form" do
          attach_file "item[in_file]", after_image
          click_button "確認画面へ"
          wait_for_ajax
        end

        temp_file = SS::ReplaceTempFile.first
        expect(SS::ReplaceTempFile.count).to eq 1
        expect(temp_file.filename).not_to eq file.filename
        expect(temp_file.name).not_to eq file.name
        expect(temp_file.state).to eq "closed"

        within "form#ajax-form" do
          expect(page).to have_css('.file-view.before', text: file.humanized_name)
          expect(page).to have_css('.file-view.after', text: temp_file.humanized_name)
          click_on I18n.t("ss.buttons.cancel")
        end

        # upload file and confirmation
        within "form#ajax-form" do
          attach_file "item[in_file]", after_image
          click_button "確認画面へ"
          wait_for_ajax
        end

        temp_file = SS::ReplaceTempFile.first
        expect(SS::ReplaceTempFile.count).to eq 1
        expect(temp_file.filename).not_to eq file.filename
        expect(temp_file.name).not_to eq file.name
        expect(temp_file.state).to eq "closed"

        # replace file and
        within "form#ajax-form" do
          expect(page).to have_css('.file-view.before', text: file.humanized_name)
          expect(page).to have_css('.file-view.after', text: temp_file.humanized_name)
          fill_in "item[name]", with: "replaced"
          click_button "差し替え保存"
        end
        wait_for_notice "差し替え保存しました。"

        expect(SS::ReplaceTempFile.count).to eq 0

        replaced_page = item.class.find(item.id)
        expect(replaced_page.attached_files.size).to eq 1

        replaced_file = replaced_page.attached_files.first
        expect(replaced_file.filename).to eq "keyvisual.jpg"
        expect(replaced_file.name).to eq "replaced"
        expect(replaced_file.state).to eq "public"
        #expect(::FileUtils.cmp(replaced_file.path, after_image)).to be true

        # history files
        expect(replaced_file.history_files.size).to eq 1
        history_file = replaced_file.history_files.first

        expect(history_file.filename).to eq "keyvisual.gif"
        expect(history_file.name).to eq "keyvisual.gif"
        expect(history_file.state).to eq "closed"
        #expect(::FileUtils.cmp(history_file.path, before_csv)).to be true
      end
    end
  end
end
