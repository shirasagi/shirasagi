require 'spec_helper'

describe "workflow_branch", dbscope: :example do
  subject(:site) { cms_site }
  subject(:item) { create_once :article_page, filename: "docs/page.html", name: "[TEST] br_page" }
  subject(:node) { create_once :article_node_page, filename: "docs", name: "article" }
  subject(:index_path) { article_pages_path site.host, node }
  subject(:show_path) { article_page_path site.host, node, item }

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    context "branch", js: true do
      it "#branch_create" do
        visit show_path
        click_button "差し替えページを作成する"
        wait_for_ajax

        click_link("[TEST] br_page")
        expect(page).to have_css("#addon-cms-agents-addons-release", :text => "非公開")
        br_show_path = current_path

        click_link("編集する")
        br_edit_path = current_path
        within "form#item-form" do
          fill_in "item[name]", with: "[TEST] br_replace"
          click_button "下書き保存"
        end
        wait_for_ajax
        if current_path == br_edit_path
          click_button "警告を無視する"
        end
        expect(current_path).to eq br_show_path
        expect(page).to have_css("#addon-cms-agents-addons-release", :text => "非公開")

        master = Article::Page.where(name: "[TEST] br_page").first
        branch = Article::Page.where(name: "[TEST] br_replace").first
        expect(master).not_to eq(nil)
        expect(master.branches).not_to eq([])
        expect(branch).not_to eq(nil)
        expect(master.branches.first.id).to eq(branch.id)
        master_id = master.id
        branch_id = branch.id

        click_link("編集する")
        br_edit_path = current_path
        within "form#item-form" do
          click_button "公開保存"
        end
        wait_for_ajax
        if current_path == br_edit_path
          click_button "警告を無視する"
        end
        expect(current_path).to eq index_path

        master = Article::Page.where(id: master_id).first
        branch = Article::Page.where(id: branch_id).first
        expect(master).not_to eq(nil)
        expect(branch).to eq(nil)

        visit show_path
        expect(page).to have_css("#addon-basic", :text => "[TEST] br_replace")
        expect(page).not_to have_css("#addon-cms-agents-addons-release", :text => "非公開")
      end
    end
  end
end
