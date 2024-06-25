require 'spec_helper'

describe "mail_pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create_once :mail_page_node_page, filename: "node", name: "article" }
  let(:new_path) { new_mail_page_page_path site.id, node }

  let!(:cate_node) { create :category_node_node, cur_site: site }
  let!(:cate_page1) { create :category_node_page, cur_site: site, cur_node: cate_node }
  let!(:cate_page2) { create :category_node_page, cur_site: site, cur_node: cate_node }

  context "basic crud" do
    before { login_cms_user }

    context "st_catgories is empty" do
      it "#new" do
        visit new_path
        within "form#item-form" do
          fill_in "item[name]", with: "sample"
          ensure_addon_opened "#addon-category-agents-addons-category"
          within "#addon-category-agents-addons-category" do
            expect(page).to have_css("[name=\"item[category_ids][]\"][value=\"#{cate_node.id}\"]")
            expect(page).to have_css("[name=\"item[category_ids][]\"][value=\"#{cate_page1.id}\"]")
            expect(page).to have_css("[name=\"item[category_ids][]\"][value=\"#{cate_page2.id}\"]")

            first(:field, name: "item[category_ids][]", with: cate_page1.id).click
          end
          click_button I18n.t("ss.buttons.publish_save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        ensure_addon_opened "#addon-category-agents-addons-category"
        within "#addon-category-agents-addons-category" do
          expect(page).to have_text(cate_page1.name)
        end
      end
    end

    context "st_catgories is cate_page2" do
      before do
        node.st_category_ids = [cate_page2.id]
        node.save!
      end

      it "#new" do
        visit new_path
        within "form#item-form" do
          fill_in "item[name]", with: "sample"
          ensure_addon_opened "#addon-category-agents-addons-category"
          within "#addon-category-agents-addons-category" do
            expect(page).to have_no_css("[name=\"item[category_ids][]\"][value=\"#{cate_node.id}\"]")
            expect(page).to have_no_css("[name=\"item[category_ids][]\"][value=\"#{cate_page1.id}\"]")
            expect(page).to have_css("[name=\"item[category_ids][]\"][value=\"#{cate_page2.id}\"]")

            first(:field, name: "item[category_ids][]", with: cate_page2.id).click
          end
          click_button I18n.t("ss.buttons.publish_save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        ensure_addon_opened "#addon-category-agents-addons-category"
        within "#addon-category-agents-addons-category" do
          expect(page).to have_text(cate_page2.name)
        end
      end
    end
  end
end
