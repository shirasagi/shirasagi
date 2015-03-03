require 'spec_helper'

describe "workflow_routes" do
  subject(:site) { cms_site }
  subject(:user) { cms_user }
  subject(:group) { cms_group }
  subject(:index_path) { workflow_routes_path site.host }
  subject(:new_path) { new_workflow_route_path site.host }

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    # it "#new" do
    #   visit new_path
    #   within "form#item-form" do
    #     fill_in "item[name]", with: "sample"
    #   end
    #   click_link "グループを選択する"
    #   click_link group.name
    #   save_and_open_page
    #   print page.html
    #   click_link "承認者を選択する"
    #   click_link user.name
    #   within "form#item-form" do
    #     click_button "保存"
    #   end
    #   expect(status_code).to eq 200
    #   expect(current_path).not_to eq new_path
    #   expect(page).not_to have_css("form#item-form")
    # end
  end

end
