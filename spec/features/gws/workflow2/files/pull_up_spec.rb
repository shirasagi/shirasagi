require 'spec_helper'

describe Gws::Workflow2::FilesController, type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:admin) { gws_user }
  let!(:minimum_role) { create(:gws_role, cur_site: site, permissions: %w(use_gws_workflow2)) }
  let!(:user1) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ]) }
  let!(:user2) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ]) }
  let!(:user3) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ]) }
  let!(:dest_user) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ]) }
  let(:route_name) { unique_id }
  let(:workflow_comment) { unique_id }
  let(:approve_comment) { unique_id }

  let!(:route) do
    create(
      :gws_workflow2_route, name: route_name, group_ids: admin.group_ids, pull_up: 'enabled',
      approvers: [
        { "level" => 1, "user_type" => user1.class.name, "user_id" => user1.id },
        { "level" => 2, "user_type" => user2.class.name, "user_id" => user2.id },
        { "level" => 3, "user_type" => user3.class.name, "user_id" => user3.id },
      ],
      required_counts: [ false, false, false, false, false ]
    )
  end

  let!(:form) do
    create(:gws_workflow2_form_application, default_route_id: route.id, state: "public", destination_user_ids: [ dest_user.id ])
  end
  let!(:column1) { create(:gws_column_text_field, form: form, input_type: "text") }
  let(:item) do
    create(
      :gws_workflow2_file, cur_user: admin, form: form, column_values: [ column1.serialize_value(unique_id) ],
      destination_user_ids: form.destination_user_ids
    )
  end
  let(:show_path) { gws_workflow2_file_path(site, item, state: 'all') }

  before do
    site.canonical_scheme = %w(http https).sample
    site.canonical_domain = "#{unique_id}.example.jp"
    site.save!

    admin.notice_workflow_user_setting = "notify"
    admin.notice_workflow_email_user_setting = "notify"
    admin.send_notice_mail_addresses = "#{unique_id}@example.jp"
    admin.save!

    ActionMailer::Base.deliveries.clear
  end

  after { ActionMailer::Base.deliveries.clear }

  context "pull up" do
    it do
      login_user admin
      visit show_path
      wait_for_turbo_frame "#workflow-approver-frame"

      #
      # admin: send request
      #
      within ".mod-workflow-request" do
        expect(page).to have_css(".pull_up", text: I18n.t("ss.options.state.enabled"))

        fill_in "item[workflow_comment]", with: workflow_comment
        click_on I18n.t("workflow.buttons.request")
      end
      wait_for_notice I18n.t("gws/workflow2.notice.requested")
      wait_for_turbo_frame "#workflow-approver-frame"

      within ".mod-workflow-view" do
        expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".workflow_comment", text: workflow_comment)
      end

      item.reload
      expect(item.workflow_user_id).to eq admin.id
      expect(item.workflow_agent_id).to be_blank
      expect(item.workflow_state).to eq 'request'
      expect(item.workflow_comment).to eq workflow_comment
      expect(item.workflow_pull_up).to eq 'enabled'
      expect(item.workflow_approvers.count).to eq 3
      expect(item.workflow_approvers).to include(
        { level: 1, user_type: Gws::User.name, user_id: user1.id, state: 'request', comment: '' })
      expect(item.workflow_approvers).to include(
        { level: 2, user_type: Gws::User.name, user_id: user2.id, state: 'pending', comment: '' })
      expect(item.workflow_approvers).to include(
        { level: 3, user_type: Gws::User.name, user_id: user3.id, state: 'pending', comment: '' })
      expect(item.workflow_circulations).to be_blank

      expect(SS::Notification.count).to eq 1
      SS::Notification.order_by(id: -1).first.tap do |memo|
        expect(memo.subject).to eq I18n.t("gws_notification.gws/workflow/file.request", name: item.name)
        expect(memo.text).to be_blank
        expect(memo.html).to be_blank
        expect(memo.user_id).to eq admin.id
        expect(memo.member_ids).to eq [user1.id]
      end

      #
      # user3: pull up request, he is the last one
      #
      login_user user3
      visit show_path
      wait_for_turbo_frame "#workflow-approver-frame"
      within ".mod-workflow-view" do
        expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.request"))
      end

      within ".mod-workflow-approve" do
        fill_in "item[comment]", with: approve_comment
        click_on I18n.t("workflow.buttons.pull_up")
      end
      wait_for_notice I18n.t("gws/workflow2.notice.pulled_up")
      wait_for_turbo_frame "#workflow-approver-frame"

      within ".mod-workflow-view" do
        expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.approve"))
        expect(page).to have_css(".workflow_comment", text: workflow_comment)
        # expect(page).to have_css(".workflow_approvers", text: approve_comment)

        # wait_for_cbox_opened { find('.workflow_approvers tr:nth-child(1) .approver_comment').click }
        # within_cbox do
        #   expect(page).to have_css(".approver-comment", text: approve_comment)
        #   wait_for_cbox_closed { find('#cboxClose').click }
        # end
      end

      item.reload
      expect(item.workflow_state).to eq "approve"
      expect(item.workflow_approvers).to include(
        { level: 1, user_type: Gws::User.name, user_id: user1.id, state: "other_pulled_up", comment: '' })
      expect(item.workflow_approvers).to include(
        { level: 2, user_type: Gws::User.name, user_id: user2.id, state: "other_pulled_up", comment: '' })
      expect(item.workflow_approvers).to include(
        { level: 3, user_type: Gws::User.name, user_id: user3.id, state: 'approve', comment: approve_comment,
          file_ids: nil, created: be_within(30.seconds).of(Time.zone.now) })
      expect(item.workflow_circulations).to be_blank

      expect(SS::Notification.count).to eq 3
      SS::Notification.order_by(id: -1).to_a.tap do |notifications|
        notifications[0].tap do |notification|
          subject = I18n.t("gws_notification.gws/workflow2/file.destination", name: item.name)
          expect(notification.subject).to eq subject
          expect(notification.text).to be_blank
          expect(notification.html).to be_blank
          expect(notification.user_id).to eq item.workflow_user_id
          expect(notification.user_id).to eq admin.id
          expect(notification.member_ids).to eq [dest_user.id]
          expect(notification.url).to eq gws_workflow2_file_path(site: site, state: 'all', id: item)
        end
        notifications[1].tap do |notification|
          subject = I18n.t("gws_notification.gws/workflow/file.approve", name: item.name)
          expect(notification.subject).to eq subject
          expect(notification.text).to be_blank
          expect(notification.html).to be_blank
          expect(notification.user_id).to eq user3.id
          expect(notification.member_ids).to eq [admin.id]
          expect(notification.url).to eq gws_workflow2_file_path(site: site, state: 'all', id: item)
        end
      end
    end
  end
end
