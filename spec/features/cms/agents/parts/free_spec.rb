require 'spec_helper'

describe "cms_agents_parts_free", type: :feature, dbscope: :example do
  let(:site) { cms_site }

  context "public" do
    let(:layout) { create_cms_layout [part] }
    let(:node)   { create :cms_node, layout_id: layout.id }
    let(:part)   { create :cms_part_free, html: '<span id="test-part"></span>' }

    it "#index" do
      visit node.full_url
      expect(status_code).to eq 200
      expect(page).to have_css("#test-part")
    end
  end

  context "part inside <head>" do
    let(:part) { create :cms_part_free, html: '<meta name="foo" content="bar" />' }
    let(:html) do
      html = []
      html << "<html><head>"
      html << "{{ part \"#{part.filename.sub(/\..*/, '')}\" }}"
      html << "</head><body></body><html>"
      html.join("\n")
    end
    let(:layout) { create :cms_layout, html: html }
    let(:node) { create :cms_node, layout_id: layout.id }

    it "#index" do
      visit node.full_url
      expect(status_code).to eq 200
      expect(page).to have_xpath("//meta[@name='foo']")
    end
  end

  context "deprecated style" do
    let(:part) { create :cms_part_free, html: '<span id="test-part"></span>' }
    let(:html) do
      html = []
      html << "<html><body>"
      html << "</ part \"#{part.filename.sub(/\..*/, '')}\" />"
      html << "</body><html>"
      html.join("\n")
    end
    let(:layout) { create :cms_layout, html: html }
    let(:node) { create :cms_node, layout_id: layout.id }

    it "#index" do
      visit node.full_url
      expect(status_code).to eq 200
      expect(page).to have_css("#test-part")
    end
  end
end
