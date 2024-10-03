require 'spec_helper'

describe "gws_workflow2_routes", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let(:permissions) do
    %w(
      use_gws2_workflow
      read_private_gws_workflow2_routes
      edit_private_gws_workflow2_routes
    )
  end
  let!(:role) { create :gws_role, cur_site: site, permissions: permissions }
  let!(:user1) { create :gws_user, group_ids: gws_user.group_ids, gws_role_ids: [ role.id ] }

  context "edit the route which readable_setting_range is 'private'" do
    let(:name1) { unique_id }
    let(:remark1) { Array.new(2) { unique_id } }
    let(:name2) { unique_id }
    let(:remark2) { Array.new(2) { unique_id } }
    let(:required_count_level1) { %w(false 1).sample }
    let(:required_count_level1_label) do
      if required_count_level1 == "false"
        I18n.t("workflow.options.required_count.all")
      else
        I18n.t("workflow.options.required_count.minimum", required_count: required_count_level1)
      end
    end
    let(:approver_attachment_use_level1) { %w(enabled disabled).sample }
    let(:approver_attachment_use_level1_label) { I18n.t("ss.options.state.#{approver_attachment_use_level1}") }
    let(:superior_label) { I18n.t("mongoid.attributes.gws/addon/group/affair_setting.superior_user_ids") }

    it do
      #
      # Create
      #
      login_user user1
      visit gws_workflow2_routes_path(site: site)
      within ".nav-menu" do
        click_on I18n.t("ss.links.new")
      end

      within "form#item-form" do
        fill_in "item[name]", with: name1
        fill_in "item[remark]", with: remark1.join("\n")

        # approver level 1
        within ".gws-workflow-route-approver-item[data-level='1']" do
          select required_count_level1_label, from: "item[required_counts][]"
          select approver_attachment_use_level1_label, from: "item[approver_attachment_uses][]"
          within "tr[data-user-type='new']" do
            select superior_label, from: "dummy-approver"
          end
        end

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Gws::Workflow2::Route.all.count).to eq 1
      Gws::Workflow2::Route.all.first.tap do |route|
        expect(route.site_id).to eq site.id
        expect(route.name).to eq name1
        expect(route.remark).to eq remark1.join("\r\n")
        expect(route.readable_setting_range).to eq "private"
        expect(route.readable_member_ids).to eq [ user1.id ]
        expect(route.readable_group_ids).to be_blank
        expect(route.readable_custom_group_ids).to be_blank
      end

      # Edit
      login_gws_user
      visit gws_workflow2_routes_path(site: site)
      click_on name1
      within ".nav-menu" do
        click_on I18n.t("ss.links.edit")
      end

      within "form#item-form" do
        fill_in "item[name]", with: name2
        fill_in "item[remark]", with: remark2.join("\n")

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Gws::Workflow2::Route.all.count).to eq 1
      Gws::Workflow2::Route.all.first.tap do |route|
        expect(route.site_id).to eq site.id
        expect(route.name).to eq name2
        expect(route.remark).to eq remark2.join("\r\n")
        expect(route.readable_setting_range).to eq "private"
        expect(route.readable_member_ids).to eq [ user1.id ]
        expect(route.readable_group_ids).to be_blank
        expect(route.readable_custom_group_ids).to be_blank
      end
    end
  end
end
