require 'spec_helper'

describe "ads_agents_parts_banner", type: :feature, dbscope: :example, js: true do
  let(:site)  { cms_site }
  let(:node)  { create :ads_node_banner, cur_site: site }
  let!(:part) { create :ads_part_banner, cur_site: site, cur_node: node, filename: "add" }
  let!(:item) { create :ads_banner, cur_site: site, cur_node: node }

  let(:layout)   { create_cms_layout [part] }
  let(:node_cms) { create :cms_node, layout_id: layout.id }

  before do
    item.link_url = node_cms.url
    item.save!
  end

  context "public" do
    it "#count" do
      visit node_cms.full_url
      expect(status_code).to eq 200
      expect(page).to have_css(".ads-banners")
      expect(page).to have_selector(".banners span a", text: item.name)

      click_on item.name
      expect(status_code).to eq 200
      expect(page).to have_selector(".banners span a", text: item.name)

      # wait for counting accesses by using img tag which is processed asynchronously.
      sleep 1

      Ads::AccessLog.find_by(site_id: item.site_id, node_id: item.parent.id, link_url: item.link_url).tap do |log|
        expect(log.count).to eq 1
      end
    end
  end

  context "preview" do
    before { login_cms_user }

    it "#count" do
      visit cms_preview_path(site: site, path: node_cms.url)
      expect(status_code).to eq 200
      expect(page).to have_css(".ads-banners")
      expect(page).to have_selector(".banners span a", text: item.name)

      # click_on item.name
      find(".banners span a", text: item.name).trigger("click")
      expect(status_code).to eq 200
      expect(page).to have_selector(".banners span a", text: item.name)

      # wait for counting accesses by using img tag which is processed asynchronously.
      sleep 1

      # in preview, no logs is created
      expect(Ads::AccessLog.count).to eq 0
    end
  end
end
