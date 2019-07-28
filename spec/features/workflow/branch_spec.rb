require 'spec_helper'

describe "workflow_branch", dbscope: :example, js: true do
  let!(:site) { cms_site }

  context "cms page" do
    let!(:item) { create_once :cms_page, filename: "page.html", name: "[TEST] br_page" }
    let(:show_path) { cms_page_path site.id, item }

    context "basic branch crud" do
      before { login_cms_user }

      it do
        visit show_path
        click_button "差し替えページを作成する"

        click_link("[TEST] br_page")
        click_link("編集する")
        within "form#item-form" do
          fill_in "item[name]", with: "[TEST] br_replace"
          click_button "下書き保存"
        end
        expect(page).to have_css("#notice", text: "保存しました。", wait: 60)

        master = item.class.where(name: "[TEST] br_page").first
        branch = item.class.where(name: "[TEST] br_replace").first
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

        master = item.class.where(id: master_id).first
        branch = item.class.where(id: branch_id).first
        expect(master).not_to be_nil
        expect(master.name).to eq "[TEST] br_replace"
        expect(master.state).to eq "public"
        expect(branch).to be_nil
      end
    end
  end

  context "article page" do
    let!(:item) { create_once :article_page, filename: "docs/page.html", name: "[TEST] br_page" }
    let!(:node) { create_once :article_node_page, filename: "docs", name: "article" }
    let(:show_path) { article_page_path site.id, node, item }

    context "basic branch crud" do
      before { login_cms_user }

      it do
        visit show_path
        click_button "差し替えページを作成する"

        click_link("[TEST] br_page")
        click_link("編集する")
        within "form#item-form" do
          fill_in "item[name]", with: "[TEST] br_replace"
          click_button "下書き保存"
        end
        expect(page).to have_css("#notice", text: "保存しました。", wait: 60)

        master = item.class.where(name: "[TEST] br_page").first
        branch = item.class.where(name: "[TEST] br_replace").first
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

        master = item.class.where(id: master_id).first
        branch = item.class.where(id: branch_id).first
        expect(master).not_to be_nil
        expect(master.name).to eq "[TEST] br_replace"
        expect(master.state).to eq "public"
        expect(branch).to be_nil
      end
    end
  end

  context "faq page" do
    let!(:item) { create_once :faq_page, filename: "faq/page.html", name: "[TEST] br_page" }
    let!(:node) { create_once :faq_node_page, filename: "faq", name: "faq" }
    let(:index_path) { faq_pages_path site.id, node }
    let(:show_path) { faq_page_path site.id, node, item }

    context "basic branch crud" do
      before { login_cms_user }

      it do
        visit show_path
        click_button "差し替えページを作成する"

        click_link("[TEST] br_page")
        click_link("編集する")
        within "form#item-form" do
          fill_in "item[name]", with: "[TEST] br_replace"
          click_button "下書き保存"
        end
        expect(page).to have_css("#notice", text: "保存しました。", wait: 60)

        master = item.class.where(name: "[TEST] br_page").first
        branch = item.class.where(name: "[TEST] br_replace").first
        expect(master).not_to be_nil
        expect(master.state).to eq "public"
        expect(branch).not_to be_nil
        expect(branch.state).to eq "closed"
        expect(master.branches.first.id).to eq(branch.id)
        master_id = master.id
        branch_id = branch.id

        click_link("編集する")
        within "form#item-form" do
          submit_on "公開保存"
        end
        expect(page).to have_css("#notice", text: "保存しました。", wait: 60)

        master = item.class.where(id: master_id).first
        branch = item.class.where(id: branch_id).first
        expect(master).not_to be_nil
        expect(master.name).to eq "[TEST] br_replace"
        expect(master.state).to eq "public"
        expect(branch).to be_nil
      end
    end
  end

  context "event page" do
    let!(:item) { create_once :event_page, filename: "event/page.html", name: "[TEST] br_page" }
    let!(:node) { create_once :event_node_page, filename: "event", name: "event" }
    let(:show_path) { event_page_path site.id, node, item }

    context "basic branch crud" do
      before { login_cms_user }

      it do
        visit show_path
        click_button "差し替えページを作成する"

        click_link("[TEST] br_page")
        click_link("編集する")
        within "form#item-form" do
          fill_in "item[name]", with: "[TEST] br_replace"
          click_button "下書き保存"
        end
        expect(page).to have_css("#notice", text: "保存しました。", wait: 60)

        master = item.class.where(name: "[TEST] br_page").first
        branch = item.class.where(name: "[TEST] br_replace").first
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

        master = item.class.where(id: master_id).first
        branch = item.class.where(id: branch_id).first
        expect(master).not_to be_nil
        expect(master.name).to eq "[TEST] br_replace"
        expect(master.state).to eq "public"
        expect(branch).to be_nil
      end
    end
  end

  context "sitemap page" do
    let!(:item) { create_once :sitemap_page, filename: "sitemap/page.html", name: "[TEST] br_page" }
    let!(:node) { create_once :sitemap_node_page, filename: "sitemap", name: "sitemap" }
    let(:show_path) { sitemap_page_path site.id, node, item }

    context "basic branch crud" do
      before { login_cms_user }

      it do
        visit show_path
        click_button "差し替えページを作成する"

        click_link("[TEST] br_page")
        click_link("編集する")
        within "form#item-form" do
          fill_in "item[name]", with: "[TEST] br_replace"
          click_button "下書き保存"
        end
        expect(page).to have_css("#notice", text: "保存しました。", wait: 60)

        master = item.class.where(name: "[TEST] br_page").first
        branch = item.class.where(name: "[TEST] br_replace").first
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

        master = item.class.where(id: master_id).first
        branch = item.class.where(id: branch_id).first
        expect(master).not_to be_nil
        expect(master.name).to eq "[TEST] br_replace"
        expect(master.state).to eq "public"
        expect(branch).to be_nil
      end
    end
  end

  context "mail_page page" do
    let!(:item) { create_once :mail_page_page, filename: "mail/page.html", name: "[TEST] br_page" }
    let!(:node) { create_once :mail_page_node_page, filename: "mail", name: "mail" }
    let(:show_path) { mail_page_page_path site.id, node, item }

    context "basic branch crud" do
      before { login_cms_user }

      it do
        visit show_path
        click_button "差し替えページを作成する"

        click_link("[TEST] br_page")
        click_link("編集する")
        within "form#item-form" do
          fill_in "item[name]", with: "[TEST] br_replace"
          click_button "下書き保存"
        end
        expect(page).to have_css("#notice", text: "保存しました。", wait: 60)

        master = item.class.where(name: "[TEST] br_page").first
        branch = item.class.where(name: "[TEST] br_replace").first
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

        master = item.class.where(id: master_id).first
        branch = item.class.where(id: branch_id).first
        expect(master).not_to be_nil
        expect(master.name).to eq "[TEST] br_replace"
        expect(master.state).to eq "public"
        expect(branch).to be_nil
      end
    end
  end
end
