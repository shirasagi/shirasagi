require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:node) { create_once :faq_node_page, filename: "docs", name: "faq" }
  let!(:group) { create(:cms_group, name: unique_id) }
  let!(:user1) { create(:cms_user, name: unique_id, email: "#{unique_id}@example.jp", group_ids: [ group.id ]) }
  let(:index_path) { faq_pages_path site.id, node }

  context "Manipulate Permissions and check accessibility" do
    before do
      login_cms_user

      cms_user.cms_roles.each do |role|
        role.permissions = role.permissions - %w(close_other_faq_pages release_other_faq_pages)
        role.save!
      end
    end

    context "check make public if not permitted" do
      let!(:item) { create(:faq_page, cur_user: user1, cur_node: node, state: "closed") }

      it do
        visit index_path
        find("input[type='checkbox'][name='ids[]'][value='#{item.id}']").set(true)

        within ".list-head" do
          click_button I18n.t("ss.links.make_them_public")
        end

        within "form" do
          within "[data-id='#{item.id}']" do
            expect(page).to have_css(".list-item-error", text: I18n.t("ss.confirm.not_allowed_to_publish"))
          end
          click_button I18n.t("ss.links.make_them_public")
        end
        expect(page).to have_title("400")

        Faq::Page.find(item.id).tap do |after_item|
          expect(after_item.state).to eq "closed"
        end
      end
    end

    context "check make private if not permitted" do
      let!(:item) { create(:faq_page, cur_user: user1, cur_node: node, state: "public") }

      it do
        visit index_path
        find("input[type='checkbox'][name='ids[]'][value='#{item.id}']").set(true)

        within ".list-head" do
          click_button I18n.t("ss.links.make_them_close")
        end

        within "form" do
          within "[data-id='#{item.id}']" do
            expect(page).to have_css(".list-item-error", text: I18n.t("ss.confirm.not_allowed_to_close"))
          end
          click_button I18n.t("ss.links.make_them_close")
        end
        expect(page).to have_title("400")

        Faq::Page.find(item.id).tap do |after_item|
          expect(after_item.state).to eq "public"
        end
      end
    end
  end
end
