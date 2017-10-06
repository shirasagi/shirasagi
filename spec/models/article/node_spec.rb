require 'spec_helper'

describe Article::Node::Base, type: :model, dbscope: :example do
  let(:item) { create :article_node_base }
  it_behaves_like "cms_node#spec_detail"
end

describe Article::Node::Page, type: :model, dbscope: :example do
  let(:item) { create :article_node_page }
  it_behaves_like "cms_node#spec_detail"

  describe "validation" do
    it "basename" do
      item = build(:article_node_page_basename_invalid)
      expect(item.invalid?).to be_truthy
    end
  end

  context 'for member' do
    let!(:page) { create(:article_page, cur_site: cms_site, cur_node: item) }

    it do
      Cms::Node::GenerateJob.bind(site_id: cms_site).perform_now
      expect(File.exist?("#{item.path}/index.html")).to be_truthy
      expect(File.exist?("#{item.path}/rss.xml")).to be_truthy
      expect(File.exist?(page.path)).to be_truthy

      item.for_member_state = 'enabled'
      item.save!

      expect(File.exist?("#{item.path}/index.html")).to be_falsey
      expect(File.exist?("#{item.path}/rss.xml")).to be_falsey
      expect(File.exist?(page.path)).to be_falsey
    end
  end
end
