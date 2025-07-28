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

  around do |example|
    save_config = SS.config.replace_value_at(:cms, 'replace_urls_after_move', true)
    example.run
    SS.config.replace_value_at(:cms, 'replace_urls_after_move', save_config)
  end

  describe "#perform" do
    before do
      # move & perform
      result = nil
      perform_enqueued_jobs do
        expect do
          service = Cms::Node::MoveService.new(cur_site: site, cur_user: user, source: node)
          service.destination_basename = dst
          result = service.move
        end.to output(include(item1.full_url.sub(src, dst))).to_stdout
      end
      expect(result).to be_truthy

      log = Job::Log.first
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
      expect(log.state).to eq "completed"

      node.reload
      item1.reload
      item2.reload
    end

    it do
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

    context 'with full_url' do
      let!(:item1) do
        create :article_page, cur_user: user, cur_site: site, cur_node: node, layout_id: layout.id,
               html: "<a href=\"#{node.full_url} \">#{node.name}</a>"
      end
      let!(:item2) do
        create :article_page, cur_user: user, cur_site: site, cur_node: node, layout_id: layout.id,
               html: "<a href=\"#{item1.full_url} \">#{item1.name}</a>"
      end

      it do
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
end
