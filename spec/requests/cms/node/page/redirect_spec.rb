require 'spec_helper'

describe Cms::Agents::Nodes::PageController, type: :request, dbscope: :example do
  let!(:site) do
    site = cms_site
    site.update!(redirect_link_state: "enabled")
    site
  end
  let!(:user) { cms_user }
  let!(:layout) { create_cms_layout }

  context "with node" do
    let!(:node1) { create :cms_node_page, cur_site: site, layout: layout, redirect_link: "/#{unique_id}.pdf" }

    context "when generated nodes are not existed" do
      before do
        Fs.rm_rf node1.path
      end

      it do
        full_url = Addressable::URI.join(site.full_root_url, "#{node1.filename}/").to_s
        get full_url
        expect(response.status).to eq 302
        expect(response.location).to end_with Addressable::URI.join(site.full_root_url, node1.redirect_link).to_s
      end
    end

    context "when generated nodes are existed" do
      before do
        expect { Cms::Node::GenerateJob.bind(site_id: site.id).perform_now }.to output(include(node1.url)).to_stdout
        expect(File.size("#{node1.path}/index.html")).to be>0
      end

      it do
        full_url = Addressable::URI.join(site.full_root_url, "#{node1.filename}/index.html").to_s
        get full_url
        expect(response.status).to eq 200
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
  end
end
