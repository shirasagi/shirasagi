require 'spec_helper'

describe Cms::RemoveImproperHtmlsJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:in_file) { Rack::Test::UploadedFile.new("#{Rails.root}/spec/fixtures/cms/import/site.zip", nil, true) }

  let!(:name) { "site" }
  let!(:import_file1) { "#{site.path}/#{name}/index.html" }
  let!(:import_file2) { "#{site.path}/#{name}/article/page.html" }
  let!(:import_file3) { "#{site.path}/#{name}/css/style.css" }
  let!(:import_file4) { "#{site.path}/#{name}/img/logo.jpg" }
  let!(:improper_html) { "#{site.path}/#{name}/#{unique_id}.html" }

  let!(:import_job_file) do
    create(:cms_import_job_file, site: site, name: name, basename: name, in_file: in_file)
  end

  before { Fs.rm_rf site.path }
  after { Fs.rm_rf site.path }

  def generate_htmls
    Cms::ImportFilesJob.bind(site_id: site).perform_now
    Cms::Node::GenerateJob.bind(site_id: site).perform_now
    Cms::Page::GenerateJob.bind(site_id: site).perform_now

    expect(File.exist?(import_file1)).to be true
    expect(File.exist?(import_file2)).to be true
    expect(File.exist?(import_file3)).to be true
    expect(File.exist?(import_file4)).to be true
  end

  def set_improper_htmls
    FileUtils.touch(improper_html)
    expect(File.exist?(improper_html)).to be true
  end

  context "no errors" do
    it "#perform" do
      generate_htmls

      expectation = expect { described_class.bind(site_id: site).perform_now }
      expectation.not_to output(include("remove")).to_stdout

      log = Job::Log.first
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)

      expect(File.exist?(import_file1)).to be true
      expect(File.exist?(import_file2)).to be true
      expect(File.exist?(import_file3)).to be true
      expect(File.exist?(import_file4)).to be true
    end
  end

  context "errors exists" do
    it "#perform" do
      generate_htmls
      set_improper_htmls

      expectation = expect { described_class.bind(site_id: site).perform_now }
      expectation.to output(
        include(
          site.name,
          "remove #{improper_html}"
        )).to_stdout

      log = Job::Log.first
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)

      expect(File.exist?(import_file1)).to be true
      expect(File.exist?(import_file2)).to be true
      expect(File.exist?(import_file3)).to be true
      expect(File.exist?(import_file4)).to be true
      expect(File.exist?(improper_html)).to be false
    end
  end
end
