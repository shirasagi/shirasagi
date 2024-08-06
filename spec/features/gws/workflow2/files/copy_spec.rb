require 'spec_helper'

describe Gws::Workflow2::FilesController, type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:dest_group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:dest_group2) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:dest_user1) { create :gws_user, group_ids: [ dest_group1.id ], gws_role_ids: gws_user.gws_role_ids }
  let!(:dest_user2) { create :gws_user, group_ids: [ dest_group2.id ], gws_role_ids: gws_user.gws_role_ids }
  let!(:form) do
    create(
      :gws_workflow2_form_application, cur_site: site, state: "public",
      destination_group_ids: [ dest_group1.id ], destination_user_ids: [ dest_user1.id ]
    )
  end
  # let!(:column1) { create(:gws_column_text_field, cur_site: site, form: form, input_type: "text") }
  let!(:column2) { create(:gws_column_file_upload, cur_site: site, cur_form: form, upload_file_count: 1) }
  let(:now) { Time.zone.now.change(sec: 0) }

  before do
    login_gws_user
  end

  context "with standard form" do
    describe "ss-2579" do
      it do
        visit gws_workflow2_files_path(site: site, state: "all")
        within ".nav-menu" do
          click_link I18n.t('gws/workflow2.navi.find_by_keyword')
        end
        within ".gws-workflow-select-forms-table" do
          click_on form.name
        end

        within "form#item-form" do
          within "#addon-gws-agents-addons-workflow2-custom_form" do
            wait_for_cbox_opened do
              click_on I18n.t("ss.buttons.upload")
            end
          end
        end
        within_cbox do
          attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/logo.png"
          wait_for_cbox_closed do
            click_on I18n.t("ss.buttons.attach")
          end
        end
        within "form#item-form" do
          expect(page).to have_content("logo")
          click_on I18n.t("gws/workflow2.buttons.save_and_apply")
        end
        wait_for_notice I18n.t('ss.notice.saved')

        expect(page).to have_css(".fileview .filename", text: "logo")
        within ".mod-workflow-request" do
          expect(page).to have_css(".workflow_approvers", text: I18n.t("gws/workflow2.errors.messages.superior_is_not_found"))
        end

        expect(Gws::Workflow2::File.all.count).to eq 1
        source_file = Gws::Workflow2::File.all.first
        form_name = [ form.name, now.strftime("%Y%m%d"), form.current_style_sequence ].join("_")
        expect(source_file.name).to eq form_name
        expect(source_file.destination_group_ids).to eq [ dest_group1.id ]
        expect(source_file.destination_user_ids).to eq [ dest_user1.id ]
        expect(source_file.destination_treat_state).to eq "untreated"
        expect(source_file.column_values.first.files.count).to eq 1
        source_file_attchment = source_file.column_values.first.files.first
        expect(source_file_attchment.name).to eq "logo.png"
        expect(source_file_attchment.filename).to eq "logo.png"
        expect(source_file_attchment.site_id).to be_blank
        expect(source_file_attchment.model).to eq "Gws::Workflow2::File"
        expect(source_file_attchment.owner_item_id).to eq source_file.id
        expect(source_file_attchment.owner_item_type).to eq source_file.class.name

        # フォームの提出先を変更する
        form.update(destination_group_ids: [ dest_group2.id ], destination_user_ids: [ dest_user2.id ])

        visit gws_workflow2_files_path(site: site, state: "all")
        click_on source_file.name
        within ".mod-workflow-request" do
          expect(page).to have_css(".workflow_approvers", text: I18n.t("gws/workflow2.errors.messages.superior_is_not_found"))
        end
        click_on I18n.t("ss.links.copy")
        within "form#item-form" do
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice(/#{I18n.t("gws/workflow2.notice.copy_created", name: ".*")}/)

        expect(page).to have_css(".fileview .filename", text: "logo")
        within ".mod-workflow-request" do
          expect(page).to have_css(".workflow_approvers", text: I18n.t("gws/workflow2.errors.messages.superior_is_not_found"))
        end

        expect(Gws::Workflow2::File.site(site).count).to eq 2
        copy_file = Gws::Workflow2::File.all.ne(id: source_file.id).first
        form_name = [ form.name, now.strftime("%Y%m%d"), form.current_style_sequence ].join("_")
        expect(copy_file.name).to eq form_name
        expect(copy_file.destination_group_ids).to eq [ dest_group2.id ]
        expect(copy_file.destination_user_ids).to eq [ dest_user2.id ]
        expect(copy_file.destination_treat_state).to eq "untreated"
        expect(copy_file.column_values.first.files.count).to eq 1
        copy_file_attchment = copy_file.column_values.first.files.first
        expect(copy_file_attchment.id).not_to eq source_file_attchment.id
        expect(copy_file_attchment.name).to eq source_file_attchment.name
        expect(copy_file_attchment.filename).to eq source_file_attchment.filename
        expect(copy_file_attchment.size).to eq source_file_attchment.size
        expect(copy_file_attchment.site_id).to be_blank
        expect(copy_file_attchment.model).to eq "Gws::Workflow2::File"
        expect(copy_file_attchment.owner_item_id).to eq copy_file.id
        expect(copy_file_attchment.owner_item_type).to eq copy_file.class.name
      end
    end
  end
end
