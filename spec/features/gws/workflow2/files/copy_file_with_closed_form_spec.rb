require 'spec_helper'

describe Gws::Workflow2::FilesController, type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:dest_group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:dest_group2) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:dest_user1) { create :gws_user, group_ids: [ dest_group1.id ], gws_role_ids: gws_user.gws_role_ids }
  let!(:dest_user2) { create :gws_user, group_ids: [ dest_group2.id ], gws_role_ids: gws_user.gws_role_ids }
  let!(:approver_group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:approver_user) { create :gws_user, group_ids: [ approver_group.id ], gws_role_ids: gws_user.gws_role_ids }

  let!(:form) do
    create(
      :gws_workflow2_form_application, cur_site: site, state: "public",
      destination_group_ids: [ dest_group1.id ], destination_user_ids: [ dest_user1.id ]
    )
  end
  let!(:column1) { create(:gws_column_text_field, cur_site: site, form: form, input_type: "text", required: "optional") }
  let!(:column2) { create(:gws_column_file_upload, cur_site: site, cur_form: form, upload_file_count: 1, required: "optional") }

  let!(:item) do
    file = tmp_ss_file(contents: '0123456789', user: gws_user)
    create(
      :gws_workflow2_file, cur_site: site, cur_user: gws_user, form: form,
      column_values: [ column1.serialize_value(unique_id), column2.serialize_value([ file.id ]) ],
      workflow_user_id: gws_user.id, workflow_state: "approve", workflow_required_counts: [ false ],
      workflow_approvers: [
        { "level" => 1, "user_type" => "Gws::User", "user_id" => approver_user.id, state: "approve", comment: unique_id },
      ],
      destination_group_ids: form.destination_group_ids, destination_user_ids: form.destination_user_ids,
      destination_treat_state: "treated"
    )
  end

  before do
    gws_user.groups.first.update!(superior_user_ids: [ approver_user.id ])
    login_gws_user
  end

  describe "copy file with closed form" do
    let(:workflow_comment) { "workflow_comment-#{unique_id}" }

    it do
      # first, close form
      visit gws_workflow2_form_forms_path(site: site)
      click_on form.name
      within ".nav-menu" do
        click_on I18n.t("gws/workflow.links.depublish")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.depublished")

      # second, copy file
      visit gws_workflow2_files_path(site: site, state: "all")
      click_on item.name
      within ".nav-menu" do
        click_on I18n.t("ss.links.copy")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice(/#{I18n.t("gws/workflow2.notice.copy_created", name: ".+")}/)

      # third, try to apply it
      expect(Gws::Workflow2::File.site(site).count).to eq 2
      copy_item = Gws::Workflow2::File.all.ne(id: item.id).first
      expect(page).to have_content(copy_item.name)
      # visit gws_workflow2_files_path(site: site, state: "all")
      # click_on copy_item.name
      within ".mod-workflow-request" do
        expect(page).to have_css(".workflow_approvers", text: approver_user.name)

        # コメントだけ入力し、申請する
        fill_in "item[workflow_comment]", with: workflow_comment

        click_on I18n.t("workflow.buttons.request")
      end
      wait_for_error I18n.t("errors.messages.unable_to_request_due_to_closed_form")
    end
  end
end
