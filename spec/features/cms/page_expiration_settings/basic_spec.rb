require 'spec_helper'

describe "cms_page_expiration_settings", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:group0) { cms_group }
  let(:now) { Time.zone.now.change(usec: 0) }

  context "editor can manage just owned pages" do
    let!(:group1) { create :cms_group, name: "#{group0.name}/#{unique_id}" }
    let!(:group2) { create :cms_group, name: "#{group0.name}/#{unique_id}" }
    let(:editor_permissions) do
      %w(
        read_private_cms_nodes read_private_cms_pages edit_private_cms_pages
        read_private_article_pages edit_private_article_pages)
    end
    let!(:editor_role) { create :cms_role, cur_site: site, name: unique_id, permissions: editor_permissions }
    let(:page_expiration_permissions) { %w(edit_cms_page_expiration_settings) }
    let!(:page_expiration_role) { create :cms_role, cur_site: site, name: unique_id, permissions: page_expiration_permissions }
    let!(:user1) { create :cms_test_user, group_ids: [ group1.id ], cms_role_ids: [ editor_role.id, page_expiration_role.id ] }
    let!(:user2) { create :cms_test_user, group_ids: [ group2.id ], cms_role_ids: [ editor_role.id, page_expiration_role.id ] }

    let!(:node) { create :article_node_page, cur_site: site, group_ids: [ group1.id, group2.id ] }
    let!(:article1) do
      Timecop.freeze(now - 1.day) do
        article = create(:article_page, cur_site: site, cur_node: node, group_ids: [ group1.id ])
        Article::Page.find(article.id)
      end
    end
    let!(:article2) do
      Timecop.freeze(now - 2.days) do
        article = create(:article_page, cur_site: site, cur_node: node, group_ids: [ group2.id ])
        Article::Page.find(article.id)
      end
    end

    it do
      expect(article1.expiration_setting_type).to eq "site"

      login_user user1, to: cms_page_expiration_settings_path(site: site)
      expect(page).to have_css(".list-item", count: 1)
      expect(page).to have_css(".list-item[data-id='#{article1.id}']", text: article1.name)
      expect(page).to have_css(".list-item[data-id='#{article1.id}']", text: article1.filename)
      expect(page).to have_no_css(".list-item[data-id='#{article2.id}']")

      click_on article1.name
      within ".nav-menu" do
        click_on I18n.t("ss.links.edit")
      end
      within "form#item-form" do
        choose I18n.t("cms.options.expiration_setting_type.never")
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      Cms::Page.find(article1.id).tap do |current|
        expect(current.expiration_setting_type).to eq "never"

        # 更新日時に変化はない
        expect(current.updated.in_time_zone).to eq article1.updated.in_time_zone
      end

      visit cms_page_expiration_settings_path(site: site)
      click_on article1.name
      within ".nav-menu" do
        click_on I18n.t("ss.links.edit")
      end
      within "form#item-form" do
        choose I18n.t("cms.options.expiration_setting_type.site")
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      Cms::Page.find(article1.id).tap do |current|
        expect(current.expiration_setting_type).to eq "site"

        # 更新日時に変化はない
        expect(current.updated.in_time_zone).to eq article1.updated.in_time_zone
      end
    end
  end

  context "editor can manage pages across multiple nodes" do
    let!(:group1) { create :cms_group, name: "#{group0.name}/#{unique_id}" }
    let(:editor_permissions) do
      %w(
        read_private_cms_nodes read_private_cms_pages edit_private_cms_pages
        read_private_article_pages edit_private_article_pages)
    end
    let!(:editor_role) { create :cms_role, cur_site: site, name: unique_id, permissions: editor_permissions }
    let(:page_expiration_permissions) { %w(edit_cms_page_expiration_settings) }
    let!(:page_expiration_role) { create :cms_role, cur_site: site, name: unique_id, permissions: page_expiration_permissions }
    let!(:user1) { create :cms_test_user, group_ids: [ group1.id ], cms_role_ids: [ editor_role.id, page_expiration_role.id ] }

    let!(:node1) { create :article_node_page, cur_site: site, group_ids: [ group1.id ] }
    let!(:article1) do
      Timecop.freeze(now - 1.day) do
        article = create(:article_page, cur_site: site, cur_node: node1, group_ids: [ group1.id ])
        Article::Page.find(article.id)
      end
    end

    let!(:node2) { create :article_node_page, cur_site: site, group_ids: [ group1.id ] }
    let!(:article2) do
      Timecop.freeze(now - 2.days) do
        article = create(:article_page, cur_site: site, cur_node: node2, group_ids: [ group1.id ])
        Article::Page.find(article.id)
      end
    end

    it do
      expect(article1.expiration_setting_type).to eq "site"
      expect(article2.expiration_setting_type).to eq "site"

      login_user user1, to: cms_page_expiration_settings_path(site: site)
      expect(page).to have_css(".list-item", count: 2)
      expect(page).to have_css(".list-item[data-id='#{article1.id}']", text: article1.name)
      expect(page).to have_css(".list-item[data-id='#{article1.id}']", text: article1.filename)
      expect(page).to have_css(".list-item[data-id='#{article2.id}']", text: article2.name)
      expect(page).to have_css(".list-item[data-id='#{article2.id}']", text: article2.filename)

      click_on article1.name
      within ".nav-menu" do
        click_on I18n.t("ss.links.edit")
      end
      within "form#item-form" do
        choose I18n.t("cms.options.expiration_setting_type.never")
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      Cms::Page.find(article1.id).tap do |current|
        expect(current.expiration_setting_type).to eq "never"

        # 更新日時に変化はない
        expect(current.updated.in_time_zone).to eq article1.updated.in_time_zone
      end

      visit cms_page_expiration_settings_path(site: site)
      click_on article2.name
      within ".nav-menu" do
        click_on I18n.t("ss.links.edit")
      end
      within "form#item-form" do
        choose I18n.t("cms.options.expiration_setting_type.never")
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      Cms::Page.find(article2.id).tap do |current|
        expect(current.expiration_setting_type).to eq "never"

        # 更新日時に変化はない
        expect(current.updated.in_time_zone).to eq article2.updated.in_time_zone
      end
    end
  end

  context "bulk operations" do
    let!(:group1) { create :cms_group, name: "#{group0.name}/#{unique_id}" }
    let(:editor_permissions) do
      %w(
        read_private_cms_nodes read_private_cms_pages edit_private_cms_pages
        read_private_article_pages edit_private_article_pages)
    end
    let!(:editor_role) { create :cms_role, cur_site: site, name: unique_id, permissions: editor_permissions }
    let(:page_expiration_permissions) { %w(edit_cms_page_expiration_settings) }
    let!(:page_expiration_role) { create :cms_role, cur_site: site, name: unique_id, permissions: page_expiration_permissions }
    let!(:user1) { create :cms_test_user, group_ids: [ group1.id ], cms_role_ids: [ editor_role.id, page_expiration_role.id ] }

    let!(:node1) { create :article_node_page, cur_site: site, group_ids: [ group1.id ] }
    let!(:article1) do
      Timecop.freeze(now - 1.day) do
        article = create(:article_page, cur_site: site, cur_node: node1, group_ids: [ group1.id ])
        Article::Page.find(article.id)
      end
    end

    let!(:node2) { create :article_node_page, cur_site: site, group_ids: [ group1.id ] }
    let!(:article2) do
      Timecop.freeze(now - 2.days) do
        article = create(:article_page, cur_site: site, cur_node: node2, group_ids: [ group1.id ])
        Article::Page.find(article.id)
      end
    end

    it do
      expect(article1.expiration_setting_type).to eq "site"
      expect(article2.expiration_setting_type).to eq "site"

      login_user user1, to: cms_page_expiration_settings_path(site: site)
      expect(page).to have_css(".list-item", count: 2)
      expect(page).to have_css(".list-item[data-id='#{article1.id}']", text: article1.name)
      expect(page).to have_css(".list-item[data-id='#{article1.id}']", text: article1.filename)
      expect(page).to have_css(".list-item[data-id='#{article2.id}']", text: article2.name)
      expect(page).to have_css(".list-item[data-id='#{article2.id}']", text: article2.filename)

      wait_for_event_fired("ss:checked-all-list-items") { first(".list-head [type='checkbox']").click }

      page.accept_confirm(I18n.t("cms.confirm.expiration_setting_type.never")) do
        within ".list-head-action" do
          click_on I18n.t("cms.options.expiration_setting_type.never")
        end
      end
      # wait_for_notice I18n.t("ss.notice.saved")
      page.accept_confirm(I18n.t("ss.notice.changed"))

      Cms::Page.find(article1.id).tap do |current|
        expect(current.expiration_setting_type).to eq "never"

        # 更新日時に変化はない
        expect(current.updated.in_time_zone).to eq article1.updated.in_time_zone
      end
      Cms::Page.find(article2.id).tap do |current|
        expect(current.expiration_setting_type).to eq "never"

        # 更新日時に変化はない
        expect(current.updated.in_time_zone).to eq article2.updated.in_time_zone
      end

      visit cms_page_expiration_settings_path(site: site)
      wait_for_event_fired("ss:checked-all-list-items") { first(".list-head [type='checkbox']").click }
      page.accept_confirm(I18n.t("cms.confirm.expiration_setting_type.site")) do
        within ".list-head-action" do
          click_on I18n.t("cms.options.expiration_setting_type.site")
        end
      end
      # wait_for_notice I18n.t("ss.notice.saved")
      page.accept_confirm(I18n.t("ss.notice.changed"))

      Cms::Page.find(article1.id).tap do |current|
        expect(current.expiration_setting_type).to eq "site"

        # 更新日時に変化はない
        expect(current.updated.in_time_zone).to eq article1.updated.in_time_zone
      end
      Cms::Page.find(article2.id).tap do |current|
        expect(current.expiration_setting_type).to eq "site"

        # 更新日時に変化はない
        expect(current.updated.in_time_zone).to eq article2.updated.in_time_zone
      end
    end
  end

  context "index-search" do
    context "by expiration_setting_type" do
      let!(:group1) { create :cms_group, name: "#{group0.name}/#{unique_id}" }
      let(:editor_permissions) do
        %w(
        read_private_cms_nodes read_private_cms_pages edit_private_cms_pages
        read_private_article_pages edit_private_article_pages)
      end
      let!(:editor_role) { create :cms_role, cur_site: site, name: unique_id, permissions: editor_permissions }
      let(:page_expiration_permissions) { %w(edit_cms_page_expiration_settings) }
      let!(:page_expiration_role) { create :cms_role, cur_site: site, name: unique_id, permissions: page_expiration_permissions }
      let!(:user1) { create :cms_test_user, group_ids: [ group1.id ], cms_role_ids: [ editor_role.id, page_expiration_role.id ] }

      let!(:node1) { create :article_node_page, cur_site: site, group_ids: [ group1.id ] }
      let!(:article1) do
        Timecop.freeze(now - 1.day) do
          article = create(
            :article_page, cur_site: site, cur_node: node1, group_ids: [ group1.id ], expiration_setting_type: "never")
          Article::Page.find(article.id)
        end
      end

      let!(:node2) { create :article_node_page, cur_site: site, group_ids: [ group1.id ] }
      let!(:article2) do
        Timecop.freeze(now - 2.days) do
          article = create(
            :article_page, cur_site: site, cur_node: node2, group_ids: [ group1.id ],
            expiration_setting_type: "site")
          Article::Page.find(article.id)
        end
      end

      it do
        expect(article1.expiration_setting_type).to eq "never"
        expect(article2.expiration_setting_type).to eq "site"

        login_user user1, to: cms_page_expiration_settings_path(site: site)
        expect(page).to have_css(".list-item", count: 2)
        expect(page).to have_css(".list-item[data-id='#{article1.id}']", text: article1.name)
        expect(page).to have_css(".list-item[data-id='#{article1.id}']", text: article1.filename)
        expect(page).to have_css(".list-item[data-id='#{article2.id}']", text: article2.name)
        expect(page).to have_css(".list-item[data-id='#{article2.id}']", text: article2.filename)

        within ".index-search" do
          select I18n.t("cms.options.expiration_setting_type.site"), from: "s[expiration_setting_type]"
          click_on I18n.t("ss.buttons.search")
        end
        expect(page).to have_css(".list-item", count: 1)
        expect(page).to have_css(".list-item[data-id='#{article2.id}']", text: article2.name)

        within ".index-search" do
          select I18n.t("cms.options.expiration_setting_type.never"), from: "s[expiration_setting_type]"
          click_on I18n.t("ss.buttons.search")
        end
        expect(page).to have_css(".list-item", count: 1)
        expect(page).to have_css(".list-item[data-id='#{article1.id}']", text: article1.name)

        within ".index-search" do
          select "", from: "s[expiration_setting_type]"
          click_on I18n.t("ss.buttons.search")
        end
        expect(page).to have_css(".list-item", count: 2)
        expect(page).to have_css(".list-item[data-id='#{article1.id}']", text: article1.name)
        expect(page).to have_css(".list-item[data-id='#{article2.id}']", text: article2.name)
      end
    end

    context "by updated_before" do
      let!(:group1) { create :cms_group, name: "#{group0.name}/#{unique_id}" }
      let(:editor_permissions) do
        %w(
        read_private_cms_nodes read_private_cms_pages edit_private_cms_pages
        read_private_article_pages edit_private_article_pages)
      end
      let!(:editor_role) { create :cms_role, cur_site: site, name: unique_id, permissions: editor_permissions }
      let(:page_expiration_permissions) { %w(edit_cms_page_expiration_settings) }
      let!(:page_expiration_role) { create :cms_role, cur_site: site, name: unique_id, permissions: page_expiration_permissions }
      let!(:user1) { create :cms_test_user, group_ids: [ group1.id ], cms_role_ids: [ editor_role.id, page_expiration_role.id ] }

      let!(:node1) { create :article_node_page, cur_site: site, group_ids: [ group1.id ] }
      let!(:article1) do
        Timecop.freeze(now - 89.days) do
          article = create(:article_page, cur_site: site, cur_node: node1, group_ids: [ group1.id ])
          Article::Page.find(article.id)
        end
      end
      let!(:article2) do
        Timecop.freeze(now - 90.days) do
          article = create(:article_page, cur_site: site, cur_node: node1, group_ids: [ group1.id ])
          Article::Page.find(article.id)
        end
      end

      it do
        login_user user1, to: cms_page_expiration_settings_path(site: site)
        expect(page).to have_css(".list-item", count: 2)
        expect(page).to have_css(".list-item[data-id='#{article1.id}']", text: article1.name)
        expect(page).to have_css(".list-item[data-id='#{article2.id}']", text: article2.name)

        within ".index-search" do
          select I18n.t("cms.options.updated_before.90_days"), from: "s[updated_before]"
          click_on I18n.t("ss.buttons.search")
        end
        expect(page).to have_css(".list-item", count: 1)
        expect(page).to have_css(".list-item[data-id='#{article2.id}']", text: article2.name)

        within ".index-search" do
          select I18n.t("cms.options.updated_before.180_days"), from: "s[updated_before]"
          click_on I18n.t("ss.buttons.search")
        end
        expect(page).to have_css(".list-item", count: 0)
      end
    end
  end
end
