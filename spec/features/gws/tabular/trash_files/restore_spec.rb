require 'spec_helper'

describe Gws::Tabular::TrashFilesController, type: :feature, dbscope: :example, js: true do
  let(:now) { Time.zone.now.change(sec: 0) }
  let!(:site) { gws_site }
  let!(:admin) { gws_user }

  let!(:space) { create :gws_tabular_space, cur_site: site, state: "public", readable_setting_range: "public" }
  let!(:form) do
    create :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1, workflow_state: 'disabled'
  end
  let!(:column1) do
    # title / name
    create(
      :gws_tabular_column_text_field, cur_site: site, cur_form: form, order: 10, required: "required",
      input_type: "single", validation_type: "none", i18n_state: "disabled", unique_state: "enabled")
  end
  let(:file1_name) { "file-#{unique_id}" }
  let(:file2_name) { "file-#{unique_id}" }

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

    form.reload
    model = Gws::Tabular::File[form.current_release]
    file1 = model.new(cur_site: site, cur_space: space, cur_form: form, cur_user: admin)
    file1.send("col_#{column1.id}=", file1_name)
    file1.save!

    file1.deleted = now
    file1.save!

    file2 = model.new(cur_site: site, cur_space: space, cur_form: form, cur_user: admin)
    file2.send("col_#{column1.id}=", file2_name)
    file2.save!

    file2.deleted = now
    file2.save!

    login_user admin
  end

  shared_examples "common restore spec" do
    it do
      visit gws_tabular_trash_files_path(site: site, space: space, form: form, view: view)
      expect(page).to have_css(".list-item", count: 2)
      click_on file1_name
      wait_for_all_turbo_frames
      page.accept_confirm I18n.t("ss.confirm.restore") do
        within ".gws-tabular-file-head" do
          click_on I18n.t("ss.buttons.restore")
        end
      end
      wait_for_all_turbo_frames
      wait_for_notice I18n.t("ss.notice.restored")
      expect(page).to have_css(".list-item", count: 1)

      model = Gws::Tabular::File[form.current_release]
      model.find_by("col_#{column1.id}" => file1_name).tap do |file|
        expect(file.deleted).to be_blank
      end
    end
  end

  context "without any views" do
    let(:view) { "-" }

    include_examples "common restore spec"
  end

  context "with list view" do
    let!(:list_view) do
      create(
        :gws_tabular_view_list, :gws_tabular_view_editable,
        cur_site: site, cur_space: space, cur_form: form, state: 'public', title_column_ids: [ column1.id ])
    end
    let(:view) { list_view }

    include_examples "common restore spec"
  end

  context "with liquid view" do
    let!(:liquid_view) do
      create(
        :gws_tabular_view_liquid, :gws_tabular_view_editable,
        cur_site: site, cur_space: space, cur_form: form, state: 'public')
    end
    let(:view) { liquid_view }

    include_examples "common restore spec"
  end
end
