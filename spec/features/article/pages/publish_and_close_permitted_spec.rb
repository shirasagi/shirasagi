require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let!(:group) { create(:cms_group, name: unique_id) }
  let!(:user1) { create(:cms_user, name: unique_id, email: "#{unique_id}@example.jp", group_ids: [ group.id ]) }
  let!(:node) { create :article_node_page, filename: "docs", name: "article" }
  let!(:item1) { create(:article_page, cur_node: node, cur_user: user1, group_ids: user1.group_ids) }
  let!(:item2) { create(:article_page, cur_node: node, cur_user: cms_user, group_ids: cms_user.group_ids) }
  let(:index_path) { article_pages_path site.id, node }

  context "Manipulate Permissions and check accessibility" do
    before do
      login_cms_user

      cms_user.cms_roles.each do |role|
        role.permissions = role.permissions - ["close_other_article_pages" , "release_other_article_pages"]
        role.save!
      end

    end

    it "check make public if not permitted" do
      visit index_path
      wait_for_event_fired("ss:checked-all-list-items") do
        find('.list-head input[type="checkbox"]').set(true)
      end

      click_button I18n.t("ss.links.make_them_public")

      wait_for_ajax

      expect(page).to have_css("[data-id='#{item1.id}']", text: I18n.t("ss.confirm.not_allowed_to_publish"))
      expect(page).to have_css("[data-id='#{item2.id}'] [type='checkbox']")
    end

    it "check make private if not permitted" do
      visit index_path
      wait_for_event_fired("ss:checked-all-list-items") do
        find('.list-head input[type="checkbox"]').set(true)
      end

      click_button I18n.t("ss.links.make_them_close")

      wait_for_ajax

      expect(page).to have_css("[data-id='#{item1.id}']", text: I18n.t("ss.confirm.not_allowed_to_close"))
      expect(page).to have_css("[data-id='#{item2.id}'] [type='checkbox']")
    end
  end
end
