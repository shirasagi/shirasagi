require 'spec_helper'

describe Cms::Page::GenerateJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:layout) { create_cms_layout cur_site: site }
  let!(:node) { create :ads_node_banner, cur_site: site, layout: layout }
  let!(:page1) do
    page = create(:ads_banner, cur_site: site, cur_user: user, cur_node: node, layout: layout, state: 'public')
    page.set(link_url: "/#{unique_id}.pdf")
    Fs.rm_rf page.path
    page
  end

  describe "#perform without node" do
    before do
      Fs.rm_rf node.path
      Fs.rm_rf page1.path

      expect { described_class.bind(site_id: site.id).perform_now }.to output(include(page1.url)).to_stdout

      expect(Job::Log.all.count).to eq 1
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end
    end

    it do
      expect(File.exist?(page1.path)).to be_truthy
      document = Nokogiri::HTML5.parse(File.read(page1.path))
      document.css('meta[http-equiv="refresh"]').tap do |meta_elements|
        expect(meta_elements).to have(1).items
        expect(meta_elements[0]["content"]).to include(page1.link_url)
      end
      document.css('link[rel="canonical"]').tap do |canonical_elements|
        expect(canonical_elements).to have(1).items
        expect(canonical_elements[0]["href"]).to eq "#{page1.full_url}?redirect=#{page1.link_url}"
      end
      document.css('body a').tap do |a_elements|
        expect(a_elements).to have(1).items
        expect(a_elements[0]["href"]).to eq page1.link_url
      end
      document.css('body img').tap do |img_elements|
        expect(img_elements).to have(1).items
        expect(img_elements[0]["src"]).to eq page1.count_url
      end
    end
  end
end
