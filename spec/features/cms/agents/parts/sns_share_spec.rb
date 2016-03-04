require 'spec_helper'

describe "cms_agents_parts_sns_share", type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout [part] }
  let(:node)   { create :cms_node, layout_id: layout.id }
  let(:part)   { create :cms_part_sns_share }

  context "public" do
    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_css(".cms-sns_share")
      expect(page).to have_css(".fb-like")
      expect(page).to have_css(".fb-share")
      expect(page).to have_css(".twitter")
      expect(page).to have_css(".hatena")
      expect(page).to have_css(".google")
      expect(page).to have_css(".evernote")
    end
  end
end
