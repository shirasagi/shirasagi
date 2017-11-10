require 'spec_helper'

describe "gws_monitor_management_trashes", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:item) { create :gws_monitor_topic, :gws_monitor_management_trashes }
  let(:item2) { create :gws_monitor_topic, :attend_group_ids }
  let(:item3) { create :gws_monitor_topic, :attend_group_ids, :article_deleted }
  let(:index_path) { gws_monitor_management_trashes_path site, gws_user }

  context "with auth", js: true do
    before { login_gws_user }

    it "#index" do
      item
      visit index_path
      wait_for_ajax
      expect(page).to have_content(item.name)
    end

    it "#index not deleted" do
      item2
      visit index_path
      wait_for_ajax
      expect(page).not_to have_content(item2.name)
    end

    it "#index deleted" do
      item3
      visit index_path
      wait_for_ajax
      expect(page).to have_content(item3.name)
    end
  end

  # it "#popup" do
  #   visit popup_gws_schedule_todo_path gws_site, item
  #   expect(page).to have_content(item.name)
  # end
  #
  # it "#finish" do
  #   visit finish_gws_schedule_todo_path gws_site, item
  #   wait_for_ajax
  #   expect(page).to have_content(item.name)
  # end
  #
  # it "#revert" do
  #   visit revert_gws_schedule_todo_path gws_site, item
  #   wait_for_ajax
  #   expect(page).to have_content(item.name)
  # end
  #
  # it "#disable" do
  #   visit disable_gws_schedule_todo_path gws_site, item
  #   wait_for_ajax
  #   expect(page).to have_no_content(item.name)
  # end
  #
  # it "#finish_all" do
  #   item
  #   visit gws_schedule_todos_path gws_site
  #   find('.list-head label.check input').set(true)
  #   page.accept_confirm do
  #     find('.finish-all').click
  #   end
  #   wait_for_ajax
  # end
  #
  # it "#revert_all" do
  #   item
  #   visit gws_schedule_todos_path gws_site
  #   find('.list-head label.check input').set(true)
  #   page.accept_confirm do
  #     find('.revert-all').click
  #   end
  #   wait_for_ajax
  # end
  #
  # it "#disable_all" do
  #   item
  #   visit gws_schedule_todos_path gws_site
  #   find('.list-head label.check input').set(true)
  #   page.accept_confirm do
  #     find('.disable-all').click
  #   end
  #   wait_for_ajax
  # end
  #
  # it "#index" do
  #   item
  #   visit gws_schedule_todos_path gws_site
  #   wait_for_ajax
  #   expect(page).to have_content(item.name)
  # end
  #
  # # it "#create" do
  # # end
  #
  # it "#new" do
  #   visit new_gws_schedule_todo_path gws_site
  #   wait_for_ajax
  # end
  #
  # it "#edit" do
  #   visit edit_gws_schedule_todo_path gws_site, item
  #   wait_for_ajax
  # end
  #
  # it "#show" do
  #   visit gws_schedule_todo_path gws_site, item
  #   wait_for_ajax
  #   expect(page).to have_content(item.name)
  # end
  #
  # # it "#update" do
  # # end
end
