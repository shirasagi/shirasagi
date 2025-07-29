require 'spec_helper'

describe "gws_schedule_todo_readables", type: :feature, dbscope: :example, js: true do
  let(:item) { create :gws_schedule_todo }
  let(:group_index_path)  { gws_schedule_group_plans_path gws_site, gws_user.groups.first }

  before { login_gws_user }

  it "group_plans_member_link_check" do
    item
    visit group_index_path
    wait_for_js_ready
    within("div#cal-#{gws_user.id}.calendar.multiple.fc.fc-ltr.fc-unthemed") do
      expect(page).to have_content(item.name)
    end
    within("div#cal-#{sys_user.id}.calendar.multiple.fc.fc-ltr.fc-unthemed") do
      expect(page).to have_no_content(item.name)
    end
    expect(current_path).not_to eq sns_login_path
  end
end
