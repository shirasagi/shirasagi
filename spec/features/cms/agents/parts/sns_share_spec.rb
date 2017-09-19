require 'spec_helper'

describe "cms_agents_parts_sns_share", type: :feature, dbscope: :example do
  context "public" do
    let(:site)   { cms_site }
    let(:layout) { create_cms_layout part }
    let(:node)   { create :cms_node, layout_id: layout.id }
    let(:part)   { create :cms_part_sns_share }

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
      expect(page).to have_css(".line")
    end
  end

  context "subsite" do
    let(:site0)   { cms_site }
    let(:site1)   { create(:cms_site_subdir, parent_id: site0.id) }
    let(:layout) { create_cms_layout part, site_id: site1.id }
    let(:node)   { create :cms_node, cur_site: site1, layout_id: layout.id }
    let(:part)   { create :cms_part_sns_share, cur_site: site1 }

    before do
      Capybara.app_host = "http://#{site1.domain}"
    end

    it do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_css('.cms-sns_share')
      expect(page).to have_css('.fb-like')
      expect(page).to have_css('.fb-share')
      expect(page).to have_css('.twitter')
      expect(page).to have_css('.hatena')
      expect(page).to have_css('.google')
      expect(page).to have_css('.evernote')
      expect(page).to have_css('.line')
      expect(find('div.fb-like div.fb-like')['data-href']).to eq node.full_url[0..-2]
      expect(find('div.twitter a')['data-url']).to eq node.full_url[0..-2]
    end
  end
end
