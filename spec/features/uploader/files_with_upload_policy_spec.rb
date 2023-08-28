require 'spec_helper'

describe "uploader_files_with_upload_policy", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:node) { create_once :uploader_node_file, name: "uploader" }
  let!(:index_path) { uploader_files_path site.id, node }

  before { login_cms_user }

  context "sanitizer settings" do
    before { upload_policy_before_settings("sanitizer") }

    after { upload_policy_after_settings }

    describe "directory operations" do
      let!(:name1) { unique_id }
      let!(:path1) { "#{node.path}/#{name1}" }
      let!(:rel_path1) { path1.delete_prefix("#{Rails.root}/") }

      it do
        visit index_path
        index_path = current_path # redirect
        click_link I18n.t('uploader.links.new_directory')
        wait_for_js_ready

        # create
        expectation = expect do
          within "form" do
            fill_in "item[directory]", with: name1
            click_button I18n.t("ss.buttons.save")
          end
          wait_for_notice I18n.t("ss.notice.saved")
        end
        expectation.to have_enqueued_job.with [{ mkdir: [rel_path1] }]
        expect(page).to have_css(".list-item-title.dir")

        # update
        visit "#{index_path}/#{name1}?do=show"
        click_link I18n.t('ss.links.edit')
        expect(page).to have_css(".errorExplanation", text: I18n.t('errors.messages.edit_restricted'))

        # delete
        visit "#{index_path}/#{name1}?do=show"
        click_link I18n.t('ss.links.delete')

        expectation = expect do
          within "form" do
            click_button I18n.t("ss.buttons.delete")
          end
        end
        expectation.to have_enqueued_job.with [{ rm: [rel_path1] }]
        expect(page).to have_no_css(".list-item")
      end
    end

    describe "image operations" do
      let!(:file) { "#{::Rails.root}/spec/fixtures/ss/logo.png" }
      let!(:name1) { "logo.png" }
      let!(:path1) { "#{node.path}/#{name1}" }
      let!(:rel_path1) { path1.delete_prefix("#{Rails.root}/") }

      it do
        visit index_path
        index_path = current_path # redirect
        click_link I18n.t('ss.links.upload')
        wait_for_js_ready

        # create
        within "form" do
          attach_file "item[files][]", file
          expect(page).to have_css(".js-uploader-alert-message", text: "ok")
          click_button I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")
        expect(page).to have_css("div.info a.file")

        job_file = Uploader::JobFile.first
        expect(job_file.path).to eq rel_path1
        expect(Fs.exist?(job_file.path)).to be_truthy
        expect(Fs.exist?(job_file.sanitizer_input_path)).to be_truthy

        # update
        visit "#{index_path}/#{name1}?do=show"
        click_link I18n.t('ss.links.edit')
        expect(page).to have_css(".errorExplanation", text: I18n.t('errors.messages.edit_restricted'))

        # delete (now sanitaizing..)
        visit "#{index_path}/#{name1}?do=show"
        click_link I18n.t('ss.links.delete')
        within "form" do
          click_button I18n.t("ss.buttons.delete")
        end
        expect(page).to have_css(".errorExplanation", text: I18n.t('errors.messages.sanitizer_waiting'))

        # sanitize
        restored_file = mock_sanitizer_restore(job_file)
        expect(Fs.exist?(restored_file.path)).to be_truthy
        expect(restored_file.path).to eq rel_path1

        # delete
        visit "#{index_path}/#{name1}?do=show"
        click_link I18n.t('ss.links.delete')
        expectation = expect do
          within "form" do
            click_button I18n.t("ss.buttons.delete")
          end
        end
        expectation.to have_enqueued_job.with [{ rm: [rel_path1] }]
        expect(page).to have_no_css(".list-item")
      end
    end

    describe "text operations" do
      let!(:file) { "#{::Rails.root}/spec/fixtures/uploader/style.scss" }
      let!(:name1) { "style.scss" }
      let!(:path1) { "#{node.path}/#{name1}" }
      let!(:rel_path1) { path1.delete_prefix("#{Rails.root}/") }
      let!(:css_path1) { "#{node.path}/style.css" }

      it do
        visit index_path
        index_path = current_path # redirect
        click_link I18n.t('ss.links.upload')
        wait_for_js_ready

        # create
        within "form" do
          attach_file "item[files][]", file
          expect(page).to have_css(".js-uploader-alert-message", text: "ok")
          click_button I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")
        expect(page).to have_css("div.info a.file")

        job_file = Uploader::JobFile.first
        expect(job_file.path).to eq rel_path1
        expect(Fs.exist?(job_file.path)).to be_truthy
        expect(Fs.exist?(job_file.sanitizer_input_path)).to be_truthy
        expect(Fs.exist?(css_path1)).to be_truthy
        FileUtils.rm(css_path1)

        # sanitize
        restored_file = mock_sanitizer_restore(job_file)
        expect(Fs.exist?(restored_file.path)).to be_truthy
        expect(restored_file.path).to eq rel_path1

        # update
        visit "#{index_path}/#{name1}?do=show"
        click_link I18n.t('ss.links.edit')
        expect(page).to have_css(".errorExplanation", text: I18n.t('errors.messages.edit_restricted'))

        # delete
        visit "#{index_path}/#{name1}?do=show"
        click_link I18n.t('ss.links.delete')

        expectation = expect do
          within "form" do
            click_button I18n.t("ss.buttons.delete")
          end
        end
        expectation.to have_enqueued_job.with [{ rm: [rel_path1] }]
      end
    end

    describe "error operations" do
      let!(:file) { "#{::Rails.root}/spec/fixtures/ss/logo.png" }
      let!(:name1) { "logo.png" }
      let!(:path1) { "#{node.path}/#{name1}" }
      let!(:rel_path1) { path1.delete_prefix("#{Rails.root}/") }
      let!(:error_file) { "#{::Rails.root}/spec/fixtures/ss/file/ss_file_1_1635597955_1000_pdfEncryptReport.txt" }
      let!(:output_path) { "#{SS.config.ss.sanitizer_output}/ss_uploader_1_1635597955_1000_pdfEncryptReport.txt" }
      let!(:error_filename) { "logo.png_sanitize_error.txt" }

      it do
        visit index_path
        index_path = current_path # redirect
        click_link I18n.t('ss.links.upload')
        wait_for_js_ready

        # create
        within "form" do
          attach_file "item[files][]", file
          expect(page).to have_css(".js-uploader-alert-message", text: "ok")
          click_button I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")
        expect(page).to have_css("div.info a.file")

        job_file = Uploader::JobFile.first
        expect(job_file.path).to eq rel_path1

        # sanitize
        Fs.cp error_file, output_path
        restored_file = mock_sanitizer_restore(job_file, output_path)
        expect(restored_file).not_to eq nil

        # index
        visit index_path
        within ".list-items" do
          expect(page).to have_selector('.list-item', count: 2)
          expect(page).to have_css(".list-item", text: error_filename)
          expect(page).to have_css('.sanitizer-status.sanitizer-error')
        end

        # show
        visit "#{index_path}/#{error_filename}?do=show"
        within "#addon-basic" do
          expect(page).to have_css('.sanitizer-status.sanitizer-error')
        end
      end
    end
  end
end
