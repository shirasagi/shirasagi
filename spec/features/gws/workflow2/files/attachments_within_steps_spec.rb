require 'spec_helper'

describe Gws::Workflow2::FilesController, type: :feature, dbscope: :example, js: true do
  before do
    ActionMailer::Base.deliveries.clear
  end

  after { ActionMailer::Base.deliveries.clear }

  context "attachments with steps" do
    let(:site) { gws_site }
    let(:admin) { gws_user }
    let!(:minimum_role) { create(:gws_role, cur_site: site, permissions: %w(use_gws_workflow2)) }
    let!(:user1) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ]) }
    let!(:user2) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ]) }
    let!(:user3) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ]) }

    let(:route_name) { unique_id }
    let!(:route) do
      create(
        :gws_workflow2_route, name: route_name, group_ids: admin.group_ids,
        approvers: [
          { "level" => 1, "user_type" => user1.class.name, "user_id" => user1.id },
        ],
        required_counts: [ false, false, false, false, false ],
        approver_attachment_uses: %w(enabled disabled disabled disabled disabled),
        circulations: [
          { "level" => 1, "user_type" => user2.class.name, "user_id" => user2.id },
        ],
        circulation_attachment_uses: %w(enabled disabled disabled)
      )
    end

    let!(:form) do
      create(:gws_workflow2_form_application, default_route_id: route.id, state: "public", destination_user_ids: [ user3.id ])
    end
    let!(:column1) { create(:gws_column_text_field, form: form, input_type: "text") }
    let(:item) do
      create(
        :gws_workflow2_file, cur_user: admin, form: form, column_values: [ column1.serialize_value(unique_id) ],
        destination_user_ids: form.destination_user_ids)
    end
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

      admin.notice_workflow_user_setting = %w(notify silence).sample
      admin.notice_workflow_email_user_setting = %w(notify silence).sample
      admin.send_notice_mail_addresses = "#{unique_id}@example.jp"
      admin.save!
    end

    it do
      #
      # admin: 申請する（承認者 1 段、1 名＋回覧者 1 段、1 名）
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
      expect(item.workflow_agent_id).to be_blank
      expect(item.workflow_state).to eq "request"
      expect(item.workflow_comment).to eq workflow_comment1
      expect(item.workflow_approvers.count).to eq 1
      expect(item.workflow_approvers).to \
        include({level: 1, user_type: Gws::User.name, user_id: user1.id, state: 'request', comment: ''})
      expect(item.workflow_circulations.count).to eq 1
      expect(item.workflow_circulations).to \
        include({level: 1, user_type: Gws::User.name, user_id: user2.id, state: 'pending', comment: ''})

      expect(SS::Notification.count).to eq 1
      notification1 = SS::Notification.order_by(id: -1).first
      expect(notification1.subject).to eq I18n.t("gws_notification.gws/workflow/file.request", name: item.name)
      expect(notification1.text).to be_blank
      expect(notification1.html).to be_blank
      expect(notification1.user_id).to eq admin.id
      expect(notification1.member_ids).to eq [user1.id]

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
        wait_for_cbox_opened { click_on I18n.t("workflow.links.approver_file_upload") }
      end
      within_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/logo.png"
        wait_for_cbox_closed { click_on I18n.t("ss.buttons.attach") }
      end
      within ".mod-workflow-approve" do
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

      expect(SS::File.all.where(model: "workflow/approver_file").count).to eq 1
      file1 = SS::File.all.where(model: "workflow/approver_file").order_by(id: -1).first
      expect(file1.name).to eq "logo.png"
      expect(file1.filename).to eq "logo.png"
      expect(file1.site_id).to be_blank
      expect(file1.model).to eq "workflow/approver_file"
      expect(file1.owner_item_id).to eq item.id
      expect(file1.owner_item_type).to eq item.class.name

      item.reload
      expect(item.workflow_user_id).to eq admin.id
      expect(item.workflow_agent_id).to be_blank
      expect(item.workflow_state).to eq "approve"
      expect(item.workflow_comment).to eq workflow_comment1
      expect(item.workflow_approvers.count).to eq 1
      expect(item.workflow_approvers).to \
        include({level: 1, user_type: Gws::User.name, user_id: user1.id, state: 'approve',
                 comment: approve_comment1, file_ids: [file1.id], created: be_within(30.seconds).of(Time.zone.now)})
      expect(item.workflow_circulations.count).to eq 1
      expect(item.workflow_circulations).to \
        include({level: 1, user_type: Gws::User.name, user_id: user2.id, state: 'unseen', comment: ''})

      expected_notification_count = admin.notice_workflow_user_setting == "notify" ? 4 : 3
      expect(SS::Notification.count).to eq expected_notification_count
      SS::Notification.order_by(id: -1).to_a.tap do |notifications|
        if admin.notice_workflow_user_setting == "notify"
          notifications[2].tap do |notification|
            subject = I18n.t("gws_notification.gws/workflow/file.approve", name: item.name)
            expect(notification.subject).to eq subject
            expect(notification.text).to be_blank
            expect(notification.html).to be_blank
            expect(notification.user_id).to eq user1.id
            expect(notification.member_ids).to eq [admin.id]
            expect(notification.url).to eq gws_workflow2_file_path(site: site, state: 'all', id: item)
          end
        end
        notifications[1].tap do |notification|
          subject = I18n.t("gws_notification.gws/workflow2/file.destination", name: item.name)
          expect(notification.subject).to eq subject
          expect(notification.text).to be_blank
          expect(notification.html).to be_blank
          expect(notification.user_id).to eq item.workflow_user_id
          expect(notification.user_id).to eq admin.id
          expect(notification.member_ids).to eq [user3.id]
          expect(notification.url).to eq gws_workflow2_file_path(site: site, state: 'all', id: item)
        end
        notifications[0].tap do |notification|
          subject = I18n.t("gws_notification.gws/workflow/file.circular", name: item.name)
          expect(notification.subject).to eq subject
          expect(notification.text).to be_blank
          expect(notification.html).to be_blank
          expect(notification.user_id).to eq item.workflow_user_id
          expect(notification.user_id).to eq admin.id
          expect(notification.member_ids).to eq [user2.id]
          expect(notification.url).to eq gws_workflow2_file_path(site: site, state: 'all', id: item)
        end
      end

      #
      # user2: 申請を確認する
      #
      login_user user2
      visit show_path
      wait_for_turbo_frame "#workflow-approver-frame"
      within ".mod-workflow-view" do
        expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.approve"))
      end

      within ".mod-workflow-circulation" do
        fill_in "item[comment]", with: circulation_comment2
        wait_for_cbox_opened { click_on I18n.t("workflow.links.approver_file_upload") }
      end
      within_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/logo.png"
        wait_for_cbox_closed { click_on I18n.t("ss.buttons.attach") }
      end
      within ".mod-workflow-circulation" do
        click_on I18n.t("workflow.links.set_seen")
      end
      wait_for_notice I18n.t("gws/workflow2.notice.seen")
      wait_for_turbo_frame "#workflow-approver-frame"

      within ".mod-workflow-view" do
        expect(page).to have_css(".workflow_comment", text: workflow_comment1)
        expect(page).to have_css(".workflow_circulations", text: circulation_comment2)

        wait_for_cbox_opened { find('.workflow_approvers tr:nth-child(1) .approver_comment').click }
        within_cbox do
          expect(page).to have_css(".approver-comment", text: approve_comment1)
          wait_for_cbox_closed { find('#cboxClose').click }
        end
      end

      expect(SS::File.all.where(model: "workflow/approver_file").count).to eq 2
      file2 = SS::File.all.where(model: "workflow/approver_file").order_by(id: -1).first
      expect(file2.name).to eq "logo.png"
      expect(file2.filename).to eq "logo.png"
      expect(file2.site_id).to be_blank
      expect(file2.model).to eq "workflow/approver_file"
      expect(file2.owner_item_id).to eq item.id
      expect(file2.owner_item_type).to eq item.class.name

      item.reload
      expect(item.workflow_user_id).to eq admin.id
      expect(item.workflow_agent_id).to be_blank
      expect(item.workflow_state).to eq "approve"
      expect(item.workflow_comment).to eq workflow_comment1
      expect(item.workflow_approvers.count).to eq 1
      expect(item.workflow_approvers).to \
        include({level: 1, user_type: Gws::User.name, user_id: user1.id, state: 'approve',
                 comment: approve_comment1, file_ids: [file1.id], created: be_within(30.seconds).of(Time.zone.now)})
      expect(item.workflow_circulations.count).to eq 1
      expect(item.workflow_circulations).to \
        include({level: 1, user_type: Gws::User.name, user_id: user2.id, state: 'seen',
                 comment: circulation_comment2, file_ids: [file2.id]})

      expected_notification_count += admin.notice_workflow_user_setting == "notify" ? 1 : 0
      expect(SS::Notification.count).to eq expected_notification_count
      if admin.notice_workflow_user_setting == "notify"
        SS::Notification.order_by(id: -1).first.tap do |memo|
          expect(memo.subject).to eq I18n.t("gws_notification.gws/workflow/file.comment", name: item.name)
          expect(memo.text).to be_blank
          expect(memo.html).to be_blank
          expect(memo.user_id).to eq user2.id
          expect(memo.member_ids).to have(1).items
          expect(memo.member_ids).to eq [admin.id]
          expect(memo.member_ids).to eq [item.workflow_user_id]
        end
      end
    end
  end
end
