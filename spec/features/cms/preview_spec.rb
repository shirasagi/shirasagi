require 'spec_helper'

describe "cms_preview", type: :feature, dbscope: :example do
  let(:site) { cms_site }

  context "with article page" do
    let(:node) { create :article_node_page, cur_site: site }
    let(:node_category_root) { create :category_node_node, cur_site: site }
    let(:node_category_child1) { create :category_node_page, cur_site: site, cur_node: node_category_root }
    let(:html) { '<h2>見出し2</h2><p>内容が入ります。</p><h3>見出し3</h3><p>内容が入ります。内容が入ります。</p>' }
    let(:item) { create(:article_page, cur_site: site, cur_node: node, html: html, category_ids: [ node_category_child1.id ]) }
    let(:pc_preview_path) { "#{cms_preview_path(site: site)}#{item.url}" }
    let(:mobile_preview_path) { "#{cms_preview_path(site: site)}#{site.mobile_location}#{item.url}" }

    before { login_cms_user }

    context "pc preview" do
      it do
        visit pc_preview_path
        expect(page).to have_css('header.released time')
        expect(page).to have_css('article.body')
        expect(page).to have_css('section.categories header')
        expect(page).to have_css('section.categories div ul li')
      end
    end

    context "mobile preview" do
      it do
        visit mobile_preview_path
        expect(page).to have_css('div.tag-header span.tag-time')
        expect(page).to have_css('div.tag-article')
        expect(page).to have_css('div.categories div h2')
        expect(page).to have_css('div.categories div.nodes ul li')
      end
    end
  end

  context "with category list node" do
    let(:node_root) { create :category_node_node, cur_site: site }
    let!(:node_child1) { create :category_node_node, cur_site: site, cur_node: node_root }
    let!(:node_child2) { create :category_node_node, cur_site: site, cur_node: node_root }
    let!(:node_faq_search) { create :faq_node_search, cur_site: site, cur_node: node_root }
    let(:pc_preview_path) { "#{cms_preview_path(site: site)}#{node_root.url}" }
    let(:mobile_preview_path) { "#{cms_preview_path(site: site)}#{site.mobile_location}#{node_root.url}" }

    before do
      faq_part_search = create(:faq_part_search, cur_site: site, cur_node: node_faq_search)
      category_part_node = create(
        :category_part_node,
        cur_site: site,
        cur_node: node_root,
        upper_html: '<nav id="category-list"><header><h2>カテゴリー一覧</h2></header>',
        loop_html: '<article class="#{class} #{current}"><header><h3><a href="#{url}">#{name}</a></h3></header></article>',
        lower_html: '</nav>')

      layout_html = ''
      layout_html << '<html><body>'
      layout_html << "{{ part \"#{faq_part_search.url.sub(/^\//, '').sub(/.part.html$/, '')}\" }}"
      layout_html << '{{ yield }}'
      layout_html << "{{ part \"#{category_part_node.url.sub(/^\//, '').sub(/.part.html$/, '')}\" }}"
      layout_html << '</body></html>'

      layout = create(:cms_layout, html: layout_html)
      node_root.layout_id = layout.id
      node_root.save!
    end

    before { login_cms_user }

    context "pc preview" do
      it do
        visit pc_preview_path
        expect(page).to have_css('div.category-nodes article header h2', count: 2)
        expect(page).to have_css('div.faq-search form')
        expect(page).to have_css('div.category-nodes nav#category-list')
      end
    end

    context "mobile preview" do
      it do
        visit mobile_preview_path
        expect(page).to have_css('div.category-nodes div.tag-article div h2', count: 2)
        expect(page).to have_css('div.faq-search form')
        expect(page).to have_css('div.category-nodes div#category-list')
      end
    end
  end
end
