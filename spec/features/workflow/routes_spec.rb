require 'spec_helper'

describe "workflow_routes", type: :feature, dbscope: :example do
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:group) { cms_group }
  let(:index_path) { workflow_routes_path site.id }
  let(:new_path) { new_workflow_route_path site.id }

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

        click_on "グループを選択する"
        within "div#ajax-box table.index" do
          click_on group.name
        end

        within "dl.workflow-level-1" do
          click_on "承認者を選択する"
        end
        within "div#ajax-box table.index tbody.items" do
          click_on user.name
        end

        within "form#item-form" do
          click_on "保存"
        end
        expect(page).to have_css('#notice', text: I18n.t('views.notice.saved'), wait: 60)

        expect(Workflow::Route.count).to eq 1
        Workflow::Route.all.first.tap do |route|
          expect(route.name).to eq "sample"
          expect(route.group_ids).to eq [ group.id ]
          expect(route.approvers).to include({ level: 1, user_id: user.id })
          expect(route.required_counts).to eq [false, false, false, false, false]
        end
      end
    end
  end
end
