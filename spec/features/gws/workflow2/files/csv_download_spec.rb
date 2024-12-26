require 'spec_helper'

describe Gws::Workflow2::FilesController, type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let(:now) { Time.zone.now.change(usec: 0) }
  let!(:admin) { gws_user }
  let!(:dest_group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:dest_user) { create :gws_user, group_ids: [ dest_group.id ], gws_role_ids: gws_user.gws_role_ids }
  let!(:approver_group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:approver_user) { create :gws_user, group_ids: [ approver_group.id ], gws_role_ids: gws_user.gws_role_ids }
  let!(:circulation_group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:circulation_user) { create :gws_user, group_ids: [ circulation_group.id ], gws_role_ids: gws_user.gws_role_ids }
  let!(:delegatee_group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:delegatee_user) { create :gws_user, group_ids: [ delegatee_group.id ], gws_role_ids: gws_user.gws_role_ids }
  let!(:form) do
    create(
      :gws_workflow2_form_application, state: "public", agent_state: "enabled",
      destination_group_ids: [ dest_group.id ], destination_user_ids: [ dest_user.id ]
    )
  end
  let!(:column1) { create(:gws_column_text_field, cur_site: site, cur_form: form, input_type: "text", order: 10) }
  let!(:column2) { create(:gws_column_file_upload, cur_site: site, cur_form: form, order: 20) }

  let(:column1_value) { unique_id }
  let!(:file1) { tmp_ss_file(basename: "file-#{unique_id}", contents: '0123456789', user: admin) }
  let!(:file2) { tmp_ss_file(basename: "file-#{unique_id}", contents: '0123456789', user: approver_user) }

  let!(:item1) do
    item = build(
      :gws_workflow2_file, cur_site: site, cur_user: admin, cur_form: form,
      column_values: [ column1.serialize_value(column1_value), column2.serialize_value([ file1.id ]) ],
      workflow_user_id: delegatee_user.id, workflow_agent_id: admin.id, workflow_state: "approve",
      workflow_comment: "comment-#{unique_id}", requested: now - 3.days,
      workflow_approvers: [
        {
          "level" => 1, "user_type" => "Gws::User", "user_id" => approver_user.id, state: "approve", comment: unique_id,
          file_ids: [ file2.id ], created: now - 2.days
        },
      ],
      workflow_required_counts: [ false ],
      workflow_circulations: [
        { "level" => 1, "user_id" => circulation_user.id, state: "seen", comment: "comment-#{unique_id}", created: now - 1.day },
      ],
      destination_group_ids: form.destination_group_ids, destination_user_ids: form.destination_user_ids,
      destination_treat_state: "treated"
    )
    item.update_workflow_user(site, delegatee_user)
    item.update_workflow_agent(site, admin)
    item.save!
    item.class.find(item.id)
  end

  before do
    clear_downloads
    login_gws_user
  end

  after { clear_downloads }

  context "csv download" do
    context "custom form file download" do
      it do
        visit gws_workflow2_files_path(site: site, state: "all")
        click_on item1.name
        wait_for_turbo_frame "#workflow-approver-frame"
        accept_confirm(I18n.t("ss.confirm.download")) do
          click_on I18n.t("gws/workflow.links.download_comment")
        end

        wait_for_download

        I18n.with_locale(I18n.default_locale) do
          SS::Csv.open(downloads.first) do |csv|
            csv_table = csv.read
            expect(csv_table.length).to eq 3
            expect(csv_table.headers[0]).to eq I18n.t("gws/workflow2.table.gws/workflow2/file.user_id")
            expect(csv_table.headers[1]).to eq I18n.t("gws/workflow2.table.gws/workflow2/file.user_name")
            expect(csv_table.headers[4]).to eq Gws::Workflow2::File.t(:name)
            expect(csv_table.headers[5]).to eq I18n.t("gws/workflow2.table.gws/workflow2/file.requested")
            expect(csv_table.headers[6]).to eq Gws::Workflow2::File.t(:workflow_comment)
            expect(csv_table.headers[7]).to eq I18n.t("workflow.csv.approvers_or_circulations")
            expect(csv_table.headers[12]).to eq Gws::Workflow2::File.t(:workflow_state)
            expect(csv_table.headers[13]).to eq Gws::Workflow2::File.t(:updated)
            expect(csv_table.headers[14]).to eq "#{form.name}/#{column1.name}"
            expect(csv_table.headers[15]).to eq "#{form.name}/#{column2.name}"
            expect(csv_table.headers[16]).to eq I18n.t("gws/workflow2.table.gws/workflow2/file.agent_id")
            expect(csv_table.headers[17]).to eq I18n.t("gws/workflow2.table.gws/workflow2/file.agent_name")
            csv_table[0].tap do |csv_row|
              expect(csv_row[0]).to eq delegatee_user.id.to_s
              expect(csv_row[1]).to eq delegatee_user.name
              expect(csv_row[4]).to eq item1.name
              expect(csv_row[5]).to eq item1.requested.strftime("%Y/%m/%d %H:%M")
              expect(csv_row[6]).to eq item1.workflow_comment
              expect(csv_row[7]).to be_blank
              expect(csv_row[8]).to be_blank
              expect(csv_row[9]).to be_blank
              expect(csv_row[10]).to be_blank
              expect(csv_row[11]).to be_blank
              expect(csv_row[12]).to eq I18n.t("workflow.state.#{item1.workflow_state}")
              expect(csv_row[13]).to eq I18n.l(item1.updated)
              expect(csv_row[14]).to eq column1_value
              expect(csv_row[15]).to eq file1.name
              expect(csv_row[16]).to eq admin.id.to_s
              expect(csv_row[17]).to eq admin.name
            end
            csv_table[1].tap do |csv_row|
              approver = item1.workflow_approvers.first
              expect(csv_row[0]).to be_blank
              expect(csv_row[1]).to be_blank
              expect(csv_row[4]).to be_blank
              expect(csv_row[5]).to be_blank
              expect(csv_row[6]).to be_blank
              expect(csv_row[7]).to eq I18n.t('mongoid.attributes.workflow/model/route.level', level: 1)
              expect(csv_row[8]).to eq I18n.t('workflow.required_count_label.all')
              expect(csv_row[9]).to eq "#{approver_user.long_name}(#{approver_user.email})"
              expect(csv_row[10]).to include I18n.t("workflow.state.approve")
              expect(csv_row[10]).to include (now - 2.days).strftime("%Y/%m/%d %H:%M")
              expect(csv_row[11]).to include approver[:comment]
              expect(csv_row[11]).to include file2.name
            end
            csv_table[2].tap do |csv_row|
              circulation = item1.workflow_circulations.first
              expect(csv_row[0]).to be_blank
              expect(csv_row[1]).to be_blank
              expect(csv_row[4]).to be_blank
              expect(csv_row[5]).to be_blank
              expect(csv_row[6]).to be_blank
              step_no = I18n.t('mongoid.attributes.workflow/model/route.level', level: 1)
              expect(csv_row[7]).to eq "#{I18n.t("workflow.circulation_step")} #{step_no}"
              expect(csv_row[8]).to be_blank
              expect(csv_row[9]).to eq "#{circulation_user.long_name}(#{circulation_user.email})"
              expect(csv_row[10]).to include I18n.t("workflow.circulation_state.seen")
              expect(csv_row[11]).to eq circulation[:comment]
            end
          end
        end
      end
    end

    context "all csv download" do
      it do
        visit gws_workflow2_files_path(site: site, state: "all")
        wait_event_to_fire("ss:checked-all-list-items") { find(".gws-workflow .list-head input[type=checkbox]").click }

        accept_confirm(I18n.t("ss.confirm.download")) do
          click_on I18n.t("ss.buttons.csv")
        end

        wait_for_download

        I18n.with_locale(I18n.default_locale) do
          SS::Csv.open(downloads.first) do |csv|
            csv_table = csv.read
            expect(csv_table.length).to eq 3
          end
        end
      end
    end
  end

  context "attachments download" do
    context "custom form file download" do
      it do
        visit gws_workflow2_files_path(site: site, state: "all")
        click_on item1.name
        wait_for_turbo_frame "#workflow-approver-frame"
        accept_confirm(I18n.t("ss.confirm.download")) do
          click_on I18n.t("gws/workflow.links.download_attachment")
        end

        wait_for_download

        entry_names = Zip::File.open(downloads.first) do |entries|
          entries.map { |entry| entry.name }
        end
        expect(entry_names).to have(2).items
        expect(entry_names).to include(file1.download_filename, file2.download_filename)
      end
    end

    context "all files download" do
      it do
        visit gws_workflow2_files_path(site: site, state: "all")
        wait_event_to_fire("ss:checked-all-list-items") { find(".gws-workflow .list-head input[type=checkbox]").click }

        accept_confirm(I18n.t("ss.confirm.download")) do
          click_on I18n.t("gws/survey.buttons.zip_all_files")
        end

        wait_for_download

        entry_names = Zip::File.open(downloads.first) do |entries|
          entries.map { |entry| entry.name }
        end
        expect(entry_names).to have(2).items
        expect(entry_names).to include(file1.download_filename, file2.download_filename)
      end
    end
  end
end
