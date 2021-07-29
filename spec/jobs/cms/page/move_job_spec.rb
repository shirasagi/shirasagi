require 'spec_helper'

describe Cms::Page::MoveJob, dbscope: :example do
  let!(:site)   { cms_site }
  let!(:layout) { create_cms_layout }
  let!(:user) { cms_user }
  let(:src) { unique_id }
  let(:dst) { unique_id }
  let!(:node) { create :article_node_page, cur_site: site, layout_id: layout.id, filename: src }
  let!(:item1) do
    create :article_page, cur_user: user, cur_site: site, cur_node: node, layout_id: layout.id,
           html: "<a href=\"#{node.url}\">#{node.name}</a>"
  end
  let!(:item2) do
    create :article_page, cur_user: user, cur_site: site, cur_node: node, layout_id: layout.id,
           html: "<a href=\"#{item1.url}\">#{item1.name}</a>"
  end

  describe "#perform" do
    before do
      # move
      node.move(dst)
      node.reload
      item1.reload
      item2.reload

      # perform
      expect do
        described_class.bind(site_id: site, user_id: user).perform_now(src: site.url + src, dst: site.url + dst)
      end.to output(include(item1.full_url)).to_stdout
    end

    it do
      log = Job::Log.first
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)

      item1.reload
      item2.reload

      expect(item1.url).not_to include(src)
      expect(item1.url).to include(dst)
      expect(item1.html).not_to include(src)
      expect(item1.html).to include(dst)
      expect(item1.html).to include(node.url)
      expect(item1.backups.count).to eq 2
      expect(item1.backups.first.action).to eq 'replace_urls'
      expect(item2.url).not_to include(src)
      expect(item2.url).to include(dst)
      expect(item2.html).not_to include(src)
      expect(item2.html).to include(dst)
      expect(item2.html).to include(item1.url)
      expect(item2.backups.count).to eq 2
      expect(item2.backups.first.action).to eq 'replace_urls'
    end
  end
end
