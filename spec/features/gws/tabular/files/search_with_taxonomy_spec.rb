require 'spec_helper'

# 検索ボックス右レール（タクソノミー）で一覧を絞り込む
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
  let(:select_options) { %w(alpha bravo charlie) }
  let!(:name_column) do
    create(
      :gws_tabular_column_text_field, cur_site: site, cur_form: form, order: 10, required: "required",
      name: "name", input_type: "single", validation_type: "none", i18n_state: "disabled", unique_state: "enabled")
  end
  let!(:enum_column) do
    create(
      :gws_tabular_column_enum_field, cur_site: site, cur_form: form, order: 20, required: "optional",
      name: "category", select_options: select_options, input_type: "checkbox", index_state: 'asc')
  end

  before do
    site.path_id = unique_id
    site.canonical_scheme = %w(http https).sample
    site.canonical_domain = "#{unique_id}.example.jp"
    site.save!

    Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: admin).perform_now(form.id.to_s)

    expect(Gws::Job::Log.count).to eq 1
    Gws::Job::Log.all.each do |log|
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
    end
    form.reload
  end

  context "filter by enum (category) checkbox" do
    let(:file_model) { Gws::Tabular::File[form.current_release] }
    let(:name_a) { "apple-#{unique_id}" }
    let(:name_b) { "banana-#{unique_id}" }
    let(:name_c) { "cherry-#{unique_id}" }
    let!(:file_a) do
      file_model.create!(
        cur_user: user1, cur_site: site, cur_space: space, cur_form: form,
        "col_#{name_column.id}" => name_a, "col_#{enum_column.id}" => %w(alpha))
    end
    let!(:file_b) do
      file_model.create!(
        cur_user: user1, cur_site: site, cur_space: space, cur_form: form,
        "col_#{name_column.id}" => name_b, "col_#{enum_column.id}" => %w(bravo))
    end
    let!(:file_c) do
      file_model.create!(
        cur_user: user1, cur_site: site, cur_space: space, cur_form: form,
        "col_#{name_column.id}" => name_c, "col_#{enum_column.id}" => %w(alpha))
    end

    it do
      login_user user1, to: gws_tabular_files_path(site: site, space: space, form: form, view: "-")
      wait_for_js_ready

      within ".list-items" do
        expect(page).to have_css(".list-item", count: 3)
      end

      expect(page).to have_css(".gws-tabular-file-index-rail")

      within ".gws-tabular-file-index-rail" do
        within ".gws-tabular-file-search-section[data-column-id='#{enum_column.id}']" do
          find(".gws-tabular-file-search-option label", text: "alpha").click
        end
        click_on I18n.t("ss.buttons.search")
      end
      wait_for_js_ready

      within ".list-items" do
        expect(page).to have_css(".list-item", count: 2)
        expect(page).to have_content(name_a)
        expect(page).to have_content(name_c)
        expect(page).to have_no_content(name_b)
      end
    end
  end
end
