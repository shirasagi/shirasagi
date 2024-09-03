require 'spec_helper'

describe Gws::Workflow2::FilesController, type: :feature, dbscope: :example, js: true do
  before { ActionMailer::Base.deliveries.clear }

  after { ActionMailer::Base.deliveries.clear }

  context "my group" do
    let(:site) { gws_site }
    let(:admin) { gws_user }
    let!(:minimum_role) { create(:gws_role, cur_site: site, permissions: %w(use_gws_workflow2)) }
    let!(:user1) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ]) }
    let!(:user2) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ]) }
    let!(:user3) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ]) }
    let!(:form) { create(:gws_workflow2_form_application, state: "public") }
    let!(:column1) { create(:gws_column_text_field, form: form, input_type: "text") }
    let(:item) { create :gws_workflow2_file, cur_user: admin, form: form, column_values: [ column1.serialize_value(unique_id) ] }
    let(:show_path) { gws_workflow2_file_path(site, item, state: 'all') }
    let(:workflow_comment) { unique_id }
    let(:approve_comment1) { unique_id }
    let(:circulation_comment2) { unique_id }

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
      # admin: 申請する（承認者 1 名＋回覧者 1 名）
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
      expect(item.workflow_approvers.count).to eq 1
      expect(item.workflow_approvers).to include({
        level: 1, user_type: "superior", user_id: user1.id, state: 'request', comment: ''
      })
      expect(item.workflow_circulations.count).to eq 0
      # expect(item.workflow_circulations).to \
      #   include({level: 1, user_type: Gws::User.name, user_id: user2.id, state: 'pending', comment: ''})

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
        expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.approve"))
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
      expect(item.workflow_state).to eq 'approve'
      expect(item.workflow_comment).to eq workflow_comment
      expect(item.workflow_approvers.count).to eq 1
      expect(item.workflow_approvers).to include({
        level: 1, user_type: "superior", user_id: user1.id, state: 'approve', comment: approve_comment1, file_ids: nil,
        created: be_within(30.seconds).of(Time.zone.now)
      })
      expect(item.workflow_circulations.count).to eq 0

      expect(SS::Notification.count).to eq 2
      SS::Notification.order_by(id: -1).first.tap do |memo|
        expect(memo.subject).to eq I18n.t("gws_notification.gws/workflow/file.approve", name: item.name)
        expect(memo.text).to be_blank
        expect(memo.html).to be_blank
        expect(memo.user_id).to eq user1.id
        expect(memo.member_ids).to eq [admin.id]
      end
    end
  end
end
