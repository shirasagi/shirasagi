require 'spec_helper'

describe "gws_workflow_routes", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:approver_user) { create :gws_user, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
  let!(:circulation_user) { create :gws_user, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
  let(:name) { unique_id }
  let(:pull_up) { %w(enabled disabled).sample }
  let(:pull_up_label) { I18n.t("ss.options.state.#{pull_up}") }
  let(:on_remand) { %w(back_to_init back_to_previous).sample }
  let(:on_remand_label) { I18n.t("workflow.options.on_remand.#{on_remand}") }
  let(:required_count_level1) { %w(false 1).sample }
  let(:required_count_level1_label) do
    if required_count_level1 == "false"
      I18n.t("workflow.options.required_count.all")
    else
      I18n.t("workflow.options.required_count.minimum", required_count: required_count_level1)
    end
  end
  let(:required_count_level2) { %w(false 1).sample }
  let(:required_count_level2_label) do
    if required_count_level2 == "false"
      I18n.t("workflow.options.required_count.all")
    else
      I18n.t("workflow.options.required_count.minimum", required_count: required_count_level2)
    end
  end
  let(:required_count_level3) { %w(false 1).sample }
  let(:required_count_level3_label) do
    if required_count_level3 == "false"
      I18n.t("workflow.options.required_count.all")
    else
      I18n.t("workflow.options.required_count.minimum", required_count: required_count_level3)
    end
  end
  let(:approver_attachment_use_level1) { %w(enabled disabled).sample }
  let(:approver_attachment_use_level1_label) { I18n.t("ss.options.state.#{approver_attachment_use_level1}") }
  let(:approver_attachment_use_level2) { %w(enabled disabled).sample }
  let(:approver_attachment_use_level2_label) { I18n.t("ss.options.state.#{approver_attachment_use_level2}") }
  let(:approver_attachment_use_level3) { %w(enabled disabled).sample }
  let(:approver_attachment_use_level3_label) { I18n.t("ss.options.state.#{approver_attachment_use_level3}") }
  let(:circulation_attachment_use_level1) { %w(enabled disabled).sample }
  let(:circulation_attachment_use_level1_label) { I18n.t("ss.options.state.#{circulation_attachment_use_level1}") }
  let(:circulation_attachment_use_level2) { %w(enabled disabled).sample }
  let(:circulation_attachment_use_level2_label) { I18n.t("ss.options.state.#{circulation_attachment_use_level2}") }
  let(:circulation_attachment_use_level3) { %w(enabled disabled).sample }
  let(:circulation_attachment_use_level3_label) { I18n.t("ss.options.state.#{circulation_attachment_use_level3}") }

  before { login_gws_user }

  context "basic crud" do
    let(:superior_label) { I18n.t("mongoid.attributes.ss/model/user.superior_id") }

    it do
      #
      # Create
      #
      visit gws_workflow_routes_path(site: site)
      within ".nav-menu" do
        click_on I18n.t("ss.links.new")
      end

      within "form#item-form" do
        fill_in "item[name]", with: name
        select pull_up_label, from: "item[pull_up]"
        select on_remand_label, from: "item[on_remand]"
        within "#addon-basic" do
          wait_for_cbox_opened { click_on I18n.t("ss.apis.groups.index") }
        end
      end
      within_cbox do
        wait_for_cbox_closed { click_on group.section_name }
      end
      within "form#item-form" do
        # approver level 1
        within ".workflow-approvers.workflow-level-1" do
          select required_count_level1_label, from: "item[required_counts][]"
          select approver_attachment_use_level1_label, from: "item[approver_attachment_uses][]"
          wait_for_cbox_opened { click_on I18n.t("workflow.search_approvers.index") }
        end
      end
      within_cbox do
        wait_for_cbox_closed { click_on approver_user.name }
      end
      within "form#item-form" do
        # circulation level 1
        within ".workflow-circulations.workflow-circulation-level-1" do
          select circulation_attachment_use_level1_label, from: "item[circulation_attachment_uses][]"
          wait_for_cbox_opened { click_on I18n.t("workflow.search_circulations.index") }
        end
      end
      within_cbox do
        wait_for_cbox_closed { click_on circulation_user.name }
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Gws::Workflow::Route.all.count).to eq 1
      route = Gws::Workflow::Route.all.first
      expect(route.name).to eq name
      expect(route.pull_up).to eq pull_up
      expect(route.on_remand).to eq on_remand
      expect(route.approvers).to have(1).items
      route.approvers[0].tap do |approver|
        expect(approver[:level]).to eq 1
        expect(approver[:user_id]).to eq approver_user.id
        expect(approver[:editable]).to be_blank
      end
      expect(route.required_counts).to have(Gws::Workflow::Route::MAX_APPROVERS).items
      if required_count_level1 == "false"
        expect(route.required_counts[0]).to eq false
      else
        expect(route.required_counts[0]).to eq required_count_level1.to_i
      end
      expect(route.approver_attachment_uses).to have(Gws::Workflow::Route::MAX_APPROVERS).items
      expect(route.approver_attachment_uses[0]).to eq approver_attachment_use_level1
      expect(route.circulations).to have(1).items
      route.circulations[0].tap do |circulation|
        expect(circulation[:level]).to eq 1
        expect(circulation[:user_id]).to eq circulation_user.id
      end
      expect(route.circulation_attachment_uses).to have(Gws::Workflow::Route::MAX_CIRCULATIONS).items
      expect(route.circulation_attachment_uses[0]).to eq circulation_attachment_use_level1

      #
      # Update
      #
      visit gws_workflow_routes_path(site: site)
      click_on route.name
      within ".nav-menu" do
        click_on I18n.t("ss.links.edit")
      end
      wait_for_js_ready
      within "form#item-form" do
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      route.reload
      expect(route.name).to eq name
      expect(route.pull_up).to eq pull_up
      expect(route.on_remand).to eq on_remand
      expect(route.approvers).to have(1).items
      route.approvers[0].tap do |approver|
        expect(approver[:level]).to eq 1
        expect(approver[:user_id]).to eq approver_user.id
        expect(approver[:editable]).to be_blank
      end
      expect(route.required_counts).to have(Gws::Workflow::Route::MAX_APPROVERS).items
      if required_count_level1 == "false"
        expect(route.required_counts[0]).to eq false
      else
        expect(route.required_counts[0]).to eq required_count_level1.to_i
      end
      expect(route.approver_attachment_uses).to have(Gws::Workflow::Route::MAX_APPROVERS).items
      expect(route.approver_attachment_uses[0]).to eq approver_attachment_use_level1
      expect(route.circulations).to have(1).items
      route.circulations[0].tap do |circulation|
        expect(circulation[:level]).to eq 1
        expect(circulation[:user_id]).to eq circulation_user.id
      end
      expect(route.circulation_attachment_uses).to have(Gws::Workflow::Route::MAX_CIRCULATIONS).items
      expect(route.circulation_attachment_uses[0]).to eq circulation_attachment_use_level1

      #
      # Delete
      #
      visit gws_workflow_routes_path(site: site)
      click_on route.name
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end

      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect { route.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end
end
