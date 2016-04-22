require 'spec_helper'

describe "workflow_routes", type: :feature, dbscope: :example do
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:group) { cms_group }
  let(:index_path) { workflow_routes_path site.id }
  let(:new_path) { new_workflow_route_path site.id }

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

    describe "#index" do
      it do
        visit index_path
        expect(current_path).not_to eq sns_login_path
      end
    end

    describe "#new", js: true do
      it do
        visit new_path
        within "form#item-form" do
          fill_in "item[name]", with: "sample"
        end

        click_link "グループを選択する"
        wait_for_cbox
        within "div#ajax-box table.index" do
          click_link group.name
        end

        within "dl.workflow-level-1" do
          click_link "承認者を選択する"
        end
        # wait a while to load contents of dialog
        wait_for_cbox
        within "div#ajax-box table.index tbody.items" do
          click_link user.name
        end

        within "form#item-form" do
          click_button "保存"
        end
        expect(status_code).to eq 200
        expect(page).not_to have_css("form#item-form")
      end
    end
  end
end
