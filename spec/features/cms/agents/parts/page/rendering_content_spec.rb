require 'spec_helper'

describe "cms_agents_parts_page", type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout part }

  describe "Liquid テンプレート内で page や node を通じて現在レンダリング中のページかフォルダーかを取得できる" do
    let(:prefix) { unique_id }
    let!(:part) do
      loop_liquid = <<~HTML
        {% if page %}
          <div class="#{prefix}-page" data-id="{{ page.id }}">
            {{ page.name }}
          </div>
        {% endif %}
        {% if node %}
          <div class="#{prefix}-node" data-id="{{ node.id }}">
            {{ node.name }}
          </div>
        {% endif %}
      HTML
      create :cms_part_page, cur_site: site, loop_format: "liquid", loop_liquid: loop_liquid
    end
    let!(:node) { create :cms_node_page, cur_site: site, layout: layout }
    let!(:doc1) { create :cms_page, cur_site: site, cur_node: node, layout: layout }

    before do
      Cms::Page.all.each { |page| ::FileUtils.rm_f(page.path) }
    end

    context "with node" do
      it do
        visit node.full_url
        expect(page).to have_css(".#{prefix}-node[data-id='#{node.id}']", text: node.name)
        expect(page).to have_no_css(".#{prefix}-page")
      end
    end

    context "with page" do
      it do
        visit doc1.full_url
        expect(page).to have_css(".#{prefix}-page[data-id='#{doc1.id}']", text: doc1.name)
        expect(page).to have_no_css(".#{prefix}-node")
      end
    end
  end
end
