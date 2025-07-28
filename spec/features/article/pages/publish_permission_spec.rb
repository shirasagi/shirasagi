require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:admin) { cms_user }
  let!(:minimum_publish_permissions) do
    %w(read_private_cms_nodes read_private_article_pages edit_private_article_pages release_private_article_pages)
  end
  let!(:minimum_publish_role) do
    create :cms_role, cur_site: site, name: "role-#{unique_id}", permissions: minimum_publish_permissions
  end
  let!(:user1) { create :cms_test_user, group_ids: admin.group_ids, cms_role_ids: [ minimum_publish_role.id ] }
  let!(:node) { create :article_node_page, cur_site: site, cur_user: admin, group_ids: admin.group_ids }
  let!(:page1) do
    create :article_page, cur_site: site, cur_user: admin, cur_node: node, group_ids: admin.group_ids, state: "closed"
  end

  context "with minimum publish permissions" do
    context "when page is published in edit view" do
      let!(:minimum_publish_permissions) do
        %w(read_private_cms_nodes read_private_article_pages edit_private_article_pages release_private_article_pages)
      end

      it do
        login_user user1
        visit article_pages_path(site: site, cid: node)
        expect(page).to have_css(".list-item[data-id='#{page1.id}']", text: page1.name)

        click_on page1.name
        wait_for_all_ckeditors_ready
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

        click_on I18n.t("ss.links.edit")
        wait_for_all_ckeditors_ready
        within "form#item-form" do
          click_on I18n.t("ss.buttons.publish_save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        Article::Page.find(page1.id).tap do |after_page|
          expect(after_page.state).to eq "public"
        end
      end
    end

    context "when page is published in index view" do
      let!(:minimum_publish_permissions) do
        %w(read_private_cms_nodes read_private_article_pages edit_private_article_pages release_private_article_pages)
      end

      it do
        login_user user1
        visit article_pages_path(site: site, cid: node)
        expect(page).to have_css(".list-item[data-id='#{page1.id}']", text: page1.name)

        within ".list-item[data-id='#{page1.id}']" do
          first("[type='checkbox']").click
        end
        within ".list-head" do
          expect(page).to have_content(I18n.t("ss.links.make_them_public"))
          click_on I18n.t("ss.links.make_them_public")
        end

        within "form" do
          expect(page).to have_css("[data-id='#{page1.id}'] [type='checkbox']")
          click_on I18n.t("ss.links.make_them_public")
        end
        wait_for_notice I18n.t("ss.notice.published")

        Article::Page.find(page1.id).tap do |after_page|
          expect(after_page.state).to eq "public"
        end
      end
    end
  end

  context "when page is linked from other pages" do
    let!(:page2) do
      create :article_page, cur_site: site, cur_user: admin, cur_node: node, group_ids: admin.group_ids, state: "closed"
    end
    let!(:link_page) do
      create :article_page, cur_site: site, cur_user: admin, cur_node: node, group_ids: admin.group_ids, state: "public",
        html: "<a href=\"#{page1.url}\">#{page1.name}</a>"
    end

    context "with minimum publish permissions and contains links in file" do
      let!(:minimum_publish_permissions) do
        %w(read_private_cms_nodes read_private_article_pages edit_private_article_pages release_private_article_pages)
      end

      it "cannot publish page in edit view without ignore_alert permission when linked from block" do
        login_user user1
        visit article_pages_path(site: site, cid: node)
        expect(page).to have_css(".list-item[data-id='#{page1.id}']", text: page1.name)

        click_on page1.name
        wait_for_all_ckeditors_ready
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

        click_on I18n.t("ss.links.edit")
        wait_for_all_ckeditors_ready
        within "form#item-form" do
          click_on I18n.t("ss.buttons.publish_save")
        end

        within "#menu" do
          click_on I18n.t("article.page_navi.back_to_index")
        end

        visit article_pages_path(site: site, cid: node)
        expect(page).to have_css(".list-item[data-id='#{page1.id}']", text: page1.name)

        Article::Page.find(page1.id).tap do |after_page|
          expect(after_page.state).to eq "public"
        end
      end

      it "cannot publish page in edit view without ignore_alert permission" do
        login_user user1
        visit article_pages_path(site: site, cid: node)
        expect(page).to have_css(".list-item[data-id='#{page1.id}']", text: page1.name)

        click_on page1.name
        wait_for_all_ckeditors_ready
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

        click_on I18n.t("ss.links.edit")
        wait_for_all_ckeditors_ready
        within "form#item-form" do
          click_on I18n.t("ss.buttons.publish_save")
        end

        within "#menu" do
          click_on I18n.t("article.page_navi.back_to_index")
        end

        Article::Page.find(page1.id).tap do |after_page|
          expect(after_page.state).to eq "public"
        end
      end

      it "cannot publish page in index view" do
        login_user user1
        visit article_pages_path(site: site, cid: node)
        expect(page).to have_css(".list-item[data-id='#{page1.id}']", text: page1.name)

        within ".list-item[data-id='#{page1.id}']" do
          first("[type='checkbox']").click
        end

        expect(page).to have_content(I18n.t("ss.links.make_them_public"))

        within ".list-head" do
          first("button, input[type='button']", text: I18n.t("ss.links.make_them_public")).click
        end

        within "form" do
          expect(page).to have_css("[data-id='#{page1.id}'] [type='checkbox']")
          click_on I18n.t("ss.links.make_them_public")
        end

        visit article_pages_path(site: site, cid: node)
        expect(page).to have_css(".list-item[data-id='#{page1.id}']", text: page1.name)

        Article::Page.find(page1.id).tap do |after_page|
          expect(after_page.state).to eq "public"
        end
      end
    end

    context "with ignore_alert permission and contains links in file" do
      let!(:minimum_publish_permissions) do
        %w(read_private_cms_nodes read_private_article_pages edit_private_article_pages release_private_article_pages)
      end

      it "can publish page in edit view without ignore_alert permission" do
        login_user user1
        visit article_pages_path(site: site, cid: node)
        expect(page).to have_css(".list-item[data-id='#{page1.id}']", text: page1.name)

        click_on page1.name
        wait_for_all_ckeditors_ready
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

        click_on I18n.t("ss.links.edit")
        wait_for_all_ckeditors_ready
        within "form#item-form" do
          click_on I18n.t("ss.buttons.publish_save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        visit article_pages_path(site: site, cid: node)
        expect(page).to have_css(".list-item[data-id='#{page1.id}']", text: page1.name)

        Article::Page.find(page1.id).tap do |after_page|
          expect(after_page.state).to eq "public"
        end
      end
      # 被リンクがある記事は一括公開操作が可能
      it "can publish page in index view without ignore_alert permission" do
        login_user user1
        visit article_pages_path(site: site, cid: node)
        expect(page).to have_css(".list-item[data-id='#{page1.id}']", text: page1.name)

        within ".list-item[data-id='#{page1.id}']" do
          first("[type='checkbox']").click
        end

        expect(page).to have_content(I18n.t("ss.links.make_them_public"))

        within ".list-head" do
          first("button, input[type='button']", text: I18n.t("ss.links.make_them_public")).click
        end

        within "form" do
          expect(page).to have_css("[data-id='#{page1.id}'] [type='checkbox']")
          click_on I18n.t("ss.links.make_them_public")
        end

        wait_for_notice I18n.t("ss.notice.published")

        Article::Page.find(page1.id).tap do |after_page|
          expect(after_page.state).to eq "public"
        end
      end
    end
  end

  # アクセシビリティエラーがあるページを一括公開する
  context "when page is closed with accessibility error" do
    let!(:page_with_accessibility_error) do
      create :article_page, cur_site: site, cur_user: admin, cur_node: node, group_ids: admin.group_ids, state: "closed",
        html: "<img src=\"image.jpg\">"
    end
    # 「警告を無視して保存する」権限なし
    context "without ignore syntax check permission" do
      let!(:minimum_publish_permissions) do
        %w(read_private_cms_nodes read_private_article_pages edit_private_article_pages release_private_article_pages)
      end

      it "cannot publish page in index view when contains accessibility error" do
        login_user user1
        visit article_pages_path(site: site, cid: node)
        expect(page).to have_css(".list-item[data-id='#{page_with_accessibility_error.id}']",
        text: page_with_accessibility_error.name)

        within ".list-item[data-id='#{page_with_accessibility_error.id}']" do
          first("[type='checkbox']").click
        end
        within ".list-head" do
          expect(page).to have_content(I18n.t("ss.links.make_them_public"))
          first("button, input[type='button']", text: I18n.t("ss.links.make_them_public")).click
        end

        within "form" do
          expect(page).to have_no_css("[data-id='#{page_with_accessibility_error.id}'] [type='checkbox']")
          expect(page).to have_content(I18n.t("errors.messages.check_html"))
        end

        visit article_pages_path(site: site, cid: node)
        expect(page).to have_css(".list-item[data-id='#{page_with_accessibility_error.id}']")

        Article::Page.find(page_with_accessibility_error.id).tap do |after_page|
          expect(after_page.state).to eq "closed"
        end
      end
    end
    # 「警告を無視して保存する」権限あり
    context "with ignore syntax check permission" do
      let!(:minimum_publish_permissions) do
        %w(read_private_cms_nodes read_private_article_pages edit_private_article_pages release_private_article_pages
           edit_cms_ignore_syntax_check)
      end

      it "can publish page in index view when contains accessibility error" do
        login_user user1
        visit article_pages_path(site: site, cid: node)
        expect(page).to have_css(".list-item[data-id='#{page_with_accessibility_error.id}']",
          text: page_with_accessibility_error.name)

        within ".list-item[data-id='#{page_with_accessibility_error.id}']" do
          first("[type='checkbox']").click
        end
        within ".list-head" do
          expect(page).to have_content(I18n.t("ss.links.make_them_public"))
          first("button, input[type='button']", text: I18n.t("ss.links.make_them_public")).click
        end

        within "form" do
          expect(page).to have_css("[data-id='#{page_with_accessibility_error.id}'] [type='checkbox']")
          expect(page).to have_content(I18n.t("errors.messages.check_html"))
          first("[type='checkbox']").click
          click_on I18n.t("ss.links.make_them_public")
        end

        wait_for_notice I18n.t("ss.notice.published")

        Article::Page.find(page_with_accessibility_error.id).tap do |after_page|
          expect(after_page.state).to eq "public"
        end
      end
    end
  end
end
