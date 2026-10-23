require 'spec_helper'

describe "key_visual_agents_parts_slide", type: :feature, dbscope: :example, js: true do
  let(:site)  { cms_site }
  let(:node)  { create :member_node_photo, cur_site: site }
  let!(:layout)   { create_cms_layout part, cur_site: site }
  let!(:node_cms) { create :cms_node, cur_site: site, layout: layout }

  context "vulnerability in Ads::Banner#link_target" do
    let(:vulnerable_link_target) do
      %(_self" onclick="window.xss=1; console.log('xss'); return false;)
    end
    let!(:part) do
      part = create :member_part_photo_slide, cur_site: site, cur_node: node, link_target: nil
      part.set(link_target: vulnerable_link_target)
      part
    end
    let!(:item1) do
      create :member_photo, cur_site: site, cur_node: node
    end

    it do
      visit node_cms.full_url
      wait_for_js_ready
      expect(page).to have_css(".bx-wrapper .bx-viewport li a", count: 3)
      # スライドが1件でも、3 つの li が作成され、そのうちどれがクリックできるのか Capybara から特定するのは難しい
      # そこで JS でクリックする。JS なら hidden であってもクリックできる。
      page.execute_script('$(".bx-wrapper .bx-viewport li a").click();')

      expect(page.evaluate_script("window.xss")).to be_blank

      logs = capture_console_logs
      expect(logs).not_to include(include("xss"))
    end
  end
end
