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
      let!(:name2) { unique_id }
      let!(:path1) { "#{node.path}/#{name1}" }
      let!(:path2) { "#{node.path}/#{name2}" }
      let!(:rel_path1) { path1.delete_prefix("#{Rails.root}/") }
      let!(:rel_path2) { path2.delete_prefix("#{Rails.root}/") }

      it do
        visit index_path
        index_path = current_path # redirect
        click_link I18n.t('uploader.links.new_directory')

        # create
        expectation = expect do
          within "form" do
            fill_in "item[directory]", with: name1
            click_button I18n.t("ss.buttons.save")
          end
        end
        expectation.to have_enqueued_job.with [{ mkdir: [rel_path1] }]
        expect(page).to have_css(".list-item-title.dir")

        # update
        visit "#{index_path}/#{name1}?do=show"
        click_link I18n.t('ss.links.edit')

        expectation = expect do
          within "form" do
            fill_in "item[filename]", with: "#{node.filename}/#{name2}"
            click_button I18n.t("ss.buttons.save")
          end
        end
        expectation.to have_enqueued_job.with [{ mv: [rel_path1, rel_path2] }]
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

        # delete
        click_link I18n.t('ss.links.back_to_show')
        click_link I18n.t('ss.links.delete')

        expectation = expect do
          within "form" do
            click_button I18n.t("ss.buttons.delete")
          end
        end
        expectation.to have_enqueued_job.with [{ rm: [rel_path2] }]
        expect(page).to have_no_css(".list-item")
      end
    end

    describe "image operations" do
      let!(:file) { "#{::Rails.root}/spec/fixtures/ss/logo.png" }
      let!(:name1) { "logo.png" }
      let!(:name2) { "logo2.png" }
      let!(:path1) { "#{node.path}/#{name1}" }
      let!(:path2) { "#{node.path}/#{name2}" }
      let!(:rel_path1) { path1.delete_prefix("#{Rails.root}/") }
      let!(:rel_path2) { path2.delete_prefix("#{Rails.root}/") }

      it do
        visit index_path
        index_path = current_path # redirect
        click_link I18n.t('ss.links.upload')

        # create
        within "form" do
          attach_file "item[files][]", file
          click_button I18n.t("ss.buttons.save")
        end
        expect(page).to have_css("div.info a.file")

        job_file = Uploader::JobFile.first
        expect(job_file.path).to eq rel_path1
        expect(Fs.exist?(job_file.path)).to be_truthy
        expect(Fs.exist?(job_file.sanitizer_input_path)).to be_truthy

        # update (now sanitaizing..)
        visit "#{index_path}/#{name1}?do=show"
        click_link I18n.t('ss.links.edit')

        expectation = expect do
          within "form" do
            fill_in "item[filename]", with: "#{node.filename}/#{name2}"
            click_button I18n.t("ss.buttons.save")
          end
        end
        expectation.not_to have_enqueued_job
        expect(page).to have_css(".errorExplanation", text: I18n.t('errors.messages.sanitizer_waiting'))

        # sanitize
        restored_file = mock_sanitizer_restore(job_file)
        expect(Fs.exist?(restored_file.path)).to be_truthy
        expect(restored_file.path).to eq rel_path1

        # update
        visit "#{index_path}/#{name1}?do=show"
        click_link I18n.t('ss.links.edit')

        expectation = expect do
          within "form" do
            fill_in "item[filename]", with: "#{node.filename}/#{name2}"
            attach_file "item[file]", file
            click_button I18n.t("ss.buttons.save")
          end
        end
        expectation.to have_enqueued_job.with [{ mv: [rel_path1, rel_path2] }]
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

        # sanitize
        job_file = Uploader::JobFile.first
        restored_file = mock_sanitizer_restore(job_file)
        expect(Fs.exist?(restored_file.path)).to be_truthy
        expect(restored_file.path).to eq rel_path2

        # delete
        click_link I18n.t('ss.links.back_to_show')
        click_link I18n.t('ss.links.delete')

        expectation = expect do
          within "form" do
            click_button I18n.t("ss.buttons.delete")
          end
        end
        expectation.to have_enqueued_job.with [{ rm: [rel_path2] }]
        expect(page).to have_no_css(".list-item")
      end
    end

    describe "text operations" do
      let!(:file) { "#{::Rails.root}/spec/fixtures/uploader/style.scss" }
      let!(:name1) { "style.scss" }
      let!(:name2) { "style2.scss" }
      let!(:path1) { "#{node.path}/#{name1}" }
      let!(:path2) { "#{node.path}/#{name2}" }
      let!(:rel_path1) { path1.delete_prefix("#{Rails.root}/") }
      let!(:rel_path2) { path2.delete_prefix("#{Rails.root}/") }
      let!(:css_path1) { "#{node.path}/style.css" }
      let!(:css_path2) { "#{node.path}/style2.css" }
      let!(:text) { "html { color: blue }" }

      it do
        visit index_path
        index_path = current_path # redirect
        click_link I18n.t('ss.links.upload')

        # create
        within "form" do
          attach_file "item[files][]", file
          click_button I18n.t("ss.buttons.save")
        end
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

        expectation = expect do
          within "form" do
            fill_in "item[filename]", with: "#{node.filename}/#{name2}"
            fill_in_code_mirror "item[text]", with: text
            click_button I18n.t("ss.buttons.save")
          end
        end
        expectation.to have_enqueued_job.with [
          { mv: [rel_path1, rel_path2] },
          { text: [rel_path2, text] }
        ]
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

        # not sanitize
        job_file = Uploader::JobFile.first
        expect(job_file.nil?).to be_truthy
        expect(Fs.exist?(css_path2)).to be_truthy

        # delete
        click_link I18n.t('ss.links.back_to_show')
        click_link I18n.t('ss.links.delete')

        expectation = expect do
          within "form" do
            click_button I18n.t("ss.buttons.delete")
          end
        end
        expectation.to have_enqueued_job.with [{ rm: [rel_path2] }]
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

        # create
        within "form" do
          attach_file "item[files][]", file
          click_button I18n.t("ss.buttons.save")
        end
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
