require 'spec_helper'

describe "gws_links", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }

  before { login_gws_user }

  context "basic crud" do
    let(:name) { "name-#{unique_id}" }
    let(:name2) { "name-#{unique_id}" }
    let(:link_name1) { "link_name-#{unique_id}" }
    let(:link_url1) { unique_url }
    let(:link_target1) { "_self" }
    let(:link_target1_label) { I18n.t("ss.options.link_target.#{link_target1}") }
    let(:link_name2) { "link_name-#{unique_id}" }
    let(:link_url2) { unique_url }
    let(:link_target2) { "_blank" }
    let(:link_target2_label) { I18n.t("ss.options.link_target.#{link_target2}") }
    let(:link_name3) { "link_name-#{unique_id}" }
    let(:link_url3) { unique_url }
    let(:link_target3) { "_blank" }
    let(:link_target3_label) { I18n.t("ss.options.link_target.#{link_target3}") }

    it do
      #
      # Create
      #
      visit gws_links_path(site: site)
      within ".nav-menu" do
        click_on I18n.t("ss.links.new")
      end
      within "form#item-form" do
        fill_in "item[name]", with: name

        ensure_addon_opened "#addon-gws-agents-addons-link"
        within "#addon-gws-agents-addons-link" do
          within all("tr")[1] do
            fill_in "item[links][][name]", with: link_name1
            fill_in "item[links][][url]", with: link_url1
            select link_target1_label, from: "item[links][][target]"

            click_on "add"
          end
          wait_for_js_ready

          within all("tr")[2] do
            fill_in "item[links][][name]", with: link_name2
            fill_in "item[links][][url]", with: link_url2
            select link_target2_label, from: "item[links][][target]"

            # 最後に空レコードを作成
            click_on "add"
          end
          wait_for_js_ready

          within all("tr")[3] do
            expect(page).to have_css("[name='item[links][][name]']")
          end
        end

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Gws::Link.all.count).to eq 1
      link = Gws::Link.all.first
      expect(link.name).to eq name
      expect(link.links).to have(2).items
      expect(link.links[0][:name]).to eq link_name1
      expect(link.links[0][:url]).to eq link_url1
      expect(link.links[0][:target]).to eq link_target1
      expect(link.links[1][:name]).to eq link_name2
      expect(link.links[1][:url]).to eq link_url2
      expect(link.links[1][:target]).to eq link_target2

      #
      # Update
      #
      visit gws_links_path(site: site)
      click_on link.name
      within ".nav-menu" do
        click_on I18n.t("ss.links.edit")
      end
      within "form#item-form" do
        fill_in "item[name]", with: name2

        ensure_addon_opened "#addon-gws-agents-addons-link"
        within "#addon-gws-agents-addons-link" do
          within all("tr")[2] do
            click_on "add"
          end
          wait_for_js_ready

          within all("tr")[3] do
            fill_in "item[links][][name]", with: link_name3
            fill_in "item[links][][url]", with: link_url3
            select link_target3_label, from: "item[links][][target]"

            click_on "add"
          end
          wait_for_js_ready
        end

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      link.reload
      expect(link.name).to eq name2
      expect(link.links).to have(3).items
      expect(link.links[2][:name]).to eq link_name3
      expect(link.links[2][:url]).to eq link_url3
      expect(link.links[2][:target]).to eq link_target3

      #
      # Delete
      #
      visit gws_links_path(site: site)
      click_on link.name
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect { link.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end

  context "public side" do
    let(:link_name1) { "link_name-#{unique_id}" }
    let(:link_url1) { sys_diag_server_path(link: "link1") }
    let(:link_target1) { "_self" }
    let(:link_name2) { "link_name-#{unique_id}" }
    let(:link_url2) { sys_diag_server_path(link: "link2") }
    let(:link_target2) { "_blank" }
    let(:link_name3) { "link_name-#{unique_id}" }
    let(:link_url3) { sys_diag_server_path(link: "link3") }
    let(:link_target3) { "" }
    let!(:item) do
      create(
        :gws_link, cur_site: site,
        links: [
          { name: link_name1, url: link_url1, target: link_target1 },
          { name: link_name2, url: link_url2, target: link_target2 },
          { name: link_name3, url: link_url3, target: link_target3 },
        ])
    end
    let!(:sys_role_admin) { create :sys_role_admin }

    before do
      @default_link_target = Gws::Link.default_link_target
      gws_user.sys_user.add_to_set(sys_role_ids: sys_role_admin.id)
    end

    after do
      Gws::Link.default_link_target = @default_link_target
    end

    context "public links" do
      it do
        visit gws_public_links_path(site: site)
        click_on item.name

        expect(page).to have_css(".list-item", count: 3)
        within all(".list-item")[0] do
          click_on link_name1
        end
        within "#query-parameters" do
          expect(page).to have_css(".addon-body", text: "link1")
        end
        page.evaluate_script('window.history.back()')

        # link2 should be opened in new tab
        new_window = window_opened_by do
          within all(".list-item")[1] do
            click_on link_name2
          end
        end
        within_window new_window do
          wait_for_document_loading
          within "#query-parameters" do
            expect(page).to have_css(".addon-body", text: "link2")
          end
        end

        Gws::Link.default_link_target = "_self"
        visit gws_public_links_path(site: site)
        click_on item.name
        within all(".list-item")[2] do
          click_on link_name3
        end
        within "#query-parameters" do
          expect(page).to have_css(".addon-body", text: "link3")
        end

        Gws::Link.default_link_target = "_blank"
        visit gws_public_links_path(site: site)
        click_on item.name
        new_window = window_opened_by do
          within all(".list-item")[2] do
            click_on link_name3
          end
        end
        within_window new_window do
          wait_for_document_loading
          within "#query-parameters" do
            expect(page).to have_css(".addon-body", text: "link3")
          end
        end
      end
    end

    context "main portal" do
      it do
        visit gws_portal_path(site: site)
        within "#navi .mod-navi.gws-links" do
          click_on item.name
        end

        expect(page).to have_css(".list-item", count: 3)

        within all(".list-item")[0] do
          click_on link_name1
        end
        within "#query-parameters" do
          expect(page).to have_css(".addon-body", text: "link1")
        end
        page.evaluate_script('window.history.back()')

        # link2 should be opened in new tab
        new_window = window_opened_by do
          within all(".list-item")[1] do
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

    context "user portal" do
      it do
        visit gws_portal_user_path(site: site, user: gws_user)
        within "#navi .mod-navi.gws-links" do
          click_on item.name
        end

        expect(page).to have_css(".list-item", count: 3)

        within all(".list-item")[0] do
          click_on link_name1
        end
        within "#query-parameters" do
          expect(page).to have_css(".addon-body", text: "link1")
        end
        page.evaluate_script('window.history.back()')

        # link2 should be opened in new tab
        new_window = window_opened_by do
          within all(".list-item")[1] do
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

    context "organization portal" do
      it do
        visit gws_portal_group_path(site: site, group: site)
        within "#navi .mod-navi.gws-links" do
          click_on item.name
        end

        expect(page).to have_css(".list-item", count: 3)

        within all(".list-item")[0] do
          click_on link_name1
        end
        within "#query-parameters" do
          expect(page).to have_css(".addon-body", text: "link1")
        end
        page.evaluate_script('window.history.back()')

        # link2 should be opened in new tab
        new_window = window_opened_by do
          within all(".list-item")[1] do
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
  end
end
