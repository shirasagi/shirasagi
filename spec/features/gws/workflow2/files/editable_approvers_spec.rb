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
  let(:approve_comment1) { unique_id }
  let(:approve_comment2) { unique_id }

  let!(:route) do
    create(
      :gws_workflow2_route, name: route_name, group_ids: admin.group_ids,
      approvers: [
        { "level" => 1, "user_type" => user1.class.name, "user_id" => user1.id, "editable" => 1 },
        { "level" => 2, "user_type" => user2.class.name, "user_id" => user2.id, "editable" => 1 },
        { "level" => 3, "user_type" => user3.class.name, "user_id" => user3.id, "editable" => 1 },
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
  let(:column1_value1) { unique_id }
  let(:column1_value2) { unique_id }
  let(:column1_value3) { unique_id }

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

  context "with editable approvers" do
    it do
      login_user admin
      visit show_path
      wait_for_turbo_frame "#workflow-approver-frame"

      #
      # admin: send request
      #
      within ".mod-workflow-request" do
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
      expect(item.workflow_approvers.count).to eq 3
      expect(item.workflow_approvers).to \
        include({level: 1, user_type: Gws::User.name, user_id: user1.id, editable: 1, state: 'request', comment: ''})
      expect(item.workflow_approvers).to \
        include({level: 2, user_type: Gws::User.name, user_id: user2.id, editable: 1, state: 'pending', comment: ''})
      expect(item.workflow_approvers).to \
        include({level: 3, user_type: Gws::User.name, user_id: user3.id, editable: 1, state: 'pending', comment: ''})
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
      # user1: edit and approve
      #
      login_user user1
      visit show_path
      wait_for_turbo_frame "#workflow-approver-frame"
      within ".mod-workflow-view" do
        expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.request"))
      end
      within ".nav-menu" do
        click_on I18n.t("ss.links.edit")
      end
      expect(page).to have_no_css(".errorExplanation")
      expect(page).to have_no_content(I18n.t("gws/workflow2.buttons.save_and_apply"))

      within "form#item-form" do
        fill_in "custom[#{column1.id}]", with: column1_value1
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")
      wait_for_turbo_frame "#workflow-approver-frame"

      within ".mod-workflow-view" do
        expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.request"))
      end

      within "#addon-gws-agents-addons-workflow2-custom_form" do
        expect(page).to have_content(column1_value1)
      end
      within ".mod-workflow-approve" do
        fill_in "item[comment]", with: approve_comment1
        click_on I18n.t("workflow.buttons.approve")
      end
      wait_for_notice I18n.t("gws/workflow2.notice.approved")
      wait_for_turbo_frame "#workflow-approver-frame"

      within ".mod-workflow-view" do
        expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".workflow_comment", text: workflow_comment)

        wait_for_cbox_opened { find('.workflow_approvers tr:nth-child(1) .approver_comment').click }
        within_cbox do
          expect(page).to have_css(".approver-comment", text: approve_comment1)
          wait_for_cbox_closed { find('#cboxClose').click }
        end
      end

      item.reload
      expect(item.workflow_user_id).to eq admin.id
      expect(item.workflow_agent_id).to be_blank
      expect(item.workflow_state).to eq 'request'
      expect(item.workflow_comment).to eq workflow_comment
      expect(item.workflow_approvers.count).to eq 3
      expect(item.workflow_approvers).to \
        include({level: 1, user_type: Gws::User.name, user_id: user1.id, editable: 1, state: 'approve',
                 comment: approve_comment1, file_ids: nil, created: be_within(30.seconds).of(Time.zone.now)})
      expect(item.workflow_approvers).to \
        include({level: 2, user_type: Gws::User.name, user_id: user2.id, editable: 1, state: 'request', comment: ''})
      expect(item.workflow_approvers).to \
        include({level: 3, user_type: Gws::User.name, user_id: user3.id, editable: 1, state: 'pending', comment: ''})
      expect(item.workflow_circulations).to be_blank

      expect(SS::Notification.count).to eq 2
      SS::Notification.order_by(id: -1).first.tap do |memo|
        expect(memo.subject).to eq I18n.t("gws_notification.gws/workflow/file.request", name: item.name)
        expect(memo.text).to be_blank
        expect(memo.html).to be_blank
        expect(memo.user_id).to eq item.workflow_user_id
        expect(memo.member_ids).to eq [user2.id]
      end

      #
      # user2: edit and approve
      #
      login_user user2
      visit show_path
      wait_for_turbo_frame "#workflow-approver-frame"
      within ".mod-workflow-view" do
        expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.request"))
      end
      within ".nav-menu" do
        click_on I18n.t("ss.links.edit")
      end
      expect(page).to have_no_css(".errorExplanation")
      expect(page).to have_no_content(I18n.t("gws/workflow2.buttons.save_and_apply"))

      within "form#item-form" do
        fill_in "custom[#{column1.id}]", with: column1_value2
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")
      wait_for_turbo_frame "#workflow-approver-frame"

      within ".mod-workflow-view" do
        expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.request"))
      end

      within "#addon-gws-agents-addons-workflow2-custom_form" do
        expect(page).to have_content(column1_value2)
        expect(page).to have_no_content(column1_value1)
      end
      within ".mod-workflow-approve" do
        fill_in "item[comment]", with: approve_comment2
        click_on I18n.t("workflow.buttons.approve")
      end
      wait_for_notice I18n.t("gws/workflow2.notice.approved")
      wait_for_turbo_frame "#workflow-approver-frame"

      within ".mod-workflow-view" do
        expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".workflow_comment", text: workflow_comment)

        wait_for_cbox_opened { find('.workflow_approvers tr:nth-child(1) .approver_comment').click }
        within_cbox do
          expect(page).to have_css(".approver-comment", text: approve_comment1)
          wait_for_cbox_closed { find('#cboxClose').click }
        end
        wait_for_cbox_opened { find('.workflow_approvers tr:nth-child(2) .approver_comment').click }
        within_cbox do
          expect(page).to have_css(".approver-comment", text: approve_comment2)
          wait_for_cbox_closed { find('#cboxClose').click }
        end
      end

      item.reload
      expect(item.workflow_user_id).to eq admin.id
      expect(item.workflow_agent_id).to be_blank
      expect(item.workflow_state).to eq 'request'
      expect(item.workflow_comment).to eq workflow_comment
      expect(item.workflow_approvers.count).to eq 3
      expect(item.workflow_approvers).to \
        include({level: 1, user_type: Gws::User.name, user_id: user1.id, editable: 1, state: 'approve',
                 comment: approve_comment1, file_ids: nil, created: be_within(30.seconds).of(Time.zone.now)})
      expect(item.workflow_approvers).to \
        include({level: 2, user_type: Gws::User.name, user_id: user2.id, editable: 1, state: 'approve',
                 comment: approve_comment2, file_ids: nil, created: be_within(30.seconds).of(Time.zone.now)})
      expect(item.workflow_approvers).to \
        include({level: 3, user_type: Gws::User.name, user_id: user3.id, editable: 1, state: 'request', comment: ''})
      expect(item.workflow_circulations).to be_blank

      expect(SS::Notification.count).to eq 3
      SS::Notification.order_by(id: -1).first.tap do |memo|
        expect(memo.subject).to eq I18n.t("gws_notification.gws/workflow/file.request", name: item.name)
        expect(memo.text).to be_blank
        expect(memo.html).to be_blank
        expect(memo.user_id).to eq item.workflow_user_id
        expect(memo.member_ids).to eq [user3.id]
      end
    end
  end
end
