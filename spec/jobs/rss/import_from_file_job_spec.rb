require 'spec_helper'

describe Rss::ImportFromFileJob, dbscope: :example do
  context "when importing weather sample xml" do
    let(:site) { cms_site }
    let(:filepath) { Rails.root.join(*%w(spec fixtures rss sample-rss.xml)) }
    let(:node) { create(:rss_node_page, cur_site: site, page_state: 'closed') }
    let(:file) { Rss::TempFile.create_from_post(site, File.read(filepath), 'application/xml+rss') }
    let(:model) { Rss::Page }

    it do
      expect { described_class.bind(site_id: site, node_id: node).perform_now(file.id) }.to change { model.count }.from(0).to(5)
      item = model.where(rss_link: 'http://example.jp/rss/1.html').first
      expect(item).not_to be_nil
      expect(item.name).to eq '記事1'
      expect(item.rss_link).to eq 'http://example.jp/rss/1.html'
      expect(item.html).to eq '本文1'
      expect(item.released).to eq Time.zone.parse('2015-06-12T19:00:00+09:00')
      expect(item.authors.count).to eq 1
      expect(item.authors.first.name).to be_nil
      expect(item.authors.first.email).to eq 'momose_tomoka@example.com (百瀬 友香)'
      expect(item.authors.first.uri).to be_nil
      expect(item.state).to eq 'closed'
    end
  end
end
