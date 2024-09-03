require 'spec_helper'

describe Gws::Workflow2::FilesController, type: :feature, dbscope: :example, js: true do
  before { ActionMailer::Base.deliveries.clear }

  after { ActionMailer::Base.deliveries.clear }

  context "my group_aflternate" do
    let(:site) { gws_site }
    let(:admin) { gws_user }
    let!(:minimum_role) { create(:gws_role, cur_site: site, permissions: %w(use_gws_workflow2)) }
    let!(:user1) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [minimum_role.id]) }
    let!(:user2) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [minimum_role.id]) }
    let!(:user3) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [minimum_role.id]) }
    let!(:form) { create(:gws_workflow2_form_application, state: "public", default_route_id: 'my_group_alternate') }
    let!(:column1) { create(:gws_column_text_field, form: form, input_type: "text") }
    let(:item) { create :gws_workflow2_file, cur_user: admin, form: form, column_values: [column1.serialize_value(unique_id)] }
    let(:show_path) { gws_workflow2_file_path(site, item, state: 'all') }
    let(:workflow_comment) { unique_id }
    let(:approve_comment1) { unique_id }

    before do
      site.canonical_scheme = %w(http https).sample
      site.canonical_domain = "#{unique_id}.example.jp"
      site.save!

      admin.notice_workflow_user_setting = "notify"
      admin.notice_workflow_email_user_setting = "notify"
      admin.send_notice_mail_addresses = "#{unique_id}@example.jp"
      admin.save!

      admin.groups.first.set(superior_user_ids: [user1.id])
    end

    it do
      login_user admin
      visit show_path
      wait_for_turbo_frame "#workflow-approver-frame"

      #
      # admin: 申請する（承認者 1 名＋代理承認者 1 名）
      #
      within ".workflow_approvers" do
        wait_for_cbox_opened { click_on I18n.t("gws/workflow2.search_alternates.index") } ##
      end
      within_cbox do
        wait_for_cbox_closed { click_on user2.long_name }
      end

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
      expect(item.workflow_approvers.count).to eq 2
      expect(item.workflow_approvers).to include({
        level: 1, user_type: "superior", user_id: user1.id, state: 'request', comment: ''
      })
      expect(item.workflow_approvers).to include({
        level: 1, user_type: "Gws::User", user_id: user2.id, state: 'request', comment: ''
      })
      expect(item.workflow_circulations.count).to eq 0

      expect(SS::Notification.count).to eq 1
      SS::Notification.order_by(id: -1).first.tap do |memo|
        expect(memo.user_id).to eq admin.id
        expect(memo.member_ids).to eq [user1.id, user2.id]
      end

      #
      # user1: 申請を承認する（代理承認者 ）
      #
      login_user user2
      visit show_path
      wait_for_turbo_frame "#workflow-approver-frame"
      within ".mod-workflow-view" do
        expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.request"))
      end

      within ".mod-workflow-approve" do
        fill_in "item[comment]", with: approve_comment1
        find('.mod-workflow-approve .alternator-notice .notice-1 input').set(true)
        find('.mod-workflow-approve .alternator-notice .notice-2 input').set(true)
        click_on I18n.t("workflow.buttons.approve")
      end
      wait_for_notice I18n.t("gws/workflow2.notice.approved")
      wait_for_turbo_frame "#workflow-approver-frame"

      item.reload
      expect(item.workflow_user_id).to eq admin.id
      expect(item.workflow_agent_id).to be_blank
      expect(item.workflow_state).to eq 'approve'
      expect(item.workflow_comment).to eq workflow_comment
      expect(item.workflow_approvers.count).to eq 2
      expect(item.workflow_approvers).to include({
        level: 1, user_type: "superior", user_id: user1.id, state: 'other_approved', comment: ''
      })
      expect(item.workflow_approvers).to include({
        level: 1, user_type: "Gws::User", user_id: user2.id, state: 'approve', comment: approve_comment1, file_ids: nil,
        created: be_within(30.seconds).of(Time.zone.now)
      })

      expect(SS::Notification.count).to eq 2
    end
  end
end
