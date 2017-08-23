require 'spec_helper'

describe "gws_schedule_todos", type: :feature, dbscope: :example, js: true do
  let(:item) { create :gws_schedule_todo }

  before { login_gws_user }

  it "#popup" do
    visit popup_gws_schedule_todo_path gws_site, item
    expect(status_code).to eq 200
  end

  it "#finish" do
    visit finish_gws_schedule_todo_path gws_site, item
    expect(status_code).to eq 200
  end

  it "#revert" do
    visit revert_gws_schedule_todo_path gws_site, item
    expect(status_code).to eq 200
  end

  it "#disable" do
    visit disable_gws_schedule_todo_path gws_site, item
    expect(status_code).to eq 200
  end

  it "#finish_all" do
    item
    visit gws_schedule_todos_path gws_site
    find('.list-head label.check input').set(true)
    find('.finish-all').click
  end

  it "#revert_all" do
    item
    visit gws_schedule_todos_path gws_site
    find('.list-head label.check input').set(true)
    find('.revert-all').click
  end

  it "#disable_all" do
    item
    visit gws_schedule_todos_path gws_site
    find('.list-head label.check input').set(true)
    find('.disable-all').click
  end

  it "#index" do
    visit gws_schedule_todos_path gws_site
    expect(status_code).to eq 200
  end

  # it "#create" do
  # end

  it "#new" do
    visit new_gws_schedule_todo_path gws_site
    expect(status_code).to eq 200
  end

  it "#edit" do
    visit edit_gws_schedule_todo_path gws_site, item
    expect(status_code).to eq 200
  end

  it "#show" do
    visit gws_schedule_todo_path gws_site, item
    expect(status_code).to eq 200
  end

  # it "#update" do
  # end
end
