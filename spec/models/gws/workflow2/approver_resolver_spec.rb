require 'spec_helper'

describe Gws::Workflow2::ApproverResolver, type: :model, dbscope: :example do
  let!(:site) { gws_site }
  let!(:minimum_role) { create(:gws_role, cur_site: site, permissions: %w(use_gws_workflow2)) }
  let!(:user) { create(:gws_user, group_ids: gws_user.group_ids, gws_role_ids: [ minimum_role.id ]) }
  let!(:group) { user.groups.first }
  let(:item) { Gws::Workflow2::File.new }

  context "with :my_group" do
    context "with superior" do
      let!(:superior_user1) { create(:gws_user, group_ids: user.group_ids, gws_role_ids: user.gws_role_ids) }
      let!(:superior_user2) { create(:gws_user, group_ids: user.group_ids, gws_role_ids: user.gws_role_ids) }
      let!(:superior_user3) do
        # superior_user1だけが見える
        create(:gws_user, group_ids: user.group_ids, gws_role_ids: user.gws_role_ids, readable_member_ids: [ superior_user1.id ])
      end

      before do
        group.update(superior_user_ids: [ superior_user1.id, superior_user2.id, superior_user3.id ])
      end

      it do
        resolver = Gws::Workflow2::ApproverResolver.new(
          cur_site: site, cur_user: user, cur_group: group, route: :my_group, item: item)
        resolver.resolve

        expect(resolver.workflow_approvers).to have(2).items
        expect(resolver.workflow_approvers.map(&:level).uniq).to eq [1]
        expect(resolver.workflow_approvers.map(&:user_type).uniq).to eq %w(superior)
        expect(resolver.workflow_approvers.map(&:user).map(&:id)).to include(superior_user1.id, superior_user2.id)
        expect(resolver.workflow_approvers.map(&:editable).uniq).to eq [ nil ]
        expect(resolver.workflow_approvers.map(&:error).uniq).to eq [ nil ]
        expect(resolver.workflow_circulations).to be_blank
      end
    end

    context "without superior" do
      it do
        resolver = Gws::Workflow2::ApproverResolver.new(
          cur_site: site, cur_user: user, cur_group: group, route: :my_group, item: item)
        resolver.resolve

        expect(resolver.workflow_approvers).to have(1).items
        resolver.workflow_approvers[0].tap do |approver|
          expect(approver.level).to eq 1
          expect(approver.user_type).to eq "superior"
          expect(approver.user).to be_blank
          expect(approver.editable).to be_blank
          expect(approver.error).to eq I18n.t("gws/workflow2.errors.messages.superior_is_not_found")
        end
        expect(resolver.workflow_circulations).to be_blank
      end
    end
  end

  context "with Gws::Workflow2::Route" do
    context "with superior" do
      context "without errors" do
        # 上長の上長の上長まで正しく解決されるかを確認
        let!(:route) do
          create(
            :gws_workflow2_route, cur_site: site,
            approvers: [
              { "level" => 1, "user_type" => "superior", "user_id" => "superior", "editable" => "" },
              { "level" => 2, "user_type" => "superior", "user_id" => "superior", "editable" => 1 },
              { "level" => 3, "user_type" => "superior", "user_id" => "superior", "editable" => 1 },
            ],
            required_counts: [ false, false, false, false, false ],
            circulations: [
              { "level" => 1, "user_type" => "superior", "user_id" => "superior" },
              { "level" => 2, "user_type" => "superior", "user_id" => "superior" },
              { "level" => 3, "user_type" => "superior", "user_id" => "superior" },
            ]
          )
        end
        # user の上長
        let!(:superior_group1) { create(:gws_group, name: "#{site.name}/#{unique_id}") }
        let!(:superior_user1) { create(:gws_user, group_ids: [ superior_group1.id ], gws_role_ids: user.gws_role_ids) }
        # user の上長の上長
        let!(:superior_group2) { create(:gws_group, name: "#{site.name}/#{unique_id}") }
        let!(:superior_user2) { create(:gws_user, group_ids: [ superior_group2.id ], gws_role_ids: user.gws_role_ids) }
        # user の上長の上長の上長
        let!(:superior_group3) { create(:gws_group, name: "#{site.name}/#{unique_id}") }
        let!(:superior_user3) { create(:gws_user, group_ids: [ superior_group3.id ], gws_role_ids: user.gws_role_ids) }

        before do
          group.update(superior_user_ids: [ superior_user1.id ])
          superior_group1.update(superior_user_ids: [ superior_user2.id ])
          superior_group2.update(superior_user_ids: [ superior_user3.id ])
        end

        it do
          resolver = Gws::Workflow2::ApproverResolver.new(
            cur_site: site, cur_user: user, cur_group: group, route: route, item: item)
          resolver.resolve

          expect(resolver.workflow_approvers).to have(3).items
          resolver.workflow_approvers[0].tap do |approver|
            expect(approver.level).to eq 1
            expect(approver.user_type).to eq "superior"
            expect(approver.user.id).to eq superior_user1.id
            expect(approver.editable).to be_falsey
            expect(approver.error).to be_blank
          end
          resolver.workflow_approvers[1].tap do |approver|
            expect(approver.level).to eq 2
            expect(approver.user_type).to eq "superior"
            expect(approver.user.id).to eq superior_user2.id
            expect(approver.editable).to be_truthy
            expect(approver.error).to be_blank
          end
          resolver.workflow_approvers[2].tap do |approver|
            expect(approver.level).to eq 3
            expect(approver.user_type).to eq "superior"
            expect(approver.user.id).to eq superior_user3.id
            expect(approver.editable).to be_truthy
            expect(approver.error).to be_blank
          end

          expect(resolver.workflow_circulations).to have(3).items
          resolver.workflow_circulations[0].tap do |circulation|
            expect(circulation.level).to eq 1
            expect(circulation.user_type).to eq "superior"
            expect(circulation.user.id).to eq superior_user1.id
            expect(circulation.error).to be_blank
          end
          resolver.workflow_circulations[1].tap do |circulation|
            expect(circulation.level).to eq 2
            expect(circulation.user_type).to eq "superior"
            expect(circulation.user.id).to eq superior_user2.id
            expect(circulation.error).to be_blank
          end
          resolver.workflow_circulations[2].tap do |circulation|
            expect(circulation.level).to eq 3
            expect(circulation.user_type).to eq "superior"
            expect(circulation.user.id).to eq superior_user3.id
            expect(circulation.error).to be_blank
          end
        end
      end

      context "when superior is not found" do
        let!(:route) do
          create(
            :gws_workflow2_route, cur_site: site,
            approvers: [
              { "level" => 1, "user_type" => "superior", "user_id" => "superior", "editable" => "" },
              { "level" => 2, "user_type" => "superior", "user_id" => "superior", "editable" => 1 },
              { "level" => 3, "user_type" => "superior", "user_id" => "superior", "editable" => 1 },
            ],
            required_counts: [ false, false, false, false, false ],
            circulations: [
              { "level" => 1, "user_type" => "superior", "user_id" => "superior" },
              { "level" => 2, "user_type" => "superior", "user_id" => "superior" },
              { "level" => 3, "user_type" => "superior", "user_id" => "superior" },
            ]
          )
        end

        it do
          resolver = Gws::Workflow2::ApproverResolver.new(
            cur_site: site, cur_user: user, cur_group: group, route: route, item: item)
          resolver.resolve

          expect(resolver.workflow_approvers).to have(3).items
          resolver.workflow_approvers[0].tap do |approver|
            expect(approver.level).to eq 1
            expect(approver.user_type).to eq "superior"
            expect(approver.user).to be_blank
            expect(approver.editable).to be_blank
            expect(approver.error).to eq I18n.t("gws/workflow2.errors.messages.superior_is_not_found")
          end
          resolver.workflow_approvers[1].tap do |approver|
            expect(approver.level).to eq 2
            expect(approver.user_type).to eq "superior"
            expect(approver.user).to be_blank
            expect(approver.editable).to be_blank
            expect(approver.error).to eq I18n.t("gws/workflow2.errors.messages.lower_level_superior_is_not_set")
          end
          resolver.workflow_approvers[2].tap do |approver|
            expect(approver.level).to eq 3
            expect(approver.user_type).to eq "superior"
            expect(approver.user).to be_blank
            expect(approver.editable).to be_blank
            expect(approver.error).to eq I18n.t("gws/workflow2.errors.messages.lower_level_superior_is_not_set")
          end

          expect(resolver.workflow_circulations).to have(3).items
          resolver.workflow_circulations[0].tap do |circulation|
            expect(circulation.level).to eq 1
            expect(circulation.user_type).to eq "superior"
            expect(circulation.user).to be_blank
            expect(circulation.error).to eq I18n.t("gws/workflow2.errors.messages.superior_is_not_found")
          end
          resolver.workflow_circulations[1].tap do |circulation|
            expect(circulation.level).to eq 2
            expect(circulation.user_type).to eq "superior"
            expect(circulation.user).to be_blank
            expect(circulation.error).to eq I18n.t("gws/workflow2.errors.messages.lower_level_superior_is_not_set")
          end
          resolver.workflow_circulations[2].tap do |circulation|
            expect(circulation.level).to eq 3
            expect(circulation.user_type).to eq "superior"
            expect(circulation.user).to be_blank
            expect(circulation.error).to eq I18n.t("gws/workflow2.errors.messages.lower_level_superior_is_not_set")
          end
        end
      end
    end

    context "with gws/user_occupation" do
      let!(:occupation1) { create :gws_user_occupation, cur_site: site }
      let!(:occupation2) { create :gws_user_occupation, cur_site: site }
      let!(:occupation3) { create :gws_user_occupation, cur_site: site }

      context "without errors" do
        let!(:route) do
          create(
            :gws_workflow2_route, cur_site: site,
            approvers: [
              { "level" => 1, "user_type" => Gws::UserOccupation.name, "user_id" => occupation1.id, "editable" => "" },
              { "level" => 2, "user_type" => Gws::UserOccupation.name, "user_id" => occupation2.id, "editable" => 1 },
              { "level" => 3, "user_type" => Gws::UserOccupation.name, "user_id" => occupation3.id, "editable" => 1 },
            ],
            required_counts: [ false, false, false, false, false ],
            circulations: [
              { "level" => 1, "user_type" => Gws::UserOccupation.name, "user_id" => occupation3.id },
              { "level" => 2, "user_type" => Gws::UserOccupation.name, "user_id" => occupation1.id },
              { "level" => 3, "user_type" => Gws::UserOccupation.name, "user_id" => occupation2.id },
            ]
          )
        end
        let!(:user1_1) do
          create(:gws_user, occupation_ids: [ occupation1.id ], group_ids: [ group.id ], gws_role_ids: user.gws_role_ids)
        end
        let!(:user1_2) do
          create(:gws_user, occupation_ids: [ occupation1.id ], group_ids: [ group.id ], gws_role_ids: user.gws_role_ids)
        end
        let!(:user1_3) do
          # user1_1だけが見える
          create(
            :gws_user, occupation_ids: [ occupation1.id ], group_ids: [ group.id ], gws_role_ids: user.gws_role_ids,
            readable_member_ids: [ user1_1.id ])
        end
        let!(:user2_1) do
          create(:gws_user, occupation_ids: [ occupation2.id ], group_ids: [ group.id ], gws_role_ids: user.gws_role_ids)
        end
        let!(:user2_2) do
          create(:gws_user, occupation_ids: [ occupation2.id ], group_ids: [ group.id ], gws_role_ids: user.gws_role_ids)
        end
        let!(:user2_3) do
          # user2_1だけが見える
          create(
            :gws_user, occupation_ids: [ occupation2.id ], group_ids: [ group.id ], gws_role_ids: user.gws_role_ids,
            readable_member_ids: [ user2_1.id ])
        end
        let!(:user3_1) do
          create(:gws_user, occupation_ids: [ occupation3.id ], group_ids: [ group.id ], gws_role_ids: user.gws_role_ids)
        end
        let!(:user3_2) do
          create(:gws_user, occupation_ids: [ occupation3.id ], group_ids: [ group.id ], gws_role_ids: user.gws_role_ids)
        end
        let!(:user3_3) do
          # user3_1だけが見える
          create(
            :gws_user, occupation_ids: [ occupation3.id ], group_ids: [ group.id ], gws_role_ids: user.gws_role_ids,
            readable_member_ids: [ user3_1.id ])
        end

        it do
          resolver = Gws::Workflow2::ApproverResolver.new(
            cur_site: site, cur_user: user, cur_group: group, route: route, item: item)
          resolver.resolve

          expect(resolver.workflow_approvers).to have(6).items
          resolver.workflow_approvers[0].tap do |approver|
            expect(approver.level).to eq 1
            expect(approver.user_type).to eq Gws::UserOccupation.name
            expect(approver.user.id).to eq user1_1.id
            expect(approver.editable).to be_falsey
            expect(approver.error).to be_blank
          end
          resolver.workflow_approvers[1].tap do |approver|
            expect(approver.level).to eq 1
            expect(approver.user_type).to eq Gws::UserOccupation.name
            expect(approver.user.id).to eq user1_2.id
            expect(approver.editable).to be_falsey
            expect(approver.error).to be_blank
          end
          resolver.workflow_approvers[2].tap do |approver|
            expect(approver.level).to eq 2
            expect(approver.user_type).to eq Gws::UserOccupation.name
            expect(approver.user.id).to eq user2_1.id
            expect(approver.editable).to be_truthy
            expect(approver.error).to be_blank
          end
          resolver.workflow_approvers[3].tap do |approver|
            expect(approver.level).to eq 2
            expect(approver.user_type).to eq Gws::UserOccupation.name
            expect(approver.user.id).to eq user2_2.id
            expect(approver.editable).to be_truthy
            expect(approver.error).to be_blank
          end
          resolver.workflow_approvers[4].tap do |approver|
            expect(approver.level).to eq 3
            expect(approver.user_type).to eq Gws::UserOccupation.name
            expect(approver.user.id).to eq user3_1.id
            expect(approver.editable).to be_truthy
            expect(approver.error).to be_blank
          end
          resolver.workflow_approvers[5].tap do |approver|
            expect(approver.level).to eq 3
            expect(approver.user_type).to eq Gws::UserOccupation.name
            expect(approver.user.id).to eq user3_2.id
            expect(approver.editable).to be_truthy
            expect(approver.error).to be_blank
          end

          expect(resolver.workflow_circulations).to have(6).items
          resolver.workflow_circulations[0].tap do |circulation|
            expect(circulation.level).to eq 1
            expect(circulation.user_type).to eq Gws::UserOccupation.name
            expect(circulation.user.id).to eq user3_1.id
            expect(circulation.error).to be_blank
          end
          resolver.workflow_circulations[1].tap do |circulation|
            expect(circulation.level).to eq 1
            expect(circulation.user_type).to eq Gws::UserOccupation.name
            expect(circulation.user.id).to eq user3_2.id
            expect(circulation.error).to be_blank
          end
          resolver.workflow_circulations[2].tap do |circulation|
            expect(circulation.level).to eq 2
            expect(circulation.user_type).to eq Gws::UserOccupation.name
            expect(circulation.user.id).to eq user1_1.id
            expect(circulation.error).to be_blank
          end
          resolver.workflow_circulations[3].tap do |circulation|
            expect(circulation.level).to eq 2
            expect(circulation.user_type).to eq Gws::UserOccupation.name
            expect(circulation.user.id).to eq user1_2.id
            expect(circulation.error).to be_blank
          end
          resolver.workflow_circulations[4].tap do |circulation|
            expect(circulation.level).to eq 3
            expect(circulation.user_type).to eq Gws::UserOccupation.name
            expect(circulation.user.id).to eq user2_1.id
            expect(circulation.error).to be_blank
          end
          resolver.workflow_circulations[5].tap do |circulation|
            expect(circulation.level).to eq 3
            expect(circulation.user_type).to eq Gws::UserOccupation.name
            expect(circulation.user.id).to eq user2_2.id
            expect(circulation.error).to be_blank
          end
        end
      end

      context "with errors" do
        let!(:route) do
          create(
            :gws_workflow2_route, cur_site: site,
            approvers: [
              { "level" => 1, "user_type" => Gws::UserOccupation.name, "user_id" => occupation1.id, "editable" => "" },
              { "level" => 2, "user_type" => Gws::UserOccupation.name, "user_id" => occupation2.id, "editable" => 1 },
              { "level" => 3, "user_type" => Gws::UserOccupation.name, "user_id" => 1001, "editable" => 1 },
            ],
            required_counts: [ false, false, false, false, false ],
            circulations: [
              { "level" => 1, "user_type" => Gws::UserOccupation.name, "user_id" => occupation3.id },
              { "level" => 2, "user_type" => Gws::UserOccupation.name, "user_id" => occupation1.id },
              { "level" => 3, "user_type" => Gws::UserOccupation.name, "user_id" => 1001 },
            ]
          )
        end
        let!(:other_group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
        let!(:user1) do
          create(:gws_user, occupation_ids: [ occupation1.id ], group_ids: [ other_group.id ], gws_role_ids: user.gws_role_ids)
        end

        it do
          resolver = Gws::Workflow2::ApproverResolver.new(
            cur_site: site, cur_user: user, cur_group: group, route: route, item: item)
          resolver.resolve

          expect(resolver.workflow_approvers).to have(3).items
          resolver.workflow_approvers[0].tap do |approver|
            expect(approver.level).to eq 1
            expect(approver.user_type).to eq Gws::UserOccupation.name
            expect(approver.user).to be_blank
            expect(approver.editable).to be_blank
            error = I18n.t("gws/workflow2.errors.messages.user_whos_occupation_is_not_found", occupation_name: occupation1.name)
            expect(approver.error).to eq error
          end
          resolver.workflow_approvers[1].tap do |approver|
            expect(approver.level).to eq 2
            expect(approver.user_type).to eq Gws::UserOccupation.name
            expect(approver.user).to be_blank
            expect(approver.editable).to be_blank
            error = I18n.t("gws/workflow2.errors.messages.user_whos_occupation_is_not_found", occupation_name: occupation2.name)
            expect(approver.error).to eq error
          end
          resolver.workflow_approvers[2].tap do |approver|
            expect(approver.level).to eq 3
            expect(approver.user_type).to eq Gws::UserOccupation.name
            expect(approver.user).to be_blank
            expect(approver.editable).to be_blank
            expect(approver.error).to eq I18n.t("gws/workflow2.errors.messages.user_occupation_is_not_found")
          end

          expect(resolver.workflow_circulations).to have(3).items
          resolver.workflow_circulations[0].tap do |circulation|
            expect(circulation.level).to eq 1
            expect(circulation.user_type).to eq Gws::UserOccupation.name
            expect(circulation.user).to be_blank
            error = I18n.t("gws/workflow2.errors.messages.user_whos_occupation_is_not_found", occupation_name: occupation3.name)
            expect(circulation.error).to eq error
          end
          resolver.workflow_circulations[1].tap do |circulation|
            expect(circulation.level).to eq 2
            expect(circulation.user_type).to eq Gws::UserOccupation.name
            expect(circulation.user).to be_blank
            error = I18n.t("gws/workflow2.errors.messages.user_whos_occupation_is_not_found", occupation_name: occupation1.name)
            expect(circulation.error).to eq error
          end
          resolver.workflow_circulations[2].tap do |circulation|
            expect(circulation.level).to eq 3
            expect(circulation.user_type).to eq Gws::UserOccupation.name
            expect(circulation.user).to be_blank
            expect(circulation.error).to eq I18n.t("gws/workflow2.errors.messages.user_occupation_is_not_found")
          end
        end
      end
    end

    context "with gws/user_title" do
      let!(:title1) { create :gws_user_title, cur_site: site }
      let!(:title2) { create :gws_user_title, cur_site: site }
      let!(:title3) { create :gws_user_title, cur_site: site }

      context "without errors" do
        let!(:route) do
          create(
            :gws_workflow2_route, cur_site: site,
            approvers: [
              { "level" => 1, "user_type" => Gws::UserTitle.name, "user_id" => title1.id, "editable" => "" },
              { "level" => 2, "user_type" => Gws::UserTitle.name, "user_id" => title2.id, "editable" => 1 },
              { "level" => 3, "user_type" => Gws::UserTitle.name, "user_id" => title3.id, "editable" => 1 },
            ],
            required_counts: [ false, false, false, false, false ],
            circulations: [
              { "level" => 1, "user_type" => Gws::UserTitle.name, "user_id" => title3.id },
              { "level" => 2, "user_type" => Gws::UserTitle.name, "user_id" => title1.id },
              { "level" => 3, "user_type" => Gws::UserTitle.name, "user_id" => title2.id },
            ]
          )
        end
        let!(:user1_1) do
          create(:gws_user, title_ids: [ title1.id ], group_ids: [ group.id ], gws_role_ids: user.gws_role_ids)
        end
        let!(:user1_2) do
          create(:gws_user, title_ids: [ title1.id ], group_ids: [ group.id ], gws_role_ids: user.gws_role_ids)
        end
        let!(:user1_3) do
          # user1_1だけが見える
          create(
            :gws_user, title_ids: [ title1.id ], group_ids: [ group.id ], gws_role_ids: user.gws_role_ids,
            readable_member_ids: [ user1_1.id ])
        end
        let!(:user2_1) do
          create(:gws_user, title_ids: [ title2.id ], group_ids: [ group.id ], gws_role_ids: user.gws_role_ids)
        end
        let!(:user2_2) do
          create(:gws_user, title_ids: [ title2.id ], group_ids: [ group.id ], gws_role_ids: user.gws_role_ids)
        end
        let!(:user2_3) do
          # user2_1だけが見える
          create(
            :gws_user, title_ids: [ title2.id ], group_ids: [ group.id ], gws_role_ids: user.gws_role_ids,
            readable_member_ids: [ user2_1.id ])
        end
        let!(:user3_1) do
          create(:gws_user, title_ids: [ title3.id ], group_ids: [ group.id ], gws_role_ids: user.gws_role_ids)
        end
        let!(:user3_2) do
          create(:gws_user, title_ids: [ title3.id ], group_ids: [ group.id ], gws_role_ids: user.gws_role_ids)
        end
        let!(:user3_3) do
          # user3_1だけが見える
          create(
            :gws_user, title_ids: [ title3.id ], group_ids: [ group.id ], gws_role_ids: user.gws_role_ids,
            readable_member_ids: [ user3_1.id ])
        end

        it do
          resolver = Gws::Workflow2::ApproverResolver.new(
            cur_site: site, cur_user: user, cur_group: group, route: route, item: item)
          resolver.resolve

          expect(resolver.workflow_approvers).to have(6).items
          resolver.workflow_approvers[0].tap do |approver|
            expect(approver.level).to eq 1
            expect(approver.user_type).to eq Gws::UserTitle.name
            expect(approver.user.id).to eq user1_1.id
            expect(approver.editable).to be_falsey
            expect(approver.error).to be_blank
          end
          resolver.workflow_approvers[1].tap do |approver|
            expect(approver.level).to eq 1
            expect(approver.user_type).to eq Gws::UserTitle.name
            expect(approver.user.id).to eq user1_2.id
            expect(approver.editable).to be_falsey
            expect(approver.error).to be_blank
          end
          resolver.workflow_approvers[2].tap do |approver|
            expect(approver.level).to eq 2
            expect(approver.user_type).to eq Gws::UserTitle.name
            expect(approver.user.id).to eq user2_1.id
            expect(approver.editable).to be_truthy
            expect(approver.error).to be_blank
          end
          resolver.workflow_approvers[3].tap do |approver|
            expect(approver.level).to eq 2
            expect(approver.user_type).to eq Gws::UserTitle.name
            expect(approver.user.id).to eq user2_2.id
            expect(approver.editable).to be_truthy
            expect(approver.error).to be_blank
          end
          resolver.workflow_approvers[4].tap do |approver|
            expect(approver.level).to eq 3
            expect(approver.user_type).to eq Gws::UserTitle.name
            expect(approver.user.id).to eq user3_1.id
            expect(approver.editable).to be_truthy
            expect(approver.error).to be_blank
          end
          resolver.workflow_approvers[5].tap do |approver|
            expect(approver.level).to eq 3
            expect(approver.user_type).to eq Gws::UserTitle.name
            expect(approver.user.id).to eq user3_2.id
            expect(approver.editable).to be_truthy
            expect(approver.error).to be_blank
          end

          expect(resolver.workflow_circulations).to have(6).items
          resolver.workflow_circulations[0].tap do |circulation|
            expect(circulation.level).to eq 1
            expect(circulation.user_type).to eq Gws::UserTitle.name
            expect(circulation.user.id).to eq user3_1.id
            expect(circulation.error).to be_blank
          end
          resolver.workflow_circulations[1].tap do |circulation|
            expect(circulation.level).to eq 1
            expect(circulation.user_type).to eq Gws::UserTitle.name
            expect(circulation.user.id).to eq user3_2.id
            expect(circulation.error).to be_blank
          end
          resolver.workflow_circulations[2].tap do |circulation|
            expect(circulation.level).to eq 2
            expect(circulation.user_type).to eq Gws::UserTitle.name
            expect(circulation.user.id).to eq user1_1.id
            expect(circulation.error).to be_blank
          end
          resolver.workflow_circulations[3].tap do |circulation|
            expect(circulation.level).to eq 2
            expect(circulation.user_type).to eq Gws::UserTitle.name
            expect(circulation.user.id).to eq user1_2.id
            expect(circulation.error).to be_blank
          end
          resolver.workflow_circulations[4].tap do |circulation|
            expect(circulation.level).to eq 3
            expect(circulation.user_type).to eq Gws::UserTitle.name
            expect(circulation.user.id).to eq user2_1.id
            expect(circulation.error).to be_blank
          end
          resolver.workflow_circulations[5].tap do |circulation|
            expect(circulation.level).to eq 3
            expect(circulation.user_type).to eq Gws::UserTitle.name
            expect(circulation.user.id).to eq user2_2.id
            expect(circulation.error).to be_blank
          end
        end
      end

      context "with errors" do
        let!(:route) do
          create(
            :gws_workflow2_route, cur_site: site,
            approvers: [
              { "level" => 1, "user_type" => Gws::UserTitle.name, "user_id" => title1.id, "editable" => "" },
              { "level" => 2, "user_type" => Gws::UserTitle.name, "user_id" => title2.id, "editable" => 1 },
              { "level" => 3, "user_type" => Gws::UserTitle.name, "user_id" => 1001, "editable" => 1 },
            ],
            required_counts: [ false, false, false, false, false ],
            circulations: [
              { "level" => 1, "user_type" => Gws::UserTitle.name, "user_id" => title3.id },
              { "level" => 2, "user_type" => Gws::UserTitle.name, "user_id" => title1.id },
              { "level" => 3, "user_type" => Gws::UserTitle.name, "user_id" => 1001 },
            ]
          )
        end
        let!(:other_group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
        let!(:user1) do
          create(:gws_user, title_ids: [ title1.id ], group_ids: [ other_group.id ], gws_role_ids: user.gws_role_ids)
        end

        it do
          resolver = Gws::Workflow2::ApproverResolver.new(
            cur_site: site, cur_user: user, cur_group: group, route: route, item: item)
          resolver.resolve

          expect(resolver.workflow_approvers).to have(3).items
          resolver.workflow_approvers[0].tap do |approver|
            expect(approver.level).to eq 1
            expect(approver.user_type).to eq Gws::UserTitle.name
            expect(approver.user).to be_blank
            expect(approver.editable).to be_blank
            error = I18n.t("gws/workflow2.errors.messages.user_whos_title_is_not_found", title_name: title1.name)
            expect(approver.error).to eq error
          end
          resolver.workflow_approvers[1].tap do |approver|
            expect(approver.level).to eq 2
            expect(approver.user_type).to eq Gws::UserTitle.name
            expect(approver.user).to be_blank
            expect(approver.editable).to be_blank
            error = I18n.t("gws/workflow2.errors.messages.user_whos_title_is_not_found", title_name: title2.name)
            expect(approver.error).to eq error
          end
          resolver.workflow_approvers[2].tap do |approver|
            expect(approver.level).to eq 3
            expect(approver.user_type).to eq Gws::UserTitle.name
            expect(approver.user).to be_blank
            expect(approver.editable).to be_blank
            expect(approver.error).to eq I18n.t("gws/workflow2.errors.messages.user_title_is_not_found")
          end

          expect(resolver.workflow_circulations).to have(3).items
          resolver.workflow_circulations[0].tap do |circulation|
            expect(circulation.level).to eq 1
            expect(circulation.user_type).to eq Gws::UserTitle.name
            expect(circulation.user).to be_blank
            error = I18n.t("gws/workflow2.errors.messages.user_whos_title_is_not_found", title_name: title3.name)
            expect(circulation.error).to eq error
          end
          resolver.workflow_circulations[1].tap do |circulation|
            expect(circulation.level).to eq 2
            expect(circulation.user_type).to eq Gws::UserTitle.name
            expect(circulation.user).to be_blank
            error = I18n.t("gws/workflow2.errors.messages.user_whos_title_is_not_found", title_name: title1.name)
            expect(circulation.error).to eq error
          end
          resolver.workflow_circulations[2].tap do |circulation|
            expect(circulation.level).to eq 3
            expect(circulation.user_type).to eq Gws::UserTitle.name
            expect(circulation.user).to be_blank
            expect(circulation.error).to eq I18n.t("gws/workflow2.errors.messages.user_title_is_not_found")
          end
        end
      end
    end

    context "with gws/user" do
      context "without errors" do
        let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
        let!(:user1_1) { create(:gws_user, group_ids: [ group1.id ], gws_role_ids: user.gws_role_ids) }
        let!(:user1_2) do
          # user1_1だけが見える
          create(:gws_user, group_ids: [ group1.id ], gws_role_ids: user.gws_role_ids, readable_member_ids: [ user1_1.id ])
        end
        let!(:group2) { create :gws_group, name: "#{site.name}/#{unique_id}" }
        let!(:user2_1) { create(:gws_user, group_ids: [ group2.id ], gws_role_ids: user.gws_role_ids) }
        let!(:user2_2) do
          # user2_1だけが見える
          create(:gws_user, group_ids: [ group2.id ], gws_role_ids: user.gws_role_ids, readable_member_ids: [ user2_1.id ])
        end
        let!(:group3) { create :gws_group, name: "#{site.name}/#{unique_id}" }
        let!(:user3_1) { create(:gws_user, group_ids: [ group3.id ], gws_role_ids: user.gws_role_ids) }
        let!(:user3_2) do
          # user3_1だけが見える
          create(:gws_user, group_ids: [ group3.id ], gws_role_ids: user.gws_role_ids, readable_member_ids: [ user3_1.id ])
        end
        let!(:route) do
          create(
            :gws_workflow2_route, cur_site: site,
            approvers: [
              { "level" => 1, "user_type" => Gws::User.name, "user_id" => user1_1.id, "editable" => "" },
              { "level" => 1, "user_type" => Gws::User.name, "user_id" => user1_2.id, "editable" => "" },
              { "level" => 2, "user_type" => Gws::User.name, "user_id" => user2_1.id, "editable" => 1 },
              { "level" => 2, "user_type" => Gws::User.name, "user_id" => user2_2.id, "editable" => 1 },
              { "level" => 3, "user_type" => Gws::User.name, "user_id" => user3_1.id, "editable" => 1 },
              { "level" => 3, "user_type" => Gws::User.name, "user_id" => user3_2.id, "editable" => 1 },
            ],
            required_counts: [ 1, 1, 1, false, false ],
            circulations: [
              { "level" => 1, "user_type" => Gws::User.name, "user_id" => user3_1.id },
              { "level" => 1, "user_type" => Gws::User.name, "user_id" => user3_2.id },
              { "level" => 2, "user_type" => Gws::User.name, "user_id" => user1_1.id },
              { "level" => 2, "user_type" => Gws::User.name, "user_id" => user1_2.id },
              { "level" => 3, "user_type" => Gws::User.name, "user_id" => user2_1.id },
              { "level" => 3, "user_type" => Gws::User.name, "user_id" => user2_2.id },
            ]
          )
        end

        it do
          resolver = Gws::Workflow2::ApproverResolver.new(
            cur_site: site, cur_user: user, cur_group: group, route: route, item: item)
          resolver.resolve

          expect(resolver.workflow_approvers).to have(6).items
          resolver.workflow_approvers[0].tap do |approver|
            expect(approver.level).to eq 1
            expect(approver.user_type).to eq Gws::User.name
            expect(approver.user.id).to eq user1_1.id
            expect(approver.editable).to be_falsey
            expect(approver.error).to be_blank
          end
          resolver.workflow_approvers[1].tap do |approver|
            expect(approver.level).to eq 1
            expect(approver.user_type).to eq Gws::User.name
            expect(approver.user).to be_blank
            expect(approver.editable).to be_blank
            expect(approver.error).to eq I18n.t("gws/workflow2.errors.messages.user_is_not_found")
          end
          resolver.workflow_approvers[2].tap do |approver|
            expect(approver.level).to eq 2
            expect(approver.user_type).to eq Gws::User.name
            expect(approver.user.id).to eq user2_1.id
            expect(approver.editable).to be_truthy
            expect(approver.error).to be_blank
          end
          resolver.workflow_approvers[3].tap do |approver|
            expect(approver.level).to eq 2
            expect(approver.user_type).to eq Gws::User.name
            expect(approver.user).to be_blank
            expect(approver.editable).to be_blank
            expect(approver.error).to eq I18n.t("gws/workflow2.errors.messages.user_is_not_found")
          end
          resolver.workflow_approvers[4].tap do |approver|
            expect(approver.level).to eq 3
            expect(approver.user_type).to eq Gws::User.name
            expect(approver.user.id).to eq user3_1.id
            expect(approver.editable).to be_truthy
            expect(approver.error).to be_blank
          end
          resolver.workflow_approvers[5].tap do |approver|
            expect(approver.level).to eq 3
            expect(approver.user_type).to eq Gws::User.name
            expect(approver.user).to be_blank
            expect(approver.editable).to be_blank
            expect(approver.error).to eq I18n.t("gws/workflow2.errors.messages.user_is_not_found")
          end

          expect(resolver.workflow_circulations).to have(6).items
          resolver.workflow_circulations[0].tap do |circulation|
            expect(circulation.level).to eq 1
            expect(circulation.user_type).to eq Gws::User.name
            expect(circulation.user.id).to eq user3_1.id
            expect(circulation.error).to be_blank
          end
          resolver.workflow_circulations[1].tap do |circulation|
            expect(circulation.level).to eq 1
            expect(circulation.user_type).to eq Gws::User.name
            expect(circulation.user).to be_blank
            expect(circulation.error).to eq I18n.t("gws/workflow2.errors.messages.user_is_not_found")
          end
          resolver.workflow_circulations[2].tap do |circulation|
            expect(circulation.level).to eq 2
            expect(circulation.user_type).to eq Gws::User.name
            expect(circulation.user.id).to eq user1_1.id
            expect(circulation.error).to be_blank
          end
          resolver.workflow_circulations[3].tap do |circulation|
            expect(circulation.level).to eq 2
            expect(circulation.user_type).to eq Gws::User.name
            expect(circulation.user).to be_blank
            expect(circulation.error).to eq I18n.t("gws/workflow2.errors.messages.user_is_not_found")
          end
          resolver.workflow_circulations[4].tap do |circulation|
            expect(circulation.level).to eq 3
            expect(circulation.user_type).to eq Gws::User.name
            expect(circulation.user.id).to eq user2_1.id
            expect(circulation.error).to be_blank
          end
          resolver.workflow_circulations[5].tap do |circulation|
            expect(circulation.level).to eq 3
            expect(circulation.user_type).to eq Gws::User.name
            expect(circulation.user).to be_blank
            expect(circulation.error).to eq I18n.t("gws/workflow2.errors.messages.user_is_not_found")
          end
        end
      end

      context "with errors" do
        let(:now) { Time.zone.now.change(usec: 0) }
        let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
        let!(:user1) do
          create(:gws_user, group_ids: [ group1.id ], gws_role_ids: user.gws_role_ids, account_expiration_date: now)
        end
        let!(:other_site) { create :gws_group, name: unique_id }
        let!(:user2) { create(:gws_user, group_ids: [ other_site.id ], gws_role_ids: user.gws_role_ids) }
        let!(:user3) { create(:gws_user, group_ids: [ other_site.id ], gws_role_ids: user.gws_role_ids) }
        let!(:route) do
          create(
            :gws_workflow2_route, cur_site: site,
            approvers: [
              { "level" => 1, "user_type" => Gws::User.name, "user_id" => user1.id, "editable" => "" },
              { "level" => 2, "user_type" => Gws::User.name, "user_id" => user2.id, "editable" => 1 },
              { "level" => 3, "user_type" => Gws::User.name, "user_id" => 1001, "editable" => 1 },
            ],
            required_counts: [ false, false, false, false, false ],
            circulations: [
              { "level" => 1, "user_type" => Gws::User.name, "user_id" => user3.id },
              { "level" => 2, "user_type" => Gws::User.name, "user_id" => user1.id },
              { "level" => 3, "user_type" => Gws::User.name, "user_id" => 1001 },
            ]
          )
        end

        it do
          resolver = Gws::Workflow2::ApproverResolver.new(
            cur_site: site, cur_user: user, cur_group: group, route: route, item: item)
          resolver.resolve

          expect(resolver.workflow_approvers).to have(3).items
          resolver.workflow_approvers[0].tap do |approver|
            expect(approver.level).to eq 1
            expect(approver.user_type).to eq Gws::User.name
            expect(approver.user).to be_blank
            expect(approver.editable).to be_blank
            expect(approver.error).to eq I18n.t("gws/workflow2.errors.messages.user_is_not_found")
          end
          resolver.workflow_approvers[1].tap do |approver|
            expect(approver.level).to eq 2
            expect(approver.user_type).to eq Gws::User.name
            expect(approver.user).to be_blank
            expect(approver.editable).to be_blank
            expect(approver.error).to eq I18n.t("gws/workflow2.errors.messages.user_is_not_found")
          end
          resolver.workflow_approvers[2].tap do |approver|
            expect(approver.level).to eq 3
            expect(approver.user_type).to eq Gws::User.name
            expect(approver.user).to be_blank
            expect(approver.editable).to be_blank
            expect(approver.error).to eq I18n.t("gws/workflow2.errors.messages.user_is_not_found")
          end

          expect(resolver.workflow_circulations).to have(3).items
          resolver.workflow_circulations[0].tap do |circulation|
            expect(circulation.level).to eq 1
            expect(circulation.user_type).to eq Gws::User.name
            expect(circulation.user).to be_blank
            expect(circulation.error).to eq I18n.t("gws/workflow2.errors.messages.user_is_not_found")
          end
          resolver.workflow_circulations[1].tap do |circulation|
            expect(circulation.level).to eq 2
            expect(circulation.user_type).to eq Gws::User.name
            expect(circulation.user).to be_blank
            expect(circulation.error).to eq I18n.t("gws/workflow2.errors.messages.user_is_not_found")
          end
          resolver.workflow_circulations[2].tap do |circulation|
            expect(circulation.level).to eq 3
            expect(circulation.user_type).to eq Gws::User.name
            expect(circulation.user).to be_blank
            expect(circulation.error).to eq I18n.t("gws/workflow2.errors.messages.user_is_not_found")
          end
        end
      end
    end
  end

  context "with :restart" do
    context "without errors" do
      let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
      let!(:user1) { create(:gws_user, group_ids: [ group1.id ], gws_role_ids: user.gws_role_ids) }
      let!(:group2) { create :gws_group, name: "#{site.name}/#{unique_id}" }
      let!(:user2) { create(:gws_user, group_ids: [ group2.id ], gws_role_ids: user.gws_role_ids) }
      let!(:group3) { create :gws_group, name: "#{site.name}/#{unique_id}" }
      let!(:user3) { create(:gws_user, group_ids: [ group3.id ], gws_role_ids: user.gws_role_ids) }
      let!(:form) { create(:gws_workflow2_form_application, cur_site: site, state: "public") }
      let!(:column1) { create(:gws_column_text_field, cur_site: site, form: form, input_type: "text") }
      let!(:item) do
        create(
          :gws_workflow2_file, cur_site: site, cur_user: user, form: form, column_values: [ column1.serialize_value(unique_id) ],
          workflow_user_id: user.id,
          workflow_state: "remand",
          workflow_approvers: [
            { "level" => 1, "user_id" => user1.id, editable: "", state: "remand", comment: "remand-comment-#{unique_id}" },
            { "level" => 2, "user_id" => user2.id, editable: 1, state: "pending" },
            { "level" => 3, "user_id" => user3.id, editable: 1, state: "pending" },
          ],
          workflow_required_counts: [ false, false, false ],
          workflow_circulations: [
            { "level" => 1, "user_id" => user3.id, state: "pending" },
            { "level" => 2, "user_id" => user1.id, state: "pending" },
            { "level" => 3, "user_id" => user2.id, state: "pending" },
          ]
        )
      end

      it do
        resolver = Gws::Workflow2::ApproverResolver.new(
          cur_site: site, cur_user: user, cur_group: group, route: :restart, item: item)
        resolver.resolve

        expect(resolver.workflow_approvers).to have(3).items
        resolver.workflow_approvers[0].tap do |approver|
          expect(approver.level).to eq 1
          expect(approver.user_type).to eq Gws::User.name
          expect(approver.user.id).to eq user1.id
          expect(approver.editable).to be_falsey
          expect(approver.error).to be_blank
        end
        resolver.workflow_approvers[1].tap do |approver|
          expect(approver.level).to eq 2
          expect(approver.user_type).to eq Gws::User.name
          expect(approver.user.id).to eq user2.id
          expect(approver.editable).to be_truthy
          expect(approver.error).to be_blank
        end
        resolver.workflow_approvers[2].tap do |approver|
          expect(approver.level).to eq 3
          expect(approver.user_type).to eq Gws::User.name
          expect(approver.user.id).to eq user3.id
          expect(approver.editable).to be_truthy
          expect(approver.error).to be_blank
        end

        expect(resolver.workflow_circulations).to have(3).items
        resolver.workflow_circulations[0].tap do |circulation|
          expect(circulation.level).to eq 1
          expect(circulation.user_type).to eq Gws::User.name
          expect(circulation.user.id).to eq user3.id
          expect(circulation.error).to be_blank
        end
        resolver.workflow_circulations[1].tap do |circulation|
          expect(circulation.level).to eq 2
          expect(circulation.user_type).to eq Gws::User.name
          expect(circulation.user.id).to eq user1.id
          expect(circulation.error).to be_blank
        end
        resolver.workflow_circulations[2].tap do |circulation|
          expect(circulation.level).to eq 3
          expect(circulation.user_type).to eq Gws::User.name
          expect(circulation.user.id).to eq user2.id
          expect(circulation.error).to be_blank
        end
      end
    end

    context "with errors" do
      let(:now) { Time.zone.now.change(usec: 0) }
      let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
      let!(:user1) { create(:gws_user, group_ids: [ group1.id ], gws_role_ids: user.gws_role_ids, account_expiration_date: now) }
      let!(:other_site) { create :gws_group, name: unique_id }
      let!(:user2) { create(:gws_user, group_ids: [ other_site.id ], gws_role_ids: user.gws_role_ids) }
      let!(:user3) { create(:gws_user, group_ids: [ other_site.id ], gws_role_ids: user.gws_role_ids) }
      let!(:form) { create(:gws_workflow2_form_application, cur_site: site, state: "public") }
      let!(:column1) { create(:gws_column_text_field, cur_site: site, form: form, input_type: "text") }
      let!(:item) do
        create(
          :gws_workflow2_file, cur_site: site, cur_user: user, form: form, column_values: [ column1.serialize_value(unique_id) ],
          workflow_user_id: user.id,
          workflow_state: "remand",
          workflow_approvers: [
            { "level" => 1, "user_id" => user1.id, editable: "", state: "remand", comment: "remand-comment-#{unique_id}" },
            { "level" => 2, "user_id" => user2.id, editable: 1, state: "pending" },
            { "level" => 3, "user_id" => 1001, editable: 1, state: "pending" },
          ],
          workflow_required_counts: [ false, false, false ],
          workflow_circulations: [
            { "level" => 1, "user_id" => user3.id, state: "pending" },
            { "level" => 2, "user_id" => user1.id, state: "pending" },
            { "level" => 3, "user_id" => 1001, state: "pending" },
          ]
        )
      end

      it do
        resolver = Gws::Workflow2::ApproverResolver.new(
          cur_site: site, cur_user: user, cur_group: group, route: :restart, item: item)
        resolver.resolve

        expect(resolver.workflow_approvers).to have(3).items
        resolver.workflow_approvers[0].tap do |approver|
          expect(approver.level).to eq 1
          expect(approver.user_type).to eq Gws::User.name
          expect(approver.user).to be_blank
          expect(approver.editable).to be_blank
          expect(approver.error).to eq I18n.t("gws/workflow2.errors.messages.approver_is_deleted")
        end
        resolver.workflow_approvers[1].tap do |approver|
          expect(approver.level).to eq 2
          expect(approver.user_type).to eq Gws::User.name
          expect(approver.user).to be_blank
          expect(approver.editable).to be_blank
          expect(approver.error).to eq I18n.t("gws/workflow2.errors.messages.approver_is_deleted")
        end
        resolver.workflow_approvers[2].tap do |approver|
          expect(approver.level).to eq 3
          expect(approver.user_type).to eq Gws::User.name
          expect(approver.user).to be_blank
          expect(approver.editable).to be_blank
          expect(approver.error).to eq I18n.t("gws/workflow2.errors.messages.approver_is_deleted")
        end

        expect(resolver.workflow_circulations).to have(3).items
        resolver.workflow_circulations[0].tap do |circulation|
          expect(circulation.level).to eq 1
          expect(circulation.user_type).to eq Gws::User.name
          expect(circulation.user).to be_blank
          expect(circulation.error).to eq I18n.t("gws/workflow2.errors.messages.circulator_is_deleted")
        end
        resolver.workflow_circulations[1].tap do |circulation|
          expect(circulation.level).to eq 2
          expect(circulation.user_type).to eq Gws::User.name
          expect(circulation.user).to be_blank
          expect(circulation.error).to eq I18n.t("gws/workflow2.errors.messages.circulator_is_deleted")
        end
        resolver.workflow_circulations[2].tap do |circulation|
          expect(circulation.level).to eq 3
          expect(circulation.user_type).to eq Gws::User.name
          expect(circulation.user).to be_blank
          expect(circulation.error).to eq I18n.t("gws/workflow2.errors.messages.circulator_is_deleted")
        end
      end
    end
  end
end
