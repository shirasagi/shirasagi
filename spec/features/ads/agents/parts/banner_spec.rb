require 'spec_helper'

describe "ads_agents_parts_banner", type: :feature, dbscope: :example, js: true do
  let(:site)  { cms_site }
  let(:node)  { create :ads_node_banner, cur_site: site }
  let!(:part) { create :ads_part_banner, cur_site: site, cur_node: node }
  let!(:item1) { create :ads_banner, cur_site: site, cur_node: node }
  let!(:item2) { create :ads_banner, cur_site: site, cur_node: node, additional_attr: 'rel="nofollow"' }

  let(:layout)   { create_cms_layout part }
  let(:node_cms) { create :cms_node, layout_id: layout.id }

  before do
    item1.link_url = node_cms.url
    item1.save!

    item2.link_url = node_cms.url
    item2.save!
  end

  context "public" do
    it "#count" do
      visit node_cms.full_url
      expect(page).to have_css(".ads-banners")
      expect(page).to have_selector(".banners span a img[alt='#{item1.name}']")

      expect(page).to have_css(".ads-banners")
      expect(page).to have_selector(".banners span a[rel='nofollow'] img[alt='#{item2.name}']")

      first(".banners span a img[alt='#{item1.name}']").click
      expect(page).to have_selector(".banners span a img[alt='#{item1.name}']")

      # wait for counting accesses by using img tag which is processed asynchronously.
      sleep 1

      Ads::AccessLog.find_by(site_id: item1.site_id, node_id: item1.parent.id, link_url: item1.link_url).tap do |log|
        expect(log.count).to eq 1
      end
    end
  end

  context "preview", driver: :chrome do
    before { login_cms_user }

    it "#count" do
      visit cms_preview_path(site: site, path: "#{node_cms.filename}/")
      expect(page).to have_css(".ads-banners")
      expect(page).to have_selector(".banners span a img[alt='#{item1.name}']")

      expect(page).to have_css(".ads-banners")
      expect(page).to have_selector(".banners span a[rel='nofollow'] img[alt='#{item2.name}']")

      first(".banners span a img[alt='#{item1.name}']").click
      expect(page).to have_selector(".banners span a img[alt='#{item1.name}']")

      # wait for counting accesses by using img tag which is processed asynchronously.
      sleep 1

      # in preview, no logs is created
      expect(Ads::AccessLog.count).to eq 0
    end
  end
end
