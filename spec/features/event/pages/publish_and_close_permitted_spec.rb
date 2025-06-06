require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  subject(:site) { cms_site }
  subject(:node) { create_once :event_node_page, filename: "docs", name: "event" }
  subject(:item) { create(:event_page, cur_node: node) }
  subject(:index_path) { event_pages_path site.id, node }
  let(:group) { create(:cms_group, name: unique_id) }
  let(:user1) { create(:cms_user, name: unique_id, email: "#{unique_id}@example.jp", group_ids: [ group.id ]) }

  context "Manipulate Permissions and check accessibilty" do

    before do
      login_cms_user
      item.user = user1
      item.save

      cms_user.cms_roles.each do |role|
        role.permissions = role.permissions - %w[close_other_event_pages release_other_event_pages]
        role.save!
      end

    end

    it "check make public if not permitted" do
      visit index_path
      find("input[type='checkbox'][name='ids[]'][value='#{item.id}']").set(true)

      click_button I18n.t("ss.links.make_them_public")

      wait_for_ajax

      expect(page).to have_content(I18n.t("ss.confirm.not_allowed_to_publish"))
    end

    it "check make private if not permitted" do
      visit index_path
      find("input[type='checkbox'][name='ids[]'][value='#{item.id}']").set(true)

      within ".list-head" do
        expect(page).to have_content(I18n.t("ss.links.make_them_close"))
        first("[type='button']", text: I18n.t("ss.links.make_them_close")).click
      end

      wait_for_ajax

      expect(page).to have_content(I18n.t("ss.confirm.not_allowed_to_close"))
    end
  end
end
