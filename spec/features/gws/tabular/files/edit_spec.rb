require 'spec_helper'

describe Gws::Tabular::FilesController, type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:admin) { gws_user }

  let!(:permissions) { %w(read_gws_organization use_gws_tabular read_gws_tabular_files edit_gws_tabular_files) }
  let!(:role) { create :gws_role, cur_site: site, permissions: permissions }
  let!(:user1) { create :gws_user, group_ids: admin.group_ids, gws_role_ids: [ role.id ] }
  let!(:user2) { create :gws_user, group_ids: admin.group_ids, gws_role_ids: [ role.id ] }

  let!(:space) { create :gws_tabular_space, cur_site: site, cur_user: admin, state: "public", readable_setting_range: "public" }
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

  before do
    Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: admin).perform_now(form.id.to_s)

    expect(Gws::Job::Log.count).to eq 1
    Gws::Job::Log.all.each do |log|
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
    end
  end

  context "edit" do
    let(:column1_value1) { unique_id }
    let(:column1_value2) { unique_id }

    it do
      #
      # first, user1 operates
      #
      login_user user1

      visit gws_tabular_files_path(site: site, space: space, form: form, view: '-')
      click_on I18n.t("ss.links.new")
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
        end
      end

      #
      # second, user2 operates on the item user1 created
      #
      login_user user2

      visit gws_tabular_files_path(site: site, space: space, form: form, view: '-')
      click_on column1_value1
      click_on I18n.t("ss.links.edit")
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
        end
      end
    end
  end
end
