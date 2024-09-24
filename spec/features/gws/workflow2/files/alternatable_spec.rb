require 'spec_helper'

describe Gws::Workflow2::FilesController, type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:admin) { gws_user }
  let!(:minimum_role) { create(:gws_role, cur_site: site, permissions: %w(use_gws_workflow2)) }
  let!(:user1) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ]) }
  let!(:user2) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ]) }

  let!(:editable) { [ true, false ].sample }
  let!(:route) do
    create(
      :gws_workflow2_route, name: unique_id, group_ids: admin.group_ids,
      approvers: [
        { "level" => 1, "user_type" => "superior", "user_id" => "superior",
          "editable" => editable ? 1 : "", "alternatable" => 1 },
      ],
      required_counts: [ false, false, false, false, false ]
    )
  end
  let!(:form) do
    create(:gws_workflow2_form_application, default_route_id: route.id, state: "public", readable_setting_range: "public")
  end
  let!(:column1) { create(:gws_column_text_field, form: form, input_type: "text") }
  let!(:item) do
    create(
      :gws_workflow2_file, cur_user: user1, form: form,
      column_values: [ column1.serialize_value(unique_id) ]
    )
  end

  let(:workflow_comment1) { unique_id }
  let(:approve_comment1) { unique_id }
  let(:approve_comment2) { unique_id }

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

  context "when superior is existed" do
    before do
      admin.groups.each do |group|
        group.update!(superior_user_ids: [ admin.id ])
      end
    end

    context "when alternate is approved" do
      it do
        login_user user1
        visit gws_workflow2_files_main_path(site: site)
        click_on item.name
        wait_for_turbo_frame "#workflow-approver-frame"
        within ".mod-workflow-request" do
          fill_in "item[workflow_comment]", with: workflow_comment1
          within ".gws-workflow-file-approver-item[data-level='1']" do
            wait_for_cbox_opened { click_on I18n.t("gws/workflow2.search_alternates.index") }
          end
        end
        within_cbox do
          wait_for_cbox_closed { click_on user2.long_name }
        end
        within ".mod-workflow-request" do
          expect(page).to have_css(".gws-workflow-file-alternative-approver-item", text: user2.long_name)

          click_on I18n.t("workflow.buttons.request")
        end
        wait_for_notice I18n.t("gws/workflow2.notice.requested")
        wait_for_turbo_frame "#workflow-approver-frame"
        within ".mod-workflow-view" do
          expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.request"))
          expect(page).to have_css(".workflow_comment", text: workflow_comment1)
        end

        item.reload
        expect(item.workflow_user_id).to eq user1.id
        expect(item.workflow_agent_id).to be_blank
        expect(item.workflow_state).to eq "request"
        expect(item.workflow_comment).to eq workflow_comment1
        expect(item.workflow_approvers.count).to eq 2
        if editable
          expect(item.workflow_approvers).to include(
            { level: 1, user_type: "superior", user_id: admin.id, state: 'request', editable: 1, comment: '' },
            { level: 1, user_type: "superior", user_id: user2.id, state: 'request', editable: 1, comment: '',
              alternate_to: "1,superior,#{admin.id}" }
          )
        else
          expect(item.workflow_approvers).to include(
            { level: 1, user_type: "superior", user_id: admin.id, state: 'request', comment: '' },
            { level: 1, user_type: "superior", user_id: user2.id, state: 'request', comment: '',
              alternate_to: "1,superior,#{admin.id}" }
          )
        end
        expect(item.workflow_required_counts).to eq Array.new(Gws::Workflow2::Route::MAX_APPROVERS) { false }
        expect(item.workflow_circulations).to be_blank

        expect(SS::Notification.count).to eq 1
        SS::Notification.order_by(id: -1).first.tap do |memo|
          expect(memo.user_id).to eq user1.id
          expect(memo.member_ids).to eq [admin.id, user2.id]
          subject = I18n.t("gws_notification.gws/workflow/file.request", name: item.name)
          expect(memo.subject).to eq subject
        end

        #
        # user2: 申請を承認する（代理承認者 ）
        #
        login_user user2
        visit gws_workflow2_files_main_path(site: site)
        click_on item.name
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
        expect(item.workflow_user_id).to eq user1.id
        expect(item.workflow_agent_id).to be_blank
        expect(item.workflow_state).to eq 'approve'
        expect(item.workflow_comment).to eq workflow_comment1
        expect(item.workflow_approvers.count).to eq 2
        if editable
          expect(item.workflow_approvers).to include(
            { level: 1, user_type: "superior", user_id: admin.id, state: 'other_approved', editable: 1, comment: '',
              created: be_within(30.seconds).of(Time.zone.now) },
            { level: 1, user_type: "superior", user_id: user2.id, state: 'approve', editable: 1, comment: approve_comment1,
              alternate_to: "1,superior,#{admin.id}", file_ids: nil, created: be_within(30.seconds).of(Time.zone.now) }
          )
        else
          expect(item.workflow_approvers).to include(
            { level: 1, user_type: "superior", user_id: admin.id, state: 'other_approved', comment: '',
              created: be_within(30.seconds).of(Time.zone.now) },
            { level: 1, user_type: "superior", user_id: user2.id, state: 'approve', comment: approve_comment1,
              alternate_to: "1,superior,#{admin.id}", file_ids: nil, created: be_within(30.seconds).of(Time.zone.now) }
          )
        end

        expect(SS::Notification.count).to eq 2
        SS::Notification.order_by(id: -1).first.tap do |memo|
          expect(memo.user_id).to eq user2.id
          expect(memo.member_ids).to eq [user1.id]
          subject = I18n.t("gws_notification.gws/workflow/file.approve", name: item.name)
          expect(memo.subject).to eq subject
        end
      end
    end

    context "when original is approved" do
      it do
        login_user user1
        visit gws_workflow2_files_main_path(site: site)
        click_on item.name
        wait_for_turbo_frame "#workflow-approver-frame"
        within ".mod-workflow-request" do
          fill_in "item[workflow_comment]", with: workflow_comment1
          within ".gws-workflow-file-approver-item[data-level='1']" do
            wait_for_cbox_opened { click_on I18n.t("gws/workflow2.search_alternates.index") }
          end
        end
        within_cbox do
          wait_for_cbox_closed { click_on user2.long_name }
        end
        within ".mod-workflow-request" do
          expect(page).to have_css(".gws-workflow-file-alternative-approver-item", text: user2.long_name)

          click_on I18n.t("workflow.buttons.request")
        end
        wait_for_notice I18n.t("gws/workflow2.notice.requested")
        wait_for_turbo_frame "#workflow-approver-frame"
        within ".mod-workflow-view" do
          expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.request"))
          expect(page).to have_css(".workflow_comment", text: workflow_comment1)
        end

        item.reload
        expect(item.workflow_user_id).to eq user1.id
        expect(item.workflow_agent_id).to be_blank
        expect(item.workflow_state).to eq "request"
        expect(item.workflow_comment).to eq workflow_comment1
        expect(item.workflow_approvers.count).to eq 2
        if editable
          expect(item.workflow_approvers).to include(
            { level: 1, user_type: "superior", user_id: admin.id, state: 'request', editable: 1, comment: '' },
            { level: 1, user_type: "superior", user_id: user2.id, state: 'request', editable: 1, comment: '',
              alternate_to: "1,superior,#{admin.id}" }
          )
        else
          expect(item.workflow_approvers).to include(
            { level: 1, user_type: "superior", user_id: admin.id, state: 'request', comment: '' },
            { level: 1, user_type: "superior", user_id: user2.id, state: 'request', comment: '',
              alternate_to: "1,superior,#{admin.id}" }
          )
        end
        expect(item.workflow_required_counts).to eq Array.new(Gws::Workflow2::Route::MAX_APPROVERS) { false }
        expect(item.workflow_circulations).to be_blank

        expect(SS::Notification.count).to eq 1
        SS::Notification.order_by(id: -1).first.tap do |memo|
          expect(memo.user_id).to eq user1.id
          expect(memo.member_ids).to eq [admin.id, user2.id]
          subject = I18n.t("gws_notification.gws/workflow/file.request", name: item.name)
          expect(memo.subject).to eq subject
        end

        #
        # admin: 申請を承認する（本来の承認者 ）
        #
        login_user admin
        visit gws_workflow2_files_main_path(site: site)
        click_on item.name
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

        item.reload
        expect(item.workflow_user_id).to eq user1.id
        expect(item.workflow_agent_id).to be_blank
        expect(item.workflow_state).to eq 'approve'
        expect(item.workflow_comment).to eq workflow_comment1
        expect(item.workflow_approvers.count).to eq 2
        if editable
          expect(item.workflow_approvers).to include(
            { level: 1, user_type: "superior", user_id: admin.id, state: 'approve', editable: 1, comment: approve_comment1,
              file_ids: nil, created: be_within(30.seconds).of(Time.zone.now) },
            { level: 1, user_type: "superior", user_id: user2.id, state: 'other_approved', editable: 1, comment: '',
              alternate_to: "1,superior,#{admin.id}", created: be_within(30.seconds).of(Time.zone.now) }
          )
        else
          expect(item.workflow_approvers).to include(
            { level: 1, user_type: "superior", user_id: admin.id, state: 'approve', comment: approve_comment1,
              file_ids: nil, created: be_within(30.seconds).of(Time.zone.now) },
            { level: 1, user_type: "superior", user_id: user2.id, state: 'other_approved', comment: '',
              alternate_to: "1,superior,#{admin.id}", created: be_within(30.seconds).of(Time.zone.now) }
          )
        end

        expect(SS::Notification.count).to eq 2
        SS::Notification.order_by(id: -1).first.tap do |memo|
          expect(memo.user_id).to eq admin.id
          expect(memo.member_ids).to eq [user1.id]
          subject = I18n.t("gws_notification.gws/workflow/file.approve", name: item.name)
          expect(memo.subject).to eq subject
        end
      end
    end
  end

  context "when multiple superiors are existed" do
    let!(:user3) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ]) }

    before do
      admin.groups.each do |group|
        group.update!(superior_user_ids: [ admin.id, user3.id ])
      end
    end

    context "when alternate is approved" do
      it do
        login_user user1
        visit gws_workflow2_files_main_path(site: site)
        click_on item.name
        wait_for_turbo_frame "#workflow-approver-frame"
        within ".mod-workflow-request" do
          fill_in "item[workflow_comment]", with: workflow_comment1
          within ".gws-workflow-file-approver-item[data-level='1'] [data-id='#{user3.id}-alternative']" do
            wait_for_cbox_opened { click_on I18n.t("gws/workflow2.search_alternates.index") }
          end
        end
        within_cbox do
          wait_for_cbox_closed { click_on user2.long_name }
        end
        within ".mod-workflow-request" do
          expect(page).to have_css(".gws-workflow-file-alternative-approver-item", text: user2.long_name)

          click_on I18n.t("workflow.buttons.request")
        end
        wait_for_notice I18n.t("gws/workflow2.notice.requested")
        wait_for_turbo_frame "#workflow-approver-frame"
        within ".mod-workflow-view" do
          expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.request"))
          expect(page).to have_css(".workflow_comment", text: workflow_comment1)
        end

        item.reload
        expect(item.workflow_user_id).to eq user1.id
        expect(item.workflow_agent_id).to be_blank
        expect(item.workflow_state).to eq "request"
        expect(item.workflow_comment).to eq workflow_comment1
        expect(item.workflow_approvers.count).to eq 3
        if editable
          expect(item.workflow_approvers).to include(
            { level: 1, user_type: "superior", user_id: admin.id, state: 'request', editable: 1, comment: '' },
            { level: 1, user_type: "superior", user_id: user3.id, state: 'request', editable: 1, comment: '' },
            { level: 1, user_type: "superior", user_id: user2.id, state: 'request', editable: 1, comment: '',
              alternate_to: "1,superior,#{user3.id}" }
          )
        else
          expect(item.workflow_approvers).to include(
            { level: 1, user_type: "superior", user_id: admin.id, state: 'request', comment: '' },
            { level: 1, user_type: "superior", user_id: user3.id, state: 'request', comment: '' },
            { level: 1, user_type: "superior", user_id: user2.id, state: 'request', comment: '',
              alternate_to: "1,superior,#{user3.id}" }
          )
        end
        expect(item.workflow_required_counts).to eq Array.new(Gws::Workflow2::Route::MAX_APPROVERS) { false }
        expect(item.workflow_circulations).to be_blank

        expect(SS::Notification.count).to eq 1
        SS::Notification.order_by(id: -1).first.tap do |memo|
          expect(memo.user_id).to eq user1.id
          expect(memo.member_ids).to eq [admin.id, user2.id, user3.id]
          subject = I18n.t("gws_notification.gws/workflow/file.request", name: item.name)
          expect(memo.subject).to eq subject
        end

        #
        # user2: 申請を承認する（代理承認者 ）
        #
        login_user user2
        visit gws_workflow2_files_main_path(site: site)
        click_on item.name
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
        expect(item.workflow_user_id).to eq user1.id
        expect(item.workflow_agent_id).to be_blank
        expect(item.workflow_state).to eq 'request'
        expect(item.workflow_comment).to eq workflow_comment1
        expect(item.workflow_approvers.count).to eq 3
        if editable
          expect(item.workflow_approvers).to include(
            { level: 1, user_type: "superior", user_id: admin.id, state: 'request', editable: 1, comment: '' },
            { level: 1, user_type: "superior", user_id: user3.id, state: 'other_approved', editable: 1, comment: '',
              created: be_within(30.seconds).of(Time.zone.now) },
            { level: 1, user_type: "superior", user_id: user2.id, state: 'approve', editable: 1, comment: approve_comment1,
              alternate_to: "1,superior,#{user3.id}", file_ids: nil, created: be_within(30.seconds).of(Time.zone.now) }
          )
        else
          expect(item.workflow_approvers).to include(
            { level: 1, user_type: "superior", user_id: admin.id, state: 'request', comment: '' },
            { level: 1, user_type: "superior", user_id: user3.id, state: 'other_approved', comment: '',
              created: be_within(30.seconds).of(Time.zone.now) },
            { level: 1, user_type: "superior", user_id: user2.id, state: 'approve', comment: approve_comment1,
              alternate_to: "1,superior,#{user3.id}", file_ids: nil, created: be_within(30.seconds).of(Time.zone.now) }
          )
        end

        expect(SS::Notification.count).to eq 1

        #
        # admin: 申請を承認する
        #
        login_user admin
        visit gws_workflow2_files_main_path(site: site)
        click_on item.name
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

        item.reload
        expect(item.workflow_user_id).to eq user1.id
        expect(item.workflow_agent_id).to be_blank
        expect(item.workflow_state).to eq 'approve'
        expect(item.workflow_comment).to eq workflow_comment1
        expect(item.workflow_approvers.count).to eq 3
        if editable
          expect(item.workflow_approvers).to include(
            { level: 1, user_type: "superior", user_id: admin.id, state: 'approve', editable: 1, comment: approve_comment2,
              file_ids: nil, created: be_within(30.seconds).of(Time.zone.now) },
            { level: 1, user_type: "superior", user_id: user3.id, state: 'other_approved', editable: 1, comment: '',
              created: be_within(30.seconds).of(Time.zone.now) },
            { level: 1, user_type: "superior", user_id: user2.id, state: 'approve', editable: 1, comment: approve_comment1,
              alternate_to: "1,superior,#{user3.id}", file_ids: nil, created: be_within(30.seconds).of(Time.zone.now) }
          )
        else
          expect(item.workflow_approvers).to include(
            { level: 1, user_type: "superior", user_id: admin.id, state: 'approve', comment: approve_comment2,
              file_ids: nil, created: be_within(30.seconds).of(Time.zone.now) },
            { level: 1, user_type: "superior", user_id: user3.id, state: 'other_approved', comment: '',
              created: be_within(30.seconds).of(Time.zone.now) },
            { level: 1, user_type: "superior", user_id: user2.id, state: 'approve', comment: approve_comment1,
              alternate_to: "1,superior,#{user3.id}", file_ids: nil, created: be_within(30.seconds).of(Time.zone.now) }
          )
        end

        expect(SS::Notification.count).to eq 2
        SS::Notification.order_by(id: -1).first.tap do |memo|
          expect(memo.user_id).to eq admin.id
          expect(memo.member_ids).to eq [user1.id]
          subject = I18n.t("gws_notification.gws/workflow/file.approve", name: item.name)
          expect(memo.subject).to eq subject
        end
      end
    end
  end

  context "when superior isn't existed" do
    it do
      login_user user1
      visit gws_workflow2_files_main_path(site: site)
      click_on item.name
      wait_for_turbo_frame "#workflow-approver-frame"
      within ".mod-workflow-request" do
        expect(page).to have_css(".error", text: I18n.t("gws/workflow2.errors.messages.superior_is_not_found"))
        expect(page).to have_no_css(".gws-workflow-file-approver-item[data-level='1']", text: I18n.t("gws/workflow2.search_alternates.index"))

        fill_in "item[workflow_comment]", with: workflow_comment1
        wait_for_event_fired("turbo:frame-load") { click_on I18n.t("workflow.buttons.request") }
      end
      within ".mod-workflow-request" do
        attr = Gws::Workflow2::File.t(:workflow_approvers)
        error = I18n.t("errors.messages.user_id_blank")
        wait_for_error I18n.t("errors.format", attribute: attr, message: error)
      end
    end
  end

  context "when mixed with 'specify_at_time_of_application'" do
    let!(:user3) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ]) }
    let!(:route) do
      create(
        :gws_workflow2_route, name: unique_id, group_ids: admin.group_ids,
        approvers: [
          { "level" => 1, "user_type" => "special", "user_id" => "specify_at_time_of_application",
            "editable" => editable ? 1 : "" },
          { "level" => 1, "user_type" => "superior", "user_id" => "superior",
            "editable" => editable ? 1 : "", "alternatable" => 1 }
        ],
        required_counts: [ false, false, false, false, false ]
      )
    end

    before do
      admin.groups.each do |group|
        group.update!(superior_user_ids: [ admin.id ])
      end
    end

    it do
      # user1: 申請する
      login_user user1
      visit gws_workflow2_files_main_path(site: site)
      click_on item.name
      wait_for_turbo_frame "#workflow-approver-frame"
      within ".mod-workflow-request" do
        fill_in "item[workflow_comment]", with: workflow_comment1
        within ".gws-workflow-file-approver-item[data-level='1']" do
          wait_for_cbox_opened { click_on I18n.t("gws/workflow2.search_alternates.index") }
        end
      end
      within_cbox do
        wait_for_cbox_closed { click_on user2.long_name }
      end
      within ".mod-workflow-request" do
        expect(page).to have_css(".gws-workflow-file-alternative-approver-item", text: user2.long_name)

        within ".gws-workflow-file-approver-item[data-level='1']" do
          wait_for_cbox_opened { click_on I18n.t("workflow.search_approvers.index") }
        end
      end
      within_cbox do
        wait_for_cbox_closed { click_on user3.long_name }
      end
      within ".mod-workflow-request" do
        expect(page).to have_css(".gws-workflow-file-approver-item-special-result-item", text: user3.long_name)

        click_on I18n.t("workflow.buttons.request")
      end
      wait_for_notice I18n.t("gws/workflow2.notice.requested")
      wait_for_turbo_frame "#workflow-approver-frame"
      within ".mod-workflow-view" do
        expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".workflow_comment", text: workflow_comment1)
      end

      item.reload
      expect(item.workflow_user_id).to eq user1.id
      expect(item.workflow_agent_id).to be_blank
      expect(item.workflow_state).to eq "request"
      expect(item.workflow_comment).to eq workflow_comment1
      expect(item.workflow_approvers.count).to eq 3
      if editable
        expect(item.workflow_approvers).to include(
          { level: 1, user_type: "superior", user_id: admin.id, state: 'request', editable: 1, comment: '' },
          { level: 1, user_type: "superior", user_id: user2.id, state: 'request', editable: 1, comment: '',
            alternate_to: "1,superior,#{admin.id}" },
          { level: 1, user_type: Gws::User.name, user_id: user3.id, state: 'request', editable: 1, comment: '' }
        )
      else
        expect(item.workflow_approvers).to include(
          { level: 1, user_type: "superior", user_id: admin.id, state: 'request', comment: '' },
          { level: 1, user_type: "superior", user_id: user2.id, state: 'request', comment: '',
            alternate_to: "1,superior,#{admin.id}" },
          { level: 1, user_type: Gws::User.name, user_id: user3.id, state: 'request', comment: '' }
        )
      end
      expect(item.workflow_required_counts).to eq Array.new(Gws::Workflow2::Route::MAX_APPROVERS) { false }
      expect(item.workflow_circulations).to be_blank

      expect(SS::Notification.count).to eq 1
      SS::Notification.order_by(id: -1).first.tap do |memo|
        expect(memo.user_id).to eq user1.id
        expect(memo.member_ids).to eq [admin.id, user2.id, user3.id]
        subject = I18n.t("gws_notification.gws/workflow/file.request", name: item.name)
        expect(memo.subject).to eq subject
      end

      # user2: 申請を承認する（代理承認者 ）
      login_user user2
      visit gws_workflow2_files_main_path(site: site)
      click_on item.name
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
      expect(item.workflow_user_id).to eq user1.id
      expect(item.workflow_agent_id).to be_blank
      expect(item.workflow_state).to eq 'request'
      expect(item.workflow_comment).to eq workflow_comment1
      expect(item.workflow_approvers.count).to eq 3
      if editable
        expect(item.workflow_approvers).to include(
          { level: 1, user_type: "superior", user_id: admin.id, state: 'other_approved', editable: 1, comment: '',
            created: be_within(30.seconds).of(Time.zone.now) },
          { level: 1, user_type: "superior", user_id: user2.id, state: 'approve', editable: 1, comment: approve_comment1,
            alternate_to: "1,superior,#{admin.id}", file_ids: nil, created: be_within(30.seconds).of(Time.zone.now) },
          { level: 1, user_type: Gws::User.name, user_id: user3.id, state: 'request', editable: 1, comment: '' }
        )
      else
        expect(item.workflow_approvers).to include(
          { level: 1, user_type: "superior", user_id: admin.id, state: 'other_approved', comment: '',
            created: be_within(30.seconds).of(Time.zone.now) },
          { level: 1, user_type: "superior", user_id: user2.id, state: 'approve', comment: approve_comment1,
            alternate_to: "1,superior,#{admin.id}", file_ids: nil, created: be_within(30.seconds).of(Time.zone.now) },
          { level: 1, user_type: Gws::User.name, user_id: user3.id, state: 'request', comment: '' }
        )
      end

      expect(SS::Notification.count).to eq 1

      # user3: 申請を承認する
      login_user user3
      visit gws_workflow2_files_main_path(site: site)
      click_on item.name
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

      item.reload
      expect(item.workflow_user_id).to eq user1.id
      expect(item.workflow_agent_id).to be_blank
      expect(item.workflow_state).to eq 'approve'
      expect(item.workflow_comment).to eq workflow_comment1
      expect(item.workflow_approvers.count).to eq 3
      if editable
        expect(item.workflow_approvers).to include(
          { level: 1, user_type: "superior", user_id: admin.id, state: 'other_approved', editable: 1, comment: '',
            created: be_within(30.seconds).of(Time.zone.now) },
          { level: 1, user_type: "superior", user_id: user2.id, state: 'approve', editable: 1, comment: approve_comment1,
            alternate_to: "1,superior,#{admin.id}", file_ids: nil, created: be_within(30.seconds).of(Time.zone.now) },
          { level: 1, user_type: Gws::User.name, user_id: user3.id, state: 'approve', editable: 1, comment: approve_comment2,
            file_ids: nil, created: be_within(30.seconds).of(Time.zone.now) }
        )
      else
        expect(item.workflow_approvers).to include(
          { level: 1, user_type: "superior", user_id: admin.id, state: 'other_approved', comment: '',
            created: be_within(30.seconds).of(Time.zone.now) },
          { level: 1, user_type: "superior", user_id: user2.id, state: 'approve', comment: approve_comment1,
            alternate_to: "1,superior,#{admin.id}", file_ids: nil, created: be_within(30.seconds).of(Time.zone.now) },
          { level: 1, user_type: Gws::User.name, user_id: user3.id, state: 'approve', comment: approve_comment2,
            file_ids: nil, created: be_within(30.seconds).of(Time.zone.now) }
        )
      end

      expect(SS::Notification.count).to eq 2
      SS::Notification.order_by(id: -1).first.tap do |memo|
        expect(memo.user_id).to eq user3.id
        expect(memo.member_ids).to eq [user1.id]
        subject = I18n.t("gws_notification.gws/workflow/file.approve", name: item.name)
        expect(memo.subject).to eq subject
      end
    end
  end
end
