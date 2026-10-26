require 'spec_helper'

describe Event::Agents::Pages::PageController, type: :request, dbscope: :example do
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:layout) { create_cms_layout cur_site: site }
  let!(:node) { create :event_node_page, cur_site: site, layout: layout }
  let!(:page1) do
    create(:event_page, cur_site: site, cur_node: node, layout: layout, ical_link: "/#{unique_id}.pdf")
  end

  context "when generated pages are not existed" do
    before do
      Fs.rm_rf node.path
      Fs.rm_rf page1.path
    end

    it do
      full_url = Addressable::URI.join(site.full_root_url, page1.filename).to_s
      get full_url
      expect(response.status).to eq 302
      expect(response.location).to end_with Addressable::URI.join(site.full_root_url, page1.ical_link).to_s
    end
  end

  context "when generated pages are existed" do
    before do
      expect(File.size(page1.path)).to be>0
    end

    it do
      full_url = Addressable::URI.join(site.full_root_url, page1.filename).to_s
      get full_url
      expect(response.status).to eq 200
      document = Nokogiri::HTML5.parse(File.read(page1.path))
      document.css('meta[http-equiv="refresh"]').tap do |meta_elements|
        expect(meta_elements).to have(1).items
        expect(meta_elements[0]["content"]).to include(page1.ical_link)
      end
      document.css('title').tap do |title_elements|
        expect(title_elements).to have(1).items
        expect(title_elements[0].text).to eq "#{page1.name} - #{site.name}"
      end
      document.css('link[rel="canonical"]').tap do |canonical_elements|
        expect(canonical_elements).to have(1).items
        expect(canonical_elements[0]["href"]).to eq Addressable::URI.join(site.full_root_url, page1.ical_link).to_s
      end
      document.css('body a').tap do |a_elements|
        expect(a_elements).to have(1).items
        expect(a_elements[0]["href"]).to eq page1.ical_link
      end
    end
  end
end
