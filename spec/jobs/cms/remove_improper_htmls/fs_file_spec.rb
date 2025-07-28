require 'spec_helper'

describe Cms::RemoveImproperHtmlsJob, dbscope: :example do
  let!(:site) { cms_site }

  let!(:article_node) { create :article_node_page, cur_site: site }
  let!(:article_page1) { create :article_page, cur_site: site, cur_node: article_node, file_ids: [file1.id, file2.id] }
  let!(:file1) { create :ss_file, site: site, user_id: cms_user.id }
  let!(:file2) do
    create(:ss_file, site: site, user_id: cms_user.id,
      in_file: Fs::UploadedFile.create_from_file("#{Rails.root}/spec/fixtures/translate/ss_proj1.html", content_type: 'text/html'))
  end

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
    expect(File.exist?(file1.public_path)).to be true
    expect(File.exist?(file2.public_path)).to be true
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
end
