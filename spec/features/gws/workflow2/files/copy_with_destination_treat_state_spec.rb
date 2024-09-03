require 'spec_helper'

describe Gws::Workflow2::FilesController, type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:dest_group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  # let!(:dest_group2) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:dest_user1) { create :gws_user, group_ids: [ dest_group1.id ], gws_role_ids: gws_user.gws_role_ids }
  # let!(:dest_user2) { create :gws_user, group_ids: [ dest_group2.id ], gws_role_ids: gws_user.gws_role_ids }
  let!(:approver_group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:approver_user) { create :gws_user, group_ids: [ approver_group.id ], gws_role_ids: gws_user.gws_role_ids }
  let!(:form) do
    create(
      :gws_workflow2_form_application, cur_site: site, state: "public",
      destination_group_ids: [ dest_group1.id ], destination_user_ids: [ dest_user1.id ]
    )
  end
  let!(:column1) { create(:gws_column_text_field, cur_site: site, form: form, input_type: "text") }
  # let!(:column2) { create(:gws_column_file_upload, cur_site: site, cur_form: form, upload_file_count: 1) }
  let(:now) { Time.zone.now.change(sec: 0) }

  let!(:item) do
    create(
      :gws_workflow2_file, cur_site: site, cur_user: gws_user, form: form, column_values: [ column1.serialize_value(unique_id) ],
      workflow_user_id: gws_user.id, workflow_state: "approve", workflow_required_counts: [ false ],
      workflow_approvers: [
        { "level" => 1, "user_type" => "Gws::User", "user_id" => approver_user.id, state: "approve", comment: unique_id },
      ],
      destination_group_ids: form.destination_group_ids, destination_user_ids: form.destination_user_ids,
      destination_treat_state: "treated"
    )
  end

  before do
    login_gws_user
  end

  context "with acive distination users / groups" do
    it do
      visit gws_workflow2_files_path(site: site, state: "all")
      click_on item.name
      within ".mod-workflow-view" do
        within ".workflow_state" do
          expect(page).to have_content(I18n.t("workflow.state.approve"))
        end
      end
      click_on I18n.t("ss.links.copy")
      within "form#item-form" do
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice(/#{I18n.t("gws/workflow2.notice.copy_created", name: ".*")}/)

      within ".mod-workflow-request" do
        expect(page).to have_css(".workflow_approvers", text: I18n.t("gws/workflow2.errors.messages.superior_is_not_found"))
      end

      expect(Gws::Workflow2::File.site(site).count).to eq 2
      copy_item = Gws::Workflow2::File.all.ne(id: item.id).first
      form_name = [ form.name, now.strftime("%Y%m%d"), form.current_style_sequence ].join("_")
      expect(copy_item.name).to eq form_name
      expect(copy_item.destination_group_ids).to eq [ dest_group1.id ]
      expect(copy_item.destination_user_ids).to eq [ dest_user1.id ]
      expect(copy_item.destination_treat_state).to eq "untreated"
    end
  end

  context "with inactive destination users / groups" do
    before do
      dest_group1.expiration_date = now - 1.day
      dest_group1.save!
      dest_user1.account_expiration_date = now - 1.day
      dest_user1.save!
    end

    it do
      visit gws_workflow2_files_path(site: site, state: "all")
      click_on item.name
      within ".mod-workflow-view" do
        within ".workflow_state" do
          expect(page).to have_content(I18n.t("workflow.state.approve"))
        end
      end
      click_on I18n.t("ss.links.copy")
      within "form#item-form" do
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice(/#{I18n.t("gws/workflow2.notice.copy_created", name: ".*")}/)

      within ".mod-workflow-request" do
        expect(page).to have_css(".workflow_approvers", text: I18n.t("gws/workflow2.errors.messages.superior_is_not_found"))
      end

      expect(Gws::Workflow2::File.site(site).count).to eq 2
      copy_item = Gws::Workflow2::File.all.ne(id: item.id).first
      form_name = [ form.name, now.strftime("%Y%m%d"), form.current_style_sequence ].join("_")
      expect(copy_item.name).to eq form_name
      expect(copy_item.destination_group_ids).to eq [ dest_group1.id ]
      expect(copy_item.destination_user_ids).to eq [ dest_user1.id ]
      expect(copy_item.destination_treat_state).to eq "no_need_to_treat"
    end
  end
end
