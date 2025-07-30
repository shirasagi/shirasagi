require 'spec_helper'

describe Gws::Tabular::FilesController, type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:admin) { gws_user }

  let!(:permissions) { %w(use_gws_tabular read_gws_tabular_files edit_gws_tabular_files) }
  let!(:role) { create :gws_role, cur_site: site, permissions: permissions }
  let!(:user1) { create :gws_user, :gws_tabular_notice, group_ids: admin.group_ids, gws_role_ids: [ role.id ] }

  let!(:space) { create :gws_tabular_space, cur_site: site, cur_user: admin, state: "public", readable_setting_range: "public" }
  let!(:form) do
    create(
      :gws_tabular_form, cur_site: site, cur_space: space, cur_user: admin, state: 'publishing', revision: 1,
      workflow_state: 'disabled', readable_setting_range: "public"
    )
  end
  let!(:column1) do
    create(
      :gws_tabular_column_text_field, cur_site: site, cur_form: form, order: 10, required: "required",
      name: "name", input_type: "single", validation_type: "none", i18n_state: "disabled")
  end

  before do
    site.path_id = unique_id
    site.canonical_scheme = %w(http https).sample
    site.canonical_domain = "#{unique_id}.example.jp"
    site.save!

    ActionMailer::Base.deliveries.clear

    Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: admin).perform_now(form.id.to_s)

    expect(Gws::Job::Log.count).to eq 1
    Gws::Job::Log.all.each do |log|
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
    end
  end

  context "pagination" do
    let(:file_model) { Gws::Tabular::File[form.current_release] }
    let!(:file_item1) do
      file_model.create!(
        cur_user: user1, cur_site: site, cur_space: space, cur_form: form, "col_#{column1.id}" => "name-#{unique_id}")
    end
    let!(:file_item2) do
      file_model.create!(
        cur_user: user1, cur_site: site, cur_space: space, cur_form: form, "col_#{column1.id}" => "name-#{unique_id}")
    end
    let!(:file_item3) do
      file_model.create!(
        cur_user: user1, cur_site: site, cur_space: space, cur_form: form, "col_#{column1.id}" => "name-#{unique_id}")
    end
    let!(:file_item4) do
      file_model.create!(
        cur_user: user1, cur_site: site, cur_space: space, cur_form: form, "col_#{column1.id}" => "name-#{unique_id}")
    end

    let!(:view) do
      create(
        :gws_tabular_view_liquid_with_pagination, :gws_tabular_view_readonly,
        cur_site: site, cur_space: space, cur_form: form, state: "public", order: form.order, default_state: "enabled",
        limit_count: 3)
    end

    it do
      login_user user1, to: gws_tabular_files_path(site: site, space: space, form: form, view: view)
      within ".list" do
        expect(page).to have_css(".list-item", count: 3)
      end
      within ".pagination.upper" do
        expect(page).to have_css(".page", count: 2)
        expect(page).to have_css(".next", count: 1)
        expect(page).to have_css(".last", count: 1)
      end
      within ".pagination.lower" do
        expect(page).to have_css(".page", count: 2)
        expect(page).to have_css(".next", count: 1)
        expect(page).to have_css(".last", count: 1)
      end

      within ".pagination.upper" do
        click_on "2"
      end
      within ".list" do
        expect(page).to have_css(".list-item", count: 1)
      end
      within ".pagination.upper" do
        expect(page).to have_css(".page", count: 2)
        expect(page).to have_css(".first", count: 1)
        expect(page).to have_css(".prev", count: 1)
      end
      within ".pagination.lower" do
        expect(page).to have_css(".page", count: 2)
        expect(page).to have_css(".first", count: 1)
        expect(page).to have_css(".prev", count: 1)
      end
    end
  end
end
