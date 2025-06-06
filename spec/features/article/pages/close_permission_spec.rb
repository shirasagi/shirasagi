require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:admin) { cms_user }
  let!(:minimum_close_role) do
    create :cms_role, cur_site: site, name: "role-#{unique_id}", permissions: minimum_close_permissions
  end
  let!(:user1) { create :cms_test_user, group_ids: admin.group_ids, cms_role_ids: [ minimum_close_role.id ] }
  let!(:node) { create :article_node_page, cur_site: site, cur_user: admin, group_ids: admin.group_ids }
  let!(:page1) do
    create :article_page, cur_site: site, cur_user: admin, cur_node: node, group_ids: admin.group_ids, state: "public"
  end

  context "with minimum close permissions" do
    context "when page is closed in edit view" do
      let!(:minimum_close_permissions) do
        %w(read_private_cms_nodes read_private_article_pages edit_private_article_pages close_private_article_pages)
      end

      it do
        login_user user1
        visit article_pages_path(site: site, cid: node)
        expect(page).to have_css(".list-item[data-id='#{page1.id}']", text: page1.name)

        click_on page1.name
        # wait_for_all_ckeditors_ready
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

        click_on I18n.t("ss.links.edit")
        # wait_for_all_ckeditors_ready
        within "form#item-form" do
          wait_for_cbox_opened { click_on I18n.t("ss.buttons.withdraw") }
        end
        within_cbox do
          expect(page).to have_content(I18n.t("cms.confirm.close"))
          click_on I18n.t("ss.buttons.ignore_alert")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        Article::Page.find(page1.id).tap do |after_page|
          expect(after_page.state).to eq "closed"
        end
      end
    end

    context "when page is closed in index view" do
      let!(:minimum_close_permissions) do
        %w(read_private_cms_nodes read_private_article_pages close_private_article_pages)
      end

      it do
        login_user user1
        visit article_pages_path(site: site, cid: node)
        expect(page).to have_css(".list-item[data-id='#{page1.id}']", text: page1.name)

        within ".list-item[data-id='#{page1.id}']" do
          first("[type='checkbox']").click
        end
        within ".list-head" do
          expect(page).to have_content(I18n.t("ss.links.make_them_close"))
          click_on I18n.t("ss.links.make_them_close")
        end

        within "form" do
          expect(page).to have_css("[data-id='#{page1.id}'] [type='checkbox']")
          click_on I18n.t("ss.links.make_them_close")
        end
        wait_for_notice I18n.t("ss.notice.depublished")

        Article::Page.find(page1.id).tap do |after_page|
          expect(after_page.state).to eq "closed"
        end
      end
    end
  end

  context "when page is linked from other pages" do
    let!(:page2) do
      create :article_page, cur_site: site, cur_user: admin, cur_node: node, group_ids: admin.group_ids, state: "public"
    end
    let!(:link_page) do
      create :article_page, cur_site: site, cur_user: admin, cur_node: node, group_ids: admin.group_ids, state: "public",
        html: "<a href=\"#{page1.url}\">#{page1.name}</a>"
    end

    context "with minimum close permissions and contains links in file" do
      let!(:minimum_close_permissions) do
        %w(read_private_cms_nodes read_private_article_pages edit_private_article_pages close_private_article_pages)
      end

      it "cannot close page in edit view without ignore_alert permission when linked from block" do
        login_user user1
        visit article_pages_path(site: site, cid: node)
        expect(page).to have_css(".list-item[data-id='#{page1.id}']", text: page1.name)

        click_on page1.name
        wait_for_all_ckeditors_ready
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

        click_on I18n.t("ss.links.edit")
        wait_for_all_ckeditors_ready
        within "form#item-form" do
          wait_for_cbox_opened { click_on I18n.t("ss.buttons.withdraw") }
        end

        within_cbox do
          expect(page).not_to have_content(I18n.t("ss.buttons.ignore_alert"))
        end

        Article::Page.find(page1.id).tap do |after_page|
          expect(after_page.state).to eq "public"
        end
      end

      it "cannot close page in edit view without ignore_alert permission" do
        login_user user1
        visit article_pages_path(site: site, cid: node)
        expect(page).to have_css(".list-item[data-id='#{page1.id}']", text: page1.name)

        click_on page1.name
        wait_for_all_ckeditors_ready
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

        click_on I18n.t("ss.links.edit")
        wait_for_all_ckeditors_ready
        within "form#item-form" do
          wait_for_cbox_opened { click_on I18n.t("ss.buttons.withdraw") }
        end

        within_cbox do
          expect(page).not_to have_content(I18n.t("ss.buttons.ignore_alert"))
        end

        Article::Page.find(page1.id).tap do |after_page|
          expect(after_page.state).to eq "public"
        end
      end

      it "cannot close page in index view" do
        login_user user1
        visit article_pages_path(site: site, cid: node)
        expect(page).to have_css(".list-item[data-id='#{page1.id}']", text: page1.name)

        within ".list-item[data-id='#{page1.id}']" do
          first("[type='checkbox']").click
        end

        expect(page).to have_content(I18n.t("ss.links.make_them_close"))

        within ".list-head" do
          first("button, input[type='button']", text: I18n.t("ss.links.make_them_close")).click
        end

        within "form" do
          expect(page).to have_content(I18n.t("ss.confirm.contains_links_in_file_close"))
          expect(page).to have_no_css("[type='checkbox']")
        end

        visit article_pages_path(site: site, cid: node)
        expect(page).to have_css(".list-item[data-id='#{page1.id}']", text: page1.name)

        Article::Page.find(page1.id).tap do |after_page|
          expect(after_page.state).to eq "public"
        end
      end
    end

    context "with ignore_alert permission and contains links in file" do
      let!(:minimum_close_permissions) do
        %w(read_private_cms_nodes read_private_article_pages edit_private_article_pages close_private_article_pages
           edit_cms_ignore_alert)
      end

      it "can close page in edit view with ignore_alert permission" do
        login_user user1
        visit article_pages_path(site: site, cid: node)
        expect(page).to have_css(".list-item[data-id='#{page1.id}']", text: page1.name)

        click_on page1.name
        wait_for_all_ckeditors_ready
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

        click_on I18n.t("ss.links.edit")
        wait_for_all_ckeditors_ready
        within "form#item-form" do
          wait_for_cbox_opened { click_on I18n.t("ss.buttons.withdraw") }
        end
        within_cbox do
          expect(page).to have_content(I18n.t("cms.confirm.close"))
          expect(page).to have_content(I18n.t("ss.buttons.ignore_alert"))
        end
        click_on I18n.t("ss.buttons.ignore_alert")
        wait_for_notice I18n.t("ss.notice.saved")

        Article::Page.find(page1.id).tap do |after_page|
          expect(after_page.state).to eq "closed"
        end
      end

      it "can close page in index view with ignore_alert permission" do
        login_user user1
        visit article_pages_path(site: site, cid: node)
        expect(page).to have_css(".list-item[data-id='#{page1.id}']", text: page1.name)

        within ".list-item[data-id='#{page1.id}']" do
          first("[type='checkbox']").click
        end

        expect(page).to have_content(I18n.t("ss.links.make_them_close"))

        within ".list-head" do
          first("button, input[type='button']", text: I18n.t("ss.links.make_them_close")).click
        end

        within "form" do
          expect(page).to have_content(I18n.t("ss.confirm.contains_links_in_file_ignoring_alert_close"))
          expect(page).to have_css("[data-id='#{page1.id}'] [type='checkbox']")
          first("[type='checkbox']").click
          click_on I18n.t("ss.links.make_them_close")
        end

        wait_for_notice I18n.t("ss.notice.depublished")

        Article::Page.find(page1.id).tap do |after_page|
          expect(after_page.state).to eq "closed"
        end
      end
    end

    context "when page is saved as draft with accessibility error" do
      let!(:minimum_close_permissions) do
        %w(read_private_cms_nodes read_private_article_pages edit_private_article_pages close_private_article_pages)
      end
      let!(:page_with_accessibility_error) do
        create :article_page, cur_site: site, cur_user: admin, cur_node: node, group_ids: admin.group_ids, state: "public",
          html: "<img src=\"image.jpg\">"
      end

      it "can save as draft even if accessibility error exists" do
        login_user user1
        visit article_pages_path(site: site, cid: node)
        expect(page).to have_css(".list-item[data-id='#{page_with_accessibility_error.id}']")

        click_on page_with_accessibility_error.name
        wait_for_all_ckeditors_ready
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

        click_on I18n.t("ss.links.edit")
        wait_for_all_ckeditors_ready
        within "form#item-form" do
          wait_for_cbox_opened { click_on I18n.t("ss.buttons.withdraw") }
        end
        within_cbox do
          expect(page).to have_content(I18n.t("cms.confirm.close"))
          expect(page).to have_content(I18n.t("ss.buttons.ignore_alert"))
          click_on I18n.t("ss.buttons.ignore_alert")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        Article::Page.find(page_with_accessibility_error.id).tap do |after_page|
          expect(after_page.state).to eq "closed"
        end
      end
    end
  end

  # アクセシビリティエラーがあるページを一括非公開する（警告を無視して保存する権限がなくても可能）
  context "when page is closed with accessibility error" do
    let!(:minimum_close_permissions) do
      %w(read_private_cms_nodes read_private_article_pages edit_private_article_pages close_private_article_pages)
    end
    let!(:page_with_accessibility_error) do
      create :article_page, cur_site: site, cur_user: admin, cur_node: node, group_ids: admin.group_ids, state: "public",
        html: "<img src=\"image.jpg\">"
    end

    it "cannot close page in index view when contains accessibility error" do
      login_user user1
      visit article_pages_path(site: site, cid: node)
      expect(page).to have_css(".list-item[data-id='#{page_with_accessibility_error.id}']",
text: page_with_accessibility_error.name)

      within ".list-item[data-id='#{page_with_accessibility_error.id}']" do
        first("[type='checkbox']").click
      end
      within ".list-head" do
        expect(page).to have_content(I18n.t("ss.links.make_them_close"))
        click_on I18n.t("ss.links.make_them_close")
      end

      within "form" do
        expect(page).to have_css("[data-id='#{page_with_accessibility_error.id}'] [type='checkbox']")
        expect(page).to have_content(I18n.t("errors.messages.check_html"))
        click_on I18n.t("ss.links.make_them_close")
      end

      wait_for_notice I18n.t("ss.notice.depublished")

      Article::Page.find(page_with_accessibility_error.id).tap do |after_page|
        expect(after_page.state).to eq "closed"
      end
    end
  end
end
