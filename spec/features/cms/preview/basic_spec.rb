require 'spec_helper'

describe "cms_preview", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  category_part_node = nil

  context "with article page" do
    let(:node) { create :article_node_page, cur_site: site }
    let(:node_category_root) { create :category_node_node, cur_site: site }
    let(:node_category_child1) { create :category_node_page, cur_site: site, cur_node: node_category_root }
    let(:html) { '<h2>見出し2</h2><p>内容が入ります。</p><h3>見出し3</h3><p>内容が入ります。内容が入ります。</p>' }
    let(:item) { create(:article_page, cur_site: site, cur_node: node, html: html, category_ids: [ node_category_child1.id ]) }
    let(:pc_preview_path) { cms_preview_path(site: site, path: item.url[1..-1]) }
    let(:mobile_preview_path) { cms_preview_path(site: site, path: "#{site.mobile_location}#{item.url}"[1..-1]) }

    before { login_cms_user }

    context "pc preview" do
      it do
        visit pc_preview_path
        expect(page).to have_css('article.body')
        expect(page).to have_css('section.categories header')
        expect(page).to have_css('section.categories div ul li')
      end
    end

    context "mobile preview" do
      it do
        visit mobile_preview_path
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
    let(:faq_part_search) { create(:faq_part_search, cur_site: site, cur_node: node_faq_search) }
    let(:pc_preview_path) { cms_preview_path(site: site, path: node_root.url[1..-1]) }
    let(:mobile_preview_path) { cms_preview_path(site: site, path: "#{site.mobile_location}#{node_root.url}"[1..-1]) }

    before do
      category_part_node = create(
        :category_part_node,
        cur_site: site,
        cur_node: node_root,
        upper_html: '<nav id="category-list"><header><h2>#{parent.parent_name} > #{parent_name}</h2></header>',
        loop_html: '<article class="#{class} #{current}"><header><h3><a href="#{url}">#{name}</a></h3></header></article>',
        lower_html: '<footer>#{part_parent.parent_name} > #{part_parent_name} > #{part_name}</footer></nav>')

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

    context "pc preview" do
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
      end
    end

    context "mobile preview" do
      it do
        visit mobile_preview_path
        expect(page).to have_selector('title', count: 1)
        expect(page).to have_no_css('meta[charset=shift_jis]')
        expect(page).to have_css('div.category-nodes div.tag-article div h2', count: 2)
        expect(page).to have_css('div.faq-search form')
        expect(page).to have_css('div.category-nodes div#category-list')
        expect(page).to have_selector('h2', text: "#{node_root.name} > #{node_root.name}")
        expect(page).to have_selector('div', text: "#{node_root.name} > #{node_root.name} > #{category_part_node.name}")
        expect(page).to have_css("body[data-layout-id=\"#{node_root.layout_id}\"]")
        expect(page).to have_css("#ss-preview")
        expect(page).to have_no_css("#ss-preview .ss-preview-btn-togglea-inplace")
        expect(page).to have_no_css("#ss-preview #ss-preview-btn-create-new-page")
        expect(page).to have_no_css("#ss-preview #ss-preview-btn-select-draft-page")
        expect(page).to have_css("#ss-preview-overlay")
        expect(page).to have_css(".ss-preview-part[data-part-id=\"#{faq_part_search.id}\"] .faq-search")
      end
    end
  end

  context "with root cms page" do
    let(:item) { create(:cms_page, filename: "404.html", cur_site: site, html: html) }
    let(:html) { '<h2>見出し2</h2><p>内容が入ります。</p><h3>見出し3</h3><p>内容が入ります。内容が入ります。</p>' }

    let(:pc_preview_path) { cms_preview_path(site: site, path: item.url[1..-1]) }
    let(:mobile_preview_path) { cms_preview_path(site: site, path: "#{site.mobile_location}#{item.url}"[1..-1]) }

    before { login_cms_user }

    context "pc preview" do
      it do
        visit pc_preview_path
        expect(page).to have_css('article.body')
        expect(page).to have_text('見出し2')
        expect(page).to have_text('内容が入ります。')
      end
    end

    context "mobile preview" do
      it do
        visit mobile_preview_path
        expect(page).to have_css('div.tag-article')
        expect(page).to have_text('見出し2')
        expect(page).to have_text('内容が入ります。')
      end
    end
  end

  context "with sub site" do
    let!(:user) { cms_user }
    let!(:sub_site) { create(:cms_site_subdir, parent_id: site.id, group_ids: user.group_ids) }
    let!(:admin_role) { create(:cms_role_admin, cur_site: sub_site, site: sub_site, site_id: sub_site) }
    let!(:layout) { create_cms_layout(cur_site: sub_site, cur_user: user) }
    let!(:html) { '<h2 class="heading">見出し2</h2><p>内容が入ります。</p><h3>見出し3</h3><p>内容が入ります。内容が入ります。</p>' }
    let!(:item) { create(:cms_page, filename: "index.html", cur_site: sub_site, cur_user: user, layout: layout, html: html) }
    let!(:preview_time) { Time.zone.now.beginning_of_minute + 3.hours }

    before do
      user.add_to_set(cms_role_ids: admin_role.id)
      user.reload

      login_user user
    end

    it do
      visit cms_main_path(site: sub_site)

      new_window = nil
      within ".site-navi" do
        new_window = window_opened_by { click_on I18n.t("cms.preview_site") }
      end

      within_window new_window do
        expect(page).to have_css(".heading", text: "見出し2")

        within ".ss-preview-wrap" do
          # fill_in "#ss-preview-date", with: I18n.l(preview_time, format: :picker)
          first("#ss-preview-date").set(I18n.l(preview_time, format: :picker))
          click_on "PC"
        end

        expect(page).to have_css(".heading", text: "見出し2")
      end
    end
  end
end
