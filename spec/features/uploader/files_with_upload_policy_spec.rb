require 'spec_helper'

describe "uploader_files_with_upload_policy", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create_once :uploader_node_file, name: "uploader" }
  let(:index_path) { uploader_files_path site.id, node }

  before { login_cms_user }
  before { upload_policy_before_settings("sanitizer") }
  after { upload_policy_after_settings }

  context "directory operations with sanitizer" do
    let!(:name1) { unique_id }
    let!(:name2) { unique_id }
    let!(:path1) { "#{node.path}/#{name1}" }
    let!(:path2) { "#{node.path}/#{name2}" }

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
      expectation.to have_enqueued_job.with [{ mkdir: [path1] }]
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
      expectation.to have_enqueued_job.with [{ mv: [path1, path2] }]
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      # delete
      click_link I18n.t('ss.links.back_to_show')
      click_link I18n.t('ss.links.delete')

      expectation = expect do
        within "form" do
          click_button I18n.t("ss.buttons.delete")
        end
      end
      expectation.to have_enqueued_job.with [{ rm: [path2] }]
      expect(page).to have_no_css(".list-item")
    end
  end

  context "image operations with sanitizer" do
    let!(:file) { "#{::Rails.root}/spec/fixtures/ss/logo.png" }
    let!(:name1) { "logo.png" }
    let!(:name2) { "logo2.png" }
    let!(:path1) { "#{node.path}/#{name1}" }
    let!(:path2) { "#{node.path}/#{name2}" }

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
      expect(job_file.path).to eq path1
      expect(FileTest.exists?(job_file.path)).to be_truthy
      expect(FileTest.exists?(job_file.sanitizer_input_path)).to be_truthy

      # sanitize
      job_file = Uploader::JobFile.first
      mock_sanitizer_restore(job_file)

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
      expectation.to have_enqueued_job.with [{ mv: [path1, path2] }]
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      # sanitize
      job_file = Uploader::JobFile.first
      mock_sanitizer_restore(job_file)

      # delete
      click_link I18n.t('ss.links.back_to_show')
      click_link I18n.t('ss.links.delete')

      expectation = expect do
        within "form" do
          click_button I18n.t("ss.buttons.delete")
        end
      end
      expectation.to have_enqueued_job.with [{ rm: [path2] }]
      expect(page).to have_no_css(".list-item")
    end
  end

  context "text operations with sanitizer" do
    let!(:file) { "#{::Rails.root}/spec/fixtures/uploader/style.scss" }
    let!(:name1) { "style.scss" }
    let!(:name2) { "style2.scss" }
    let!(:path1) { "#{node.path}/#{name1}" }
    let!(:path2) { "#{node.path}/#{name2}" }
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
      expect(job_file.path).to eq path1
      expect(FileTest.exists?(job_file.path)).to be_truthy
      expect(FileTest.exists?(job_file.sanitizer_input_path)).to be_truthy
      expect(Fs.exists?(css_path1)).to be_truthy
      FileUtils.rm(css_path1)

      # sanitize
      job_file = Uploader::JobFile.first
      mock_sanitizer_restore(job_file)
      expect(Fs.exists?(css_path1)).to be_truthy

      # update
      visit "#{index_path}/#{name1}?do=show"
      click_link I18n.t('ss.links.edit')

      expectation = expect do
        within "form" do
          fill_in "item[filename]", with: "#{node.filename}/#{name2}"
          within ".CodeMirror" do
            current_scope.click
            field = current_scope.find("textarea", visible: false)
            field.send_keys [:control, 'a'], :clear, text
          end
          click_button I18n.t("ss.buttons.save")
        end
      end
      expectation.to have_enqueued_job.with [{ mv: [path1, path2] }, { text: [path2, text] }]
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      # not sanitize
      job_file = Uploader::JobFile.first
      expect(job_file.nil?).to be_truthy
      expect(Fs.exists?(css_path2)).to be_truthy

      # delete
      click_link I18n.t('ss.links.back_to_show')
      click_link I18n.t('ss.links.delete')

      expectation = expect do
        within "form" do
          click_button I18n.t("ss.buttons.delete")
        end
      end
      expectation.to have_enqueued_job.with [{ rm: [path2] }]
    end
  end
end
