require 'spec_helper'

describe "gws_schedule_todo_readables", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let!(:category) { create(:gws_schedule_todo_category, cur_site: site, readable_setting_range: "public") }
  let!(:item1) do
    create(:gws_schedule_todo, cur_site: site, cur_user: user, member_ids: [user.id], user_ids: [user.id])
  end
  let!(:item2) do
    create(
      :gws_schedule_todo, cur_site: site, cur_user: user, member_ids: [user.id], user_ids: [user.id],
      category_ids: [ category.id ]
    )
  end

  before { login_user user }

  it do
    # Gws::Schedule::TodoCategory::ALL
    visit gws_schedule_todo_main_path(site: site)
    expect(page).to have_css(".list-item", text: item1.name)
    expect(page).to have_css(".list-item", text: item2.name)

    # Gws::Schedule::TodoCategory::NONE
    visit gws_schedule_todo_main_path(site: site)
    within ".gws-schedule-todo-categoy-navi" do
      click_on Gws::Schedule::TodoCategory::NONE.name
    end
    expect(page).to have_css(".list-item", text: item1.name)
    expect(page).to have_no_css(".list-item", text: item2.name)

    # category
    visit gws_schedule_todo_main_path(site: site)
    within ".gws-schedule-todo-categoy-navi" do
      click_on category.name
    end
    expect(page).to have_no_css(".list-item", text: item1.name)
    expect(page).to have_css(".list-item", text: item2.name)
  end
end
