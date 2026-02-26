require 'spec_helper'

describe "cms", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:group) { cms_group }
  let!(:site_admin) { cms_user }
  let!(:page_editor_role) do
    permissions = %w(read_private_cms_nodes read_private_article_pages edit_private_article_pages)
    create :cms_role, name: unique_id, permissions: permissions
  end
  let!(:page_editor) { create :cms_test_user, cms_role_ids: [ page_editor_role.id ], group_ids: site_admin.group_ids }
  let!(:node) { create :article_node_page, cur_site: site, group_ids: site_admin.group_ids }

  context "with site-admin" do
    it do
      login_user site_admin, to: cms_contents_path(site: site)
      within first("#main .main-navi") do
        expect(page).to have_link(I18n.t("cms.node"), href: cms_nodes_path(site: site))
        expect(page).to have_link(I18n.t("cms.page"), href: cms_pages_path(site: site))
        expect(page).to have_link(I18n.t("cms.part"), href: cms_parts_path(site: site))
        expect(page).to have_link(I18n.t("cms.layout"), href: cms_layouts_path(site: site))
        expect(page).to have_no_link(I18n.t("cms.node_config"))
        expect(page).to have_css(".dropdown", text: I18n.t("cms.etc"))

        # click_on I18n.t("cms.etc")
        first(".dropdown .icon-ss").click

        within ".dropdown-menu" do
          expect(page).to have_link(I18n.t("cms.import_node"), href: cms_import_path(site: site))
          expect(page).to have_link(I18n.t("cms.generate_node"), href: cms_generate_nodes_path(site: site))
          expect(page).to have_link(I18n.t("cms.generate_page"), href: cms_generate_pages_path(site: site))
          expect(page).to have_link(I18n.t("cms.csv_export_node"), href: download_cms_nodes_path(site: site))
          expect(page).to have_link(I18n.t("cms.csv_import_node"), href: import_cms_nodes_path(site: site))
        end
      end

      visit article_pages_path(site: site, cid: node)
      within first("#main .main-navi") do
        expect(page).to have_link(I18n.t("cms.node"), href: node_nodes_path(site: site, cid: node))
        expect(page).to have_link(I18n.t("cms.page"), href: node_pages_path(site: site, cid: node))
        expect(page).to have_link(I18n.t("cms.part"), href: node_parts_path(site: site, cid: node))
        expect(page).to have_link(I18n.t("cms.layout"), href: node_layouts_path(site: site, cid: node))
        expect(page).to have_link(I18n.t("cms.node_config"), href: node_conf_path(site: site, cid: node))
        expect(page).to have_css(".dropdown", text: I18n.t("cms.etc"))

        # click_on I18n.t("cms.etc")
        first(".dropdown .icon-ss").click

        within ".dropdown-menu" do
          expect(page).to have_link(I18n.t("cms.import_node"), href: node_import_path(site: site, cid: node))
          expect(page).to have_link(I18n.t("cms.generate_node"), href: node_generate_nodes_path(site: site, cid: node))
          expect(page).to have_link(I18n.t("cms.generate_page"), href: node_generate_pages_path(site: site, cid: node))
          expect(page).to have_link(I18n.t("cms.csv_export_node"), href: download_node_nodes_path(site: site, cid: node))
          expect(page).to have_link(I18n.t("cms.csv_import_node"), href: import_node_nodes_path(site: site, cid: node))
        end
      end

      visit cms_site_path(site: site)
      expect(page).to have_no_css("#main .main-navi")
    end
  end

  context "with page-editor" do
    it do
      login_user page_editor, to: cms_contents_path(site: site)
      within first("#main .main-navi") do
        expect(page).to have_link(I18n.t("cms.node"), href: cms_nodes_path(site: site))
        expect(page).to have_no_link(I18n.t("cms.page"))
        expect(page).to have_no_link(I18n.t("cms.part"))
        expect(page).to have_no_link(I18n.t("cms.layout"))
        expect(page).to have_no_link(I18n.t("cms.node_config"))
        expect(page).to have_no_css(".dropdown")
      end

      visit article_pages_path(site: site, cid: node)
      within first("#main .main-navi") do
        expect(page).to have_link(I18n.t("cms.node"), href: node_nodes_path(site: site, cid: node))
        expect(page).to have_no_link(I18n.t("cms.page"))
        expect(page).to have_no_link(I18n.t("cms.part"))
        expect(page).to have_no_link(I18n.t("cms.layout"))
        expect(page).to have_link(I18n.t("cms.node_config"), href: node_conf_path(site: site, cid: node))
        expect(page).to have_no_css(".dropdown")
      end
    end
  end
end
