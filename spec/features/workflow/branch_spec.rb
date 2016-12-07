require 'spec_helper'

describe "workflow_branch", dbscope: :example do
  subject(:site) { cms_site }
  subject(:item) { create_once :article_page, filename: "docs/page.html", name: "[TEST] br_page" }
  subject(:node) { create_once :article_node_page, filename: "docs", name: "article" }
  subject(:index_path) { article_pages_path site.id, node }
  subject(:show_path) { article_page_path site.id, node, item }

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

        click_link("[TEST] br_page")
        click_link("編集する")
        within "form#item-form" do
          fill_in "item[name]", with: "[TEST] br_replace"
          click_button "下書き保存"
        end
        expect(page).to have_css("#notice", text: "保存しました。")

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
