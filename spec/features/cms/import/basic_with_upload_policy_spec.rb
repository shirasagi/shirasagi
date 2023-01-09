require 'spec_helper'

describe "cms_import_with_upload_policy", type: :feature, dbscope: :example, js: true do
  subject(:site) { cms_site }
  subject(:index_path) { cms_import_path site.id }
  let!(:file) { "#{Rails.root}/spec/fixtures/cms/import/site.zip" }
  let!(:name) { File.basename(file, ".*") }
  let!(:now) { Time.zone.now.beginning_of_minute }
  let!(:job_wait) { 1.year.since.to_f }

  before { login_cms_user }
  before { upload_policy_before_settings("sanitizer") }
  after { upload_policy_after_settings }

  context "sanitizer settings" do
    context "import_date is presnet" do
      it do
        visit index_path

        # upload
        expectation = expect do
          within "form#task-form" do
            attach_file "item[in_file]", file
            fill_in_datetime 'item[import_date]', with: now
            click_button I18n.t('ss.buttons.import')
          end
        end
        expectation.to have_enqueued_job(Cms::ImportFilesJob)

        enqueued_jobs.first.tap do |enqueued_job|
          expect(enqueued_job[:at]).to be > job_wait
        end

        # sanitize
        job_file = Cms::ImportJobFile.first
        restored_file = mock_sanitizer_restore(job_file.files[0])
        expect(Fs.exist?(restored_file)).to be_truthy
      end
    end

    context "import_date is empty" do
      it do
        visit index_path

        # upload
        expectation = expect do
          within "form#task-form" do
            attach_file "item[in_file]", file
            click_button I18n.t('ss.buttons.import')
          end
        end
        expectation.to have_enqueued_job(Cms::ImportFilesJob)

        enqueued_jobs.first.tap do |enqueued_job|
          expect(enqueued_job[:at]).to be > job_wait
        end

        # sanitize
        job_file = Cms::ImportJobFile.first
        restored_file = mock_sanitizer_restore(job_file.files[0])
        expect(Fs.exist?(restored_file)).to be_truthy
      end
    end
  end
end
