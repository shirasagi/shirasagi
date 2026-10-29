require 'spec_helper'

describe Cms::Node::GenerateJob, dbscope: :example do
  let(:today) { Time.zone.today }
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout cur_site: site }
  let!(:node1) { create :article_node_page, cur_site: site, layout: layout }
  let!(:page1) { create :article_page, cur_site: site, cur_node: node1, layout: layout }
  let!(:node1_1) { create :cms_node_archive, cur_site: site, cur_node: node1, layout: layout }

  before do
    Fs.rm_rf node1.path
    Fs.rm_rf node1_1.path

    # expect { described_class.bind(site_id: site.id).perform_now }.to output(include(node1.url)).to_stdout
    described_class.bind(site_id: site.id).perform_now

    expect(Job::Log.all.count).to eq 1
    Job::Log.all.each do |log|
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
    end
  end

  it do
    expect(File.exist?("#{node1_1.path}/index.html")).to be_truthy
    document = Nokogiri::HTML5.parse(File.read("#{node1_1.path}/index.html"))
    document.css('meta[http-equiv="refresh"]').tap do |meta_elements|
      expect(meta_elements).to have(1).items
      expect(meta_elements[0]["content"]).to include("#{node1_1.full_url}#{today.strftime('%Y%m')}/")
    end
    document.css('title').tap do |title_elements|
      expect(title_elements).to have(1).items
      expect(title_elements[0].text).to eq "#{node1_1.name} - #{site.name}"
    end
    document.css('link[rel="canonical"]').tap do |canonical_elements|
      expect(canonical_elements).to have(1).items
      expect(canonical_elements[0]["href"]).to eq node1_1.full_url
    end
    document.css('body a').tap do |a_elements|
      expect(a_elements).to have(1).items
      expect(a_elements[0]["href"]).to eq "#{node1_1.full_url}#{today.strftime('%Y%m')}/"
    end
  end
end
