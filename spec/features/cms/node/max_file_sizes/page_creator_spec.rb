require 'spec_helper'

describe "node_max_file_sizes", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:site_admin) { cms_user }
  let!(:node) { create :article_node_page, cur_site: site, group_ids: site_admin.group_ids }

  let!(:page_creator_role) do
    permissions = %w(read_private_cms_nodes read_private_article_pages edit_private_article_pages)
    create :cms_role, name: unique_id, permissions: permissions
  end
  let!(:page_creator) do
    create :cms_test_user, cms_role_ids: [ page_creator_role.id ], group_ids: site_admin.group_ids
  end

  context "basic crud" do
    it do
      login_user page_creator, to: article_pages_path(site: site, cid: node)
      within first("#main .main-navi") do
        click_on I18n.t("cms.node_config")
      end

      expect(:page).to have_no_css("#addon-cms-agents-addons-max_file_size_setting")
    end
  end

  context "when a cms/max_file_size is existed" do
    let!(:item) { create :cms_max_file_size, cur_site: site, cur_node: node }

    it do
      login_user page_creator, to: article_pages_path(site: site, cid: node)
      within first("#main .main-navi") do
        click_on I18n.t("cms.node_config")
      end

      ensure_addon_opened "#addon-cms-agents-addons-max_file_size_setting"
      within "#addon-cms-agents-addons-max_file_size_setting" do
        expect(page).to have_no_link(I18n.t("cms.add_max_file_size"))

        expect(page).to have_css("[data-id='#{item.id}']", text: item.name)
      end
    end
  end
end
