require 'spec_helper'

describe "cms_form_preview", type: :feature, dbscope: :example do
  let(:site) { cms_site }

  context "with article page" do
    let(:node) { create :article_node_page, cur_site: site }
    let(:node_category_root) { create :category_node_node, cur_site: site }
    let(:node_category_child1) { create :category_node_page, cur_site: site, cur_node: node_category_root }
    let(:html) { '<h2>見出し2</h2><p>内容が入ります。</p><h3>見出し3</h3><p>内容が入ります。内容が入ります。</p>' }
    let(:item) { create(:article_page, cur_site: site, cur_node: node, html: html, category_ids: [ node_category_child1.id ]) }
    let(:edit_path) { edit_article_page_path site.id, node.id, item }

    before { login_cms_user }

    context "pc form preview", js: true do
      it do
        visit edit_path

        within "form#item-form" do
          fill_in "item[name]", with: "sample"
          fill_in "item[basename]", with: "sample"
          page.first("#addon-cms-agents-addons-body .preview").click
        end

        handle = page.driver.browser.window_handles.last
        page.driver.browser.within_window(handle) do
          expect(page.html.include?('<h2>見出し2</h2>')).to be_truthy
          expect(page.html.include?('<p>内容が入ります。</p>')).to be_truthy
          expect(page.html.include?('<h3>見出し3</h3>')).to be_truthy
          expect(page.html.include?('<p>内容が入ります。内容が入ります。</p>')).to be_truthy
          expect(page.html.include?('<header><h2>カテゴリー</h2></header>')).to be_truthy
        end
      end
    end
  end
end
