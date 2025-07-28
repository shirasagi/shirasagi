require 'spec_helper'

describe "cms_preview", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }

  context "with category node node" do
    let(:category_part_node) do
      create(:category_part_node,
        cur_site: site,
        cur_node: node_root,
        upper_html: '<nav id="category-list"><header><h2>#{parent.parent_name} > #{parent_name}</h2></header>',
        loop_html: '<article class="#{class} #{current}"><header><h3><a href="#{url}">#{name}</a></h3></header></article>',
        lower_html: '<footer>#{part_parent.parent_name} > #{part_parent_name} > #{part_name}</footer></nav>'
      )
    end
    let(:node_root) { create :category_node_node, cur_site: site }
    let!(:node_child1) { create :category_node_node, cur_site: site, cur_node: node_root }
    let!(:node_child2) { create :category_node_node, cur_site: site, cur_node: node_root }
    let!(:node_faq_search) { create :faq_node_search, cur_site: site, cur_node: node_root }
    let(:faq_part_search) { create(:faq_part_search, cur_site: site, cur_node: node_faq_search) }
    let(:pc_preview_path) { cms_preview_path(site: site, path: node_root.url[1..-1]) }

    before do
      layout_html = ''
      layout_html << '<html><body>'
      layout_html << "<title>#{cms_site.name}</title>"
      layout_html << '<meta charset="shift_jis" />'
      layout_html << "{{ part \"#{faq_part_search.url.sub(/^\//, '').sub(/.part.html$/, '')}\" }}"
      layout_html << '{{ yield }}'
      layout_html << "{{ part \"#{category_part_node.url.sub(/^\//, '').sub(/.part.html$/, '')}\" }}"
      layout_html << '</body></html>'

      layout = create(:cms_layout, html: layout_html)
      node_root.layout_id = layout.id
      node_root.save!
    end

    before { login_cms_user }

    it do
      visit pc_preview_path
      expect(page).to have_selector('title', count: 1)
      expect(page).to have_css('meta[charset]', count: 1)
      expect(page).to have_css('div.category-nodes article header h2', count: 2)
      expect(page).to have_css('div.faq-search form')
      expect(page).to have_css('div.category-nodes nav#category-list')
      expect(page).to have_selector('h2', text: "#{node_root.name} > #{node_root.name}")
      expect(page).to have_selector('footer', text: "#{node_root.name} > #{node_root.name} > #{category_part_node.name}")
      expect(page).to have_css("body[data-layout-id=\"#{node_root.layout_id}\"]")
      expect(page).to have_css("#ss-preview")
      expect(page).to have_css("#ss-preview .ss-preview-btn-toggle-inplace")
      expect(page).to have_css("#ss-preview #ss-preview-btn-create-new-page")
      expect(page).to have_css("#ss-preview #ss-preview-btn-select-draft-page")
      expect(page).to have_css("#ss-preview-overlay")
      expect(page).to have_css(".ss-preview-part[data-part-id=\"#{faq_part_search.id}\"] .faq-search")

      click_button I18n.t("ss.buttons.new")
      switch_to_window(windows.last)
      wait_for_document_loading

      expect(current_path).to eq new_category_node_path(site: site, cid: node_root.id)
    end
  end

  context "with category node page" do
    let(:node_root) { create :category_node_page, cur_site: site }
    let(:pc_preview_path) { cms_preview_path(site: site, path: node_root.url[1..-1]) }

    before do
      layout_html = ''
      layout_html << '<html><body>'
      layout_html << "<title>#{cms_site.name}</title>"
      layout_html << '<meta charset="shift_jis" />'
      layout_html << '{{ yield }}'
      layout_html << '</body></html>'

      layout = create(:cms_layout, html: layout_html)
      node_root.layout_id = layout.id
      node_root.save!
    end

    before { login_cms_user }

    it do
      visit pc_preview_path
      expect(page).to have_selector('title', count: 1)
      expect(page).to have_css('meta[charset]', count: 1)
      expect(page).to have_css("body[data-layout-id=\"#{node_root.layout_id}\"]")
      expect(page).to have_css("#ss-preview")
      expect(page).to have_css("#ss-preview .ss-preview-btn-toggle-inplace")
      expect(page).to have_css("#ss-preview #ss-preview-btn-create-new-page")
      expect(page).to have_css("#ss-preview #ss-preview-btn-select-draft-page")
      expect(page).to have_css("#ss-preview-overlay")

      click_button I18n.t("ss.buttons.new")
      switch_to_window(windows.last)
      wait_for_document_loading

      expect(current_path).to eq new_category_node_path(site: site, cid: node_root.id)
    end
  end

  context "with article node page" do
    let(:node_root) { create :article_node_page, cur_site: site }
    let(:pc_preview_path) { cms_preview_path(site: site, path: node_root.url[1..-1]) }

    before do
      layout_html = ''
      layout_html << '<html><body>'
      layout_html << "<title>#{cms_site.name}</title>"
      layout_html << '<meta charset="shift_jis" />'
      layout_html << '{{ yield }}'
      layout_html << '</body></html>'

      layout = create(:cms_layout, html: layout_html)
      node_root.layout_id = layout.id
      node_root.save!
    end

    before { login_cms_user }

    it do
      visit pc_preview_path
      expect(page).to have_selector('title', count: 1)
      expect(page).to have_css('meta[charset]', count: 1)
      expect(page).to have_css("body[data-layout-id=\"#{node_root.layout_id}\"]")
      expect(page).to have_css("#ss-preview")
      expect(page).to have_css("#ss-preview .ss-preview-btn-toggle-inplace")
      expect(page).to have_css("#ss-preview #ss-preview-btn-create-new-page")
      expect(page).to have_css("#ss-preview #ss-preview-btn-select-draft-page")
      expect(page).to have_css("#ss-preview-overlay")

      click_button I18n.t("ss.buttons.new")
      switch_to_window(windows.last)
      wait_for_document_loading

      expect(current_path).to eq new_article_page_path(site: site, cid: node_root.id)
    end
  end
end
