require 'spec_helper'

describe Contact::ContactsController, type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:group0) { cms_group }
  let!(:groups) do
    Array.new(3) do |i|
      create(
        :contact_group, name: "#{group0.name}/#{unique_id}", order: 100 + (i + 1) * 10,
        contact_groups: [
          {
            name: "name-#{unique_id}",
            contact_group_name: "contact_group_name-#{unique_id}", contact_charge: "contact_charge-#{unique_id}",
            contact_tel: unique_tel, contact_fax: unique_tel, contact_email: unique_email,
            contact_postal_code: unique_id, contact_address: "address-#{unique_id}",
            contact_link_url: "/#{unique_id}", contact_link_name: "link_name-#{unique_id}",
            main_state: "main"
          },
          {
            name: "name-#{unique_id}",
            contact_group_name: "contact_group_name-#{unique_id}", contact_charge: "contact_charge-#{unique_id}",
            contact_tel: unique_tel, contact_fax: unique_tel, contact_email: unique_email,
            contact_postal_code: unique_id, contact_address: "address-#{unique_id}",
            contact_link_url: "/#{unique_id}", contact_link_name: "link_name-#{unique_id}",
          }
        ]
      )
    end
  end
  let!(:node) { create :article_node_page, cur_site: site }

  before do
    # ページネーションのテストがしやすいように、一ページ当たりお表示件数を減らす
    @save_max_items_per_page = SS.max_items_per_page
    SS.max_items_per_page = 3
  end

  after do
    SS.max_items_per_page = @save_max_items_per_page
  end

  context "when pages' contact is forcibly disconnected" do
    it do
      login_cms_user to: article_pages_path(site: site, cid: node)
      click_on I18n.t("ss.links.new")
      wait_for_all_ckeditors_ready

      within "form#item-form" do
        ensure_addon_opened "#addon-contact-agents-addons-page"
        within "#addon-contact-agents-addons-page" do
          wait_for_cbox_opened { click_on I18n.t("contact.apis.contacts.index") }
        end
      end

      within_cbox do
        expect(page).to have_css("[data-id='#{group0.id}']")
        expect(page).to have_css("[data-id='#{groups[0].id}:#{groups[0].contact_groups[0].id}']")
        expect(page).to have_css("[data-id='#{groups[0].id}:#{groups[0].contact_groups[1].id}']")
        expect(page).to have_css("[data-id]", count: 3)

        expect(page).to have_css(".pagination .current", text: "1")

        within ".pagination" do
          click_on "2"
        end
      end

      within_cbox do
        expect(page).to have_css("[data-id='#{groups[1].id}:#{groups[1].contact_groups[0].id}']")
        expect(page).to have_css("[data-id='#{groups[1].id}:#{groups[1].contact_groups[1].id}']")
        expect(page).to have_css("[data-id='#{groups[2].id}:#{groups[2].contact_groups[0].id}']")
        expect(page).to have_css("[data-id]", count: 3)

        expect(page).to have_css(".pagination .current", text: "2")

        within ".pagination" do
          click_on "3"
        end
      end

      within_cbox do
        expect(page).to have_css("[data-id='#{groups[2].id}:#{groups[2].contact_groups[1].id}']")
        expect(page).to have_css("[data-id]", count: 1)

        expect(page).to have_css(".pagination .current", text: "3")

        within ".pagination" do
          click_on "1"
        end
      end

      within_cbox do
        expect(page).to have_css("[data-id='#{group0.id}']")
        expect(page).to have_css("[data-id='#{groups[0].id}:#{groups[0].contact_groups[0].id}']")
        expect(page).to have_css("[data-id='#{groups[0].id}:#{groups[0].contact_groups[1].id}']")
        expect(page).to have_css("[data-id]", count: 3)

        expect(page).to have_css(".pagination .current", text: "1")
      end
    end
  end
end
