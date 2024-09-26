require 'spec_helper'

describe Gws::Workflow2::FilesController, type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:admin) { gws_user }
  let!(:minimum_role) { create(:gws_role, cur_site: site, permissions: %w(use_gws_workflow2)) }
  let!(:user0) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ]) }
  let!(:user1) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ]) }
  let!(:user2) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ]) }
  let!(:user3) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ]) }

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

  context "specify approvers at the time of application" do
    let!(:route) do
      create(
        :gws_workflow2_route, name: unique_id, group_ids: admin.group_ids,
        approvers: [
          { "level" => 1, "user_type" => "special", "user_id" => "specify_at_time_of_application" },
          { "level" => 2, "user_type" => "special", "user_id" => "specify_at_time_of_application" },
          { "level" => 3, "user_type" => "special", "user_id" => "specify_at_time_of_application" },
        ],
        required_counts: [ false, false, false, false, false ],
        circulations: [
          { "level" => 1, "user_type" => "special", "user_id" => "specify_at_time_of_application" },
          { "level" => 2, "user_type" => "special", "user_id" => "specify_at_time_of_application" },
          { "level" => 3, "user_type" => "special", "user_id" => "specify_at_time_of_application" },
        ]
      )
    end

    let!(:form) { create(:gws_workflow2_form_application, default_route_id: route.id, state: "public") }
    let!(:column1) { create(:gws_column_text_field, form: form, input_type: "text") }
    let!(:item) do
      create :gws_workflow2_file, cur_user: user0, form: form, column_values: [ column1.serialize_value(unique_id) ]
    end

    let(:workflow_comment1) { unique_id }
    let(:approve_comment1) { unique_id }
    let(:approve_comment2) { unique_id }
    let(:approve_comment3) { unique_id }
    let(:circulation_comment1) { unique_id }
    let(:circulation_comment2) { unique_id }
    let(:circulation_comment3) { unique_id }

    it do
      #
      # user0: 申請する（承認者 3＋回覧者 3 段）
      #
      login_user user0
      visit gws_workflow2_file_path(site: site, state: 'all', id: item)
      wait_for_turbo_frame "#workflow-approver-frame"

      within ".mod-workflow-request" do
        fill_in "item[workflow_comment]", with: workflow_comment1

        within ".gws-workflow-file-approver-item[data-level='1']" do
          wait_for_cbox_opened { click_on I18n.t("workflow.search_approvers.index") }
        end
      end
      within_cbox do
        wait_for_cbox_closed { click_on user1.long_name }
      end
      within ".mod-workflow-request" do
        within ".gws-workflow-file-approver-item[data-level='1']" do
          expect(page).to have_css(".gws-workflow-file-approver-item-special-result-item", text: user1.long_name)
        end

        within ".gws-workflow-file-approver-item[data-level='2']" do
          wait_for_cbox_opened { click_on I18n.t("workflow.search_approvers.index") }
        end
      end
      within_cbox do
        wait_for_cbox_closed { click_on user2.long_name }
      end
      within ".mod-workflow-request" do
        within ".gws-workflow-file-approver-item[data-level='2']" do
          expect(page).to have_css(".gws-workflow-file-approver-item-special-result-item", text: user2.long_name)
        end

        within ".gws-workflow-file-approver-item[data-level='3']" do
          wait_for_cbox_opened { click_on I18n.t("workflow.search_approvers.index") }
        end
      end
      within_cbox do
        wait_for_cbox_closed { click_on user3.long_name }
      end
      within ".mod-workflow-request" do
        within ".gws-workflow-file-approver-item[data-level='3']" do
          expect(page).to have_css(".gws-workflow-file-approver-item-special-result-item", text: user3.long_name)
        end

        within ".gws-workflow-file-circulation-item[data-level='1']" do
          wait_for_cbox_opened { click_on I18n.t("workflow.search_circulations.index") }
        end
      end
      within_cbox do
        wait_for_cbox_closed { click_on user2.long_name }
      end
      within ".mod-workflow-request" do
        within ".gws-workflow-file-circulation-item[data-level='1']" do
          expect(page).to have_css(".gws-workflow-file-circulation-item-special-result-item", text: user2.long_name)
        end

        within ".gws-workflow-file-circulation-item[data-level='2']" do
          wait_for_cbox_opened { click_on I18n.t("workflow.search_circulations.index") }
        end
      end
      within_cbox do
        wait_for_cbox_closed { click_on user3.long_name }
      end
      within ".mod-workflow-request" do
        within ".gws-workflow-file-circulation-item[data-level='2']" do
          expect(page).to have_css(".gws-workflow-file-circulation-item-special-result-item", text: user3.long_name)
        end

        within ".gws-workflow-file-circulation-item[data-level='3']" do
          wait_for_cbox_opened { click_on I18n.t("workflow.search_circulations.index") }
        end
      end
      within_cbox do
        wait_for_cbox_closed { click_on user1.long_name }
      end
      within ".mod-workflow-request" do
        within ".gws-workflow-file-circulation-item[data-level='3']" do
          expect(page).to have_css(".gws-workflow-file-circulation-item-special-result-item", text: user1.long_name)
        end

        click_on I18n.t("workflow.buttons.request")
      end
      wait_for_notice I18n.t("gws/workflow2.notice.requested")
      wait_for_turbo_frame "#workflow-approver-frame"

      within ".mod-workflow-view" do
        expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".workflow_comment", text: workflow_comment1)
      end

      item.reload
      expect(item.workflow_user_id).to eq user0.id
      expect(item.workflow_state).to eq "request"
      expect(item.workflow_comment).to eq workflow_comment1
      expect(item.workflow_approvers.count).to eq 3
      expect(item.workflow_approvers).to \
        include(
          { level: 1, user_type: Gws::User.name, user_id: user1.id, state: 'request', comment: '', editable: 1 },
          { level: 2, user_type: Gws::User.name, user_id: user2.id, state: 'pending', comment: '', editable: 1 },
          { level: 3, user_type: Gws::User.name, user_id: user3.id, state: 'pending', comment: '', editable: 1 }
        )
      expect(item.workflow_circulations.count).to eq 3
      expect(item.workflow_circulations).to \
        include(
          { level: 1, user_type: Gws::User.name, user_id: user2.id, state: 'pending', comment: '' },
          { level: 2, user_type: Gws::User.name, user_id: user3.id, state: 'pending', comment: '' },
          { level: 3, user_type: Gws::User.name, user_id: user1.id, state: 'pending', comment: '' }
        )

      expect(SS::Notification.count).to eq 1
      SS::Notification.order_by(id: -1).first.tap do |notice|
        expect(notice.subject).to eq I18n.t("gws_notification.gws/workflow/file.request", name: item.name)
        expect(notice.text).to be_blank
        expect(notice.html).to be_blank
        expect(notice.user_id).to eq user0.id
        expect(notice.member_ids).to eq [user1.id]
      end

      # user1: 承認
      login_user user1
      visit gws_workflow2_files_main_path(site: site)
      click_on I18n.t("gws/workflow2.navi.approve")
      click_on item.name
      wait_for_turbo_frame "#workflow-approver-frame"

      within ".mod-workflow-approve" do
        fill_in "item[comment]", with: approve_comment1
        click_on I18n.t("workflow.buttons.approve")
      end
      wait_for_notice I18n.t("gws/workflow2.notice.approved")
      wait_for_turbo_frame "#workflow-approver-frame"

      item.reload
      expect(item.workflow_user_id).to eq user0.id
      expect(item.workflow_state).to eq "request"
      expect(item.workflow_comment).to eq workflow_comment1
      expect(item.workflow_approvers.count).to eq 3
      expect(item.workflow_approvers).to \
        include(
          { level: 1, user_type: Gws::User.name, user_id: user1.id, state: 'approve', comment: approve_comment1, editable: 1,
            file_ids: nil, created: be_within(30.seconds).of(Time.zone.now) },
          { level: 2, user_type: Gws::User.name, user_id: user2.id, state: 'request', comment: '', editable: 1 },
          { level: 3, user_type: Gws::User.name, user_id: user3.id, state: 'pending', comment: '', editable: 1 }
        )
      expect(item.workflow_circulations.count).to eq 3
      expect(item.workflow_circulations).to \
        include(
          { level: 1, user_type: Gws::User.name, user_id: user2.id, state: 'pending', comment: '' },
          { level: 2, user_type: Gws::User.name, user_id: user3.id, state: 'pending', comment: '' },
          { level: 3, user_type: Gws::User.name, user_id: user1.id, state: 'pending', comment: '' }
        )

      expect(SS::Notification.count).to eq 2
      SS::Notification.order_by(id: -1).first.tap do |notice|
        expect(notice.subject).to eq I18n.t("gws_notification.gws/workflow/file.request", name: item.name)
        expect(notice.text).to be_blank
        expect(notice.html).to be_blank
        expect(notice.user_id).to eq user0.id
        expect(notice.member_ids).to eq [user2.id]
      end

      # user2: 承認
      login_user user2
      visit gws_workflow2_files_main_path(site: site)
      click_on I18n.t("gws/workflow2.navi.approve")
      click_on item.name
      wait_for_turbo_frame "#workflow-approver-frame"

      within ".mod-workflow-approve" do
        fill_in "item[comment]", with: approve_comment2
        click_on I18n.t("workflow.buttons.approve")
      end
      wait_for_notice I18n.t("gws/workflow2.notice.approved")
      wait_for_turbo_frame "#workflow-approver-frame"

      item.reload
      expect(item.workflow_user_id).to eq user0.id
      expect(item.workflow_state).to eq "request"
      expect(item.workflow_comment).to eq workflow_comment1
      expect(item.workflow_approvers.count).to eq 3
      expect(item.workflow_approvers).to \
        include(
          { level: 1, user_type: Gws::User.name, user_id: user1.id, state: 'approve', comment: approve_comment1, editable: 1,
            file_ids: nil, created: be_within(30.seconds).of(Time.zone.now) },
          { level: 2, user_type: Gws::User.name, user_id: user2.id, state: 'approve', comment: approve_comment2, editable: 1,
            file_ids: nil, created: be_within(30.seconds).of(Time.zone.now) },
          { level: 3, user_type: Gws::User.name, user_id: user3.id, state: 'request', comment: '', editable: 1 }
        )
      expect(item.workflow_circulations.count).to eq 3
      expect(item.workflow_circulations).to \
        include(
          { level: 1, user_type: Gws::User.name, user_id: user2.id, state: 'pending', comment: '' },
          { level: 2, user_type: Gws::User.name, user_id: user3.id, state: 'pending', comment: '' },
          { level: 3, user_type: Gws::User.name, user_id: user1.id, state: 'pending', comment: '' }
        )

      expect(SS::Notification.count).to eq 3
      SS::Notification.order_by(id: -1).first.tap do |notice|
        expect(notice.subject).to eq I18n.t("gws_notification.gws/workflow/file.request", name: item.name)
        expect(notice.text).to be_blank
        expect(notice.html).to be_blank
        expect(notice.user_id).to eq user0.id
        expect(notice.member_ids).to eq [user3.id]
      end

      # user3: 承認
      login_user user3
      visit gws_workflow2_files_main_path(site: site)
      click_on I18n.t("gws/workflow2.navi.approve")
      click_on item.name
      wait_for_turbo_frame "#workflow-approver-frame"

      within ".mod-workflow-approve" do
        fill_in "item[comment]", with: approve_comment3
        click_on I18n.t("workflow.buttons.approve")
      end
      wait_for_notice I18n.t("gws/workflow2.notice.approved")
      wait_for_turbo_frame "#workflow-approver-frame"

      item.reload
      expect(item.workflow_user_id).to eq user0.id
      expect(item.workflow_state).to eq "approve"
      expect(item.workflow_comment).to eq workflow_comment1
      expect(item.workflow_approvers.count).to eq 3
      expect(item.workflow_approvers).to \
        include(
          { level: 1, user_type: Gws::User.name, user_id: user1.id, state: 'approve', comment: approve_comment1, editable: 1,
            file_ids: nil, created: be_within(30.seconds).of(Time.zone.now) },
          { level: 2, user_type: Gws::User.name, user_id: user2.id, state: 'approve', comment: approve_comment2, editable: 1,
            file_ids: nil, created: be_within(30.seconds).of(Time.zone.now) },
          { level: 3, user_type: Gws::User.name, user_id: user3.id, state: 'approve', comment: approve_comment3, editable: 1,
            file_ids: nil, created: be_within(30.seconds).of(Time.zone.now) }
        )
      expect(item.workflow_circulations.count).to eq 3
      expect(item.workflow_circulations).to \
        include(
          { level: 1, user_type: Gws::User.name, user_id: user2.id, state: 'unseen', comment: '' },
          { level: 2, user_type: Gws::User.name, user_id: user3.id, state: 'pending', comment: '' },
          { level: 3, user_type: Gws::User.name, user_id: user1.id, state: 'pending', comment: '' }
        )

      expect(SS::Notification.count).to eq 5
      SS::Notification.order_by(id: -1).to_a.tap do |notices|
        notices[1].tap do |notice|
          expect(notice.subject).to eq I18n.t("gws_notification.gws/workflow/file.approve", name: item.name)
          expect(notice.text).to be_blank
          expect(notice.html).to be_blank
          expect(notice.user_id).to eq user3.id
          expect(notice.member_ids).to eq [user0.id]
        end
        notices[0].tap do |notice|
          expect(notice.subject).to eq I18n.t("gws_notification.gws/workflow/file.circular", name: item.name)
          expect(notice.text).to be_blank
          expect(notice.html).to be_blank
          expect(notice.user_id).to eq user0.id
          expect(notice.member_ids).to eq [user2.id]
        end
      end
    end
  end

  context "specify no approvers at the time of application" do
    let!(:route) do
      create(
        :gws_workflow2_route, name: unique_id, group_ids: admin.group_ids,
        approvers: [
          { "level" => 1, "user_type" => "special", "user_id" => "specify_at_time_of_application" },
        ],
        required_counts: [ false, false, false, false, false ]
      )
    end

    let!(:form) { create(:gws_workflow2_form_application, default_route_id: route.id, state: "public") }
    let!(:column1) { create(:gws_column_text_field, form: form, input_type: "text") }
    let!(:item) do
      create :gws_workflow2_file, cur_user: user0, form: form, column_values: [ column1.serialize_value(unique_id) ]
    end

    it do
      # user0: 申請する
      login_user user0
      visit gws_workflow2_file_path(site: site, state: 'all', id: item)
      wait_for_turbo_frame "#workflow-approver-frame"

      within ".mod-workflow-request" do
        fill_in "item[workflow_comment]", with: unique_id
        click_on I18n.t("workflow.buttons.request")
      end
      wait_for_turbo_frame "#workflow-approver-frame"
      within ".mod-workflow-request" do
        attr = Gws::Workflow2::File.t(:workflow_approvers)
        error = I18n.t("errors.messages.user_id_blank")
        wait_for_error I18n.t("errors.format", attribute: attr, message: error)
      end
    end
  end

  context "js specs" do
    let!(:route) do
      create(
        :gws_workflow2_route, name: unique_id, group_ids: admin.group_ids,
        approvers: [
          { "level" => 1, "user_type" => "special", "user_id" => "specify_at_time_of_application" },
          { "level" => 2, "user_type" => "special", "user_id" => "specify_at_time_of_application" },
          { "level" => 3, "user_type" => "special", "user_id" => "specify_at_time_of_application" },
        ],
        required_counts: [ false, false, false, false, false ],
        circulations: [
          { "level" => 1, "user_type" => "special", "user_id" => "specify_at_time_of_application" },
          { "level" => 2, "user_type" => "special", "user_id" => "specify_at_time_of_application" },
          { "level" => 3, "user_type" => "special", "user_id" => "specify_at_time_of_application" },
        ]
      )
    end

    let!(:form) { create(:gws_workflow2_form_application, default_route_id: route.id, state: "public") }
    let!(:column1) { create(:gws_column_text_field, form: form, input_type: "text") }
    let!(:item) { create :gws_workflow2_file, form: form, column_values: [ column1.serialize_value(unique_id) ] }

    it do
      login_gws_user
      visit gws_workflow2_file_path(site: site, state: 'all', id: item)
      wait_for_turbo_frame "#workflow-approver-frame"

      # select
      within ".mod-workflow-request" do
        within ".gws-workflow-file-approver-item[data-level='1']" do
          wait_for_cbox_opened { click_on I18n.t("workflow.search_approvers.index") }
        end
      end
      within_cbox do
        wait_for_cbox_closed { click_on user1.long_name }
      end
      within ".mod-workflow-request" do
        within ".gws-workflow-file-approver-item[data-level='1']" do
          expect(page).to have_css(".gws-workflow-file-approver-item-special-result-item", text: user1.long_name)
          expect(page).to have_css(".gws-workflow-file-approver-item-special-result-item", count: 1)
        end
      end

      # select again
      within ".mod-workflow-request" do
        within ".gws-workflow-file-approver-item[data-level='1']" do
          wait_for_cbox_opened { click_on I18n.t("workflow.search_approvers.index") }
        end
      end
      within_cbox do
        expect(page).to have_css("tr[data-id='#{user1.id}'] [type='checkbox']:disabled")
        expect(page).to have_no_link user1.long_name

        wait_for_cbox_closed { click_on user3.long_name }
      end
      within ".mod-workflow-request" do
        within ".gws-workflow-file-approver-item[data-level='1']" do
          expect(page).to have_css(".gws-workflow-file-approver-item-special-result-item", count: 2)
          expect(page).to have_css(".gws-workflow-file-approver-item-special-result-item", text: user1.long_name)
          expect(page).to have_css(".gws-workflow-file-approver-item-special-result-item", text: user3.long_name)
        end
      end

      # delete user1
      within ".mod-workflow-request" do
        within ".gws-workflow-file-approver-item[data-level='1']" do
          within "[data-id='#{user1.id}']" do
            click_on I18n.t("ss.buttons.delete")
          end

          expect(page).to have_css(".gws-workflow-file-approver-item-special-result-item", count: 1)
          expect(page).to have_css(".gws-workflow-file-approver-item-special-result-item", text: user3.long_name)
        end
      end
    end
  end
end
