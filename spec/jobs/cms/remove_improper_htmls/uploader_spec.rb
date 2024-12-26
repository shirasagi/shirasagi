require 'spec_helper'

describe Cms::RemoveImproperHtmlsJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:node) { create :uploader_node_file }

  let!(:upload_dir) { "#{node.path}/#{unique_id}" }
  let!(:upload_html1) { "#{node.path}/#{unique_id}.html" }
  let!(:upload_html2) { "#{upload_dir}/#{unique_id}.html" }

  before { Fs.rm_rf site.path }
  after { Fs.rm_rf site.path }

  def generate_htmls
    FileUtils.mkdir_p(site.path)
    FileUtils.mkdir_p(upload_dir)
    FileUtils.touch(upload_html1)
    FileUtils.touch(upload_html2)

    Cms::Node::GenerateJob.bind(site_id: site).perform_now
    Cms::Page::GenerateJob.bind(site_id: site).perform_now

    expect(File.exist?(node.path)).to be true
    expect(File.exist?(upload_dir)).to be true
    expect(File.exist?(upload_html1)).to be true
    expect(File.exist?(upload_html2)).to be true
  end

  context "no errors" do
    it "#perform" do
      generate_htmls
      expectation = expect { described_class.bind(site_id: site).perform_now }
      expectation.not_to output(include("remove")).to_stdout

      log = Job::Log.first
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)

      expect(File.exist?(node.path)).to be true
      expect(File.exist?(upload_dir)).to be true
      expect(File.exist?(upload_html1)).to be true
      expect(File.exist?(upload_html2)).to be true
    end
  end
end
