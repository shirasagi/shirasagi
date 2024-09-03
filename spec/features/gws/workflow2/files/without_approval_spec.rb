require 'spec_helper'

describe Gws::Workflow2::FilesController, type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:admin) { gws_user }
  let!(:minimum_role) { create(:gws_role, cur_site: site, permissions: %w(use_gws_workflow2)) }
  let!(:user1) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ]) }
  let!(:user2) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ]) }
  let!(:user3) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ]) }

  let!(:form) do
    create(
      :gws_workflow2_form_application, approval_state: "without_approval", destination_user_ids: [ user3.id ],
      state: "public")
  end
  let!(:column1) { create(:gws_column_text_field, form: form, input_type: "text") }

  let!(:item) do
    create(
      :gws_workflow2_file, form: form, column_values: [ column1.serialize_value(unique_id) ],
      destination_user_ids: form.destination_user_ids)
  end

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

  context "request without approval" do
    it do
      #
      # admin: 申請する（承認なし）
      #
      login_user admin
      visit gws_workflow2_file_path(site, item, state: 'all')
      wait_for_turbo_frame "#workflow-approver-frame"
      within ".mod-workflow-request" do
        click_on I18n.t("workflow.buttons.request")
      end
      wait_for_notice I18n.t("gws/workflow2.notice.requested")
      wait_for_turbo_frame "#workflow-approver-frame"

      within ".mod-workflow-view" do
        expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.approve_without_approval"))
      end

      item.reload
      expect(item.workflow_user_id).to eq admin.id
      expect(item.workflow_agent_id).to be_blank
      expect(item.workflow_state).to eq "approve_without_approval"
      expect(item.workflow_comment).to be_blank
      expect(item.workflow_approvers).to be_blank
      expect(item.workflow_circulations).to be_blank

      expect(SS::Notification.count).to eq 1
      SS::Notification.order_by(id: -1).first.tap do |notification|
        subject = I18n.t("gws_notification.gws/workflow2/file.destination", name: item.name)
        expect(notification.subject).to eq subject
        expect(notification.text).to be_blank
        expect(notification.html).to be_blank
        expect(notification.user_id).to eq item.workflow_user_id
        expect(notification.user_id).to eq admin.id
        expect(notification.member_ids).to eq [user3.id]
        expect(notification.url).to eq gws_workflow2_file_path(site: site, state: 'all', id: item)
      end
    end
  end
end
