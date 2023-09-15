require 'spec_helper'

describe Contact::ContactsController, type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:group0) { cms_group }
  let!(:group) do
    create(
      :contact_group, name: "#{group0.name}/#{unique_id}",
      contact_groups: [
        {
          name: "name-#{unique_id}", contact_group_name: "contact_group_name-#{unique_id}",
          contact_tel: unique_tel, contact_fax: unique_tel, contact_email: unique_email,
          contact_link_url: "/#{unique_id}", contact_link_name: "link_name-#{unique_id}",
          main_state: "main"
        },
        {
          name: "name-#{unique_id}", contact_group_name: "contact_group_name-#{unique_id}",
          contact_tel: unique_tel, contact_fax: unique_tel, contact_email: unique_email,
          contact_link_url: "/#{unique_id}", contact_link_name: "link_name-#{unique_id}",
        }
      ]
    )
  end
  let!(:main_contact) { group.contact_groups.where(main_state: "main").first }
  let!(:sub_contact) { group.contact_groups.ne(main_state: "main").first }
  let!(:node) { create :article_node_page, cur_site: site }
  let!(:article) do
    create(
      :article_page, cur_site: site, cur_node: node,
      contact_group: group, contact_group_contact_id: main_contact.id, contact_group_relation: "related")
  end

  let!(:other_site) { create :cms_site_unique, group_ids: [ group0.id ] }
  let!(:other_site_node) { create :article_node_page, cur_site: other_site }
  let!(:other_site_article) do
    create(
      :article_page, cur_site: other_site, cur_node: other_site_node,
      contact_group: group, contact_group_contact_id: main_contact.id, contact_group_relation: "related")
  end

  before do
    login_cms_user
  end

  context "confirm page usage" do
    it do
      visit contact_contacts_path(site: site)
      within "[data-id='#{main_contact.id}']" do
        expect(page).to have_css(".name", text: main_contact.name)
        expect(page).to have_css(".pages-used", text: "2")
      end
      within "[data-id='#{sub_contact.id}']" do
        expect(page).to have_css(".name", text: sub_contact.name)
        expect(page).to have_css(".pages-used", text: I18n.t("contact.pages_used.zero"))
      end

      within "[data-id='#{main_contact.id}']" do
        click_on "2"
      end

      expect(page).to have_css(".list-item", count: 1)
      within ".list-item[data-id='#{article.id}']" do
        expect(page).to have_css(".title", text: article.name)
      end
      # other_site_article は site の所有ではないので見えない。しかし使用数には含まれる。
      expect(page).to have_no_css(".list-item[data-id='#{other_site_article.id}']")
    end
  end

  context "delete all" do
    it do
      visit contact_contacts_path(site: site)
      within "[data-id='#{main_contact.id}']" do
        expect(page).to have_css(".name", text: main_contact.name)
        expect(page).to have_css(".pages-used", text: "2")
      end
      within "[data-id='#{sub_contact.id}']" do
        expect(page).to have_css(".name", text: sub_contact.name)
        expect(page).to have_css(".pages-used", text: I18n.t("contact.pages_used.zero"))
      end

      #
      # delete all
      #
      wait_event_to_fire("ss:checked-all-list-items") { find('.list-head input[type="checkbox"]').set(true) }
      wait_event_to_fire("ss:all-list-action-finished") do
        page.accept_confirm(I18n.t("ss.confirm.delete")) do
          within ".list-head-action" do
            click_on I18n.t("ss.links.delete")
          end
        end
      end

      Cms::Group.find(group.id).tap do |group1|
        expect(group1.contact_groups.count).to eq 1
        expect(group1.contact_groups.first.id).to eq main_contact.id
      end
    end
  end
end
