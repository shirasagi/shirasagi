require 'spec_helper'

describe Uploader::FilesJob, dbscope: :example do
  let!(:user) { cms_user }
  let!(:site) { cms_site }
  let!(:file) { "#{Rails.root}/spec/fixtures/ss/logo.png" }
  let!(:bindings) { { user_id: user.id, site_id: site.id } }
  let!(:job) { described_class.bind(bindings) }

  describe "perform directory" do
    let!(:dir1_path) { "#{site.path}/#{unique_id}" }
    let!(:dir2_path) { "#{site.path}/#{unique_id}" }

    it do
      expect(Dir.exist?(dir1_path)).to be_falsey
      expect(Dir.exist?(dir2_path)).to be_falsey

      # create
      perform_enqueued_jobs do
        job.perform_now([{ mkdir: [dir1_path] }])
      end
      expect(Dir.exist?(dir1_path)).to be_truthy

      # update
      perform_enqueued_jobs do
        job.perform_now([{ mv: [dir1_path, dir2_path] }])
      end
      expect(Dir.exist?(dir1_path)).to be_falsey
      expect(Dir.exist?(dir2_path)).to be_truthy

      # delete
      perform_enqueued_jobs do
        job.perform_now([{ rm: [dir2_path] }])
      end
      expect(Dir.exist?(dir2_path)).to be_falsey
    end
  end

  describe "perform scss file" do
    let!(:source) { "#{::Rails.root}/spec/fixtures/uploader/style.scss" }
    let!(:file_path) { "#{site.path}/style.scss" }
    let!(:css_path) { "#{site.path}/style.css" }
    let!(:text_data) { "html { body { color: red; } }" }

    before { upload_policy_before_settings }
    after { upload_policy_after_settings }

    it do
      # upload
      FileUtils.mkdir_p ::File.dirname(file_path)
      FileUtils.cp(source, file_path)
      Uploader::JobFile.upload(file_path, bindings)
      FileUtils.rm(file_path)

      file = Uploader::JobFile.first
      mock_sanitizer_restore(file)
      expect(file.path).to eq file_path
      expect(Fs.exists?(file_path)).to be_truthy
      expect(Fs.exists?(css_path)).to be_truthy
      expect(Uploader::JobFile.all.size).to eq 0

      # update
      FileUtils.rm(css_path)
      perform_enqueued_jobs do
        job.perform_now([{ text: [file_path, text_data] }])
      end
      expect(Fs.read(file_path)).to eq text_data
      expect(Fs.exists?(css_path)).to be_truthy

      # delete
      perform_enqueued_jobs do
        job.perform_now([{ rm: [file_path] }])
      end
      expect(Fs.exists?(file_path)).to be_falsey
    end
  end

  describe "perform coffee file" do
    let!(:source) { "#{::Rails.root}/spec/fixtures/uploader/example.coffee" }
    let!(:file_path) { "#{site.path}/example.coffee" }
    let!(:js_path) { "#{site.path}/example.js" }
    let!(:text_data) { "value = 2" }

    before { upload_policy_before_settings }
    after { upload_policy_after_settings }

    it do
      # upload
      FileUtils.mkdir_p ::File.dirname(file_path)
      FileUtils.cp(source, file_path)
      Uploader::JobFile.upload(file_path, bindings)
      FileUtils.rm(file_path)

      file = Uploader::JobFile.first
      mock_sanitizer_restore(file)
      expect(file.path).to eq file_path
      expect(Fs.exists?(file_path)).to be_truthy
      expect(Fs.exists?(js_path)).to be_truthy
      expect(Uploader::JobFile.all.size).to eq 0

      # update
      FileUtils.rm(js_path)
      perform_enqueued_jobs do
        job.perform_now([{ text: [file_path, text_data] }])
      end
      expect(Fs.read(file_path)).to eq text_data
      expect(Fs.exists?(js_path)).to be_truthy

      # delete
      perform_enqueued_jobs do
        job.perform_now([{ rm: [file_path] }])
      end
      expect(Fs.exists?(file_path)).to be_falsey
    end
  end

  describe "perform image file" do
    let!(:source) { "#{::Rails.root}/spec/fixtures/ss/logo.png" }
    let!(:file_path) { "#{site.path}/example.png" }

    before { upload_policy_before_settings }
    after { upload_policy_after_settings }

    it do
      # upload
      FileUtils.mkdir_p ::File.dirname(file_path)
      FileUtils.cp(source, file_path)
      Uploader::JobFile.upload(file_path, bindings)
      FileUtils.rm(file_path)

      file = Uploader::JobFile.first
      mock_sanitizer_restore(file)
      expect(file.path).to eq file_path
      expect(Fs.exists?(file_path)).to be_truthy
      expect(Uploader::JobFile.all.size).to eq 0

      # delete
      perform_enqueued_jobs do
        job.perform_now([{ rm: [file_path] }])
      end
      expect(Fs.exists?(file_path)).to be_falsey
    end
  end
end
