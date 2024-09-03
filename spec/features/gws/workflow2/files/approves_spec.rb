require 'spec_helper'

describe Gws::Workflow2::FilesController, type: :feature, dbscope: :example, js: true do
  context "approve file" do
    let!(:site) { gws_site }
    let!(:admin) { gws_user }
    let!(:minimum_role) { create(:gws_role, cur_site: site, permissions: %w(use_gws_workflow2)) }
    let(:group1) { admin.groups.first }
    let!(:user1) { create(:gws_user, :gws_workflow_notice, group_ids: [ group1.id ], gws_role_ids: [ minimum_role.id ]) }
    let!(:user2) { create(:gws_user, :gws_workflow_notice, group_ids: [ group1.id ], gws_role_ids: [ minimum_role.id ]) }
    let!(:form) { create(:gws_workflow2_form_application, cur_site: site, state: "public") }
    let!(:column1) { create(:gws_column_text_field, cur_site: site, form: form, input_type: "text") }
    let!(:item) do
      create(
        :gws_workflow2_file, cur_site: site, cur_user: user1, form: form,
        column_values: [ column1.serialize_value(unique_id) ])
    end

    before do
      site.canonical_scheme = %w(http https).sample
      site.canonical_domain = "#{unique_id}.example.jp"
      site.save!

      user1.notice_workflow_user_setting = %w(notify silence).sample
      user1.notice_workflow_email_user_setting = %w(notify silence).sample
      user1.send_notice_mail_addresses = "#{unique_id}@example.jp"
      user1.save!

      user2.notice_workflow_user_setting = %w(notify silence).sample
      user2.notice_workflow_email_user_setting = %w(notify silence).sample
      user2.send_notice_mail_addresses = "#{unique_id}@example.jp"
      user2.save!

      ActionMailer::Base.deliveries.clear
    end

    after { ActionMailer::Base.deliveries.clear }

    context "superior user is automatically set if group is set superior user" do
      let(:workflow_comment) { unique_id }
      let(:approve_comment) { unique_id }

      before do
        group1.update!(superior_user_ids: [ user2.id ])
      end

      it do
        #
        # 申請
        #
        login_user user1
        visit gws_workflow2_files_main_path(site: site)
        click_on item.name
        wait_for_turbo_frame "#workflow-approver-frame"

        within ".mod-workflow-request" do
          # 上長（user2）自動セット
          expect(page).to have_content(user2.name)

          # コメントだけ入力し、申請する
          fill_in "item[workflow_comment]", with: workflow_comment

          click_on I18n.t("workflow.buttons.request")
        end
        wait_for_notice I18n.t("gws/workflow2.notice.requested")
        wait_for_turbo_frame "#workflow-approver-frame"

        # 上長が自動セットされているので、コメントだけで申請が受理される。
        within ".mod-workflow-view" do
          expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.request"))
          expect(page).to have_css(".workflow_comment", text: workflow_comment)
        end

        item.reload
        expect(item.workflow_user_id).to eq user1.id
        expect(item.workflow_state).to eq 'request'
        expect(item.workflow_comment).to eq workflow_comment
        expect(item.workflow_approvers.count).to eq 1
        expect(item.workflow_approvers).to \
          include({level: 1, user_type: "superior", user_id: user2.id, state: 'request', comment: ''})

        if user2.notice_workflow_user_setting == "notify"
          expect(SS::Notification.count).to eq 1
          notice1 = SS::Notification.all.reorder(created: -1).first
          expect(notice1.group_id).to eq site.id
          expect(notice1.member_ids).to eq [ user2.id ]
          expect(notice1.user_id).to eq user1.id
          subject = I18n.t("gws_notification.gws/workflow/file.request", name: item.name)
          expect(notice1.subject).to eq subject
          expect(notice1.text).to be_blank
          expect(notice1.html).to be_blank
          expect(notice1.format).to eq "text"
          expect(notice1.user_settings).to be_blank
          expect(notice1.state).to eq "public"
          expect(notice1.send_date).to be_present
          expect(notice1.url).to eq "/.g#{site.id}/workflow2/files/all/#{item.id}"
          expect(notice1.reply_module).to be_blank
          expect(notice1.reply_model).to be_blank
          expect(notice1.reply_item_id).to be_blank

          if user2.notice_workflow_email_user_setting == "notify"
            expect(ActionMailer::Base.deliveries.length).to eq 1
            ActionMailer::Base.deliveries.last.tap do |mail|
              expect(mail.from.first).to eq site.sender_address
              expect(mail.bcc.first).to eq user2.send_notice_mail_addresses.first
              expect(mail.subject).to eq I18n.t("gws_notification.gws/workflow/file.request", name: item.name)
              url = "#{site.canonical_scheme}://#{site.canonical_domain}/.g#{site.id}/memo/notices/#{notice1.id}"
              expect(mail.decoded.to_s).to include(mail.subject, url)
              expect(mail.message_id).to end_with("@#{site.canonical_domain}.mail")
            end
          else
            expect(ActionMailer::Base.deliveries.length).to eq 0
          end
        else
          expect(SS::Notification.count).to eq 0
          expect(ActionMailer::Base.deliveries.length).to eq 0
        end

        #
        # 承認
        #
        login_user user2
        visit gws_workflow2_files_main_path(site: site)
        click_on I18n.t("gws/workflow2.navi.approve")
        click_on item.name
        wait_for_turbo_frame "#workflow-approver-frame"

        within ".mod-workflow-approve" do
          fill_in "item[comment]", with: approve_comment
          click_on I18n.t("workflow.buttons.approve")
        end
        wait_for_notice I18n.t("gws/workflow2.notice.approved")
        wait_for_turbo_frame "#workflow-approver-frame"

        within ".mod-workflow-view" do
          expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.approve"))
          expect(page).to have_css(".workflow_comment", text: workflow_comment)
        end

        item.reload
        expect(item.workflow_user_id).to eq user1.id
        expect(item.workflow_agent_id).to be_blank
        expect(item.workflow_state).to eq "approve"
        expect(item.workflow_comment).to eq workflow_comment
        expect(item.workflow_approvers.count).to eq 1
        expect(item.workflow_approvers).to include({
          level: 1, user_type: "superior", user_id: user2.id, state: 'approve', comment: approve_comment,
          file_ids: nil, created: be_within(30.seconds).of(Time.zone.now)
        })
      end
    end

    context "superior user isn't set if group isn't set superior user" do
      it do
        login_user user1
        visit gws_workflow2_files_main_path(site: site)
        click_on item.name
        wait_for_turbo_frame "#workflow-approver-frame"

        # 上長を自動的にセットすることができないので、エラーが表示されているはず。
        within ".mod-workflow-request" do
          expect(page).to have_css(".workflow_approvers", text: I18n.t("gws/workflow2.errors.messages.superior_is_not_found"))
        end
      end
    end
  end
end
