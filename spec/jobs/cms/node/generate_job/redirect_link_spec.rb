require 'spec_helper'

describe Cms::Node::GenerateJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout cur_site: site }
  let!(:node1) { create :cms_node_page, cur_site: site, layout: layout, redirect_link: "/#{unique_id}.pdf" }

  before do
    Fs.rm_rf node1.path

    site.update!(redirect_link_state: "enabled")

    expect { described_class.bind(site_id: site.id).perform_now }.to output(include(node1.url)).to_stdout

    expect(Job::Log.all.count).to eq 1
    Job::Log.all.each do |log|
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
    end
  end

  it do
    expect(File.exist?("#{node1.path}/index.html")).to be_truthy
    document = Nokogiri::HTML5.parse(File.read("#{node1.path}/index.html"))
    document.css('meta[http-equiv="refresh"]').tap do |meta_elements|
      expect(meta_elements).to have(1).items
      expect(meta_elements[0]["content"]).to include(node1.redirect_link)
    end
    document.css('title').tap do |title_elements|
      expect(title_elements).to have(1).items
      expect(title_elements[0].text).to eq "#{node1.name} - #{site.name}"
    end
    document.css('link[rel="canonical"]').tap do |canonical_elements|
      expect(canonical_elements).to have(1).items
      expect(canonical_elements[0]["href"]).to eq "#{Addressable::URI.join(site.full_root_url, node1.filename)}/"
    end
    document.css('body a').tap do |a_elements|
      expect(a_elements).to have(1).items
      expect(a_elements[0]["href"]).to eq node1.redirect_link
    end
  end
end
