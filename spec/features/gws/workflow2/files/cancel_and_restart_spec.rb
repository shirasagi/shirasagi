require 'spec_helper'

describe Gws::Workflow2::FilesController, type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:admin) { gws_user }

  let!(:minimum_role) { create(:gws_role, cur_site: site, permissions: %w(use_gws_workflow2)) }
  let(:role_ids) { [ minimum_role.id ] }
  let(:group_ids) { admin.group_ids }
  let(:user1) { create(:gws_user, :gws_workflow_notice, group_ids: group_ids, gws_role_ids: role_ids) }
  let(:user2) { create(:gws_user, :gws_workflow_notice, group_ids: group_ids, gws_role_ids: role_ids) }
  let(:user3) { create(:gws_user, :gws_workflow_notice, group_ids: group_ids, gws_role_ids: role_ids) }

  let(:route_name) { unique_id }
  let!(:route) do
    create(
      :gws_workflow2_route, name: route_name, group_ids: group_ids,
      approvers: [
        { "level" => 1, "user_type" => user1.class.name, "user_id" => user1.id },
        { "level" => 2, "user_type" => user2.class.name, "user_id" => user2.id },
        { "level" => 3, "user_type" => user3.class.name, "user_id" => user3.id },
      ],
      required_counts: [ false, false, false, false, false ]
    )
  end

  let(:workflow_comment1) { unique_id }
  let(:workflow_comment2) { unique_id }
  let(:approve_comment1) { unique_id }
  let(:approve_comment2) { unique_id }
  let(:approve_comment3) { unique_id }
  let(:approve_comment4) { unique_id }
  let(:remand_comment1) { unique_id }

  before do
    site.canonical_scheme = %w(http https).sample
    site.canonical_domain = "#{unique_id}.example.jp"
    site.save!

    admin.notice_workflow_user_setting = %w(notify silence).sample
    admin.notice_workflow_email_user_setting = %w(notify silence).sample
    admin.send_notice_mail_addresses = "#{unique_id}@example.jp"
    admin.save!

    ActionMailer::Base.deliveries.clear
  end

  after { ActionMailer::Base.deliveries.clear }

  context "cancel request and restart workflow" do
    let!(:form) { create(:gws_workflow2_form_application, default_route_id: route.id, state: "public") }
    let!(:column1) { create(:gws_column_text_field, form: form, input_type: "text") }
    let(:item) { create :gws_workflow2_file, form: form, column_values: [ column1.serialize_value(unique_id) ] }
    let(:show_path) { gws_workflow2_file_path(site, item, state: 'all') }

    it do
      #
      # admin: send request
      #
      login_user admin
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
      expect(item.workflow_approvers.count).to eq 3
      expect(item.workflow_approvers).to \
        include({level: 1, user_type: Gws::User.name, user_id: user1.id, state: 'request', comment: ''})
      expect(item.workflow_approvers).to \
        include({level: 2, user_type: Gws::User.name, user_id: user2.id, state: 'pending', comment: ''})
      expect(item.workflow_approvers).to \
        include({level: 3, user_type: Gws::User.name, user_id: user3.id, state: 'pending', comment: ''})

      expect(SS::Notification.count).to eq 1
      SS::Notification.order_by(id: -1).first.tap do |memo|
        expect(memo.subject).to eq I18n.t("gws_notification.gws/workflow/file.request", name: item.name)
        expect(memo.text).to be_blank
        expect(memo.html).to be_blank
        expect(memo.user_id).to eq item.workflow_user_id
        expect(memo.member_ids).to eq [user1.id]
      end

      #
      # user1: approve request
      #
      login_user user1
      visit show_path
      wait_for_turbo_frame "#workflow-approver-frame"
      within ".mod-workflow-view" do
        expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.request"))
      end
      within ".mod-workflow-approve" do
        fill_in "item[comment]", with: approve_comment1
        click_on I18n.t("workflow.buttons.approve")
      end
      wait_for_notice I18n.t("gws/workflow2.notice.approved")
      wait_for_turbo_frame "#workflow-approver-frame"

      within ".mod-workflow-view" do
        expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".workflow_comment", text: workflow_comment1)

        wait_for_cbox_opened { find('.workflow_approvers tr:nth-child(1) .approver_comment').click }
        within_cbox do
          expect(page).to have_css(".approver-comment", text: approve_comment1)
          wait_for_cbox_closed { find('#cboxClose').click }
        end
      end

      item.reload
      expect(item.workflow_user_id).to eq admin.id
      expect(item.workflow_state).to eq 'request'
      expect(item.workflow_comment).to eq workflow_comment1
      expect(item.workflow_approvers.count).to eq 3
      expect(item.workflow_approvers).to \
        include({level: 1, user_type: Gws::User.name, user_id: user1.id, state: 'approve',
                 comment: approve_comment1, file_ids: nil, created: be_within(30.seconds).of(Time.zone.now)})
      expect(item.workflow_approvers).to \
        include({level: 2, user_type: Gws::User.name, user_id: user2.id, state: 'request', comment: ''})
      expect(item.workflow_approvers).to \
        include({level: 3, user_type: Gws::User.name, user_id: user3.id, state: 'pending', comment: ''})

      expect(SS::Notification.count).to eq 2
      SS::Notification.order_by(id: -1).first.tap do |memo|
        expect(memo.subject).to eq I18n.t("gws_notification.gws/workflow/file.request", name: item.name)
        expect(memo.text).to be_blank
        expect(memo.html).to be_blank
        expect(memo.user_id).to eq item.workflow_user_id
        expect(memo.member_ids).to eq [user2.id]
      end

      #
      # admin: cancel request
      #
      login_user admin
      visit show_path
      wait_for_turbo_frame "#workflow-approver-frame"
      within ".mod-workflow-view" do
        expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.request"))
        page.accept_confirm I18n.t("workflow.confirm.request_cancel") do
          click_on I18n.t('workflow.buttons.cancel')
        end
      end
      wait_for_notice I18n.t("workflow.notice.request_cancelled")
      wait_for_turbo_frame "#workflow-approver-frame"

      within ".mod-workflow-view" do
        expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.cancelled"))
        expect(page).to have_css(".workflow_comment", text: workflow_comment1)

        wait_for_cbox_opened { find('.workflow_approvers tr:nth-child(1) .approver_comment').click }
        within_cbox do
          expect(page).to have_css(".approver-comment", text: approve_comment1)
          wait_for_cbox_closed { find('#cboxClose').click }
        end
      end

      item.reload
      expect(item.workflow_user_id).to eq admin.id
      expect(item.workflow_state).to eq 'cancelled'
      expect(item.workflow_comment).to eq workflow_comment1
      expect(item.workflow_approvers.count).to eq 3
      expect(item.workflow_approvers).to \
        include({level: 1, user_type: Gws::User.name, user_id: user1.id, state: 'approve',
                 comment: approve_comment1, file_ids: nil, created: be_within(30.seconds).of(Time.zone.now)})
      expect(item.workflow_approvers).to \
        include({level: 2, user_type: Gws::User.name, user_id: user2.id, state: 'request', comment: ''})
      expect(item.workflow_approvers).to \
        include({level: 3, user_type: Gws::User.name, user_id: user3.id, state: 'pending', comment: ''})

      expect(SS::Notification.count).to eq 3
      SS::Notification.order_by(id: -1).first.tap do |memo|
        expect(memo.subject).to eq I18n.t("gws_notification.gws/workflow2/file.cancel", name: item.name)
        expect(memo.text).to be_blank
        expect(memo.html).to be_blank
        expect(memo.user_id).to eq admin.id
        expect(memo.user_id).to eq item.workflow_user_id
        expect(memo.member_ids).to eq [user2.id]
      end

      #
      # admin: restart request
      #
      login_user admin
      visit show_path
      wait_for_turbo_frame "#workflow-approver-frame"
      within ".mod-workflow-view" do
        expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.cancelled"))

        within ".route_id" do
          wait_event_to_fire("turbo:frame-load") { click_on I18n.t("workflow.restart_workflow") }
        end
      end
      within ".mod-workflow-request" do
        fill_in "item[workflow_comment]", with: workflow_comment2
        click_on I18n.t("workflow.buttons.restart")
      end
      wait_for_notice I18n.t("gws/workflow2.notice.requested")
      wait_for_turbo_frame "#workflow-approver-frame"

      within ".mod-workflow-view" do
        expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".workflow_comment", text: workflow_comment2)
        expect(page).to have_no_content(workflow_comment1)
        expect(page).to have_no_content(approve_comment1)
        expect(page).to have_no_content(remand_comment1)
      end

      item.reload
      expect(item.workflow_user_id).to eq admin.id
      expect(item.workflow_state).to eq "request"
      expect(item.workflow_comment).to eq workflow_comment2
      expect(item.workflow_approvers.count).to eq 3
      expect(item.workflow_approvers).to \
        include({level: 1, user_type: Gws::User.name, user_id: user1.id, state: 'request', comment: ''})
      expect(item.workflow_approvers).to \
        include({level: 2, user_type: Gws::User.name, user_id: user2.id, state: 'pending', comment: ''})
      expect(item.workflow_approvers).to \
        include({level: 3, user_type: Gws::User.name, user_id: user3.id, state: 'pending', comment: ''})

      expect(SS::Notification.count).to eq 4
      SS::Notification.order_by(id: -1).first.tap do |memo|
        expect(memo.subject).to eq I18n.t("gws_notification.gws/workflow/file.request", name: item.name)
        expect(memo.text).to be_blank
        expect(memo.html).to be_blank
        expect(memo.user_id).to eq item.workflow_user_id
        expect(memo.member_ids).to eq [user1.id]
      end

      #
      # user1: approve request
      #
      login_user user1
      visit show_path
      wait_for_turbo_frame "#workflow-approver-frame"

      within ".mod-workflow-approve" do
        fill_in "item[comment]", with: approve_comment2
        click_on I18n.t("workflow.buttons.approve")
      end
      wait_for_notice I18n.t("gws/workflow2.notice.approved")
      wait_for_turbo_frame "#workflow-approver-frame"

      within ".mod-workflow-view" do
        expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".workflow_comment", text: workflow_comment2)

        wait_for_cbox_opened { find('.workflow_approvers tr:nth-child(1) .approver_comment').click }
        within_cbox do
          expect(page).to have_css(".approver-comment", text: approve_comment2)
          wait_for_cbox_closed { find('#cboxClose').click }
        end
      end

      item.reload
      expect(item.workflow_user_id).to eq admin.id
      expect(item.workflow_state).to eq 'request'
      expect(item.workflow_comment).to eq workflow_comment2
      expect(item.workflow_approvers.count).to eq 3
      expect(item.workflow_approvers).to \
        include({level: 1, user_type: Gws::User.name, user_id: user1.id, state: 'approve',
                 comment: approve_comment2, file_ids: nil, created: be_within(30.seconds).of(Time.zone.now)})
      expect(item.workflow_approvers).to \
        include({level: 2, user_type: Gws::User.name, user_id: user2.id, state: 'request', comment: ''})
      expect(item.workflow_approvers).to \
        include({level: 3, user_type: Gws::User.name, user_id: user3.id, state: 'pending', comment: ''})

      expect(SS::Notification.count).to eq 5

      #
      # user2: approve request
      #
      login_user user2
      visit show_path
      wait_for_turbo_frame "#workflow-approver-frame"

      within ".mod-workflow-approve" do
        fill_in "item[comment]", with: approve_comment3
        click_on I18n.t("workflow.buttons.approve")
      end
      wait_for_notice I18n.t("gws/workflow2.notice.approved")
      wait_for_turbo_frame "#workflow-approver-frame"

      within ".mod-workflow-view" do
        expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".workflow_comment", text: workflow_comment2)

        wait_for_cbox_opened { find('.workflow_approvers tr:nth-child(1) .approver_comment').click }
        within_cbox do
          expect(page).to have_css(".approver-comment", text: approve_comment2)
          wait_for_cbox_closed { find('#cboxClose').click }
        end
        wait_for_cbox_opened { find('.workflow_approvers tr:nth-child(2) .approver_comment').click }
        within_cbox do
          expect(page).to have_css(".approver-comment", text: approve_comment3)
          wait_for_cbox_closed { find('#cboxClose').click }
        end
      end

      item.reload
      expect(item.workflow_user_id).to eq admin.id
      expect(item.workflow_state).to eq 'request'
      expect(item.workflow_comment).to eq workflow_comment2
      expect(item.workflow_approvers.count).to eq 3
      expect(item.workflow_approvers).to \
        include({level: 1, user_type: Gws::User.name, user_id: user1.id, state: 'approve',
                 comment: approve_comment2, file_ids: nil, created: be_within(30.seconds).of(Time.zone.now)})
      expect(item.workflow_approvers).to \
        include({level: 2, user_type: Gws::User.name, user_id: user2.id, state: 'approve',
                 comment: approve_comment3, file_ids: nil, created: be_within(30.seconds).of(Time.zone.now)})
      expect(item.workflow_approvers).to \
        include({level: 3, user_type: Gws::User.name, user_id: user3.id, state: 'request', comment: ''})

      expect(SS::Notification.count).to eq 6

      #
      # user3: approve request, he is the last one
      #
      login_user user3
      visit show_path
      wait_for_turbo_frame "#workflow-approver-frame"

      within ".mod-workflow-approve" do
        fill_in "item[comment]", with: approve_comment4
        click_on I18n.t("workflow.buttons.approve")
      end
      wait_for_notice I18n.t("gws/workflow2.notice.approved")
      wait_for_turbo_frame "#workflow-approver-frame"

      within ".mod-workflow-view" do
        expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.approve"))
        expect(page).to have_css(".workflow_comment", text: workflow_comment2)

        wait_for_cbox_opened { find('.workflow_approvers tr:nth-child(1) .approver_comment').click }
        within_cbox do
          expect(page).to have_css(".approver-comment", text: approve_comment2)
          wait_for_cbox_closed { find('#cboxClose').click }
        end
        wait_for_cbox_opened { find('.workflow_approvers tr:nth-child(2) .approver_comment').click }
        within_cbox do
          expect(page).to have_css(".approver-comment", text: approve_comment3)
          wait_for_cbox_closed { find('#cboxClose').click }
        end
        wait_for_cbox_opened { find('.workflow_approvers tr:nth-child(3) .approver_comment').click }
        within_cbox do
          expect(page).to have_css(".approver-comment", text: approve_comment4)
          wait_for_cbox_closed { find('#cboxClose').click }
        end
      end

      item.reload
      expect(item.workflow_user_id).to eq admin.id
      expect(item.workflow_state).to eq 'approve'
      expect(item.workflow_comment).to eq workflow_comment2
      expect(item.workflow_approvers.count).to eq 3
      expect(item.workflow_approvers).to \
        include({level: 1, user_type: Gws::User.name, user_id: user1.id, state: 'approve',
                 comment: approve_comment2, file_ids: nil, created: be_within(30.seconds).of(Time.zone.now)})
      expect(item.workflow_approvers).to \
        include({level: 2, user_type: Gws::User.name, user_id: user2.id, state: 'approve',
                 comment: approve_comment3, file_ids: nil, created: be_within(30.seconds).of(Time.zone.now)})
      expect(item.workflow_approvers).to \
        include({level: 3, user_type: Gws::User.name, user_id: user3.id, state: 'approve',
                 comment: approve_comment4, file_ids: nil, created: be_within(30.seconds).of(Time.zone.now)})

      expected_notification_count = admin.notice_workflow_user_setting == "notify" ? 7 : 6
      expect(SS::Notification.count).to eq expected_notification_count
      if admin.notice_workflow_user_setting == "notify"
        SS::Notification.order_by(id: -1).first.tap do |memo|
          expect(memo.subject).to eq I18n.t("gws_notification.gws/workflow/file.approve", name: item.name)
          expect(memo.text).to be_blank
          expect(memo.html).to be_blank
          expect(memo.user_id).to eq user3.id
          expect(memo.member_ids).to have(1).items
          expect(memo.member_ids).to eq [item.workflow_user_id]
          expect(memo.member_ids).to eq [admin.id]
        end
      end
    end
  end
end
