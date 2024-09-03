require 'spec_helper'

describe Gws::Workflow2::FilesController, type: :feature, dbscope: :example, js: true do
  before { ActionMailer::Base.deliveries.clear }

  after { ActionMailer::Base.deliveries.clear }

  context "my group with circulation step" do
    let(:site) { gws_site }
    let(:admin) { gws_user }
    let!(:minimum_role) { create(:gws_role, cur_site: site, permissions: %w(use_gws_workflow2)) }
    let!(:user1) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ]) }
    let!(:user2) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ]) }
    let!(:user3) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ]) }
    let!(:user4) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ]) }

    let(:route_name) { unique_id }
    let!(:route) do
      create(
        :gws_workflow2_route, name: route_name, group_ids: admin.group_ids,
        approvers: [
          { "level" => 1, "user_type" => user1.class.name, "user_id" => user1.id },
        ],
        required_counts: [ false, false, false, false, false ],
        circulations: [
          { "level" => 1, "user_type" => user2.class.name, "user_id" => user2.id },
          { "level" => 1, "user_type" => user3.class.name, "user_id" => user3.id },
          { "level" => 2, "user_type" => user4.class.name, "user_id" => user4.id },
        ]
      )
    end

    let!(:form) { create(:gws_workflow2_form_application, default_route_id: route.id, state: "public") }
    let!(:column1) { create(:gws_column_text_field, form: form, input_type: "text") }
    let(:item) { create :gws_workflow2_file, form: form, column_values: [ column1.serialize_value(unique_id) ] }
    let(:show_path) { gws_workflow2_file_path(site, item, state: 'all') }

    let(:workflow_comment1) { unique_id }
    let(:approve_comment1) { unique_id }
    let(:circulation_comment2) { unique_id }
    let(:circulation_comment3) { unique_id }
    let(:circulation_comment4) { unique_id }

    before do
      site.canonical_scheme = %w(http https).sample
      site.canonical_domain = "#{unique_id}.example.jp"
      site.save!

      admin.notice_workflow_user_setting = "notify"
      admin.notice_workflow_email_user_setting = "notify"
      admin.send_notice_mail_addresses = "#{unique_id}@example.jp"
      admin.save!
    end

    it do
      #
      # admin: 申請する（承認者 1 段、1 名＋回覧者 2 段、3 名）
      #
      login_gws_user
      visit show_path
      wait_for_turbo_frame "#workflow-approver-frame"

      within ".mod-workflow-request" do
        fill_in "item[workflow_comment]", with: workflow_comment1
        click_on I18n.t("workflow.buttons.request")
      end
      wait_for_notice I18n.t("gws/workflow2.notice.requested")
      wait_for_turbo_frame "#workflow-approver-frame"

      within ".mod-workflow-view" do
        expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".workflow_comment", text: workflow_comment1)
      end

      item.reload
      expect(item.workflow_user_id).to eq admin.id
      expect(item.workflow_state).to eq "request"
      expect(item.workflow_comment).to eq workflow_comment1
      expect(item.workflow_approvers.count).to eq 1
      expect(item.workflow_approvers).to \
        include({level: 1, user_type: Gws::User.name, user_id: user1.id, state: 'request', comment: ''})
      expect(item.workflow_circulations.count).to eq 3
      expect(item.workflow_circulations).to \
        include({level: 1, user_type: Gws::User.name, user_id: user2.id, state: 'pending', comment: ''})
      expect(item.workflow_circulations).to \
        include({level: 1, user_type: Gws::User.name, user_id: user3.id, state: 'pending', comment: ''})
      expect(item.workflow_circulations).to \
        include({level: 2, user_type: Gws::User.name, user_id: user4.id, state: 'pending', comment: ''})

      expect(SS::Notification.count).to eq 1
      SS::Notification.order_by(id: -1).first.tap do |memo|
        expect(memo.subject).to eq I18n.t("gws_notification.gws/workflow/file.request", name: item.name)
        expect(memo.text).to be_blank
        expect(memo.html).to be_blank
        expect(memo.user_id).to eq admin.id
        expect(memo.member_ids).to eq [user1.id]
      end

      #
      # user1: 申請を承認する
      #
      login_user user1
      visit show_path
      wait_for_turbo_frame "#workflow-approver-frame"

      within ".mod-workflow-approve" do
        fill_in "item[comment]", with: approve_comment1
        click_on I18n.t("workflow.buttons.approve")
      end
      wait_for_notice I18n.t("gws/workflow2.notice.approved")
      wait_for_turbo_frame "#workflow-approver-frame"

      within ".mod-workflow-view" do
        expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.approve"))
        expect(page).to have_css(".workflow_comment", text: workflow_comment1)

        wait_for_cbox_opened { find('.workflow_approvers tr:nth-child(1) .approver_comment').click }
        within_cbox do
          expect(page).to have_css(".approver-comment", text: approve_comment1)
          wait_for_cbox_closed { find('#cboxClose').click }
        end
      end

      item.reload
      expect(item.workflow_user_id).to eq admin.id
      expect(item.workflow_state).to eq 'approve'
      expect(item.workflow_comment).to eq workflow_comment1
      expect(item.workflow_approvers.count).to eq 1
      expect(item.workflow_approvers).to \
        include({level: 1, user_type: Gws::User.name, user_id: user1.id, state: 'approve',
                 comment: approve_comment1, file_ids: nil, created: be_within(30.seconds).of(Time.zone.now)})
      expect(item.workflow_circulations.count).to eq 3
      expect(item.workflow_circulations).to \
        include({level: 1, user_type: Gws::User.name, user_id: user2.id, state: 'unseen', comment: ''})
      expect(item.workflow_circulations).to \
        include({level: 1, user_type: Gws::User.name, user_id: user3.id, state: 'unseen', comment: ''})
      expect(item.workflow_circulations).to \
        include({level: 2, user_type: Gws::User.name, user_id: user4.id, state: 'pending', comment: ''})

      expect(SS::Notification.count).to eq 3
      SS::Notification.order_by(id: -1).second.tap do |memo|
        expect(memo.subject).to eq I18n.t("gws_notification.gws/workflow/file.approve", name: item.name)
        expect(memo.text).to be_blank
        expect(memo.html).to be_blank
        expect(memo.user_id).to eq user1.id
        expect(memo.member_ids).to eq [admin.id]
      end
      SS::Notification.order_by(id: -1).first.tap do |memo|
        expect(memo.subject).to eq I18n.t("gws_notification.gws/workflow/file.circular", name: item.name)
        expect(memo.text).to be_blank
        expect(memo.html).to be_blank
        expect(memo.user_id).to eq admin.id
        expect(memo.user_id).to eq item.workflow_user_id
        expect(memo.member_ids).to eq [user2.id, user3.id]
      end

      #
      # user2: 申請を確認する
      #
      login_user user2
      visit show_path
      wait_for_turbo_frame "#workflow-approver-frame"

      within ".mod-workflow-circulation" do
        fill_in "item[comment]", with: circulation_comment2
        click_on I18n.t("workflow.links.set_seen")
      end
      wait_for_notice I18n.t("gws/workflow2.notice.seen")
      wait_for_turbo_frame "#workflow-approver-frame"

      within ".mod-workflow-view" do
        expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.approve"))
        expect(page).to have_css(".workflow_comment", text: workflow_comment1)
        expect(page).to have_css(".workflow_circulations", text: circulation_comment2)

        wait_for_cbox_opened { find('.workflow_approvers tr:nth-child(1) .approver_comment').click }
        within_cbox do
          expect(page).to have_css(".approver-comment", text: approve_comment1)
          wait_for_cbox_closed { find('#cboxClose').click }
        end
      end

      item.reload
      expect(item.workflow_user_id).to eq admin.id
      expect(item.workflow_state).to eq 'approve'
      expect(item.workflow_comment).to eq workflow_comment1
      expect(item.workflow_approvers.count).to eq 1
      expect(item.workflow_approvers).to \
        include({level: 1, user_type: Gws::User.name, user_id: user1.id, state: 'approve',
                 comment: approve_comment1, file_ids: nil, created: be_within(30.seconds).of(Time.zone.now)})
      expect(item.workflow_circulations.count).to eq 3
      expect(item.workflow_circulations).to \
        include({level: 1, user_type: Gws::User.name, user_id: user2.id, state: 'seen', comment: circulation_comment2})
      expect(item.workflow_circulations).to \
        include({level: 1, user_type: Gws::User.name, user_id: user3.id, state: 'unseen', comment: ''})
      expect(item.workflow_circulations).to \
        include({level: 2, user_type: Gws::User.name, user_id: user4.id, state: 'pending', comment: ''})

      expect(SS::Notification.count).to eq 4
      SS::Notification.order_by(id: -1).first.tap do |memo|
        expect(memo.subject).to eq I18n.t("gws_notification.gws/workflow/file.comment", name: item.name)
        expect(memo.text).to be_blank
        expect(memo.html).to be_blank
        expect(memo.user_id).to eq user2.id
        expect(memo.member_ids).to eq [admin.id]
        expect(memo.member_ids).to eq [item.workflow_user_id]
      end

      #
      # user3: 申請を確認する
      #
      login_user user3
      visit show_path
      wait_for_turbo_frame "#workflow-approver-frame"

      within ".mod-workflow-circulation" do
        fill_in "item[comment]", with: circulation_comment3
        click_on I18n.t("workflow.links.set_seen")
      end
      wait_for_notice I18n.t("gws/workflow2.notice.seen")
      wait_for_turbo_frame "#workflow-approver-frame"

      within ".mod-workflow-view" do
        expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.approve"))
        expect(page).to have_css(".workflow_comment", text: workflow_comment1)
        expect(page).to have_css(".workflow_circulations", text: circulation_comment2)
        expect(page).to have_css(".workflow_circulations", text: circulation_comment3)

        wait_for_cbox_opened { find('.workflow_approvers tr:nth-child(1) .approver_comment').click }
        within_cbox do
          expect(page).to have_css(".approver-comment", text: approve_comment1)
          wait_for_cbox_closed { find('#cboxClose').click }
        end
      end

      item.reload
      expect(item.workflow_user_id).to eq admin.id
      expect(item.workflow_state).to eq 'approve'
      expect(item.workflow_comment).to eq workflow_comment1
      expect(item.workflow_approvers.count).to eq 1
      expect(item.workflow_approvers).to \
        include({level: 1, user_type: Gws::User.name, user_id: user1.id, state: 'approve',
                 comment: approve_comment1, file_ids: nil, created: be_within(30.seconds).of(Time.zone.now)})
      expect(item.workflow_circulations.count).to eq 3
      expect(item.workflow_circulations).to \
        include({level: 1, user_type: Gws::User.name, user_id: user2.id, state: 'seen', comment: circulation_comment2})
      expect(item.workflow_circulations).to \
        include({level: 1, user_type: Gws::User.name, user_id: user3.id, state: 'seen', comment: circulation_comment3})
      expect(item.workflow_circulations).to \
        include({level: 2, user_type: Gws::User.name, user_id: user4.id, state: 'unseen', comment: ''})

      expect(SS::Notification.count).to eq 6
      SS::Notification.order_by(id: -1).second.tap do |memo|
        expect(memo.subject).to eq I18n.t("gws_notification.gws/workflow/file.comment", name: item.name)
        expect(memo.text).to be_blank
        expect(memo.html).to be_blank
        expect(memo.user_id).to eq user3.id
        expect(memo.member_ids).to eq [admin.id]
        expect(memo.member_ids).to eq [item.workflow_user_id]
      end
      SS::Notification.order_by(id: -1).first.tap do |memo|
        expect(memo.subject).to eq I18n.t("gws_notification.gws/workflow/file.circular", name: item.name)
        expect(memo.text).to be_blank
        expect(memo.html).to be_blank
        expect(memo.user_id).to eq admin.id
        expect(memo.user_id).to eq item.workflow_user_id
        expect(memo.member_ids).to eq [user4.id]
      end

      #
      # user4: 申請を確認する
      #
      login_user user4
      visit show_path
      wait_for_turbo_frame "#workflow-approver-frame"

      within ".mod-workflow-circulation" do
        fill_in "item[comment]", with: circulation_comment4
        click_on I18n.t("workflow.links.set_seen")
      end
      wait_for_notice I18n.t("gws/workflow2.notice.seen")
      wait_for_turbo_frame "#workflow-approver-frame"

      within ".mod-workflow-view" do
        expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.approve"))
        expect(page).to have_css(".workflow_comment", text: workflow_comment1)
        expect(page).to have_css(".workflow_circulations", text: circulation_comment2)
        expect(page).to have_css(".workflow_circulations", text: circulation_comment3)
        expect(page).to have_css(".workflow_circulations", text: circulation_comment4)

        wait_for_cbox_opened { find('.workflow_approvers tr:nth-child(1) .approver_comment').click }
        within_cbox do
          expect(page).to have_css(".approver-comment", text: approve_comment1)
          wait_for_cbox_closed { find('#cboxClose').click }
        end
      end

      item.reload
      expect(item.workflow_user_id).to eq admin.id
      expect(item.workflow_state).to eq 'approve'
      expect(item.workflow_comment).to eq workflow_comment1
      expect(item.workflow_approvers.count).to eq 1
      expect(item.workflow_approvers).to \
        include({level: 1, user_type: Gws::User.name, user_id: user1.id, state: 'approve',
                 comment: approve_comment1, file_ids: nil, created: be_within(30.seconds).of(Time.zone.now)})
      expect(item.workflow_circulations.count).to eq 3
      expect(item.workflow_circulations).to \
        include({level: 1, user_type: Gws::User.name, user_id: user2.id, state: 'seen', comment: circulation_comment2})
      expect(item.workflow_circulations).to \
        include({level: 1, user_type: Gws::User.name, user_id: user3.id, state: 'seen', comment: circulation_comment3})
      expect(item.workflow_circulations).to \
        include({level: 2, user_type: Gws::User.name, user_id: user4.id, state: 'seen', comment: circulation_comment4})

      expect(SS::Notification.count).to eq 7
      SS::Notification.order_by(id: -1).first.tap do |memo|
        expect(memo.subject).to eq I18n.t("gws_notification.gws/workflow/file.comment", name: item.name)
        expect(memo.text).to be_blank
        expect(memo.html).to be_blank
        expect(memo.user_id).to eq user4.id
        expect(memo.member_ids).to eq [admin.id]
        expect(memo.member_ids).to eq [item.workflow_user_id]
      end
    end
  end
end
