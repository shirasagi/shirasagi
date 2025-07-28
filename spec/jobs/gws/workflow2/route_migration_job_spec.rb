require 'spec_helper'

describe Gws::Workflow2::RouteMigrationJob, dbscope: :example do
  let!(:site) { gws_site }
  let!(:admin) { gws_user }
  let!(:user1) { create(:gws_user, group_ids: admin.group_ids, gws_role_ids: admin.gws_role_ids) }
  let!(:user2) { create(:gws_user, group_ids: admin.group_ids, gws_role_ids: admin.gws_role_ids) }
  let!(:user3) { create(:gws_user, group_ids: admin.group_ids, gws_role_ids: admin.gws_role_ids) }

  let!(:route1_single_approver) do
    create(
      :gws_workflow_route, cur_site: site, name: unique_id, group_ids: admin.group_ids,
      approvers: [
        { "level" => 1, "user_id" => user1.id, "editable" => 1 }
      ],
      required_counts: [ false ], approver_attachment_uses: %w(enabled),
      circulations: [], circulation_attachment_uses: []
    )
  end
  let!(:route2_multiple_approvers) do
    create(
      :gws_workflow_route, cur_site: site, name: unique_id, group_ids: admin.group_ids,
      approvers: [
        { "level" => 1, "user_id" => user1.id, "editable" => 0 },
        { "level" => 1, "user_id" => user2.id, "editable" => 0 },
        { "level" => 2, "user_id" => user3.id, "editable" => 1 },
      ],
      required_counts: [ false, false ], approver_attachment_uses: %w(enabled enabled),
      circulations: [], circulation_attachment_uses: []
    )
  end
  let!(:route3_multiple_approvers_and_circulations) do
    create(
      :gws_workflow_route, cur_site: site, name: unique_id, group_ids: admin.group_ids,
      approvers: [
        { "level" => 1, "user_id" => user1.id },
        { "level" => 1, "user_id" => user2.id },
        { "level" => 2, "user_id" => user3.id },
      ],
      required_counts: [ false, false ], approver_attachment_uses: %w(enabled enabled),
      circulations: [
        { "level" => 1, "user_id" => user3.id },
        { "level" => 1, "user_id" => user1.id },
        { "level" => 2, "user_id" => user2.id },
      ],
      circulation_attachment_uses: %w(enabled enabled)
    )
  end

  it do
    expect { described_class.bind(site_id: site.id).perform_now }.to output.to_stdout

    expect(Job::Log.count).to eq 1
    Job::Log.first.tap do |log|
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
    end

    expect(Gws::Workflow2::Route.all.count).to eq 3

    Gws::Workflow2::Route.find_by(name: route1_single_approver.name).tap do |new_route|
      # Gws::Reference::Site
      expect(new_route.site_id).to eq site.id
      # Gws::Workflow2::Route
      expect(new_route.name).to eq route1_single_approver.name
      expect(new_route.order).to be_numeric
      expect(new_route.pull_up).to eq route1_single_approver.pull_up
      expect(new_route.on_remand).to eq route1_single_approver.on_remand
      new_route.approvers.tap do |new_approvers|
        source_approvers = route1_single_approver.approvers
        expect(new_approvers.count).to eq 1
        expect(new_approvers.count).to eq source_approvers.count
        expect(new_approvers[0][:level]).to eq source_approvers[0][:level]
        expect(new_approvers[0][:user_id]).to eq source_approvers[0][:user_id]
        expect(new_approvers[0][:editable]).to eq source_approvers[0][:editable]
        expect(new_approvers[0][:user_type]).to eq Gws::User.name
      end
      expect(new_route.required_counts).to eq route1_single_approver.required_counts
      expect(new_route.approver_attachment_uses).to eq route1_single_approver.approver_attachment_uses
      expect(new_route.circulations.count).to eq route1_single_approver.circulations.count
      expect(new_route.circulations).to be_blank
      expect(new_route.circulation_attachment_uses).to eq route1_single_approver.circulation_attachment_uses
      expect(new_route.remark).to include(route1_single_approver.name)
      # Gws::Reference::User
      expect(new_route.user_uid).to be_blank
      expect(new_route.user_name).to be_blank
      expect(new_route.user_group_id).to be_blank
      expect(new_route.user_group_name).to be_blank
      expect(new_route.user_id).to be_blank
      # Gws::Addon::Workflow2::RouteReadableSetting
      expect(new_route.readable_setting_range).to eq "public"
      expect(new_route.readable_group_ids).to be_blank
      expect(new_route.readable_member_ids).to be_blank
      expect(new_route.readable_custom_group_ids).to be_blank
      # Gws::Addon::Workflow2::RouteGroupPermission
      expect(new_route.group_ids).to eq route1_single_approver.group_ids
      expect(new_route.user_ids).to eq route1_single_approver.user_ids
      expect(new_route.custom_group_ids).to eq route1_single_approver.custom_group_ids
    end

    Gws::Workflow2::Route.find_by(name: route2_multiple_approvers.name).tap do |new_route|
      # Gws::Reference::Site
      expect(new_route.site_id).to eq site.id
      # Gws::Workflow2::Route
      expect(new_route.name).to eq route2_multiple_approvers.name
      expect(new_route.order).to be_numeric
      expect(new_route.pull_up).to eq route2_multiple_approvers.pull_up
      expect(new_route.on_remand).to eq route2_multiple_approvers.on_remand
      new_route.approvers.tap do |new_approvers|
        source_approvers = route2_multiple_approvers.approvers
        expect(new_approvers.count).to eq 3
        expect(new_approvers.count).to eq source_approvers.count
        expect(new_approvers[0][:level]).to eq source_approvers[0][:level]
        expect(new_approvers[0][:user_id]).to eq source_approvers[0][:user_id]
        expect(new_approvers[0][:editable]).to eq source_approvers[0][:editable]
        expect(new_approvers[0][:user_type]).to eq Gws::User.name
        expect(new_approvers[1][:level]).to eq source_approvers[1][:level]
        expect(new_approvers[1][:user_id]).to eq source_approvers[1][:user_id]
        expect(new_approvers[1][:editable]).to eq source_approvers[1][:editable]
        expect(new_approvers[1][:user_type]).to eq Gws::User.name
        expect(new_approvers[2][:level]).to eq source_approvers[2][:level]
        expect(new_approvers[2][:user_id]).to eq source_approvers[2][:user_id]
        expect(new_approvers[2][:editable]).to eq source_approvers[2][:editable]
        expect(new_approvers[2][:user_type]).to eq Gws::User.name
      end
      expect(new_route.required_counts).to eq route2_multiple_approvers.required_counts
      expect(new_route.approver_attachment_uses).to eq route2_multiple_approvers.approver_attachment_uses
      expect(new_route.circulations.count).to eq route2_multiple_approvers.circulations.count
      expect(new_route.circulations).to be_blank
      expect(new_route.circulation_attachment_uses).to eq route2_multiple_approvers.circulation_attachment_uses
      expect(new_route.remark).to include(route2_multiple_approvers.name)
      # Gws::Reference::User
      expect(new_route.user_uid).to be_blank
      expect(new_route.user_name).to be_blank
      expect(new_route.user_group_id).to be_blank
      expect(new_route.user_group_name).to be_blank
      expect(new_route.user_id).to be_blank
      # Gws::Addon::Workflow2::RouteReadableSetting
      expect(new_route.readable_setting_range).to eq "public"
      expect(new_route.readable_group_ids).to be_blank
      expect(new_route.readable_member_ids).to be_blank
      expect(new_route.readable_custom_group_ids).to be_blank
      # Gws::Addon::Workflow2::RouteGroupPermission
      expect(new_route.group_ids).to eq route2_multiple_approvers.group_ids
      expect(new_route.user_ids).to eq route2_multiple_approvers.user_ids
      expect(new_route.custom_group_ids).to eq route2_multiple_approvers.custom_group_ids
    end

    Gws::Workflow2::Route.find_by(name: route3_multiple_approvers_and_circulations.name).tap do |new_route|
      # Gws::Reference::Site
      expect(new_route.site_id).to eq site.id
      # Gws::Workflow2::Route
      expect(new_route.name).to eq route3_multiple_approvers_and_circulations.name
      expect(new_route.order).to be_numeric
      expect(new_route.pull_up).to eq route3_multiple_approvers_and_circulations.pull_up
      expect(new_route.on_remand).to eq route3_multiple_approvers_and_circulations.on_remand
      new_route.approvers.tap do |new_approvers|
        source_approvers = route3_multiple_approvers_and_circulations.approvers
        expect(new_approvers.count).to eq 3
        expect(new_approvers.count).to eq source_approvers.count
        expect(new_approvers[0][:level]).to eq source_approvers[0][:level]
        expect(new_approvers[0][:user_id]).to eq source_approvers[0][:user_id]
        expect(new_approvers[0][:editable]).to be_blank
        expect(new_approvers[0][:user_type]).to eq Gws::User.name
        expect(new_approvers[1][:level]).to eq source_approvers[1][:level]
        expect(new_approvers[1][:user_id]).to eq source_approvers[1][:user_id]
        expect(new_approvers[1][:editable]).to be_blank
        expect(new_approvers[1][:user_type]).to eq Gws::User.name
        expect(new_approvers[2][:level]).to eq source_approvers[2][:level]
        expect(new_approvers[2][:user_id]).to eq source_approvers[2][:user_id]
        expect(new_approvers[2][:editable]).to be_blank
        expect(new_approvers[2][:user_type]).to eq Gws::User.name
      end
      expect(new_route.required_counts).to eq route3_multiple_approvers_and_circulations.required_counts
      expect(new_route.approver_attachment_uses).to eq route3_multiple_approvers_and_circulations.approver_attachment_uses
      expect(new_route.circulations.count).to eq route3_multiple_approvers_and_circulations.circulations.count
      new_route.circulations.tap do |new_circulations|
        source_circulations = route3_multiple_approvers_and_circulations.circulations
        expect(new_circulations.count).to eq 3
        expect(new_circulations.count).to eq source_circulations.count
        expect(new_circulations[0][:level]).to eq source_circulations[0][:level]
        expect(new_circulations[0][:user_id]).to eq source_circulations[0][:user_id]
        expect(new_circulations[0][:user_type]).to eq Gws::User.name
        expect(new_circulations[1][:level]).to eq source_circulations[1][:level]
        expect(new_circulations[1][:user_id]).to eq source_circulations[1][:user_id]
        expect(new_circulations[1][:user_type]).to eq Gws::User.name
        expect(new_circulations[2][:level]).to eq source_circulations[2][:level]
        expect(new_circulations[2][:user_id]).to eq source_circulations[2][:user_id]
        expect(new_circulations[2][:user_type]).to eq Gws::User.name
      end
      expect(new_route.circulation_attachment_uses).to eq route3_multiple_approvers_and_circulations.circulation_attachment_uses
      expect(new_route.remark).to include(route3_multiple_approvers_and_circulations.name)
      # Gws::Reference::User
      expect(new_route.user_uid).to be_blank
      expect(new_route.user_name).to be_blank
      expect(new_route.user_group_id).to be_blank
      expect(new_route.user_group_name).to be_blank
      expect(new_route.user_id).to be_blank
      # Gws::Addon::Workflow2::RouteReadableSetting
      expect(new_route.readable_setting_range).to eq "public"
      expect(new_route.readable_group_ids).to be_blank
      expect(new_route.readable_member_ids).to be_blank
      expect(new_route.readable_custom_group_ids).to be_blank
      # Gws::Addon::Workflow2::RouteGroupPermission
      expect(new_route.group_ids).to eq route3_multiple_approvers_and_circulations.group_ids
      expect(new_route.user_ids).to eq route3_multiple_approvers_and_circulations.user_ids
      expect(new_route.custom_group_ids).to eq route3_multiple_approvers_and_circulations.custom_group_ids
    end
  end
end
