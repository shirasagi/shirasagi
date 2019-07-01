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
          page.first("#addon-cms-agents-addons-body .preview").click
        end

        within_window(windows.last) do
          expect(page).to have_selector('h2', text: '見出し2')
          expect(page).to have_selector('p', text: '内容が入ります。')
          expect(page).to have_selector('h3', text: '見出し3')
          expect(page).to have_selector('p', text: '内容が入ります。内容が入ります。')
          expect(page).to have_selector('h2', text: 'カテゴリー')
        end
      end
    end
  end

  context "with cms page" do
    let(:html) { '<p>お探しのページは見つかりませんでした。<br />一時的にアクセスできない状態になっているか、URLが変更・削除されたのかもしれません。</p>' }
    let!(:item) { create(:cms_page, cur_site: site, filename: '404.html', html: html) }
    let(:edit_path) { edit_cms_page_path site.id, item }

    before { login_cms_user }

    context "pc form preview", js: true do
      it do
        visit edit_path

        within "form#item-form" do
          page.first("#addon-cms-agents-addons-body .preview").click
        end

        within_window(windows.last) do
          expect(page).to have_content('お探しのページは見つかりませんでした。')
          expect(page).to have_content('一時的にアクセスできない状態になっているか、URLが変更・削除されたのかもしれません。')
        end
      end
    end
  end
end
