require 'spec_helper'

describe "gws_public_links_menu", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }

  let(:link_name1) { "link_name-#{unique_id}" }
  let(:link_url1) { sys_diag_server_path(link: "link1") }
  let(:link_name2) { "link_name-#{unique_id}" }
  let(:link_url2) { sys_diag_server_path(link: "link2") }
  let!(:item) do
    create(
      :gws_link, cur_site: site,
      links: [
        { name: link_name1, url: link_url1, target: "_self" },
        { name: link_name2, url: link_url2, target: "_blank" },
      ])
  end
  let!(:sys_role_admin) { create :sys_role_admin }

  before do
    @default_link_target = Gws::Link.default_link_target
    gws_user.sys_user.add_to_set(sys_role_ids: sys_role_admin.id)
    login_gws_user
  end

  after do
    Gws::Link.default_link_target = @default_link_target
  end

  context "with link read permission" do
    it "opens the header dropdown and shows boxes/links and the manage gear" do
      visit gws_portal_path(site: site)

      within ".gws-public-links" do
        find(".gws-public-links-toggle").click

        # contents are loaded lazily through the turbo-frame
        expect(page).to have_css(".gws-public-links-box .gws-public-links-box-head h3", text: item.name)
        expect(page).to have_link(link_name1)
        expect(page).to have_link(link_name2)

        # the external (_blank) link has the open-in-new icon
        within all(".gws-public-links-list-item")[1] do
          expect(page).to have_css(".gws-public-links-link--external")
        end

        # the manage gear is visible and points to the management list
        expect(page).to have_css(".gws-public-links-menu-manage")
        expect(find(".gws-public-links-menu-manage")[:href]).to end_with(gws_links_path(site: site))
      end
    end

    it "follows an internal link through the redirect" do
      visit gws_portal_path(site: site)

      within ".gws-public-links" do
        find(".gws-public-links-toggle").click
        expect(page).to have_link(link_name1)
        click_on link_name1
      end

      within "#query-parameters" do
        expect(page).to have_css(".addon-body", text: "link1")
      end
    end

    it "opens an external link in a new window" do
      visit gws_portal_path(site: site)

      within ".gws-public-links" do
        find(".gws-public-links-toggle").click
        expect(page).to have_link(link_name2)
      end

      new_window = window_opened_by do
        within ".gws-public-links" do
          click_on link_name2
        end
      end
      within_window new_window do
        wait_for_document_loading
        within "#query-parameters" do
          expect(page).to have_css(".addon-body", text: "link2")
        end
      end
    end
  end

  context "without link read permission" do
    before do
      role = gws_user.gws_roles[0]
      role.update(permissions: Gws::Role.permission_names - %w(read_other_gws_links read_private_gws_links))
      gws_user.clear_gws_role_permissions
    end

    it "shows an empty panel without the manage gear" do
      # When read permission is missing, the readable scope returns no records
      # (gws.readable_setting.requires_read_permission defaults to true), so the
      # panel shows the empty message and the management gear is hidden.
      visit gws_portal_path(site: site)

      within ".gws-public-links" do
        find(".gws-public-links-toggle").click
        expect(page).to have_content(I18n.t("gws.public_links.no_items"))
        expect(page).to have_no_link(link_name1)
        expect(page).to have_no_css(".gws-public-links-menu-manage")
      end
    end
  end
end
