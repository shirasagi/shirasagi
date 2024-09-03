require 'spec_helper'

describe Gws::Workflow2::File, type: :model, dbscope: :example do
  context "empty" do
    subject { described_class.new }
    its(:valid?) { is_expected.to be_falsey }
  end

  context "factory girl" do
    let(:form) { create(:gws_workflow2_form_application, state: "public") }
    let!(:column1) { create(:gws_column_text_field, cur_form: form, input_type: "text") }
    let(:column1_value) { unique_id }
    subject { create :gws_workflow2_file, form: form, column_values: [ column1.serialize_value(column1_value) ] }
    its(:valid?) { is_expected.to be_truthy }
  end

  context "permissions" do
    let(:site) { gws_site }
    let!(:user_role) do
      permissions = %w(use_gws_workflow2)
      create(:gws_role, cur_site: site, permissions: permissions)
    end
    let!(:user1) { create :gws_user, group_ids: gws_user.group_ids, gws_role_ids: [ user_role.id ] }
    let!(:user2) { create :gws_user, group_ids: gws_user.group_ids, gws_role_ids: [ user_role.id ] }
    let!(:user3) { create :gws_user, group_ids: gws_user.group_ids, gws_role_ids: [ user_role.id ] }
    let!(:admin_user) { create :gws_user, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let(:user_other) { create :gws_user, group_ids: gws_user.group_ids, gws_role_ids: [ user_role.id ] }
    let!(:form) { create(:gws_workflow2_form_application, cur_site: site, state: "public", destination_user_ids: [ user3.id ]) }
    let!(:column1) { create(:gws_column_text_field, cur_site: site, cur_form: form, input_type: "text") }
    let!(:column2) { create(:gws_column_file_upload, cur_site: site, cur_form: form, upload_file_count: 1) }
    let!(:user1_file) do
      tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", basename: "logo.png")
    end

    describe ".readable?" do
      context "user in user_ids" do
        subject! do
          create(
            :gws_workflow2_file, cur_site: site, cur_user: user1, form: form,
            column_values: [ column1.serialize_value(unique_id), column2.serialize_value([ user1_file.id ]) ],
            destination_group_ids: form.destination_group_ids, destination_user_ids: form.destination_user_ids)
        end

        before do
          SS::File.find(user1_file.id).tap do |file|
            expect(file.owner_item_type).to eq subject.class.name
            expect(file.owner_item_id).to eq subject.id
          end
        end

        it do
          expect(subject.readable?(user1, site: site)).to be_truthy
          expect(subject.readable?(user2, site: site)).to be_falsey
          expect(subject.readable?(user3, site: site)).to be_falsey
          expect(subject.readable?(admin_user, site: site)).to be_truthy

          # すべて
          expect(described_class.search(cur_site: site, cur_user: user1, state: 'all').count).to eq 1
          expect(described_class.search(cur_site: site, cur_user: user2, state: 'all').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: user3, state: 'all').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'all').count).to eq 1

          # 承認依頼されているもの
          expect(described_class.search(cur_site: site, cur_user: user1, state: 'approve').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: user2, state: 'approve').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: user3, state: 'approve').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'approve').count).to eq 0

          # 承認依頼したもの
          expect(described_class.search(cur_site: site, cur_user: user1, state: 'request').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: user2, state: 'request').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: user3, state: 'request').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'request').count).to eq 0

          # 回覧中のもの
          expect(described_class.search(cur_site: site, cur_user: user1, state: 'circulation').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: user2, state: 'circulation').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: user3, state: 'circulation').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'circulation').count).to eq 0

          # 申請手続きが完了したもの（仮称）
          expect(described_class.search(cur_site: site, cur_user: user1, state: 'destination').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: user2, state: 'destination').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: user3, state: 'destination').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'destination').count).to eq 0

          # 添付ファイルが閲覧可能
          SS::File.find(user1_file.id).tap do |file|
            expect(file.previewable?(site: nil, user: user1, member: nil)).to be_truthy
            expect(file.previewable?(site: nil, user: user2, member: nil)).to be_falsey
            expect(file.previewable?(site: nil, user: user3, member: nil)).to be_falsey
            expect(file.previewable?(site: nil, user: admin_user, member: nil)).to be_truthy
          end
        end
      end

      context "user is at workflow_agent_id" do
        subject! do
          # user1 の代わりに admin_user が作成した user1 のワークフロー（申請書）
          create(
            :gws_workflow2_file, cur_site: site, cur_user: admin_user, form: form,
            column_values: [ column1.serialize_value(unique_id), column2.serialize_value([ user1_file.id ]) ],
            destination_group_ids: form.destination_group_ids, destination_user_ids: form.destination_user_ids,
            workflow_state: "request", workflow_user_id: user1.id, workflow_agent_id: admin_user.id,
            workflow_approvers: [{ level: 1, user_id: user_other.id, state: "request" }],
            workflow_required_counts: [ false ])
        end

        before do
          SS::File.find(user1_file.id).tap do |file|
            expect(file.owner_item_type).to eq subject.class.name
            expect(file.owner_item_id).to eq subject.id
          end
        end

        it do
          expect(subject.readable?(user1, site: site)).to be_truthy
          expect(subject.readable?(user2, site: site)).to be_falsey
          expect(subject.readable?(user3, site: site)).to be_falsey
          expect(subject.readable?(admin_user, site: site)).to be_truthy

          # すべて
          expect(described_class.search(cur_site: site, cur_user: user1, state: 'all').count).to eq 1
          expect(described_class.search(cur_site: site, cur_user: user2, state: 'all').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: user3, state: 'all').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'all').count).to eq 1

          # 承認依頼されているもの
          expect(described_class.search(cur_site: site, cur_user: user1, state: 'approve').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: user2, state: 'approve').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: user3, state: 'approve').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'approve').count).to eq 0

          # 承認依頼したもの
          expect(described_class.search(cur_site: site, cur_user: user1, state: 'request').count).to eq 1
          expect(described_class.search(cur_site: site, cur_user: user2, state: 'request').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: user3, state: 'request').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'request').count).to eq 1

          # 回覧中のもの
          expect(described_class.search(cur_site: site, cur_user: user1, state: 'circulation').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: user2, state: 'circulation').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: user3, state: 'circulation').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'circulation').count).to eq 0

          # 申請手続きが完了したもの（仮称）
          expect(described_class.search(cur_site: site, cur_user: user1, state: 'destination').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: user2, state: 'destination').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: user3, state: 'destination').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'destination').count).to eq 0

          # 添付ファイルが閲覧可能
          SS::File.find(user1_file.id).tap do |file|
            expect(file.previewable?(site: nil, user: user1, member: nil)).to be_truthy
            expect(file.previewable?(site: nil, user: user2, member: nil)).to be_falsey
            expect(file.previewable?(site: nil, user: user3, member: nil)).to be_falsey
            expect(file.previewable?(site: nil, user: admin_user, member: nil)).to be_truthy
          end
        end
      end

      context "user in workflow_approvers" do
        context "workflow_state is 'request' and user's state is 'request'" do
          subject! do
            create(
              :gws_workflow2_file, cur_site: site, cur_user: gws_user, form: form,
              column_values: [ column1.serialize_value(unique_id), column2.serialize_value([ user1_file.id ]) ],
              destination_group_ids: form.destination_group_ids, destination_user_ids: form.destination_user_ids,
              workflow_state: "request", workflow_user_id: gws_user.id,
              workflow_approvers: [{ level: 1, user_id: user1.id, state: "request" }],
              workflow_required_counts: [ false ])
          end

          before do
            SS::File.find(user1_file.id).tap do |file|
              expect(file.owner_item_type).to eq subject.class.name
              expect(file.owner_item_id).to eq subject.id
            end
          end

          it do
            expect(subject.readable?(user1, site: site)).to be_truthy
            expect(subject.readable?(user2, site: site)).to be_falsey
            expect(subject.readable?(user3, site: site)).to be_falsey
            expect(subject.readable?(admin_user, site: site)).to be_truthy

            # すべて
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'all').count).to eq 1
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'all').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'all').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'all').count).to eq 1

            # 承認依頼されているもの
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'approve').count).to eq 1
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'approve').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'approve').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'approve').count).to eq 0

            # 承認依頼したもの
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'request').count).to eq 0

            # 回覧中のもの
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'circulation').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'circulation').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'circulation').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'circulation').count).to eq 0

            # 申請手続きが完了したもの（仮称）
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'destination').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'destination').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'destination').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'destination').count).to eq 0

            # 添付ファイルが閲覧可能
            SS::File.find(user1_file.id).tap do |file|
              expect(file.previewable?(site: nil, user: user1, member: nil)).to be_truthy
              expect(file.previewable?(site: nil, user: user2, member: nil)).to be_falsey
              expect(file.previewable?(site: nil, user: user3, member: nil)).to be_falsey
              expect(file.previewable?(site: nil, user: admin_user, member: nil)).to be_truthy
            end
          end
        end

        context "workflow_state is 'request' and user's state is 'pending'" do
          subject! do
            create(
              :gws_workflow2_file, cur_site: site, cur_user: gws_user, form: form,
              column_values: [ column1.serialize_value(unique_id), column2.serialize_value([ user1_file.id ]) ],
              destination_group_ids: form.destination_group_ids, destination_user_ids: form.destination_user_ids,
              workflow_state: "request", workflow_user_id: gws_user.id,
              workflow_approvers: [
                { level: 1, user_id: user_other.id, state: "request" },
                { level: 2, user_id: user1.id, state: "pending" },
              ],
              workflow_required_counts: [ false, false ])
          end

          before do
            SS::File.find(user1_file.id).tap do |file|
              expect(file.owner_item_type).to eq subject.class.name
              expect(file.owner_item_id).to eq subject.id
            end
          end

          it do
            # 引き上げ承認が有効になっている可能性を考慮し、"pending" 状態にある user1 にも閲覧を許可する
            expect(subject.readable?(user1, site: site)).to be_truthy
            expect(subject.readable?(user2, site: site)).to be_falsey
            expect(subject.readable?(user3, site: site)).to be_falsey
            expect(subject.readable?(admin_user, site: site)).to be_truthy

            # すべて
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'all').count).to eq 1
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'all').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'all').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'all').count).to eq 1

            # 承認依頼されているもの
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'approve').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'approve').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'approve').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'approve').count).to eq 0

            # 承認依頼したもの
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'request').count).to eq 0

            # 回覧中のもの
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'circulation').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'circulation').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'circulation').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'circulation').count).to eq 0

            # 申請手続きが完了したもの（仮称）
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'destination').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'destination').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'destination').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'destination').count).to eq 0

            # 添付ファイルが閲覧可能
            SS::File.find(user1_file.id).tap do |file|
              expect(file.previewable?(site: nil, user: user1, member: nil)).to be_truthy
              expect(file.previewable?(site: nil, user: user2, member: nil)).to be_falsey
              expect(file.previewable?(site: nil, user: user3, member: nil)).to be_falsey
              expect(file.previewable?(site: nil, user: admin_user, member: nil)).to be_truthy
            end
          end
        end

        context "workflow_state is 'request' and user's state is 'approve'" do
          subject! do
            create(
              :gws_workflow2_file, cur_site: site, cur_user: gws_user, form: form,
              column_values: [ column1.serialize_value(unique_id), column2.serialize_value([ user1_file.id ]) ],
              destination_group_ids: form.destination_group_ids, destination_user_ids: form.destination_user_ids,
              workflow_state: "request", workflow_user_id: gws_user.id,
              workflow_approvers: [
                { level: 1, user_id: user1.id, state: "approve" },
                { level: 2, user_id: user_other.id, state: "request" },
              ],
              workflow_required_counts: [ false, false ])
          end

          before do
            SS::File.find(user1_file.id).tap do |file|
              expect(file.owner_item_type).to eq subject.class.name
              expect(file.owner_item_id).to eq subject.id
            end
          end

          it do
            expect(subject.readable?(user1, site: site)).to be_truthy
            expect(subject.readable?(user2, site: site)).to be_falsey
            expect(subject.readable?(user3, site: site)).to be_falsey
            expect(subject.readable?(admin_user, site: site)).to be_truthy

            # すべて
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'all').count).to eq 1
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'all').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'all').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'all').count).to eq 1

            # 承認依頼されているもの
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'approve').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'approve').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'approve').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'approve').count).to eq 0

            # 承認依頼したもの
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'request').count).to eq 0

            # 回覧中のもの
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'circulation').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'circulation').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'circulation').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'circulation').count).to eq 0

            # 申請手続きが完了したもの（仮称）
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'destination').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'destination').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'destination').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'destination').count).to eq 0

            # 添付ファイルが閲覧可能
            SS::File.find(user1_file.id).tap do |file|
              expect(file.previewable?(site: nil, user: user1, member: nil)).to be_truthy
              expect(file.previewable?(site: nil, user: user2, member: nil)).to be_falsey
              expect(file.previewable?(site: nil, user: user3, member: nil)).to be_falsey
              expect(file.previewable?(site: nil, user: admin_user, member: nil)).to be_truthy
            end
          end
        end

        context "workflow_state is 'remand' and user's state is 'pending'" do
          subject! do
            create(
              :gws_workflow2_file, cur_site: site, cur_user: gws_user, form: form,
              column_values: [ column1.serialize_value(unique_id), column2.serialize_value([ user1_file.id ]) ],
              destination_group_ids: form.destination_group_ids, destination_user_ids: form.destination_user_ids,
              workflow_state: "remand", workflow_user_id: gws_user.id,
              workflow_approvers: [
                { level: 1, user_id: user_other.id, state: "remand" },
                { level: 2, user_id: user1.id, state: "pending" },
              ],
              workflow_required_counts: [ false, false ])
          end

          before do
            SS::File.find(user1_file.id).tap do |file|
              expect(file.owner_item_type).to eq subject.class.name
              expect(file.owner_item_id).to eq subject.id
            end
          end

          it do
            # 引き上げ承認が有効になっている可能性を考慮し、"pending" 状態にある user1 にも閲覧を許可する
            expect(subject.readable?(user1, site: site)).to be_truthy
            expect(subject.readable?(user2, site: site)).to be_falsey
            expect(subject.readable?(user3, site: site)).to be_falsey
            expect(subject.readable?(admin_user, site: site)).to be_truthy

            # すべて
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'all').count).to eq 1
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'all').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'all').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'all').count).to eq 1

            # 承認依頼されているもの
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'approve').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'approve').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'approve').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'approve').count).to eq 0

            # 承認依頼したもの
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'request').count).to eq 0

            # 回覧中のもの
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'circulation').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'circulation').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'circulation').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'circulation').count).to eq 0

            # 申請手続きが完了したもの（仮称）
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'destination').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'destination').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'destination').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'destination').count).to eq 0

            # 添付ファイルが閲覧可能
            SS::File.find(user1_file.id).tap do |file|
              expect(file.previewable?(site: nil, user: user1, member: nil)).to be_truthy
              expect(file.previewable?(site: nil, user: user2, member: nil)).to be_falsey
              expect(file.previewable?(site: nil, user: user3, member: nil)).to be_falsey
              expect(file.previewable?(site: nil, user: admin_user, member: nil)).to be_truthy
            end
          end
        end

        context "workflow_state is 'remand' and user's state is 'remand'" do
          subject! do
            create(
              :gws_workflow2_file, cur_site: site, cur_user: gws_user, form: form,
              column_values: [ column1.serialize_value(unique_id), column2.serialize_value([ user1_file.id ]) ],
              destination_group_ids: form.destination_group_ids, destination_user_ids: form.destination_user_ids,
              workflow_state: "remand", workflow_user_id: gws_user.id,
              workflow_approvers: [
                { level: 1, user_id: user1.id, state: "remand" },
                { level: 2, user_id: user_other.id, state: "pending" },
              ],
              workflow_required_counts: [ false, false ])
          end

          before do
            SS::File.find(user1_file.id).tap do |file|
              expect(file.owner_item_type).to eq subject.class.name
              expect(file.owner_item_id).to eq subject.id
            end
          end

          it do
            # このケースで user1 が閲覧可能かどうかは悩むが、user1 が差し戻したのだから user1 が閲覧できても良いと判断する
            expect(subject.readable?(user1, site: site)).to be_truthy
            expect(subject.readable?(user2, site: site)).to be_falsey
            expect(subject.readable?(user3, site: site)).to be_falsey
            expect(subject.readable?(admin_user, site: site)).to be_truthy

            # すべて
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'all').count).to eq 1
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'all').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'all').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'all').count).to eq 1

            # 承認依頼されているもの
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'approve').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'approve').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'approve').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'approve').count).to eq 0

            # 承認依頼したもの
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'request').count).to eq 0

            # 回覧中のもの
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'circulation').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'circulation').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'circulation').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'circulation').count).to eq 0

            # 申請手続きが完了したもの（仮称）
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'destination').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'destination').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'destination').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'destination').count).to eq 0

            # 添付ファイルが閲覧可能
            SS::File.find(user1_file.id).tap do |file|
              expect(file.previewable?(site: nil, user: user1, member: nil)).to be_truthy
              expect(file.previewable?(site: nil, user: user2, member: nil)).to be_falsey
              expect(file.previewable?(site: nil, user: user3, member: nil)).to be_falsey
              expect(file.previewable?(site: nil, user: admin_user, member: nil)).to be_truthy
            end
          end
        end

        context "workflow_state is 'approve' and user's state is 'request'" do
          subject! do
            create(
              :gws_workflow2_file, cur_site: site, cur_user: gws_user, form: form,
              column_values: [ column1.serialize_value(unique_id), column2.serialize_value([ user1_file.id ]) ],
              destination_group_ids: form.destination_group_ids, destination_user_ids: form.destination_user_ids,
              workflow_state: "approve", workflow_user_id: gws_user.id,
              workflow_approvers: [
                { level: 1, user_id: user_other.id, state: "approve" },
                { level: 1, user_id: user1.id, state: "request" },
              ],
              workflow_required_counts: [ 1 ])
          end

          before do
            SS::File.find(user1_file.id).tap do |file|
              expect(file.owner_item_type).to eq subject.class.name
              expect(file.owner_item_id).to eq subject.id
            end
          end

          it do
            expect(subject.readable?(user1, site: site)).to be_truthy
            expect(subject.readable?(user2, site: site)).to be_falsey
            expect(subject.readable?(user3, site: site)).to be_truthy
            expect(subject.readable?(admin_user, site: site)).to be_truthy

            # すべて
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'all').count).to eq 1
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'all').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'all').count).to eq 1
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'all').count).to eq 1

            # 承認依頼されているもの
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'approve').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'approve').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'approve').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'approve').count).to eq 0

            # 承認依頼したもの
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'request').count).to eq 0

            # 回覧中のもの
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'circulation').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'circulation').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'circulation').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'circulation').count).to eq 0

            # 申請手続きが完了したもの（仮称）
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'destination').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'destination').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'destination').count).to eq 1
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'destination').count).to eq 0

            # 添付ファイルが閲覧可能
            SS::File.find(user1_file.id).tap do |file|
              expect(file.previewable?(site: nil, user: user1, member: nil)).to be_truthy
              expect(file.previewable?(site: nil, user: user2, member: nil)).to be_falsey
              expect(file.previewable?(site: nil, user: user3, member: nil)).to be_truthy
              expect(file.previewable?(site: nil, user: admin_user, member: nil)).to be_truthy
            end
          end
        end

        context "workflow_state is 'approve' and user's state is 'approve'" do
          subject! do
            create(
              :gws_workflow2_file, cur_site: site, cur_user: gws_user, form: form,
              column_values: [ column1.serialize_value(unique_id), column2.serialize_value([ user1_file.id ]) ],
              destination_group_ids: form.destination_group_ids, destination_user_ids: form.destination_user_ids,
              workflow_state: "approve", workflow_user_id: gws_user.id,
              workflow_approvers: [
                { level: 1, user_id: user1.id, state: "approve" },
                { level: 1, user_id: user_other.id, state: "request" },
              ],
              workflow_required_counts: [ 1 ])
          end

          before do
            SS::File.find(user1_file.id).tap do |file|
              expect(file.owner_item_type).to eq subject.class.name
              expect(file.owner_item_id).to eq subject.id
            end
          end

          it do
            # このケースで user1 が閲覧可能かどうかは悩むが、user1 が差し戻したのだから user1 が閲覧できても良いと判断する
            expect(subject.readable?(user1, site: site)).to be_truthy
            expect(subject.readable?(user2, site: site)).to be_falsey
            expect(subject.readable?(user3, site: site)).to be_truthy
            expect(subject.readable?(admin_user, site: site)).to be_truthy

            # すべて
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'all').count).to eq 1
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'all').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'all').count).to eq 1
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'all').count).to eq 1

            # 承認依頼されているもの
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'approve').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'approve').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'approve').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'approve').count).to eq 0

            # 承認依頼したもの
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'request').count).to eq 0

            # 回覧中のもの
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'circulation').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'circulation').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'circulation').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'circulation').count).to eq 0

            # 申請手続きが完了したもの（仮称）
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'destination').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'destination').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'destination').count).to eq 1
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'destination').count).to eq 0

            # 添付ファイルが閲覧可能
            SS::File.find(user1_file.id).tap do |file|
              expect(file.previewable?(site: nil, user: user1, member: nil)).to be_truthy
              expect(file.previewable?(site: nil, user: user2, member: nil)).to be_falsey
              expect(file.previewable?(site: nil, user: user3, member: nil)).to be_truthy
              expect(file.previewable?(site: nil, user: admin_user, member: nil)).to be_truthy
            end
          end
        end
      end

      context "user in workflow_circulations" do
        context "workflow_state is 'request'" do
          subject! do
            create(
              :gws_workflow2_file, cur_site: site, cur_user: gws_user, form: form,
              column_values: [ column1.serialize_value(unique_id), column2.serialize_value([ user1_file.id ]) ],
              destination_group_ids: form.destination_group_ids, destination_user_ids: form.destination_user_ids,
              workflow_state: "request", workflow_user_id: gws_user.id,
              workflow_approvers: [{ level: 1, user_id: user_other.id, state: "request" }],
              workflow_required_counts: [ false ],
              workflow_circulations: [{ level: 1, user_id: user1.id, state: "pending" }])
          end

          before do
            SS::File.find(user1_file.id).tap do |file|
              expect(file.owner_item_type).to eq subject.class.name
              expect(file.owner_item_id).to eq subject.id
            end
          end

          it do
            expect(subject.readable?(user1, site: site)).to be_falsey
            expect(subject.readable?(user2, site: site)).to be_falsey
            expect(subject.readable?(user3, site: site)).to be_falsey
            expect(subject.readable?(admin_user, site: site)).to be_truthy

            # すべて
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'all').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'all').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'all').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'all').count).to eq 1

            # 承認依頼されているもの
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'approve').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'approve').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'approve').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'approve').count).to eq 0

            # 承認依頼したもの
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'request').count).to eq 0

            # 回覧中のもの
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'circulation').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'circulation').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'circulation').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'circulation').count).to eq 0

            # 申請手続きが完了したもの（仮称）
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'destination').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'destination').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'destination').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'destination').count).to eq 0

            # 添付ファイルが閲覧可能
            SS::File.find(user1_file.id).tap do |file|
              expect(file.previewable?(site: nil, user: user1, member: nil)).to be_falsey
              expect(file.previewable?(site: nil, user: user2, member: nil)).to be_falsey
              expect(file.previewable?(site: nil, user: user3, member: nil)).to be_falsey
              expect(file.previewable?(site: nil, user: admin_user, member: nil)).to be_truthy
            end
          end
        end

        context "workflow_state is 'remand'" do
          subject! do
            create(
              :gws_workflow2_file, cur_site: site, cur_user: gws_user, form: form,
              column_values: [ column1.serialize_value(unique_id), column2.serialize_value([ user1_file.id ]) ],
              destination_group_ids: form.destination_group_ids, destination_user_ids: form.destination_user_ids,
              workflow_state: "remand", workflow_user_id: gws_user.id,
              workflow_approvers: [{ level: 1, user_id: user_other.id, state: "remand" }],
              workflow_required_counts: [ false ],
              workflow_circulations: [{ level: 1, user_id: user1.id, state: "pending" }])
          end

          before do
            SS::File.find(user1_file.id).tap do |file|
              expect(file.owner_item_type).to eq subject.class.name
              expect(file.owner_item_id).to eq subject.id
            end
          end

          it do
            expect(subject.readable?(user1, site: site)).to be_falsey
            expect(subject.readable?(user2, site: site)).to be_falsey
            expect(subject.readable?(user3, site: site)).to be_falsey
            expect(subject.readable?(admin_user, site: site)).to be_truthy

            # すべて
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'all').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'all').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'all').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'all').count).to eq 1

            # 承認依頼されているもの
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'approve').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'approve').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'approve').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'approve').count).to eq 0

            # 承認依頼したもの
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'request').count).to eq 0

            # 回覧中のもの
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'circulation').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'circulation').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'circulation').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'circulation').count).to eq 0

            # 申請手続きが完了したもの（仮称）
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'destination').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'destination').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'destination').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'destination').count).to eq 0

            # 添付ファイルが閲覧可能
            SS::File.find(user1_file.id).tap do |file|
              expect(file.previewable?(site: nil, user: user1, member: nil)).to be_falsey
              expect(file.previewable?(site: nil, user: user2, member: nil)).to be_falsey
              expect(file.previewable?(site: nil, user: user3, member: nil)).to be_falsey
              expect(file.previewable?(site: nil, user: admin_user, member: nil)).to be_truthy
            end
          end
        end

        context "workflow_state is 'approve' and user's state is 'unseen'" do
          subject! do
            create(
              :gws_workflow2_file, cur_site: site, cur_user: gws_user, form: form,
              column_values: [ column1.serialize_value(unique_id), column2.serialize_value([ user1_file.id ]) ],
              destination_group_ids: form.destination_group_ids, destination_user_ids: form.destination_user_ids,
              workflow_state: "approve", workflow_user_id: gws_user.id,
              workflow_approvers: [{ level: 1, user_id: user_other.id, state: "approve" }],
              workflow_required_counts: [ false ],
              workflow_circulations: [{ level: 1, user_id: user1.id, state: "unseen" }])
          end

          before do
            SS::File.find(user1_file.id).tap do |file|
              expect(file.owner_item_type).to eq subject.class.name
              expect(file.owner_item_id).to eq subject.id
            end
          end

          it do
            expect(subject.readable?(user1, site: site)).to be_truthy
            expect(subject.readable?(user2, site: site)).to be_falsey
            expect(subject.readable?(user3, site: site)).to be_truthy
            expect(subject.readable?(admin_user, site: site)).to be_truthy

            # すべて
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'all').count).to eq 1
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'all').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'all').count).to eq 1
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'all').count).to eq 1

            # 承認依頼されているもの
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'approve').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'approve').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'approve').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'approve').count).to eq 0

            # 承認依頼したもの
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'request').count).to eq 0

            # 回覧中のもの
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'circulation').count).to eq 1
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'circulation').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'circulation').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'circulation').count).to eq 0

            # 申請手続きが完了したもの（仮称）
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'destination').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'destination').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'destination').count).to eq 1
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'destination').count).to eq 0

            # 添付ファイルが閲覧可能
            SS::File.find(user1_file.id).tap do |file|
              expect(file.previewable?(site: nil, user: user1, member: nil)).to be_truthy
              expect(file.previewable?(site: nil, user: user2, member: nil)).to be_falsey
              expect(file.previewable?(site: nil, user: user3, member: nil)).to be_truthy
              expect(file.previewable?(site: nil, user: admin_user, member: nil)).to be_truthy
            end
          end
        end

        context "workflow_state is 'approve' and user's state is 'seen'" do
          subject! do
            create(
              :gws_workflow2_file, cur_site: site, cur_user: gws_user, form: form,
              column_values: [ column1.serialize_value(unique_id), column2.serialize_value([ user1_file.id ]) ],
              destination_group_ids: form.destination_group_ids, destination_user_ids: form.destination_user_ids,
              workflow_state: "approve", workflow_user_id: gws_user.id,
              workflow_approvers: [{ level: 1, user_id: user_other.id, state: "approve" }],
              workflow_required_counts: [ false ],
              workflow_circulations: [{ level: 1, user_id: user1.id, state: "seen" }])
          end

          before do
            SS::File.find(user1_file.id).tap do |file|
              expect(file.owner_item_type).to eq subject.class.name
              expect(file.owner_item_id).to eq subject.id
            end
          end

          it do
            expect(subject.readable?(user1, site: site)).to be_truthy
            expect(subject.readable?(user2, site: site)).to be_falsey
            expect(subject.readable?(user3, site: site)).to be_truthy
            expect(subject.readable?(admin_user, site: site)).to be_truthy

            # すべて
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'all').count).to eq 1
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'all').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'all').count).to eq 1
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'all').count).to eq 1

            # 承認依頼されているもの
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'approve').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'approve').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'approve').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'approve').count).to eq 0

            # 承認依頼したもの
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'request').count).to eq 0

            # 回覧中のもの（回覧を完了したら「回覧中のもの」内に上がってこなくなる）
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'circulation').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'circulation').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'circulation').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'circulation').count).to eq 0

            # 申請手続きが完了したもの（仮称）
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'destination').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'destination').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'destination').count).to eq 1
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'destination').count).to eq 0

            # 添付ファイルが閲覧可能
            SS::File.find(user1_file.id).tap do |file|
              expect(file.previewable?(site: nil, user: user1, member: nil)).to be_truthy
              expect(file.previewable?(site: nil, user: user2, member: nil)).to be_falsey
              expect(file.previewable?(site: nil, user: user3, member: nil)).to be_truthy
              expect(file.previewable?(site: nil, user: admin_user, member: nil)).to be_truthy
            end
          end
        end

        context "workflow_state is 'approve' and user's state is 'pending'" do
          subject! do
            create(
              :gws_workflow2_file, cur_site: site, cur_user: gws_user, form: form,
              column_values: [ column1.serialize_value(unique_id), column2.serialize_value([ user1_file.id ]) ],
              destination_group_ids: form.destination_group_ids, destination_user_ids: form.destination_user_ids,
              workflow_state: "approve", workflow_user_id: gws_user.id,
              workflow_approvers: [{ level: 1, user_id: user_other.id, state: "approve" }],
              workflow_required_counts: [ false ],
              workflow_circulations: [
                { level: 1, user_id: user_other.id, state: "unseen" },
                { level: 2, user_id: user1.id, state: "pending" },
              ])
          end

          before do
            SS::File.find(user1_file.id).tap do |file|
              expect(file.owner_item_type).to eq subject.class.name
              expect(file.owner_item_id).to eq subject.id
            end
          end

          it do
            expect(subject.readable?(user1, site: site)).to be_falsey
            expect(subject.readable?(user2, site: site)).to be_falsey
            expect(subject.readable?(user3, site: site)).to be_truthy
            expect(subject.readable?(admin_user, site: site)).to be_truthy

            # すべて
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'all').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'all').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'all').count).to eq 1
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'all').count).to eq 1

            # 承認依頼されているもの
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'approve').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'approve').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'approve').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'approve').count).to eq 0

            # 承認依頼したもの
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'request').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'request').count).to eq 0

            # 回覧中のもの
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'circulation').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'circulation').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'circulation').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'circulation').count).to eq 0

            # 申請手続きが完了したもの（仮称）
            expect(described_class.search(cur_site: site, cur_user: user1, state: 'destination').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user2, state: 'destination').count).to eq 0
            expect(described_class.search(cur_site: site, cur_user: user3, state: 'destination').count).to eq 1
            expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'destination').count).to eq 0

            # 添付ファイルが閲覧可能
            SS::File.find(user1_file.id).tap do |file|
              expect(file.previewable?(site: nil, user: user1, member: nil)).to be_falsey
              expect(file.previewable?(site: nil, user: user2, member: nil)).to be_falsey
              expect(file.previewable?(site: nil, user: user3, member: nil)).to be_truthy
              expect(file.previewable?(site: nil, user: admin_user, member: nil)).to be_truthy
            end
          end
        end
      end

      context "workflow_state is 'approve_without_approval'" do
        subject! do
          create(
            :gws_workflow2_file, cur_site: site, cur_user: gws_user, form: form,
            column_values: [ column1.serialize_value(unique_id), column2.serialize_value([ user1_file.id ]) ],
            destination_group_ids: form.destination_group_ids, destination_user_ids: form.destination_user_ids,
            workflow_state: "approve_without_approval", workflow_user_id: gws_user.id,
            workflow_approvers: [], workflow_required_counts: [])
        end

        before do
          SS::File.find(user1_file.id).tap do |file|
            expect(file.owner_item_type).to eq subject.class.name
            expect(file.owner_item_id).to eq subject.id
          end
        end

        it do
          expect(subject.readable?(user1, site: site)).to be_falsey
          expect(subject.readable?(user2, site: site)).to be_falsey
          expect(subject.readable?(user3, site: site)).to be_truthy
          expect(subject.readable?(admin_user, site: site)).to be_truthy

          # すべて
          expect(described_class.search(cur_site: site, cur_user: user1, state: 'all').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: user2, state: 'all').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: user3, state: 'all').count).to eq 1
          expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'all').count).to eq 1

          # 承認依頼されているもの
          expect(described_class.search(cur_site: site, cur_user: user1, state: 'approve').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: user2, state: 'approve').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: user3, state: 'approve').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'approve').count).to eq 0

          # 承認依頼したもの
          expect(described_class.search(cur_site: site, cur_user: user1, state: 'request').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: user2, state: 'request').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: user3, state: 'request').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'request').count).to eq 0

          # 回覧中のもの
          expect(described_class.search(cur_site: site, cur_user: user1, state: 'circulation').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: user2, state: 'circulation').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: user3, state: 'circulation').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'circulation').count).to eq 0

          # 申請手続きが完了したもの（仮称）
          expect(described_class.search(cur_site: site, cur_user: user1, state: 'destination').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: user2, state: 'destination').count).to eq 0
          expect(described_class.search(cur_site: site, cur_user: user3, state: 'destination').count).to eq 1
          expect(described_class.search(cur_site: site, cur_user: admin_user, state: 'destination').count).to eq 0

          # 添付ファイルが閲覧可能
          SS::File.find(user1_file.id).tap do |file|
            expect(file.previewable?(site: nil, user: user1, member: nil)).to be_falsey
            expect(file.previewable?(site: nil, user: user2, member: nil)).to be_falsey
            expect(file.previewable?(site: nil, user: user3, member: nil)).to be_truthy
            expect(file.previewable?(site: nil, user: admin_user, member: nil)).to be_truthy
          end
        end
      end
    end

    describe ".editable?" do
      context "with user in user_ids" do
        subject! do
          create(
            :gws_workflow2_file, cur_site: site, cur_user: user1, form: form,
            column_values: [ column1.serialize_value(unique_id), column2.serialize_value([ user1_file.id ]) ],
            destination_group_ids: form.destination_group_ids, destination_user_ids: form.destination_user_ids)
        end

        it do
          expect(subject.editable?(user1, site: site)).to be_truthy
          expect(subject.editable?(user2, site: site)).to be_falsey
          expect(subject.editable?(user3, site: site)).to be_falsey
          expect(subject.editable?(admin_user, site: site)).to be_truthy
        end
      end

      context "with user at workflow_agent_id" do
        subject! do
          # user1 の代わりに admin_user が作成した user1 のワークフロー（申請書）
          create(
            :gws_workflow2_file, cur_site: site, cur_user: admin_user, form: form,
            column_values: [ column1.serialize_value(unique_id), column2.serialize_value([ user1_file.id ]) ],
            destination_group_ids: form.destination_group_ids, destination_user_ids: form.destination_user_ids,
            workflow_user_id: user1.id, workflow_agent_id: admin_user.id)
        end

        it do
          expect(subject.editable?(user1, site: site)).to be_truthy
          expect(subject.editable?(user2, site: site)).to be_falsey
          expect(subject.editable?(user3, site: site)).to be_falsey
          expect(subject.editable?(admin_user, site: site)).to be_truthy
        end
      end

      context "with requested workflow" do
        subject! do
          # user1 の代わりに admin_user が作成した user1 のワークフロー（申請書）
          create(
            :gws_workflow2_file, cur_site: site, cur_user: admin_user, form: form,
            column_values: [ column1.serialize_value(unique_id), column2.serialize_value([ user1_file.id ]) ],
            destination_group_ids: form.destination_group_ids, destination_user_ids: form.destination_user_ids,
            workflow_state: "request", workflow_user_id: user1.id, workflow_agent_id: admin_user.id,
            workflow_approvers: [{ level: 1, user_id: user_other.id, state: "request" }], workflow_required_counts: [ false ])
        end

        it do
          expect(subject.editable?(user1, site: site)).to be_falsey
          expect(subject.editable?(user2, site: site)).to be_falsey
          expect(subject.editable?(user3, site: site)).to be_falsey
          expect(subject.editable?(admin_user, site: site)).to be_falsey
        end
      end
    end

    describe ".destroyable?" do
      context "user in user_ids" do
        subject! do
          create(
            :gws_workflow2_file, cur_site: site, cur_user: user1, form: form,
            column_values: [ column1.serialize_value(unique_id), column2.serialize_value([ user1_file.id ]) ],
            destination_group_ids: form.destination_group_ids, destination_user_ids: form.destination_user_ids)
        end

        it do
          expect(subject.destroyable?(user1, site: site)).to be_truthy
          expect(subject.destroyable?(user2, site: site)).to be_falsey
          expect(subject.destroyable?(user3, site: site)).to be_falsey
          expect(subject.editable?(admin_user, site: site)).to be_truthy
        end
      end
    end
  end

  describe ".search_destination_treat_state" do
    let(:site) { gws_site }
    let(:user) { gws_user }
    let!(:dest_group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
    let!(:dest_user) { create :gws_user, group_ids: [ dest_group.id ], gws_role_ids: user.gws_role_ids }
    let!(:approver_group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
    let!(:approver_user) { create :gws_user, group_ids: [ approver_group.id ], gws_role_ids: user.gws_role_ids }
    let!(:form) do
      create(
        :gws_workflow2_form_application, cur_site: site, state: "public",
        destination_group_ids: [ dest_group.id ], destination_user_ids: [ dest_user.id ]
      )
    end
    let!(:column1) { create(:gws_column_text_field, cur_site: site, form: form, input_type: "text") }

    let!(:item1) do
      create(
        :gws_workflow2_file, cur_site: site, cur_user: user, form: form, column_values: [ column1.serialize_value(unique_id) ],
        workflow_user_id: user.id, workflow_state: "request", workflow_required_counts: [ false ],
        workflow_approvers: [
          { "level" => 1, "user_type" => "Gws::User", "user_id" => approver_user.id, state: "request", comment: "" },
        ],
        destination_group_ids: form.destination_group_ids, destination_user_ids: form.destination_user_ids,
        destination_treat_state: "untreated"
      )
    end
    let!(:item2) do
      create(
        :gws_workflow2_file, cur_site: site, cur_user: user, form: form, column_values: [ column1.serialize_value(unique_id) ],
        workflow_user_id: user.id, workflow_state: "approve", workflow_required_counts: [ false ],
        workflow_approvers: [
          { "level" => 1, "user_type" => "Gws::User", "user_id" => approver_user.id, state: "approve", comment: unique_id },
        ],
        destination_group_ids: form.destination_group_ids, destination_user_ids: form.destination_user_ids,
        destination_treat_state: "treated"
      )
    end
    let!(:item3) do
      create(
        :gws_workflow2_file, cur_site: site, cur_user: user, form: form, column_values: [ column1.serialize_value(unique_id) ],
        workflow_user_id: user.id, workflow_state: "approve", workflow_required_counts: [ false ],
        workflow_approvers: [
          { "level" => 1, "user_type" => "Gws::User", "user_id" => approver_user.id, state: "approve", comment: unique_id },
        ],
        destination_treat_state: "no_need_to_treat"
      )
    end

    it do
      described_class.search_destination_treat_state(destination_treat_state: "treated").tap do |criteria|
        expect(criteria.count).to eq 2
        expect(criteria.pluck(:id)).to include(item2.id, item3.id)
      end
      described_class.search_destination_treat_state(destination_treat_state: "untreated").tap do |criteria|
        expect(criteria.count).to eq 1
        expect(criteria.pluck(:id)).to include(item1.id)
      end
    end
  end
end
