require 'spec_helper'
describe Cms::NodesTreeComponent, type: :component, dbscope: :example do
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:component) { described_class.new(site: site, user: user) }
  around do |example|
    with_request_url("/.s#{site.id}/cms/nodes") do
      example.run
    end
  end
  context "simple test" do
    let!(:node1) { create :article_node_page, cur_site: site }
    let!(:node1_1) { create :cms_node_archive, cur_site: site, cur_node: node1 }
    let!(:node1_2) { create :cms_node_photo_album, cur_site: site, cur_node: node1 }
    let!(:node2) { create :cms_node_page, cur_site: site }
    let!(:node3) { create :inquiry_node_node, cur_site: site }
    let!(:node3_1) { create :inquiry_node_form, cur_site: site, cur_node: node3 }
    it do
      html = render_inline component
      # puts html
      html.css("a[href='/.s#{site.id}/article#{node1.id}/pages']").tap do |anchors|
        expect(anchors).to have(1).items
        expect(anchors[0].text).to eq node1.name
      end
      html.css("a[href='/.s#{site.id}/cms#{node1_1.id}/archives']").tap do |anchors|
        expect(anchors).to have(1).items
        expect(anchors[0].text).to eq node1_1.name
      end
      html.css("a[href='/.s#{site.id}/cms#{node1_2.id}/photo_albums']").tap do |anchors|
        expect(anchors).to have(1).items
        expect(anchors[0].text).to eq node1_2.name
      end
      html.css("a[href='/.s#{site.id}/cms#{node2.id}/pages']").tap do |anchors|
        expect(anchors).to have(1).items
        expect(anchors[0].text).to eq node2.name
      end
      html.css("a[href='/.s#{site.id}/inquiry#{node3.id}/nodes']").tap do |anchors|
        expect(anchors).to have(1).items
        expect(anchors[0].text).to eq node3.name
      end
      html.css("a[href='/.s#{site.id}/inquiry#{node3_1.id}/forms']").tap do |anchors|
        expect(anchors).to have(1).items
        expect(anchors[0].text).to eq node3_1.name
      end
    end
  end
end