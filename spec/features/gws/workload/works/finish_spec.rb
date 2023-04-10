require 'spec_helper'

describe "gws_workload_works", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:show_path) { gws_workload_work_path site, item }
  let(:item) { create :gws_workload_work }

  context "with auth" do
    before { login_gws_user }

    it "#show" do
      visit show_path

      within ".nav-menu" do
        expect(page).to have_no_link I18n.t("gws/schedule/todo.links.revert")
        expect(page).to have_link I18n.t("gws/schedule/todo.links.finish")

        click_on I18n.t("gws/schedule/todo.links.finish")
      end
      within "form" do
        click_on I18n.t("gws/schedule/todo.links.finish")
      end
      wait_for_notice I18n.t('ss.notice.saved')
      item.reload

      within ".gws-comment-post" do
        within "#comment-#{item.last_comment.id}" do
          expect(page).to have_css(".achievement-rate", text: "100%")
        end
      end

      within ".nav-menu" do
        expect(page).to have_link I18n.t("gws/schedule/todo.links.revert")
        expect(page).to have_no_link I18n.t("gws/schedule/todo.links.finish")

        click_on I18n.t("gws/schedule/todo.links.revert")
      end
      within "form" do
        click_on I18n.t("gws/schedule/todo.links.revert")
      end
      wait_for_notice I18n.t('ss.notice.saved')
      item.reload

      within ".gws-comment-post" do
        within "#comment-#{item.last_comment.id}" do
          expect(page).to have_css(".achievement-rate", text: "0%")
        end
      end
    end
  end
end
