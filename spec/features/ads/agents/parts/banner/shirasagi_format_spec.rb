require 'spec_helper'

describe "ads_agents_parts_banner", type: :feature, dbscope: :example, js: true do
  let(:site)  { cms_site }
  let(:node)  { create :ads_node_banner, cur_site: site }
  let!(:part) do
    upper_html = <<~HTML
      <div class="ss-image-box-item-list">
    HTML
    lower_html = <<~HTML
      </div>
    HTML
    loop_html = <<~HTML
      <span class="ss-image-box-item loop-html" data-id="\#{id}">
        <a target="\#{link_target}" href="\#{link_url}">
          <img src="\#{img.src}" alt="\#{name}">
        </a>
      </span>
    HTML
    create(
      :ads_part_banner, cur_site: site, cur_node: node, loop_format: "shirasagi",
      upper_html: upper_html, loop_html: loop_html, lower_html: lower_html)
  end

  let!(:layout)   { create_cms_layout part }
  let!(:node_cms) { create :cms_node, layout_id: layout.id }

  context "public" do
    let!(:item1) { create :ads_banner, cur_site: site, cur_node: node, link_url: unique_url, link_target: unique_id }
    let!(:item2) { create :ads_banner, cur_site: site, cur_node: node, link_url: unique_url, link_target: unique_id }

    it do
      visit node_cms.full_url
      expect(page).to have_css(".ss-image-box")
      expect(page).to have_css(".ss-image-box-item.loop-html[data-id]", count: 2)
      within ".ss-image-box-item[data-id='#{item1.id}']" do
        expect(page).to have_css("a[href='#{item1.link_url}'][target='#{item1.link_target}']")
        expect(page).to have_css("img[src='#{item1.file.url}']")
      end
      within ".ss-image-box-item[data-id='#{item2.id}']" do
        expect(page).to have_css("a[href='#{item2.link_url}'][target='#{item2.link_target}']")
        expect(page).to have_css("img[src='#{item2.file.url}']")
      end
    end
  end
end
