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
      expect(page).to have_css(".ss-image-box")
      expect(page).to have_selector(".ss-image-box-item-list span a img[alt='#{item1.name}']")

      expect(page).to have_css(".ss-image-box")
      expect(page).to have_selector(".ss-image-box-item-list span a[rel='nofollow'] img[alt='#{item2.name}']")

      first(".ss-image-box-item-list span a img[alt='#{item1.name}']").click
      expect(page).to have_selector(".ss-image-box-item-list span a img[alt='#{item1.name}']")

      # wait for counting accesses by using img tag which is processed asynchronously.
      sleep 1

      Ads::AccessLog.find_by(site_id: item1.site_id, node_id: item1.parent.id, link_url: item1.link_url).tap do |log|
        expect(log.count).to eq 1
      end
    end

    it "check link targets" do 
      item1.update(link_target: "_blank", link_url: "/example.jp")
      item1.reload
      part.update(link_target: "")
      part.reload
      visit node_cms.full_url
      expect(page).to have_css(".ss-image-box")
      link_selector1 = ".ss-image-box-item-list span a[target='#{item1.link_target}'] img[alt='#{item1.name}']"
      link_selector2 = ".ss-image-box-item-list span a img[alt='#{item2.name}']"

      # check for the ad needs to open in new tab

      expect(page).to have_selector(link_selector1)  
      link = find(link_selector1).find(:xpath, '..')
      expect(link[:target]).to eq "_blank"
      previous_url = current_url
      new_window = window_opened_by { link.click }

      within_window new_window do
        expect(previous_url).not_to eq current_url
        expect(current_url).to include(item1.link_url)
      end

      # check for the ad needs to open in current_tab

      expect(page).to have_selector(link_selector2)
      link2 = find(link_selector2).find(:xpath, '..')
      expect(link2[:target]).to eq ""
      link2.click
      expect(current_url).to eq previous_url
      expect(current_url).to include(item2.link_url)
    end

  end

  context "preview" do
    before { login_cms_user }

    it "#count" do
      visit cms_preview_path(site: site, path: "#{node_cms.filename}/")
      expect(page).to have_css(".ss-image-box")
      expect(page).to have_selector(".ss-image-box-item-list span a img[alt='#{item1.name}']")

      expect(page).to have_css(".ss-image-box")
      expect(page).to have_selector(".ss-image-box-item-list span a[rel='nofollow'] img[alt='#{item2.name}']")

      first(".ss-image-box-item-list span a img[alt='#{item1.name}']").click
      expect(page).to have_selector(".ss-image-box-item-list span a img[alt='#{item1.name}']")

      # wait for counting accesses by using img tag which is processed asynchronously.
      sleep 1

      # in preview, no logs is created
      expect(Ads::AccessLog.count).to eq 0
    end
  end
end
