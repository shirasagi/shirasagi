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
          select "無効", from: "item[pull_up]"

          click_on "グループを選択する"
        end

        wait_for_cbox do
          within "table.index" do
            wait_cbox_close { click_on group.name }
          end
        end

        within "form#item-form" do
          within "dl.workflow-level-1" do
            click_on "承認者を選択する"
          end
        end
        wait_for_cbox do
          within "table.index tbody.items" do
            wait_cbox_close { click_on user.name }
          end
        end

        within "form#item-form" do
          expect(page).to have_css("#addon-basic", text: group.name)
          within "#addon-workflow-agents-addons-approver_view dl.workflow-level-1" do
            expect(page).to have_css('[data-id="1,1"]', text: user.name)
          end
          click_on I18n.t('ss.buttons.save')
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'), wait: 60)

        expect(Workflow::Route.count).to eq 1
        Workflow::Route.all.first.tap do |route|
          expect(route.name).to eq "sample"
          expect(route.pull_up).to eq 'disabled'
          expect(route.group_ids).to eq [ group.id ]
          expect(route.approvers).to include({ level: 1, user_id: user.id })
          expect(route.required_counts).to eq [false, false, false, false, false]
        end
      end
    end
  end
end
