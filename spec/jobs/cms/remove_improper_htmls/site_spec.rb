require 'spec_helper'

describe Cms::RemoveImproperHtmlsJob, dbscope: :example do
  let!(:site1) { create :cms_site_unique }
  let!(:site2) { create :cms_site_unique }

  let!(:article_node1) { create :article_node_page, cur_site: site1 }
  let!(:article_page1) { create :article_page, cur_site: site1, cur_node: article_node1 }

  let!(:article_node2) { create :article_node_page, cur_site: site2 }
  let!(:article_page2) { create :article_page, cur_site: site2, cur_node: article_node2 }

  before do
    Fs.rm_rf site1.path
    Fs.rm_rf site2.path
  end
  after do
    Fs.rm_rf site2.path
    Fs.rm_rf site2.path
  end

  def generate_htmls
    Cms::Node::GenerateJob.bind(site_id: site1).perform_now
    Cms::Page::GenerateJob.bind(site_id: site1).perform_now

    Cms::Node::GenerateJob.bind(site_id: site2).perform_now
    Cms::Page::GenerateJob.bind(site_id: site2).perform_now

    expect(File.exists?(article_node1.path)).to be true
    expect(File.exists?(article_page1.path)).to be true
    expect(File.exists?(article_node2.path)).to be true
    expect(File.exists?(article_page2.path)).to be true
  end

  def set_improper_htmls
    [article_page1, article_page2].each do |item|
      item.state = "closed"
      item.update!
    end
    expect(File.exists?(article_page1.path)).to be false
    expect(File.exists?(article_page2.path)).to be false

    [article_page1, article_page2].each do |item|
      ::FileUtils.touch(item.path)
    end
    expect(File.exists?(article_page1.path)).to be true
    expect(File.exists?(article_page2.path)).to be true
  end

  context "no errors" do
    it "#perform" do
      generate_htmls

      expectation = expect { described_class.bind(site_id: site1).perform_now }
      expectation.to output(include(site1.name)).to_stdout
      expectation.not_to output(include("remove")).to_stdout

      expectation = expect { described_class.bind(site_id: site2).perform_now }
      expectation.to output(include(site2.name)).to_stdout
      expectation.not_to output(include("remove")).to_stdout
    end
  end

  context "errors exists" do
    it "#perform" do
      generate_htmls
      set_improper_htmls

      expectation = expect { described_class.bind(site_id: site1).perform_now }
      expectation.to output(
        include(
          site1.name,
          "remove #{article_page1.path}"
        )).to_stdout

      expect(File.exists?(article_page1.path)).to be false
      expect(File.exists?(article_page2.path)).to be true

      expectation = expect { described_class.bind(site_id: site2).perform_now }
      expectation.to output(
        include(
          site2.name,
          "remove #{article_page2.path}"
        )).to_stdout

      expect(File.exists?(article_page1.path)).to be false
      expect(File.exists?(article_page2.path)).to be false
    end
  end
end
