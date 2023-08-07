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
  let!(:article1) do
    create(
      :article_page, cur_site: site, cur_node: node,
      contact_group: group, contact_group_contact_id: main_contact.id, contact_group_relation: "related")
  end
  let!(:article2) do
    create(
      :article_page, cur_site: site, cur_node: node,
      contact_group: group, contact_group_contact_id: sub_contact.id, contact_group_relation: "related")
  end

  let!(:other_site) { create :cms_site_unique, group_ids: [ group0.id ] }
  let!(:other_site_node) { create :article_node_page, cur_site: other_site }
  let!(:other_site_article) do
    create(
      :article_page, cur_site: other_site, cur_node: other_site_node,
      contact_group: group, contact_group_contact_id: sub_contact.id, contact_group_relation: "related")
  end

  before do
    login_cms_user
  end

  context "unify contacts" do
    it do
      visit cms_groups_path(site: site)
      click_on group.trailing_name
      within "#addon-contact-agents-addons-group" do
        within ".list-item[data-id='#{main_contact.id}']" do
          expect(page).to have_css(".pages-used", text: "1")
        end
      end
      click_on I18n.t("contact.links.unify_to_main")

      expect do
        within "form#item-form" do
          click_on I18n.t("contact.buttons.unify")
        end
        wait_for_notice I18n.t("contact.notices.unified")
      end.to output.to_stdout

      Cms::Group.find(group.id).tap do |group1|
        expect(group1.contact_groups.count).to eq 1
        expect(group1.contact_groups.first.id).to eq main_contact.id
      end

      Article::Page.find(article1.id).tap do |article|
        expect(article.contact_group_contact_id).to eq main_contact.id
      end
      Article::Page.find(article2.id).tap do |article|
        expect(article.contact_group_contact_id).to eq main_contact.id
      end
      Article::Page.find(other_site_article.id).tap do |article|
        expect(article.contact_group_contact_id).to eq main_contact.id
      end

      visit cms_groups_path(site: site)
      click_on group.trailing_name
      within "#addon-contact-agents-addons-group" do
        within ".list-item[data-id='#{main_contact.id}']" do
          expect(page).to have_css(".pages-used", text: "3")
        end
      end
    end
  end
end
