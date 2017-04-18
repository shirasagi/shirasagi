require 'spec_helper'

describe "workflow_branch", dbscope: :example do
  let!(:site) { cms_site }
  let!(:item) { create_once :article_page, filename: "docs/page.html", name: "[TEST] br_page" }
  let!(:node) { create_once :article_node_page, filename: "docs", name: "article" }
  let(:index_path) { article_pages_path site.id, node }
  let(:show_path) { article_page_path site.id, node, item }

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    context "branch", js: true, fragile: true do
      it "#branch_create" do
        visit show_path
        click_button "差し替えページを作成する"

        click_link("[TEST] br_page")
        click_link("編集する")
        within "form#item-form" do
          fill_in "item[name]", with: "[TEST] br_replace"
          click_button "下書き保存"
        end
        expect(page).to have_css("#notice", text: "保存しました。", wait: 60)

        master = Article::Page.where(name: "[TEST] br_page").first
        branch = Article::Page.where(name: "[TEST] br_replace").first
        expect(master).not_to be_nil
        expect(master.state).to eq "public"
        expect(branch).not_to be_nil
        expect(branch.state).to eq "closed"
        expect(master.branches.first.id).to eq(branch.id)
        master_id = master.id
        branch_id = branch.id

        click_link("編集する")
        within "form#item-form" do
          click_button "公開保存"
        end
        expect(page).to have_css("#notice", text: "保存しました。", wait: 60)

        master = Article::Page.where(id: master_id).first
        branch = Article::Page.where(id: branch_id).first
        expect(master).not_to be_nil
        expect(master.name).to eq "[TEST] br_replace"
        expect(master.state).to eq "public"
        expect(branch).to be_nil
      end
    end
  end
end
