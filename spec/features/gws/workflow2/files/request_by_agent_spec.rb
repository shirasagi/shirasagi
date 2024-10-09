require 'spec_helper'

describe Gws::Workflow2::FilesController, type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:admin) { gws_user }
  let!(:minimum_role) { create(:gws_role, cur_site: site, permissions: %w(use_gws_workflow2)) }
  let(:now) { Time.zone.now.change(usec: 0) }

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

  context "request by agent" do
    context "with fixed rout (no superiors)" do
      let!(:user1) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ]) }
      let!(:user1_superior) do
        create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ])
      end
      let!(:user2) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ]) }
      let!(:user3) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ]) }
      let!(:route) do
        create(
          :gws_workflow2_route, group_ids: admin.group_ids,
          approvers: [
            { "level" => 1, "user_type" => user2.class.name, "user_id" => user2.id }
          ],
          required_counts: [ false, false, false, false, false ],
          circulations: [
            { "level" => 1, "user_type" => user3.class.name, "user_id" => user3.id }
          ]
        )
      end

      let(:workflow_comment) { unique_id }
      let(:approve_comment1) { unique_id }
      let(:circulation_comment2) { unique_id }

      before do
        user1.in_gws_superior_user_ids = [ user1_superior.id ]
        user1.save!
      end

      context "when approval_state is 'with_approval'" do
        let(:form) do
          create(
            :gws_workflow2_form_application, default_route_id: route.id,
            state: "public", approval_state: "with_approval", agent_state: "enabled"
          )
        end
        let!(:column1) { create(:gws_column_text_field, cur_site: site, cur_form: form, input_type: "text") }

        it do
          #
          # admin: 申請書の作成
          #
          login_user admin
          visit new_gws_workflow2_form_file_path(site: site, state: "all", form_id: form)

          within "form#item-form" do
            fill_in "custom[#{column1.id}]", with: unique_id
            click_on I18n.t("ss.buttons.save")
          end
          wait_for_notice I18n.t('ss.notice.saved')
          wait_for_turbo_frame "#workflow-approver-frame"

          within ".mod-workflow-request" do
            expect(page).to have_css(".workflow_approvers", text: user2.long_name)
          end

          expect(Gws::Workflow2::File.all.count).to eq 1
          file = Gws::Workflow2::File.all.first
          expect(file.site_id).to eq site.id
          expect(file.form_id).to eq form.id
          form_name = [ form.name, now.strftime("%Y%m%d"), form.current_style_sequence ].join("_")
          expect(file.name).to eq form_name
          expect(file.workflow_user_id).to be_blank
          expect(file.workflow_agent_id).to be_blank

          #
          # admin: 代理で申請する（承認者 1 名＋回覧者 1 名）
          #
          visit gws_workflow2_files_path(site: site, state: "all")
          click_on file.name
          wait_for_turbo_frame "#workflow-approver-frame"

          within ".mod-workflow-request" do
            choose "item_workflow_agent_type_agent"
            wait_for_cbox_opened { click_on I18n.t("gws/workflow2.search_delegatees.index") }
          end
          within_cbox do
            wait_for_cbox_closed { click_on user1.long_name }
          end
          within ".mod-workflow-request" do
            expect(page).to have_css(".agent-type-agent [data-id='#{user1.id}']", text: user1.long_name)
            fill_in "item[workflow_comment]", with: workflow_comment
            click_on I18n.t("workflow.buttons.request")
          end
          wait_for_notice I18n.t("gws/workflow2.notice.requested")
          wait_for_turbo_frame "#workflow-approver-frame"

          within ".mod-workflow-view" do
            expect(page).to have_css(".workflow_agent_id", text: admin.name)
            expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.request"))
            expect(page).to have_css(".workflow_comment", text: workflow_comment)
          end

          expect(Gws::Workflow2::File.count).to eq 1
          Gws::Workflow2::File.all.first.tap do |item|
            expect(item.workflow_user_id).to eq user1.id
            expect(item.workflow_agent_id).to eq admin.id
            expect(item.workflow_state).to eq 'request'
            expect(item.workflow_approvers.count).to eq 1
            expect(item.workflow_approvers).to include(
              { level: 1, user_type: Gws::User.name, user_id: user2.id, state: 'request', comment: '' })
            expect(item.workflow_circulations.count).to eq 1
            expect(item.workflow_circulations).to include(
              { level: 1, user_type: Gws::User.name, user_id: user3.id, state: 'pending', comment: '' })
          end

          expect(SS::Notification.count).to eq 1
          SS::Notification.order_by(id: -1).to_a.tap do |notifications|
            notifications[0].tap do |notification|
              expect(notification.subject).to eq I18n.t("gws_notification.gws/workflow/file.request", name: file.name)
              expect(notification.text).to be_blank
              expect(notification.html).to be_blank
              expect(notification.user_id).to eq user1.id
              expect(notification.member_ids).to eq [user2.id]
            end
          end

          #
          # user2: 申請を承認する
          #
          login_user user2
          visit gws_workflow2_files_path(site: site, state: "all")
          click_on file.name
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

          Gws::Workflow2::File.all.first.tap do |item|
            expect(item.workflow_user_id).to eq user1.id
            expect(item.workflow_agent_id).to eq admin.id
            expect(item.workflow_state).to eq 'approve'
            expect(item.workflow_comment).to eq workflow_comment
            expect(item.workflow_approvers.count).to eq 1
            expect(item.workflow_approvers).to include(
              { level: 1, user_type: Gws::User.name, user_id: user2.id, state: 'approve', comment: approve_comment1,
                file_ids: nil, created: be_within(30.seconds).of(Time.zone.now) })
            expect(item.workflow_circulations.count).to eq 1
            expect(item.workflow_circulations).to \
              include({level: 1, user_type: Gws::User.name, user_id: user3.id, state: 'unseen', comment: ''})
          end

          expect(SS::Notification.count).to eq 3
          SS::Notification.order_by(id: -1).to_a.tap do |notifications|
            notifications[1].tap do |notification|
              expect(notification.subject).to eq I18n.t("gws_notification.gws/workflow/file.approve", name: file.name)
              expect(notification.text).to be_blank
              expect(notification.html).to be_blank
              expect(notification.user_id).to eq user2.id
              expect(notification.member_ids).to include(admin.id, user1.id)
            end
            notifications[0].tap do |notification|
              expect(notification.subject).to eq I18n.t("gws_notification.gws/workflow/file.circular", name: file.name)
              expect(notification.text).to be_blank
              expect(notification.html).to be_blank
              expect(notification.user_id).to eq user1.id
              expect(notification.member_ids).to eq [user3.id]
            end
          end

          #
          # user3: 申請を確認する
          #
          login_user user3
          visit gws_workflow2_files_path(site: site, state: "all")
          click_on file.name
          wait_for_turbo_frame "#workflow-approver-frame"
          within ".mod-workflow-view" do
            expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.approve"))
          end

          within ".mod-workflow-circulation" do
            fill_in "item[comment]", with: circulation_comment2
            click_on I18n.t("workflow.links.set_seen")
          end
          wait_for_notice I18n.t("gws/workflow2.notice.seen")
          wait_for_turbo_frame "#workflow-approver-frame"

          within ".mod-workflow-view" do
            expect(page).to have_css(".workflow_approvers_created")
            expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.approve"))
            expect(page).to have_css(".workflow_comment", text: workflow_comment)
            expect(page).to have_css(".workflow_circulations", text: circulation_comment2)

            wait_for_cbox_opened { find('.workflow_approvers tr:nth-child(1) .approver_comment').click }
            within_cbox do
              expect(page).to have_css(".approver-comment", text: approve_comment1)
              wait_for_cbox_closed { find('#cboxClose').click }
            end
          end

          Gws::Workflow2::File.all.first.tap do |item|
            expect(item.workflow_user_id).to eq user1.id
            expect(item.workflow_agent_id).to eq admin.id
            expect(item.workflow_state).to eq 'approve'
            expect(item.workflow_comment).to eq workflow_comment
            expect(item.workflow_approvers.count).to eq 1
            expect(item.workflow_approvers).to include(
              { level: 1, user_type: Gws::User.name, user_id: user2.id, state: 'approve', comment: approve_comment1,
                file_ids: nil, created: be_within(30.seconds).of(Time.zone.now) })
            expect(item.workflow_circulations.count).to eq 1
            expect(item.workflow_circulations).to \
              include({level: 1, user_type: Gws::User.name, user_id: user3.id, state: 'seen', comment: circulation_comment2})
          end

          expect(SS::Notification.count).to eq 4
          SS::Notification.order_by(id: -1).to_a.tap do |notifications|
            notifications[0].tap do |notification|
              expect(notification.subject).to eq I18n.t("gws_notification.gws/workflow/file.comment", name: file.name)
              expect(notification.text).to be_blank
              expect(notification.html).to be_blank
              expect(notification.user_id).to eq user3.id
              expect(notification.member_ids).to include(admin.id, user1.id)
            end
          end
        end
      end

      context "when approval_state is 'without_approval'" do
        let(:form) do
          create(
            :gws_workflow2_form_application, default_route_id: route.id,
            state: "public", approval_state: "without_approval", agent_state: "enabled"
          )
        end
        let!(:column1) { create(:gws_column_text_field, cur_site: site, cur_form: form, input_type: "text") }

        it do
          #
          # admin: 申請書の作成
          #
          login_user admin
          visit new_gws_workflow2_form_file_path(site: site, state: "all", form_id: form)

          within "form#item-form" do
            fill_in "custom[#{column1.id}]", with: unique_id
            click_on I18n.t("ss.buttons.save")
          end
          wait_for_notice I18n.t('ss.notice.saved')
          wait_for_turbo_frame "#workflow-approver-frame"

          within ".mod-workflow-request" do
            expect(page).to have_css(".agent_type", text: I18n.t("gws/workflow.agent_type.myself"))
          end

          expect(Gws::Workflow2::File.all.count).to eq 1
          file = Gws::Workflow2::File.all.first
          expect(file.site_id).to eq site.id
          expect(file.form_id).to eq form.id
          form_name = [ form.name, now.strftime("%Y%m%d"), form.current_style_sequence ].join("_")
          expect(file.name).to eq form_name
          expect(file.workflow_user_id).to be_blank
          expect(file.workflow_agent_id).to be_blank

          #
          # admin: 代理で申請する（承認者なし＋回覧者なし）
          #
          visit gws_workflow2_files_path(site: site, state: "all")
          click_on file.name
          wait_for_turbo_frame "#workflow-approver-frame"

          within ".mod-workflow-request" do
            choose "item_workflow_agent_type_agent"
            wait_for_cbox_opened { click_on I18n.t("gws/workflow2.search_delegatees.index") }
          end
          within_cbox do
            wait_for_cbox_closed { click_on user1.long_name }
          end
          within ".mod-workflow-request" do
            expect(page).to have_css(".agent-type-agent [data-id='#{user1.id}']", text: user1.long_name)
            fill_in "item[workflow_comment]", with: workflow_comment
            click_on I18n.t("workflow.buttons.request")
          end
          wait_for_notice I18n.t("gws/workflow2.notice.requested")
          wait_for_turbo_frame "#workflow-approver-frame"

          within ".mod-workflow-view" do
            expect(page).to have_css(".workflow_user_id", text: user1.name)
            expect(page).to have_css(".workflow_agent_id", text: admin.name)
            expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.approve_without_approval"))
            expect(page).to have_css(".workflow_comment", text: workflow_comment)
          end

          expect(Gws::Workflow2::File.count).to eq 1
          Gws::Workflow2::File.all.first.tap do |item|
            expect(item.workflow_user_id).to eq user1.id
            expect(item.workflow_agent_id).to eq admin.id
            expect(item.workflow_state).to eq 'approve_without_approval'
            expect(item.workflow_approvers.count).to eq 0
            # expect(item.workflow_approvers).to be_blank
            expect(item.workflow_circulations.count).to eq 0
            # expect(item.workflow_circulations).to be_blank
          end

          expect(SS::Notification.count).to eq 0
        end
      end
    end

    context "with route 'my_group' / 'my_group_alternate'" do
      let!(:form) do
        create(
          :gws_workflow2_form_application, default_route_id: %w(my_group my_group_alternate).sample,
          state: "public", approval_state: "with_approval", agent_state: "enabled"
        )
      end
      let!(:column1) { create(:gws_column_text_field, cur_site: site, cur_form: form, input_type: "text") }
      let!(:user1) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ]) }
      let!(:user1_superior) do
        create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ])
      end
      let(:workflow_comment) { unique_id }
      let(:approve_comment1) { unique_id }

      before do
        user1.in_gws_superior_user_ids = [ user1_superior.id ]
        user1.save!
      end

      it do
        #
        # admin: 申請書の作成
        #
        login_user admin
        visit new_gws_workflow2_form_file_path(site: site, state: "all", form_id: form)

        within "form#item-form" do
          fill_in "custom[#{column1.id}]", with: unique_id
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t('ss.notice.saved')
        wait_for_turbo_frame "#workflow-approver-frame"

        expect(Gws::Workflow2::File.all.count).to eq 1
        file = Gws::Workflow2::File.all.first
        expect(file.site_id).to eq site.id
        expect(file.form_id).to eq form.id
        form_name = [ form.name, now.strftime("%Y%m%d"), form.current_style_sequence ].join("_")
        expect(file.name).to eq form_name
        expect(file.workflow_user_id).to be_blank
        expect(file.workflow_agent_id).to be_blank

        #
        # admin: 代理で申請する
        #
        visit gws_workflow2_files_path(site: site, state: "all")
        click_on file.name
        wait_for_turbo_frame "#workflow-approver-frame"

        within ".mod-workflow-request" do
          choose "item_workflow_agent_type_agent"
          wait_for_cbox_opened { click_on I18n.t("gws/workflow2.search_delegatees.index") }
        end
        within_cbox do
          wait_for_cbox_closed { click_on user1.long_name }
        end
        within ".mod-workflow-request" do
          expect(page).to have_css(".agent-type-agent [data-id='#{user1.id}']", text: user1.long_name)
          fill_in "item[workflow_comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end
        wait_for_notice I18n.t("gws/workflow2.notice.requested")
        wait_for_turbo_frame "#workflow-approver-frame"

        within ".mod-workflow-view" do
          expect(page).to have_css(".workflow_agent_id", text: admin.name)
          expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.request"))
          expect(page).to have_css(".workflow_comment", text: workflow_comment)
        end

        expect(Gws::Workflow2::File.count).to eq 1
        Gws::Workflow2::File.all.first.tap do |item|
          expect(item.workflow_user_id).to eq user1.id
          expect(item.workflow_agent_id).to eq admin.id
          expect(item.workflow_state).to eq 'request'
          expect(item.workflow_approvers.count).to eq 1
          expect(item.workflow_approvers).to include(
            { level: 1, user_type: "superior", user_id: user1_superior.id, state: 'request', comment: '' })
          expect(item.workflow_circulations).to be_blank
        end

        SS::Notification.order_by(id: -1).to_a.tap do |notifications|
          notifications[0].tap do |notification|
            expect(notification.subject).to eq I18n.t("gws_notification.gws/workflow/file.request", name: file.name)
            expect(notification.text).to be_blank
            expect(notification.html).to be_blank
            expect(notification.user_id).to eq user1.id
            expect(notification.member_ids).to eq [user1_superior.id]
          end
        end

        #
        # user1_superior: 申請を承認する
        #
        login_user user1_superior
        visit gws_workflow2_files_path(site: site, state: "all")
        click_on file.name
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
        end

        Gws::Workflow2::File.all.first.tap do |item|
          expect(item.workflow_user_id).to eq user1.id
          expect(item.workflow_agent_id).to eq admin.id
          expect(item.workflow_state).to eq 'approve'
          expect(item.workflow_comment).to eq workflow_comment
          expect(item.workflow_approvers.count).to eq 1
          expect(item.workflow_approvers).to include(
            { level: 1, user_type: "superior", user_id: user1_superior.id, state: 'approve', comment: approve_comment1,
              file_ids: nil, created: be_within(30.seconds).of(Time.zone.now) })
          expect(item.workflow_circulations).to be_blank
        end

        expect(SS::Notification.count).to eq 2
        SS::Notification.order_by(id: -1).to_a.tap do |notifications|
          notifications[0].tap do |notification|
            expect(notification.subject).to eq I18n.t("gws_notification.gws/workflow/file.approve", name: file.name)
            expect(notification.text).to be_blank
            expect(notification.html).to be_blank
            expect(notification.user_id).to eq user1_superior.id
            expect(notification.member_ids).to include(admin.id, user1.id)
          end
        end
      end
    end

    context "with route fixed-user and superior" do
      let!(:user1) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ]) }
      let!(:user1_superior) do
        create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ])
      end
      let!(:user2) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ]) }
      let!(:route) do
        create(
          :gws_workflow2_route, group_ids: admin.group_ids,
          approvers: [
            { "level" => 1, "user_type" => user2.class.name, "user_id" => user2.id },
            { "level" => 1, "user_type" => "superior", "user_id" => "superior" }
          ],
          required_counts: [ false ]
        )
      end
      let!(:form) do
        create(
          :gws_workflow2_form_application, default_route_id: route.id,
          state: "public", approval_state: "with_approval", agent_state: "enabled"
        )
      end
      let!(:column1) { create(:gws_column_text_field, cur_site: site, cur_form: form, input_type: "text") }
      let(:workflow_comment) { unique_id }
      let(:approve_comment1) { unique_id }
      let(:approve_comment2) { unique_id }

      before do
        user1.in_gws_superior_user_ids = [ user1_superior.id ]
        user1.save!
      end

      it do
        #
        # admin: 申請書の作成
        #
        login_user admin
        visit new_gws_workflow2_form_file_path(site: site, state: "all", form_id: form)

        within "form#item-form" do
          fill_in "custom[#{column1.id}]", with: unique_id
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t('ss.notice.saved')
        wait_for_turbo_frame "#workflow-approver-frame"

        expect(Gws::Workflow2::File.all.count).to eq 1
        file = Gws::Workflow2::File.all.first
        expect(file.site_id).to eq site.id
        expect(file.form_id).to eq form.id
        form_name = [ form.name, now.strftime("%Y%m%d"), form.current_style_sequence ].join("_")
        expect(file.name).to eq form_name
        expect(file.workflow_user_id).to be_blank
        expect(file.workflow_agent_id).to be_blank

        #
        # admin: 代理で申請する
        #
        visit gws_workflow2_files_path(site: site, state: "all")
        click_on file.name
        wait_for_turbo_frame "#workflow-approver-frame"

        within ".mod-workflow-request" do
          choose "item_workflow_agent_type_agent"
          wait_for_cbox_opened { click_on I18n.t("gws/workflow2.search_delegatees.index") }
        end
        within_cbox do
          wait_for_cbox_closed { click_on user1.long_name }
        end
        within ".mod-workflow-request" do
          expect(page).to have_css(".agent-type-agent [data-id='#{user1.id}']", text: user1.long_name)
          fill_in "item[workflow_comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end
        wait_for_notice I18n.t("gws/workflow2.notice.requested")
        wait_for_turbo_frame "#workflow-approver-frame"

        within ".mod-workflow-view" do
          expect(page).to have_css(".workflow_agent_id", text: admin.name)
          expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.request"))
          expect(page).to have_css(".workflow_comment", text: workflow_comment)
        end

        expect(Gws::Workflow2::File.count).to eq 1
        Gws::Workflow2::File.all.first.tap do |item|
          expect(item.workflow_user_id).to eq user1.id
          expect(item.workflow_agent_id).to eq admin.id
          expect(item.workflow_state).to eq 'request'
          expect(item.workflow_approvers.count).to eq 2
          expect(item.workflow_approvers).to include(
            { level: 1, user_type: Gws::User.name, user_id: user2.id, state: 'request', comment: '' })
          expect(item.workflow_approvers).to include(
            { level: 1, user_type: "superior", user_id: user1_superior.id, state: 'request', comment: '' })
          expect(item.workflow_circulations).to be_blank
        end

        SS::Notification.order_by(id: -1).to_a.tap do |notifications|
          notifications[0].tap do |notification|
            expect(notification.subject).to eq I18n.t("gws_notification.gws/workflow/file.request", name: file.name)
            expect(notification.text).to be_blank
            expect(notification.html).to be_blank
            expect(notification.user_id).to eq user1.id
            expect(notification.member_ids).to eq [user1_superior.id, user2.id]
          end
        end

        #
        # user1_superior: 申請を承認する
        #
        login_user user1_superior
        visit gws_workflow2_files_path(site: site, state: "all")
        click_on file.name
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

        #
        # user2: 申請を承認する
        #
        login_user user2
        visit gws_workflow2_files_path(site: site, state: "all")
        click_on file.name
        wait_for_turbo_frame "#workflow-approver-frame"
        within ".mod-workflow-view" do
          expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.request"))
        end
        within ".mod-workflow-approve" do
          fill_in "item[comment]", with: approve_comment2
          click_on I18n.t("workflow.buttons.approve")
        end
        wait_for_notice I18n.t("gws/workflow2.notice.approved")
        wait_for_turbo_frame "#workflow-approver-frame"

        Gws::Workflow2::File.all.first.tap do |item|
          expect(item.workflow_user_id).to eq user1.id
          expect(item.workflow_agent_id).to eq admin.id
          expect(item.workflow_state).to eq 'approve'
          expect(item.workflow_comment).to eq workflow_comment
          expect(item.workflow_approvers.count).to eq 2
          expect(item.workflow_approvers).to include(
            { level: 1, user_type: "superior", user_id: user1_superior.id, state: 'approve', comment: approve_comment1,
              file_ids: nil, created: be_within(30.seconds).of(Time.zone.now) })
          expect(item.workflow_approvers).to include(
            { level: 1, user_type: Gws::User.name, user_id: user2.id, state: 'approve', comment: approve_comment2,
              file_ids: nil, created: be_within(30.seconds).of(Time.zone.now) })
          expect(item.workflow_circulations).to be_blank
        end

        expect(SS::Notification.count).to eq 2
        SS::Notification.order_by(id: -1).to_a.tap do |notifications|
          notifications[0].tap do |notification|
            expect(notification.subject).to eq I18n.t("gws_notification.gws/workflow/file.approve", name: file.name)
            expect(notification.text).to be_blank
            expect(notification.html).to be_blank
            expect(notification.user_id).to eq user2.id
            expect(notification.member_ids).to include(admin.id, user1.id)
          end
        end
      end
    end
  end
end
