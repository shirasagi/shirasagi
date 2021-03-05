require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout }
  let!(:node) { create :article_node_page, cur_site: site, layout: layout, group_ids: cms_user.group_ids }
  let!(:permissions) do
    permissions = []

    permissions << 'read_private_article_pages'
    permissions << 'edit_private_article_pages'
    permissions << 'release_private_article_pages'
    permissions << 'delete_private_article_pages'

    permissions << 'read_private_cms_nodes'
    permissions << 'edit_private_cms_nodes'

    permissions
  end
  let!(:role) { create :cms_role, name: unique_id, permissions: permissions }
  let!(:user1) { create :cms_test_user, group_ids: cms_user.group_ids, cms_role_ids: [ role.id ] }
  let!(:user2) { create :cms_test_user, group_ids: cms_user.group_ids, cms_role_ids: [ role.id ] }

  let!(:category_node) { create :category_node_node, cur_site: site, layout: layout }
  let!(:category_page1) do
    create(
      :category_node_page, cur_site: site, cur_node: category_node, layout: layout,
      readable_setting_range: 'select', readable_member_ids: [ user1.id ]
    )
  end
  let!(:category_page2) do
    create(
      :category_node_page, cur_site: site, cur_node: category_node, layout: layout,
      readable_setting_range: 'select', readable_member_ids: [ user2.id ]
    )
  end

  context "category readable" do
    # page has category_page2 that is unreadable for user1
    let!(:item) do
      create(
        :article_page, cur_site: site, cur_node: node, layout: layout,
        category_ids: [ category_page2.id ],
        group_ids: cms_user.group_ids
      )
    end

    it do
      item.reload
      expect(item.category_ids).to include(category_page2.id)
      expect(item.category_ids).not_to include(category_page1.id)

      login_user user1
      visit article_pages_path(site: site, cid: node)

      click_on item.name
      click_on I18n.t("ss.links.edit")

      within "#item-form" do
        ensure_addon_opened("#addon-category-agents-addons-category")
        within "#addon-category-agents-addons-category" do
          # confirm that category_page1 is on the form, but category_page2 isn't.
          expect(page).to have_css(".child", text: category_page1.name)
          expect(page).not_to have_css(".child", text: category_page2.name)

          # check category_page1.name
          find("input[name='item[category_ids][]'][value='#{category_page1.id}']").check
        end

        click_on I18n.t("ss.buttons.publish_save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      # confirm that category_page2 doesn't disappear
      item.reload
      expect(item.category_ids).to include(category_page1.id, category_page2.id)
    end
  end
end
