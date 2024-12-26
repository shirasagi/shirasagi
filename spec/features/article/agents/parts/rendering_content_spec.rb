require 'spec_helper'

describe "article_agents_parts_page", type: :feature, dbscope: :example, js: true do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout part }

  shared_examples "Liquid テンプレート内で page や node を通じて現在レンダリング中のページかフォルダーかを取得できる" do
    let(:prefix) { unique_id }
    let!(:part) do
      loop_liquid = <<~HTML
        <div class="#{prefix}">
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
        </div>
      HTML
      create :article_part_page, cur_site: site, ajax_view: ajax_view, loop_format: "liquid", loop_liquid: loop_liquid
    end
    let!(:node) { create :article_node_page, cur_site: site, layout: layout }
    let!(:doc1) { create :article_page, cur_site: site, cur_node: node, layout: layout }

    before do
      Cms::Page.all.each { |page| FileUtils.rm_f(page.path) }
    end

    context "with node" do
      it do
        visit node.full_url
        expect(page).to have_css(".#{prefix}")
        expect(page).to have_css(".#{prefix}-node[data-id='#{node.id}']", text: node.name)
        expect(page).to have_no_css(".#{prefix}-page")
      end
    end

    context "with page" do
      it do
        visit doc1.full_url
        expect(page).to have_css(".#{prefix}")
        expect(page).to have_css(".#{prefix}-page[data-id='#{doc1.id}']", text: doc1.name)
        expect(page).to have_no_css(".#{prefix}-node")
      end
    end
  end

  context "when 'ajax_view' is disabled" do
    let(:ajax_view) { [ nil, "disabled" ].sample }
    it_behaves_like "Liquid テンプレート内で page や node を通じて現在レンダリング中のページかフォルダーかを取得できる"
  end

  context "when 'ajax_view' is enabled" do
    let(:ajax_view) { "enabled" }
    it_behaves_like "Liquid テンプレート内で page や node を通じて現在レンダリング中のページかフォルダーかを取得できる"
  end
end
