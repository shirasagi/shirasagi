require 'spec_helper'

describe Workflow do
  describe ".approvable_users" do
    let!(:site0) { cms_site }
    let!(:admin0) { cms_user }

    let(:now) { Time.zone.now.change(usec: 0) }
    let!(:group0) { create :cms_group, name: "group-#{unique_id}" }
    let!(:group1) { create :cms_group, name: "#{group0.name}/group-#{unique_id}" }
    let!(:group2) { create :cms_group, name: "#{group0.name}/group-#{unique_id}" }
    let!(:group3) { create :cms_group, name: "#{group0.name}/group-#{unique_id}" }
    let!(:site) { create :cms_site_unique, group_ids: [ group0.id ] }
    let!(:role_admin) do
      create :cms_role, cur_site: site, cur_user: nil, name: "role-#{unique_id}", permissions: Cms::Role.permission_names
    end
    let!(:role_editor) do
      permissions = %w(read_private_cms_pages edit_private_cms_pages)
      create :cms_role, cur_site: site, cur_user: nil, name: "role-#{unique_id}", permissions: permissions
    end
    let!(:role_approver) do
      permissions = %w(approve_private_cms_pages)
      create :cms_role, cur_site: site, cur_user: nil, name: "role-#{unique_id}", permissions: permissions
    end
    let!(:admin) { create :cms_test_user, cur_site: site, group_ids: [ group1.id ], cms_role_ids: [ role_admin.id ] }
    let!(:user_editor) do
      create :cms_test_user, cur_site: site, group_ids: [ group2.id ], cms_role_ids: [ role_editor.id ]
    end
    let!(:user_approver) do
      create :cms_test_user, cur_site: site, group_ids: [ group2.id ], cms_role_ids: [ role_editor.id, role_approver.id ]
    end
    let!(:user_disabled_approver) do
      create :cms_test_user, cur_site: site, account_expiration_date: now - 1.day, group_ids: [ group2.id ],
             cms_role_ids: [ role_editor.id, role_approver.id ]
    end
    let!(:user_approver_in_other_group) do
      # 無関係なユーザー（他グループの承認者）
      create :cms_test_user, cur_site: site, group_ids: [ group3.id ],
             cms_role_ids: [ role_editor.id, role_approver.id ]
    end
    let!(:node) { create :cms_node_page, cur_site: site, group_ids: [ group1.id, group2.id ] }

    context "when a persisted page is given" do
      let!(:page1) { create :cms_page, cur_site: site, cur_node: node, group_ids: [ group2.id ] }

      context "when a criteria is not given" do
        subject { Workflow.approvable_users(cur_site: site, item: page1) }

        it do
          expect(subject).to be_a(Array)
          expect(subject).to have(2).items
          expect(subject).to include(admin, user_approver)
        end
      end

      context "when all users are given to criteria" do
        subject { Workflow.approvable_users(cur_site: site, item: page1, criteria: Cms::User.unscoped) }

        it do
          expect(subject).to be_a(Array)
          expect(subject).to have(2).items
          expect(subject).to include(admin, user_approver)
        end
      end

      context "when array of users are given to criteria" do
        subject { Workflow.approvable_users(cur_site: site, item: page1, criteria: Cms::User.unscoped.to_a) }

        it do
          expect(subject).to be_a(Array)
          expect(subject).to have(2).items
          expect(subject).to include(admin, user_approver)
        end
      end
    end

    context "when a new page is given" do
      let!(:page1) { build :cms_page, cur_site: site, cur_node: node, group_ids: [ group2.id ] }

      context "when a criteria is not given" do
        subject { Workflow.approvable_users(cur_site: site, item: page1) }

        it do
          expect(subject).to be_a(Array)
          expect(subject).to have(2).items
          expect(subject).to include(admin, user_approver)
        end
      end

      context "when all users are given to criteria" do
        subject { Workflow.approvable_users(cur_site: site, item: page1, criteria: Cms::User.unscoped) }

        it do
          expect(subject).to be_a(Array)
          expect(subject).to have(2).items
          expect(subject).to include(admin, user_approver)
        end
      end

      context "when array of users are given to criteria" do
        subject { Workflow.approvable_users(cur_site: site, item: page1, criteria: Cms::User.unscoped.to_a) }

        it do
          expect(subject).to be_a(Array)
          expect(subject).to have(2).items
          expect(subject).to include(admin, user_approver)
        end
      end
    end
  end
end
