require 'spec_helper'

describe Gws::Tabular::FilesController, type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:admin) { gws_user }

  let!(:permissions) do
    %w(use_gws_tabular read_gws_tabular_files edit_gws_tabular_files delete_gws_tabular_files)
  end
  let!(:role) { create :gws_role, cur_site: site, permissions: permissions }
  let!(:user1) { create :gws_user, group_ids: admin.group_ids, gws_role_ids: [ role.id ] }
  let!(:user2) { create :gws_user, group_ids: admin.group_ids, gws_role_ids: [ role.id ] }

  let!(:space) do
    create :gws_tabular_space, cur_site: site, cur_user: admin, state: "public", readable_setting_range: "public"
  end
  let!(:form) do
    create(
      :gws_tabular_form, cur_site: site, cur_space: space, cur_user: admin, state: 'publishing', revision: 1,
      workflow_state: 'disabled', readable_setting_range: "public"
    )
  end
  let!(:column1) do
    create(
      :gws_tabular_column_text_field, cur_site: site, cur_form: form, order: 10,
      input_type: "single", validation_type: "none", i18n_state: "disabled")
  end

  let!(:editable_view) do
    create(
      :gws_tabular_view_list, :gws_tabular_view_editable,
      cur_site: site, cur_space: space, cur_form: form, state: 'public', title_column_ids: [ column1.id ])
  end
  let!(:readonly_view) do
    create(
      :gws_tabular_view_list, :gws_tabular_view_readonly,
      cur_site: site, cur_space: space, cur_form: form, state: 'public', title_column_ids: [ column1.id ])
  end

  before do
    Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: admin).perform_now(form.id.to_s)

    expect(Gws::Job::Log.count).to eq 1
    Gws::Job::Log.all.each do |log|
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
    end
  end

  context "crud with editable view" do
    let(:column1_value1) { unique_id }
    let(:column1_value2) { unique_id }

    it do
      #
      # first, user1 creates a file
      #
      login_user user1
      visit gws_tabular_files_path(site: site, space: space, form: form, view: editable_view)
      wait_for_all_turbo_frames
      within ".current-navi" do
        within "h3.current" do
          expect(page).to have_css("[title='#{editable_view.i18n_name}']", text: editable_view.i18n_name)
          expect(page).to have_css("[title='#{I18n.t("ss.navi.trash")}']", text: "delete")
        end
      end
      within ".nav-menu" do
        expect(page).to have_link(I18n.t("ss.links.new"))
        click_on I18n.t("ss.links.new")
      end
      wait_for_all_turbo_frames
      within "form#item-form" do
        fill_in "item[col_#{column1.id}]", with: column1_value1

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      Gws::Tabular::File[form.current_release].tap do |file_model|
        expect(file_model.all.count).to eq 1
        file_model.all.first.tap do |file|
          expect(file.site_id).to eq site.id
          expect(file.user_id).to eq user1.id
          expect(file.space_id).to eq space.id
          expect(file.form_id).to eq form.id
          expect(file.read_tabular_value(column1)).to eq column1_value1
          expect(file.deleted).to be_blank
        end
      end

      #
      # second, user2 edits a file created by user1
      #
      login_user user2
      visit gws_tabular_files_path(site: site, space: space, form: form, view: editable_view)
      wait_for_all_turbo_frames
      within ".current-navi" do
        within "h3.current" do
          expect(page).to have_css("[title='#{editable_view.i18n_name}']", text: editable_view.i18n_name)
          expect(page).to have_css("[title='#{I18n.t("ss.navi.trash")}']", text: "delete")
        end
      end
      click_on column1_value1
      within ".nav-menu" do
        expect(page).to have_link(I18n.t("ss.links.edit"))
        click_on I18n.t("ss.links.edit")
      end
      within "form#item-form" do
        fill_in "item[col_#{column1.id}]", with: column1_value2

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      Gws::Tabular::File[form.current_release].tap do |file_model|
        expect(file_model.all.count).to eq 1
        file_model.all.first.tap do |file|
          expect(file.site_id).to eq site.id
          expect(file.user_id).to eq user1.id
          expect(file.space_id).to eq space.id
          expect(file.form_id).to eq form.id
          expect(file.read_tabular_value(column1)).to eq column1_value2
          expect(file.deleted).to be_blank
        end
      end

      #
      # third, user1 deletes a file created by himself
      #
      login_user user1
      visit gws_tabular_files_path(site: site, space: space, form: form, view: editable_view)
      click_on column1_value2
      within ".gws-tabular-file-head" do
        page.accept_confirm(I18n.t("ss.confirm.delete")) { click_on "delete" }
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      Gws::Tabular::File[form.current_release].tap do |file_model|
        expect(file_model.all.count).to eq 1
        file_model.all.first.tap do |file|
          expect(file.site_id).to eq site.id
          expect(file.user_id).to eq user1.id
          expect(file.space_id).to eq space.id
          expect(file.form_id).to eq form.id
          expect(file.read_tabular_value(column1)).to eq column1_value2
          expect(file.deleted.in_time_zone).to be_within(30.seconds).of(Time.zone.now)
        end
      end

      #
      # finally, user2 completely deletes a file created by himself
      #
      login_user user2
      visit gws_tabular_files_path(site: site, space: space, form: form, view: editable_view)
      wait_for_all_turbo_frames
      within ".current-navi" do
        within "h3.current" do
          expect(page).to have_css("[title='#{editable_view.i18n_name}']", text: editable_view.i18n_name)
          expect(page).to have_css("[title='#{I18n.t("ss.navi.trash")}']", text: "delete")
          click_on "delete"
        end
      end
      click_on column1_value2
      within ".gws-tabular-file-head" do
        page.accept_confirm(I18n.t("ss.confirm.delete")) { click_on "delete" }
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      Gws::Tabular::File[form.current_release].tap do |file_model|
        expect(file_model.all.count).to eq 0
      end
    end
  end

  context "crud with readonly view" do
    let(:column1_value) { unique_id }
    # let(:column1_value1) { unique_id }
    # let(:column1_value2) { unique_id }

    it do
      # user1 is unable to create a file with read only view
      login_user user1
      visit gws_tabular_files_path(site: site, space: space, form: form, view: readonly_view)
      wait_for_all_turbo_frames
      within ".current-navi" do
        within "h3.current" do
          expect(page).to have_css("[title='#{readonly_view.i18n_name}']", text: readonly_view.i18n_name)
          expect(page).to have_no_css("[title='#{I18n.t("ss.navi.trash")}']")
        end
      end
      within ".nav-menu" do
        expect(page).to have_no_link(I18n.t("ss.links.new"))
      end
      # user1 try to directly access new view
      visit new_gws_tabular_file_path(site: site, space: space, form: form, view: readonly_view)
      expect(page).to have_title("404 Not Found")

      # create a file
      file_model = Gws::Tabular::File[form.current_release]
      file_item = file_model.new(cur_site: site, cur_space: space, cur_form: form)
      file_item.send("col_#{column1.id}=", column1_value)
      file_item.save!

      #
      # user2 is unable to edit a file with read only view
      #
      login_user user2
      visit gws_tabular_files_path(site: site, space: space, form: form, view: readonly_view)
      click_on column1_value
      wait_for_all_turbo_frames
      within ".nav-menu" do
        expect(page).to have_link(I18n.t("ss.links.back_to_index"))
        expect(page).to have_no_link(I18n.t("ss.links.edit"))
      end

      # user2 try to directly access edit view
      visit edit_gws_tabular_file_path(site: site, space: space, form: form, view: readonly_view, id: file_item)
      expect(page).to have_title("404 Not Found")

      #
      # user1 is unable to copy and unable to delete a file with read only view
      #
      login_user user1
      visit gws_tabular_files_path(site: site, space: space, form: form, view: readonly_view)
      click_on column1_value
      wait_for_all_turbo_frames
      expect(page).to have_no_css(".gws-tabular-file-head")

      # user2 try to directly access copy view
      visit copy_gws_tabular_file_path(site: site, space: space, form: form, view: readonly_view, id: file_item)
      expect(page).to have_title("404 Not Found")
    end
  end
end
