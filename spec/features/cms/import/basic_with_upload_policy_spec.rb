require 'spec_helper'

describe "cms_import_with_upload_policy", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:index_path) { cms_import_path site.id }
  let!(:file) { "#{Rails.root}/spec/fixtures/cms/import/site.zip" }
  let!(:name) { File.basename(file, ".*") }
  let!(:now) { Time.zone.now.beginning_of_minute }
  let!(:job_wait) { (now + 1.year.seconds).to_f }

  before { login_cms_user }
  before { upload_policy_before_settings("sanitizer") }
  after { upload_policy_after_settings }

  context "sanitizer settings" do
    let(:import_date) { now + 1.week }
    context "import_date is presented" do
      it do
        visit index_path

        # upload
        expectation = expect do
          Timecop.freeze(now) do
            within "form#task-form" do
              attach_file "item[in_file]", file
              fill_in 'item[import_date]', with: I18n.l(import_date, format: :long)
              click_button I18n.t('ss.buttons.import')
            end
            wait_for_notice I18n.t('ss.notice.started_import')
          end
        end
        expectation.to have_enqueued_job(Cms::ImportFilesJob)

        expect(enqueued_jobs.length).to eq 1
        enqueued_job = enqueued_jobs.first
        expect(enqueued_job[:job]).to eq Cms::ImportFilesJob
        expect(enqueued_job[:args]).to be_blank
        expect(enqueued_job[:queue]).to eq "default"
        # import_date がセットされようがセットされまいが、一律 1 年後がセットされる。
        # 1年の計算方法に注意が必要。1.year.seconds により1 年後が算出されるので、翌年が閏年の場合、1日ずれる点に注意。
        # 参照:
        # https://github.com/rails/rails/blob/v6.1.4.1/activejob/lib/active_job/enqueuing.rb#L49
        expect(enqueued_job[:at]).to eq job_wait

        # sanitize
        expect(Cms::ImportJobFile.count).to eq 1
        job_file = Cms::ImportJobFile.first
        expect(job_file.job_name).to eq enqueued_job["job_id"]
        # import_date は job_wait にセットされる
        expect(job_file.job_wait).to eq import_date.to_i
        restored_file = mock_sanitizer_restore(job_file.files[0])
        expect(Fs.exist?(restored_file)).to be_truthy
      end
    end

    context "import_date is empty" do
      it do
        visit index_path

        # upload
        expectation = expect do
          Timecop.freeze(now) do
            within "form#task-form" do
              attach_file "item[in_file]", file
              click_button I18n.t('ss.buttons.import')
            end
            wait_for_notice I18n.t('ss.notice.started_import')
          end
        end
        expectation.to have_enqueued_job(Cms::ImportFilesJob)

        expect(enqueued_jobs.length).to eq 1
        enqueued_job = enqueued_jobs.first
        expect(enqueued_job[:job]).to eq Cms::ImportFilesJob
        expect(enqueued_job[:args]).to be_blank
        expect(enqueued_job[:queue]).to eq "default"
        # import_date がセットされようがセットされまいが、一律 1 年後がセットされる。
        # 1年の計算方法に注意が必要。1.year.seconds により1 年後が算出されるので、翌年が閏年の場合、1日ずれる点に注意。
        # 参照:
        # https://github.com/rails/rails/blob/v6.1.4.1/activejob/lib/active_job/enqueuing.rb#L49
        expect(enqueued_job[:at]).to eq job_wait

        # sanitize
        expect(Cms::ImportJobFile.count).to eq 1
        job_file = Cms::ImportJobFile.first
        expect(job_file.job_name).to eq enqueued_job["job_id"]
        expect(job_file.job_wait).to eq now.to_i
        restored_file = mock_sanitizer_restore(job_file.files[0])
        expect(Fs.exist?(restored_file)).to be_truthy
      end
    end
  end
end
