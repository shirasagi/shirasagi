require 'spec_helper'

describe Cms::RemoveImproperHtmlsJob, dbscope: :example do
  let!(:site) { cms_site }

  let!(:article_node) { create :article_node_page, cur_site: site }
  let!(:article_page1) { create :article_page, cur_site: site, cur_node: article_node }
  let!(:article_page2) { create :article_page, cur_site: site, cur_node: article_node }

  let!(:faq_node) { create :faq_node_page, cur_site: site }
  let!(:faq_page1) { create :faq_page, cur_site: site, cur_node: faq_node }
  let!(:faq_page2) { create :faq_page, cur_site: site, cur_node: faq_node }

  let!(:event_node) { create :event_node_page, cur_site: site }
  let!(:event_page1) { create :event_page, cur_site: site, cur_node: event_node }
  let!(:event_page2) { create :event_page, cur_site: site, cur_node: event_node }

  let!(:cms_page1) { create :cms_page, cur_site: site }
  let!(:cms_page2) { create :cms_page, cur_site: site, cur_node: article_node }
  let!(:cms_page3) { create :cms_page, cur_site: site, cur_node: event_node }
  let!(:cms_page4) { create :cms_page, cur_site: site, cur_node: faq_node }

  let(:email) { "sample@example.jp" }

  before do
    Fs.rm_rf site.path
    ActionMailer::Base.deliveries.clear
  end
  after do
    Fs.rm_rf site.path
    ActionMailer::Base.deliveries.clear
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
    expect(File.exist?(event_node.path)).to be true
    expect(File.exist?(event_page1.path)).to be true
    expect(File.exist?(event_page2.path)).to be true
    expect(File.exist?(cms_page1.path)).to be true
    expect(File.exist?(cms_page2.path)).to be true
    expect(File.exist?(cms_page3.path)).to be true
    expect(File.exist?(cms_page4.path)).to be true
  end

  def set_improper_htmls
    [article_page1, event_page1, cms_page1, cms_page2, faq_node].each do |item|
      item.state = "closed"
      item.update!
    end
    expect(File.exist?(article_node.path)).to be true
    expect(File.exist?(article_page1.path)).to be false
    expect(File.exist?(article_page2.path)).to be true
    expect(File.exist?(faq_node.path)).to be true
    expect(File.exist?(faq_page1.path)).to be false
    expect(File.exist?(faq_page2.path)).to be false
    expect(File.exist?(event_node.path)).to be true
    expect(File.exist?(event_page1.path)).to be false
    expect(File.exist?(event_page2.path)).to be true
    expect(File.exist?(cms_page1.path)).to be false
    expect(File.exist?(cms_page2.path)).to be false
    expect(File.exist?(cms_page3.path)).to be true
    expect(File.exist?(cms_page4.path)).to be false

    [article_page1, event_page1, cms_page1, cms_page2, faq_page1].each do |item|
      ::FileUtils.touch(item.path)
    end
    expect(File.exist?(article_node.path)).to be true
    expect(File.exist?(article_page1.path)).to be true
    expect(File.exist?(article_page2.path)).to be true
    expect(File.exist?(faq_node.path)).to be true
    expect(File.exist?(faq_page1.path)).to be true
    expect(File.exist?(faq_page2.path)).to be false
    expect(File.exist?(event_node.path)).to be true
    expect(File.exist?(event_page1.path)).to be true
    expect(File.exist?(event_page2.path)).to be true
    expect(File.exist?(cms_page1.path)).to be true
    expect(File.exist?(cms_page2.path)).to be true
    expect(File.exist?(cms_page3.path)).to be true
    expect(File.exist?(cms_page4.path)).to be false
  end

  context "no errors" do
    it "#perform" do
      generate_htmls

      expectation = expect { described_class.bind(site_id: site).perform_now }
      expectation.not_to output(include("remove")).to_stdout

      log = Job::Log.first
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
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
          "remove #{article_page1.path}",
          "remove #{event_page1.path}",
          "remove #{cms_page1.path}",
          "remove #{cms_page2.path}",
          "remove #{faq_page1.path}"
        )).to_stdout

      expect(File.exist?(article_page1.path)).to be false
      expect(File.exist?(event_page1.path)).to be false
      expect(File.exist?(cms_page1.path)).to be false
      expect(File.exist?(cms_page2.path)).to be false
      expect(File.exist?(faq_page1.path)).to be false

      log = Job::Log.first
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
    end

    it "#perform with dry_run option" do
      generate_htmls
      set_improper_htmls

      expectation = expect { described_class.bind(site_id: site).perform_now(dry_run: 1) }
      expectation.to output(
        include(
          site.name,
          "remove #{article_page1.path}",
          "remove #{event_page1.path}",
          "remove #{cms_page1.path}",
          "remove #{cms_page2.path}",
          "remove #{faq_page1.path}"
        )).to_stdout

      expect(File.exist?(article_page1.path)).to be true
      expect(File.exist?(event_page1.path)).to be true
      expect(File.exist?(cms_page1.path)).to be true
      expect(File.exist?(cms_page2.path)).to be true
      expect(File.exist?(faq_page1.path)).to be true

      log = Job::Log.first
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
    end

    it "#perform with email option" do
      generate_htmls
      set_improper_htmls

      expectation = expect { described_class.bind(site_id: site).perform_now(email: email) }
      expectation.to output(
        include(
          site.name,
          "remove #{article_page1.path}",
          "remove #{event_page1.path}",
          "remove #{cms_page1.path}",
          "remove #{cms_page2.path}",
          "remove #{faq_page1.path}"
        )).to_stdout

      expect(File.exist?(article_page1.path)).to be false
      expect(File.exist?(event_page1.path)).to be false
      expect(File.exist?(cms_page1.path)).to be false
      expect(File.exist?(cms_page2.path)).to be false
      expect(File.exist?(faq_page1.path)).to be false

      log = Job::Log.first
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)

      expect(ActionMailer::Base.deliveries.length).to eq 1
      mail = ActionMailer::Base.deliveries.last
      body = mail.body.decoded
      expect(mail.to).to eq [email]
      expect(body).to include("[5 errors]")
      expect(body).to include("remove #{article_page1.path}")
      expect(body).to include("remove #{event_page1.path}")
      expect(body).to include("remove #{cms_page1.path}")
      expect(body).to include("remove #{cms_page2.path}")
      expect(body).to include("remove #{faq_page1.path}")
    end
  end
end
