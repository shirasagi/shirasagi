require 'spec_helper'

describe "ads_agents_parts_banner", type: :feature, dbscope: :example, js: true do
  let(:site)  { cms_site }
  let(:node)  { create :ads_node_banner, cur_site: site }
  let!(:part) { create :ads_part_banner, cur_site: site, cur_node: node, link_target: nil }
  let!(:layout)   { create_cms_layout part, cur_site: site }
  let!(:node_cms) { create :cms_node, cur_site: site, layout: layout }

  context "vulnerability in Ads::Banner#link_target" do
    let(:vulnerable_link_target) do
      %(" onclick="window.xss=1; console.log('xss'); return false;)
    end
    let!(:item1) do
      create :ads_banner, cur_site: site, cur_node: node, link_url: unique_url, link_target: vulnerable_link_target
    end

    it do
      visit node_cms.full_url
      wait_for_js_ready

      first(".ss-image-box-item a").click

      expect(page.evaluate_script("window.xss")).to be_blank

      logs = capture_console_logs
      expect(logs).not_to include(include("xss"))
    end
  end
end
