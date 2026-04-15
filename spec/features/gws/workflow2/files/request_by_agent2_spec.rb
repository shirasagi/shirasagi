require 'spec_helper'

describe Gws::Workflow2::FilesController, type: :feature, dbscope: :example, js: true do
  let(:now) { Time.zone.now.change(usec: 0) }

  before do
    ActionMailer::Base.deliveries.clear
  end

  after { ActionMailer::Base.deliveries.clear }

  context "request by agent with minimum permissions" do
    let!(:site) { gws_site }
    let!(:admin) { gws_user }

    let!(:minimum_role) do
      permissions = %w(use_gws_workflow2)
      create(:gws_role, cur_site: site, permissions: permissions)
    end
    let!(:user1_group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
    let!(:user1_superior) do
      create(:gws_user, :gws_workflow_notice, group_ids: [ user1_group.id ], gws_role_ids: [ minimum_role.id ])
    end
    let!(:user1) do
      create(:gws_user, :gws_workflow_notice, group_ids: [ user1_group.id ], gws_role_ids: [ minimum_role.id ])
    end
    let!(:user2_group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
    let!(:user2_superior) do
      create(:gws_user, :gws_workflow_notice, group_ids: [ user2_group.id ], gws_role_ids: [ minimum_role.id ])
    end
    let!(:user2) do
      create(:gws_user, :gws_workflow_notice, group_ids: [ user2_group.id ], gws_role_ids: [ minimum_role.id ])
    end

    let(:workflow_comment) { unique_id }

    before do
      site.canonical_scheme = %w(http https).sample
      site.canonical_domain = "#{unique_id}.example.jp"
      site.save!

      admin.notice_workflow_user_setting = "notify"
      admin.notice_workflow_email_user_setting = "notify"
      admin.send_notice_mail_addresses = "#{unique_id}@example.jp"
      admin.save!

      user1.in_gws_superior_user_ids = [ user1_superior.id ]
      user1.save!

      user2.in_gws_superior_user_ids = [ user2_superior.id ]
      user2.save!

      user1_group.add_to_set(superior_user_ids: user1_superior.id)
      # user2 はグループ長のため user2_group の上長を user2 にセット
      user2_group.add_to_set(superior_user_ids: user2.id)
    end

    context "with 所属長承認 (my_group)" do
      let(:form) do
        create(
          :gws_workflow2_form_application, cur_site: site, state: "public",
          approval_state: "with_approval", default_route_id: "my_group",
          agent_state: "enabled"
        )
      end
      let!(:column1) { create(:gws_column_text_field, cur_site: site, cur_form: form, input_type: "text") }

      it do
        #
        # user1: 申請書の作成
        #
        login_user user1, to: new_gws_workflow2_form_file_path(site: site, state: "all", form_id: form)
        within "form#item-form" do
          fill_in "custom[#{column1.id}]", with: unique_id
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t('ss.notice.saved')

        expect(Gws::Workflow2::File.all.count).to eq 1
        file = Gws::Workflow2::File.all.first
        expect(file.site_id).to eq site.id
        expect(file.form_id).to eq form.id
        form_name = [ form.name, now.strftime("%Y%m%d"), form.current_style_sequence ].join("_")
        expect(file.name).to eq form_name
        expect(file.workflow_user_id).to be_blank
        expect(file.workflow_agent_id).to be_blank

        #
        # user1: user2 の代理で申請する
        #
        visit gws_workflow2_files_path(site: site, state: "all")
        click_on file.name
        wait_for_all_turbo_frames

        within ".mod-workflow-request" do
          choose "item_workflow_agent_type_agent"
          wait_for_cbox_opened { click_on I18n.t("gws/workflow2.search_delegatees.index") }
        end
        within_cbox do
          within "form.search" do
            click_on user1_group.name
            within ".dropdown-container" do
              click_on user2_group.trailing_name
            end
          end
        end
        wait_for_event_fired "turbo:frame-load" do
          within_cbox do
            wait_for_cbox_closed { click_on user2.long_name }
          end
        end
        within ".mod-workflow-request" do
          expect(page).to have_css(".agent-type-agent [data-id='#{user2.id}']", text: user2.long_name)
          within ".gws-workflow-file-approver-item[data-level='1']" do
            expect(page).to have_css("[data-id='#{user2_superior.id}']", text: user2_superior.long_name)
          end

          fill_in "item[workflow_comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end
        wait_for_notice I18n.t("workflow.notice.requested")

        within ".mod-workflow-view" do
          expect(page).to have_css(".workflow_agent_id", text: user1.name)
          expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.request"))
          expect(page).to have_css(".workflow_comment", text: workflow_comment)
          within ".workflow_approvers" do
            expect(page).to have_css("[data-user-id]", count: 1)
            expect(page).to have_css("[data-user-id='#{user2_superior.id}']", text: user2_superior.long_name)
          end
        end

        expect(Gws::Workflow2::File.count).to eq 1
        Gws::Workflow2::File.all.first.tap do |item|
          expect(item.workflow_user_id).to eq user2.id
          expect(item.workflow_agent_id).to eq user1.id
          expect(item.workflow_state).to eq 'request'
          expect(item.workflow_approvers.count).to eq 1
          expect(item.workflow_approvers).to include(
            { level: 1, user_type: "superior", user_id: user2_superior.id, state: 'request', comment: be_blank }
          )
        end

        expect(SS::Notification.count).to eq 1
        SS::Notification.order_by(id: -1).first.tap do |notification|
          expect(notification.subject).to eq I18n.t("gws_notification.gws/workflow/file.request", name: file.name)
          expect(notification.text).to be_blank
          expect(notification.html).to be_blank
          expect(notification.user_id).to eq user2.id
          expect(notification.member_ids).to eq [user2_superior.id]
        end
      end
    end

    context "with 所属長承認（代理承認者へ変更可） (my_group_alternate)" do
      let(:form) do
        create(
          :gws_workflow2_form_application, cur_site: site, state: "public",
          approval_state: "with_approval", default_route_id: "my_group_alternate",
          agent_state: "enabled"
        )
      end
      let!(:column1) { create(:gws_column_text_field, cur_site: site, cur_form: form, input_type: "text") }

      it do
        #
        # user1: 申請書の作成
        #
        login_user user1, to: new_gws_workflow2_form_file_path(site: site, state: "all", form_id: form)
        within "form#item-form" do
          fill_in "custom[#{column1.id}]", with: unique_id
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t('ss.notice.saved')

        expect(Gws::Workflow2::File.all.count).to eq 1
        file = Gws::Workflow2::File.all.first
        expect(file.site_id).to eq site.id
        expect(file.form_id).to eq form.id
        form_name = [ form.name, now.strftime("%Y%m%d"), form.current_style_sequence ].join("_")
        expect(file.name).to eq form_name
        expect(file.workflow_user_id).to be_blank
        expect(file.workflow_agent_id).to be_blank

        #
        # user1: user2 の代理で申請する
        #
        visit gws_workflow2_files_path(site: site, state: "all")
        click_on file.name
        wait_for_all_turbo_frames

        within ".mod-workflow-request" do
          choose "item_workflow_agent_type_agent"
          wait_for_cbox_opened { click_on I18n.t("gws/workflow2.search_delegatees.index") }
        end
        within_cbox do
          within "form.search" do
            click_on user1_group.name
            within ".dropdown-container" do
              click_on user2_group.trailing_name
            end
          end
        end
        wait_for_event_fired "turbo:frame-load" do
          within_cbox do
            wait_for_cbox_closed { click_on user2.long_name }
          end
        end
        within ".mod-workflow-request" do
          expect(page).to have_css(".agent-type-agent [data-id='#{user2.id}']", text: user2.long_name)
          within ".gws-workflow-file-approver-item[data-level='1']" do
            expect(page).to have_css("[data-id='#{user2_superior.id}']", text: user2_superior.long_name)
          end

          fill_in "item[workflow_comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end
        wait_for_notice I18n.t("workflow.notice.requested")

        within ".mod-workflow-view" do
          expect(page).to have_css(".workflow_agent_id", text: user1.name)
          expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.request"))
          expect(page).to have_css(".workflow_comment", text: workflow_comment)
          within ".workflow_approvers" do
            expect(page).to have_css("[data-user-id]", count: 1)
            expect(page).to have_css("[data-user-id='#{user2_superior.id}']", text: user2_superior.long_name)
          end
        end

        expect(Gws::Workflow2::File.count).to eq 1
        Gws::Workflow2::File.all.first.tap do |item|
          expect(item.workflow_user_id).to eq user2.id
          expect(item.workflow_agent_id).to eq user1.id
          expect(item.workflow_state).to eq 'request'
          expect(item.workflow_approvers.count).to eq 1
          expect(item.workflow_approvers).to include(
            { level: 1, user_type: "superior", user_id: user2_superior.id, state: 'request', comment: be_blank }
          )
        end

        expect(SS::Notification.count).to eq 1
        SS::Notification.order_by(id: -1).first.tap do |notification|
          expect(notification.subject).to eq I18n.t("gws_notification.gws/workflow/file.request", name: file.name)
          expect(notification.text).to be_blank
          expect(notification.html).to be_blank
          expect(notification.user_id).to eq user2.id
          expect(notification.member_ids).to eq [user2_superior.id]
        end
      end
    end

    context "「本人が申請する」と「代理で申請する」を行ったり来たり" do
      let(:form) do
        create(
          :gws_workflow2_form_application, cur_site: site, state: "public",
          approval_state: "with_approval", default_route_id: %w(my_group my_group_alternate).sample,
          agent_state: "enabled"
        )
      end
      let!(:column1) { create(:gws_column_text_field, cur_site: site, cur_form: form, input_type: "text") }

      it do
        # user1: 申請書の作成
        login_user user1, to: new_gws_workflow2_form_file_path(site: site, state: "all", form_id: form)
        within "form#item-form" do
          fill_in "custom[#{column1.id}]", with: unique_id
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t('ss.notice.saved')

        expect(Gws::Workflow2::File.all.count).to eq 1
        file = Gws::Workflow2::File.all.first
        expect(file.site_id).to eq site.id
        expect(file.form_id).to eq form.id
        form_name = [ form.name, now.strftime("%Y%m%d"), form.current_style_sequence ].join("_")
        expect(file.name).to eq form_name
        expect(file.workflow_user_id).to be_blank
        expect(file.workflow_agent_id).to be_blank

        # 承認経路には user1 の上長が設定されているはず
        within ".mod-workflow-request" do
          within ".gws-workflow-file-approver-item[data-level='1']" do
            expect(page).to have_css("[data-id='#{user1_superior.id}']", text: user1_superior.long_name)
          end
        end

        within ".mod-workflow-request" do
          # 「代理で申請する」を明示的に選択しなくても、本来の申請者を選択すると自動で選択される
          # choose I18n.t("gws/workflow.agent_type.agent")
          wait_for_cbox_opened { click_on I18n.t("gws/workflow2.search_delegatees.index") }
        end
        wait_for_event_fired "turbo:frame-load" do
          within_cbox do
            within "form.search" do
              click_on user1_group.name
              within ".dropdown-container" do
                click_on user2_group.trailing_name
              end
            end
          end
          within_cbox do
            wait_for_cbox_closed { click_on user2.long_name }
          end
        end
        within ".mod-workflow-request" do
          expect(page).to have_css(".agent-type-agent [data-id='#{user2.id}']", text: user2.long_name)
          within ".gws-workflow-file-approver-item[data-level='1']" do
            expect(page).to have_css("[data-id='#{user2_superior.id}']", text: user2_superior.long_name)
          end
        end

        # 「本人が申請する」に戻す => 承認経路には user1 の上長が設定されているはず
        wait_for_event_fired "turbo:frame-load" do
          within ".mod-workflow-request" do
            choose I18n.t("gws/workflow.agent_type.myself")
          end
        end
        within ".mod-workflow-request" do
          within ".gws-workflow-file-approver-item[data-level='1']" do
            expect(page).to have_css("[data-id='#{user1_superior.id}']", text: user1_superior.long_name)
          end
        end

        # 「代理で申請する」を再び選択 => 承認経路が直前で選択したユーザーの上長がセットされているはず
        wait_for_event_fired "turbo:frame-load" do
          within ".mod-workflow-request" do
            choose I18n.t("gws/workflow.agent_type.agent")
          end
        end
        within ".mod-workflow-request" do
          within ".gws-workflow-file-approver-item[data-level='1']" do
            expect(page).to have_css("[data-id='#{user2_superior.id}']", text: user2_superior.long_name)
          end
        end
      end
    end
  end
end
