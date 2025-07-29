require 'spec_helper'

describe Gws::Workflow2::FilesController, type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let!(:minimum_role) { create :gws_role, permissions: %w(use_gws_workflow2) }
  let!(:dest_group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:dest_user) { create :gws_user, group_ids: [ dest_group.id ], gws_role_ids: [ minimum_role.id ] }
  let!(:approver_group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:approver_user) { create :gws_user, group_ids: [ approver_group.id ], gws_role_ids: [ minimum_role.id ] }
  let!(:form) do
    create(
      :gws_workflow2_form_application, cur_site: site, state: "public",
      destination_group_ids: destination_group_ids, destination_user_ids: destination_user_ids
    )
  end
  let!(:column1) { create(:gws_column_text_field, cur_site: site, form: form, input_type: "text") }

  shared_examples "workflow destination" do
    context "with approved file" do
      let!(:item) do
        create(
          :gws_workflow2_file, cur_site: site, cur_user: user, form: form, column_values: [ column1.serialize_value(unique_id) ],
          workflow_user_id: user.id, workflow_state: "approve", workflow_required_counts: [ false ],
          workflow_approvers: [
            { "level" => 1, "user_type" => "Gws::User", "user_id" => approver_user.id, state: "approve", comment: unique_id },
          ],
          destination_group_ids: form.destination_group_ids, destination_user_ids: form.destination_user_ids,
          destination_treat_state: "untreated"
        )
      end

      context "destination user" do
        before do
          login_user dest_user
        end

        it do
          visit gws_workflow2_files_path(site: site, state: 'all')
          expect(page).to have_css(".list-item", count: 1)
          expect(page).to have_css(".list-item", text: item.name)
          visit gws_workflow2_files_path(site: site, state: 'destination')
          click_on item.name

          within "form#gws-workflow-destination-states-form" do
            wait_event_to_fire("turbo:frame-load") do
              select I18n.t("gws/workflow2.options.destination_treat_state.treated"), from: "item[destination_treat_state]"
            end
          end
          within "form#gws-workflow-destination-states-form" do
            expect(page).to have_content(I18n.t("gws/workflow2.notice.treated"))
          end

          item.reload
          expect(item.destination_treat_state).to eq "treated"
        end
      end

      context "requested user" do
        before do
          login_user user
        end

        it do
          visit gws_workflow2_files_path(site: site, state: 'destination')
          expect(page).to have_css(".list-item", count: 0)

          visit gws_workflow2_files_path(site: site, state: 'all')
          click_on item.name
          wait_for_turbo_frame "#workflow-approver-frame"
          within "#addon-gws-agents-addons-workflow2-approver" do
            expect(page).to have_css(".workflow_approvers", text: "#{approver_user.long_name}(#{approver_user.email})")
          end
          expect(page).to have_no_css("#gws-workflow-destination-states-form")
        end
      end

      context "approved user" do
        before do
          login_user approver_user
        end

        it do
          visit gws_workflow2_files_path(site: site, state: 'destination')
          expect(page).to have_css(".list-item", count: 0)

          visit gws_workflow2_files_path(site: site, state: 'all')
          click_on item.name
          wait_for_turbo_frame "#workflow-approver-frame"
          within "#addon-gws-agents-addons-workflow2-approver" do
            expect(page).to have_css(".workflow_approvers", text: "#{approver_user.long_name}(#{approver_user.email})")
          end
          expect(page).to have_no_css("#gws-workflow-destination-states-form")
        end
      end
    end

    context "with approved without approval (aka instantly approved) file" do
      let!(:item) do
        create(
          :gws_workflow2_file, cur_site: site, cur_user: user, form: form, column_values: [ column1.serialize_value(unique_id) ],
          workflow_user_id: user.id, workflow_state: "approve_without_approval", workflow_required_counts: [],
          workflow_approvers: [],
          destination_group_ids: form.destination_group_ids, destination_user_ids: form.destination_user_ids,
          destination_treat_state: "untreated"
        )
      end

      context "destination user" do
        before do
          login_user dest_user
        end

        it do
          visit gws_workflow2_files_path(site: site, state: 'all')
          expect(page).to have_css(".list-item", count: 1)
          expect(page).to have_css(".list-item", text: item.name)
          visit gws_workflow2_files_path(site: site, state: 'destination')
          click_on item.name

          within "form#gws-workflow-destination-states-form" do
            wait_event_to_fire("turbo:frame-load") do
              select I18n.t("gws/workflow2.options.destination_treat_state.treated"), from: "item[destination_treat_state]"
            end
          end
          within "form#gws-workflow-destination-states-form" do
            expect(page).to have_content(I18n.t("gws/workflow2.notice.treated"))
          end

          item.reload
          expect(item.destination_treat_state).to eq "treated"
        end
      end

      context "requested user" do
        before do
          login_user user
        end

        it do
          visit gws_workflow2_files_path(site: site, state: 'destination')
          expect(page).to have_css(".list-item", count: 0)

          visit gws_workflow2_files_path(site: site, state: 'all')
          click_on item.name
          wait_for_turbo_frame "#workflow-approver-frame"
          within "#addon-gws-agents-addons-workflow2-approver" do
            expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.approve_without_approval"))
          end
          expect(page).to have_no_css("#gws-workflow-destination-states-form")
        end
      end

      context "approved user" do
        before do
          login_user approver_user
        end

        it do
          visit gws_workflow2_files_path(site: site, state: 'all')
          expect(page).to have_css(".list-item", count: 0)
          visit gws_workflow2_files_path(site: site, state: 'destination')
          expect(page).to have_css(".list-item", count: 0)
        end
      end
    end

    context "with request file" do
      let!(:item) do
        create(
          :gws_workflow2_file, cur_site: site, cur_user: user, form: form, column_values: [ column1.serialize_value(unique_id) ],
          workflow_user_id: user.id, workflow_state: "request", workflow_required_counts: [ false ],
          workflow_approvers: [
            { "level" => 1, "user_type" => "Gws::User", "user_id" => approver_user.id, state: "request", comment: "" },
          ],
          destination_group_ids: form.destination_group_ids, destination_user_ids: form.destination_user_ids,
          destination_treat_state: "untreated"
        )
      end

      context "destination user" do
        before do
          login_user dest_user
        end

        it do
          visit gws_workflow2_files_path(site: site, state: 'all')
          expect(page).to have_css(".list-item", count: 0)
          visit gws_workflow2_files_path(site: site, state: 'destination')
          expect(page).to have_css(".list-item", count: 0)
        end
      end

      context "requested user" do
        before do
          login_user user
        end

        it do
          visit gws_workflow2_files_path(site: site, state: 'destination')
          expect(page).to have_css(".list-item", count: 0)

          visit gws_workflow2_files_path(site: site, state: 'all')
          click_on item.name
          wait_for_turbo_frame "#workflow-approver-frame"
          within "#addon-gws-agents-addons-workflow2-approver" do
            expect(page).to have_css(".workflow_approvers", text: "#{approver_user.long_name}(#{approver_user.email})")
          end
          expect(page).to have_no_css("#gws-workflow-destination-states-form")
        end
      end
    end

    context "ユースケース: 列定義が変わってしまいバリデーションエラーが発生するようになってしまった" do
      let!(:column2) { create(:gws_column_radio_button, cur_site: site, form: form, required: "required") }
      let!(:item) do
        create(
          :gws_workflow2_file, cur_site: site, cur_user: user, form: form,
          column_values: [ column1.serialize_value(unique_id), column2.serialize_value(column2.select_options.sample) ],
          workflow_user_id: user.id, workflow_state: "approve", workflow_required_counts: [ false ],
          workflow_approvers: [
            { "level" => 1, "user_type" => "Gws::User", "user_id" => approver_user.id, state: "approve", comment: unique_id },
          ],
          destination_group_ids: form.destination_group_ids, destination_user_ids: form.destination_user_ids,
          destination_treat_state: "untreated"
        )
      end

      before do
        column2.update(select_options: Array.new(3) { "option-#{unique_id}" })
        Gws::Workflow2::File.find(item.id).tap do |item0|
          expect(item0.valid?).to be_falsey
        end

        login_user dest_user
      end

      it do
        visit gws_workflow2_files_path(site: site, state: 'destination')
        click_on item.name

        within "form#gws-workflow-destination-states-form" do
          wait_event_to_fire("turbo:frame-load") do
            select I18n.t("gws/workflow2.options.destination_treat_state.treated"), from: "item[destination_treat_state]"
          end
        end
        within "form#gws-workflow-destination-states-form" do
          expect(page).to have_content(I18n.t("gws/workflow2.notice.treated"))
        end

        item.reload
        expect(item.destination_treat_state).to eq "treated"
      end
    end
  end

  context 'with destination user' do
    let(:destination_group_ids) { [] }
    let(:destination_user_ids) { [ dest_user.id ] }
    include_context "workflow destination"
  end

  context 'with destination group' do
    let(:destination_group_ids) { [ dest_group.id ] }
    let(:destination_user_ids) { [] }
    include_context "workflow destination"
  end
end
