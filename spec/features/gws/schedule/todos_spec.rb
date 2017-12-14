require 'spec_helper'

describe "gws_schedule_todos", type: :feature, dbscope: :example, js: true do
  let(:item) { create :gws_schedule_todo }
  let(:group_index_path)  { gws_schedule_group_plans_path gws_site, gws_user.groups.first }

  before { login_gws_user }

  it "group_plans_member_link_check" do
    item
    visit group_index_path
    wait_for_ajax
    within("div#cal-#{gws_user.id}.calendar.multiple.fc.fc-ltr.fc-unthemed") do
      expect(page).to have_content(item.name)
    end
    within("div#cal-#{sys_user.id}.calendar.multiple.fc.fc-ltr.fc-unthemed") do
      expect(page).to have_no_content(item.name)
    end
    expect(current_path).not_to eq sns_login_path
  end

  it "#finish" do
    visit finish_gws_schedule_todo_path gws_site, item
    wait_for_ajax
    expect(page).to have_content(item.name)
  end

  it "#revert" do
    visit revert_gws_schedule_todo_path gws_site, item
    wait_for_ajax
    expect(page).to have_content(item.name)
  end

  it "#disable" do
    visit disable_gws_schedule_todo_path gws_site, item
    wait_for_ajax
    expect(page).to have_no_content(item.name)
  end

  it "#finish_all" do
    item
    visit gws_schedule_todos_path gws_site
    find('.list-head label.check input').set(true)
    page.accept_confirm do
      find('.finish-all').click
    end
    wait_for_ajax
    expect(page).to have_no_content(item.name)
  end

  it "#revert_all" do
    item
    visit gws_schedule_todos_path gws_site
    find('.list-head label.check input').set(true)
    page.accept_confirm do
      find('.revert-all').click
    end
    wait_for_ajax
    expect(page).to have_content(item.name)
  end

  it "#disable_all" do
    item
    visit gws_schedule_todos_path gws_site
    find('.list-head label.check input').set(true)
    page.accept_confirm do
      find('.disable-all').click
    end
    wait_for_ajax
    expect(page).to have_no_content(item.name)
  end

  it "#index" do
    item
    visit gws_schedule_todos_path gws_site
    wait_for_ajax
    expect(page).to have_content(item.name)
  end

  # it "#create" do
  # end

  it "#new" do
    visit new_gws_schedule_todo_path gws_site
    wait_for_ajax
    expect(page).to have_content('基本情報')
  end

  it "#edit" do
    visit edit_gws_schedule_todo_path gws_site, item
    wait_for_ajax
    expect(page).to have_content('基本情報')
  end

  it "#show" do
    visit gws_schedule_todo_path gws_site, item
    wait_for_ajax
    expect(page).to have_content(item.name)
  end

  # it "#update" do
  # end
end
