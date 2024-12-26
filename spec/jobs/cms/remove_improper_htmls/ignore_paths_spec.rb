require 'spec_helper'

describe Cms::RemoveImproperHtmlsJob, dbscope: :example do
  let!(:site) { cms_site }

  let!(:article_node) { create :article_node_page, cur_site: site }
  let!(:article_page1) { create :article_page, cur_site: site, cur_node: article_node }
  let!(:article_page2) { create :article_page, cur_site: site, cur_node: article_node }

  let!(:faq_node) { create :faq_node_page, cur_site: site }
  let!(:faq_page1) { create :faq_page, cur_site: site, cur_node: faq_node }
  let!(:faq_page2) { create :faq_page, cur_site: site, cur_node: faq_node }

  let(:ignore_paths) { [article_node.filename, faq_page1.filename] }

  before do
    Fs.rm_rf site.path
    @saved_ignore_paths = SS.config.remove_improper_htmls.ignore_paths
    SS.config.replace_value_at(:remove_improper_htmls, :ignore_paths, ignore_paths)
  end
  after do
    Fs.rm_rf site.path
    SS.config.replace_value_at(:remove_improper_htmls, :ignore_paths, @saved_ignore_paths)
  end

  def generate_htmls
    Cms::Node::GenerateJob.bind(site_id: site).perform_now
    Cms::Page::GenerateJob.bind(site_id: site).perform_now

    expect(File.exist?(article_node.path)).to be true
    expect(File.exist?(article_page1.path)).to be true
    expect(File.exist?(article_page2.path)).to be true
    expect(File.exist?(faq_node.path)).to be true
    expect(File.exist?(faq_page1.path)).to be true
    expect(File.exist?(faq_page2.path)).to be true
  end

  def set_improper_htmls
    [article_node, faq_node].each do |item|
      item.state = "closed"
      item.update!
    end
    expect(File.exist?(article_node.path)).to be true
    expect(File.exist?(article_page1.path)).to be false
    expect(File.exist?(article_page2.path)).to be false
    expect(File.exist?(faq_node.path)).to be true
    expect(File.exist?(faq_page1.path)).to be false
    expect(File.exist?(faq_page2.path)).to be false

    FileUtils.touch(article_page1.path)
    FileUtils.touch(article_page2.path)
    FileUtils.touch(faq_page1.path)
    FileUtils.touch(faq_page2.path)

    expect(File.exist?(article_node.path)).to be true
    expect(File.exist?(article_page1.path)).to be true
    expect(File.exist?(article_page2.path)).to be true
    expect(File.exist?(faq_node.path)).to be true
    expect(File.exist?(faq_page1.path)).to be true
    expect(File.exist?(faq_page2.path)).to be true
  end

  context "errors exists" do
    it "#perform" do
      generate_htmls
      set_improper_htmls

      expectation = expect { described_class.bind(site_id: site).perform_now }
      expectation.to output(
        include(
          site.name,
          "skip #{article_page1.path}",
          "skip #{article_page2.path}",
          "skip #{faq_page1.path}",
          "remove #{faq_page2.path}"
        )).to_stdout

      expect(File.exist?(article_page1.path)).to be true
      expect(File.exist?(article_page2.path)).to be true
      expect(File.exist?(faq_page1.path)).to be true
      expect(File.exist?(faq_page2.path)).to be false

      log = Job::Log.first
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
    end
  end
end
