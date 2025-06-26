require 'spec_helper'

describe Gws::Tabular::File::CsvImportJob, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:space) { create :gws_tabular_space, cur_site: site }
  let!(:category_form) do
    create :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1
  end
  let!(:category_state_column) do
    create(:gws_tabular_column_enum_field, cur_site: site, cur_form: category_form, order: 10, input_type: "radio")
  end
  # 2番目にユニークなテキスト型がある。これがIDに代わるCSV上の主キー。
  let!(:category_name_column) do
    create(
      :gws_tabular_column_text_field, cur_site: site, cur_form: category_form, order: 20,
      input_type: "single", max_length: nil, validation_type: "none", i18n_state: "enabled", unique_state: "enabled")
  end
  let!(:category_workflow_state_column) do
    create(:gws_tabular_column_enum_field, cur_site: site, cur_form: category_form, order: 20)
  end
  let!(:recycle_item_form) do
    create :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1
  end
  let!(:recycle_item_category_column) do
    create(
      :gws_tabular_column_reference_field, cur_site: site, cur_form: recycle_item_form, order: 20, required: 'optional',
      reference_form: category_form, reference_type: reference_type
    )
  end

  before do
    Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: user).perform_now(category_form.id.to_s)
    Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: user).perform_now(recycle_item_form.id.to_s)

    expect(Gws::Job::Log.count).to eq 2
    Gws::Job::Log.all.each do |log|
      expect(log.state).to eq Gws::Job::Log::STATE_COMPLETED
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
      expect(log.logs).not_to include(include('WARN'))
      expect(log.logs).not_to include(include('ERROR'))
    end

    category_form.reload
    category_form_release = category_form.current_release
    expect(category_form_release).to be_present

    recycle_item_form.reload
    recycle_item_form_release = recycle_item_form.current_release
    expect(recycle_item_form_release).to be_present
  end

  context "with gws/tabular/column/reference_field" do
    let!(:category_model) { Gws::Tabular::File[category_form.current_release] }
    let!(:category1_name_translations) { i18n_translations(prefix: "class") }
    let!(:category1) do
      category_file = category_model.new(cur_site: site, cur_space: space, cur_form: category_form)
      category_file.send("col_#{category_state_column.id}=", category_state_column.select_options.sample(1))
      category_file.send("col_#{category_name_column.id}_translations=", category1_name_translations)
      category_file.send("col_#{category_workflow_state_column.id}=", [ category_workflow_state_column.select_options.sample ])
      category_file.save!
      category_model.find(category_file.id)
    end
    let!(:category2_name_translations) { i18n_translations(prefix: "class") }
    let!(:category2) do
      category_file = category_model.new(cur_site: site, cur_space: space, cur_form: category_form)
      category_file.send("col_#{category_state_column.id}=", category_state_column.select_options.sample(1))
      category_file.send("col_#{category_name_column.id}_translations=", category2_name_translations)
      category_file.send("col_#{category_workflow_state_column.id}=", [ category_workflow_state_column.select_options.sample ])
      category_file.save!
      category_model.find(category_file.id)
    end
    let!(:recycle_item_model) { Gws::Tabular::File[recycle_item_form.current_release] }

    context "when reference_type is 'one_to_one'" do
      let(:reference_type) { "one_to_one" }

      context "with id and name joined with '_'" do
        let(:csv_filepath) do
          I18n.with_locale(I18n.default_locale) do
            tmpfile(extname: ".csv") do |file|
              headers = [ recycle_item_model.t(:id), recycle_item_category_column.name ]
              file.write SS::Csv::UTF8_BOM
              file.write headers.to_csv

              data_row = [ nil, "#{category1.id}_#{category1_name_translations[I18n.default_locale]}" ]
              file.write data_row.to_csv
            end
          end
        end
        let(:ss_csv_file) { tmp_ss_file(user: user, contents: csv_filepath) }

        it do
          job = described_class.bind(site_id: site, user_id: user)
          job.perform_now(space.id.to_s, recycle_item_form.id.to_s, recycle_item_form.current_release.id.to_s, ss_csv_file.id)

          expect(Gws::Job::Log.count).to eq 3
          Gws::Job::Log.all.each do |log|
            expect(log.state).to eq Gws::Job::Log::STATE_COMPLETED
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
            expect(log.logs).not_to include(include('WARN'))
            expect(log.logs).not_to include(include('ERROR'))
          end

          expect(recycle_item_model.all.count).to eq 1
          recycle_item_model.all.first.tap do |recycle_item|
            expect(recycle_item.site_id).to eq site.id
            expect(recycle_item.space_id.to_s).to eq space.id.to_s
            expect(recycle_item.form_id.to_s).to eq recycle_item_form.id.to_s
            recycle_item.read_tabular_value(recycle_item_category_column).tap do |criteria|
              expect(criteria.count).to eq 1
              imported = criteria.first
              expect(imported.class.name).to eq category1.class.name
              expect(imported.id).to eq category1.id
            end
          end
        end
      end

      context "with only id" do
        let(:csv_filepath) do
          I18n.with_locale(I18n.default_locale) do
            tmpfile(extname: ".csv") do |file|
              headers = [ recycle_item_model.t(:id), recycle_item_category_column.name ]
              file.write SS::Csv::UTF8_BOM
              file.write headers.to_csv

              data_row = [ nil, category1.id.to_s ]
              file.write data_row.to_csv
            end
          end
        end
        let(:ss_csv_file) { tmp_ss_file(user: user, contents: csv_filepath) }

        it do
          job = described_class.bind(site_id: site, user_id: user)
          job.perform_now(space.id.to_s, recycle_item_form.id.to_s, recycle_item_form.current_release.id.to_s, ss_csv_file.id)

          expect(Gws::Job::Log.count).to eq 3
          Gws::Job::Log.all.each do |log|
            expect(log.state).to eq Gws::Job::Log::STATE_COMPLETED
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
            expect(log.logs).not_to include(include('WARN'))
            expect(log.logs).not_to include(include('ERROR'))
          end

          expect(recycle_item_model.all.count).to eq 1
          recycle_item_model.all.first.tap do |recycle_item|
            expect(recycle_item.site_id).to eq site.id
            expect(recycle_item.space_id.to_s).to eq space.id.to_s
            expect(recycle_item.form_id.to_s).to eq recycle_item_form.id.to_s
            recycle_item.read_tabular_value(recycle_item_category_column).tap do |criteria|
              expect(criteria.count).to eq 1
              imported = criteria.first
              expect(imported.class.name).to eq category1.class.name
              expect(imported.id).to eq category1.id
            end
          end
        end
      end

      context "with name (ja)" do
        let(:csv_filepath) do
          I18n.with_locale(I18n.default_locale) do
            tmpfile(extname: ".csv") do |file|
              headers = [ recycle_item_model.t(:id), recycle_item_category_column.name ]
              file.write SS::Csv::UTF8_BOM
              file.write headers.to_csv

              data_row = [ nil, category1_name_translations[I18n.default_locale] ]
              file.write data_row.to_csv
            end
          end
        end
        let(:ss_csv_file) { tmp_ss_file(user: user, contents: csv_filepath) }

        it do
          job = described_class.bind(site_id: site, user_id: user)
          job.perform_now(space.id.to_s, recycle_item_form.id.to_s, recycle_item_form.current_release.id.to_s, ss_csv_file.id)

          expect(Gws::Job::Log.count).to eq 3
          Gws::Job::Log.all.each do |log|
            expect(log.state).to eq Gws::Job::Log::STATE_COMPLETED
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
            expect(log.logs).not_to include(include('WARN'))
            expect(log.logs).not_to include(include('ERROR'))
          end

          expect(recycle_item_model.all.count).to eq 1
          recycle_item_model.all.first.tap do |recycle_item|
            expect(recycle_item.site_id).to eq site.id
            expect(recycle_item.space_id.to_s).to eq space.id.to_s
            expect(recycle_item.form_id.to_s).to eq recycle_item_form.id.to_s
            recycle_item.read_tabular_value(recycle_item_category_column).tap do |criteria|
              expect(criteria.count).to eq 1
              imported = criteria.first
              expect(imported.class.name).to eq category1.class.name
              expect(imported.id).to eq category1.id
            end
          end
        end
      end

      context "with name (en)" do
        let(:csv_filepath) do
          I18n.with_locale(I18n.default_locale) do
            tmpfile(extname: ".csv") do |file|
              headers = [ recycle_item_model.t(:id), recycle_item_category_column.name ]
              file.write SS::Csv::UTF8_BOM
              file.write headers.to_csv

              alternative_locales = I18n.available_locales - [ I18n.default_locale ]
              alternative_locale = alternative_locales.sample
              data_row = [ nil, category1_name_translations[alternative_locale] ]
              file.write data_row.to_csv
            end
          end
        end
        let(:ss_csv_file) { tmp_ss_file(user: user, contents: csv_filepath) }

        it do
          job = described_class.bind(site_id: site, user_id: user)
          job.perform_now(space.id.to_s, recycle_item_form.id.to_s, recycle_item_form.current_release.id.to_s, ss_csv_file.id)

          expect(Gws::Job::Log.count).to eq 3
          Gws::Job::Log.all.each do |log|
            expect(log.state).to eq Gws::Job::Log::STATE_COMPLETED
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
            expect(log.logs).not_to include(include('WARN'))
            expect(log.logs).not_to include(include('ERROR'))
          end

          expect(recycle_item_model.all.count).to eq 1
          recycle_item_model.all.first.tap do |recycle_item|
            expect(recycle_item.site_id).to eq site.id
            expect(recycle_item.space_id.to_s).to eq space.id.to_s
            expect(recycle_item.form_id.to_s).to eq recycle_item_form.id.to_s
            recycle_item.read_tabular_value(recycle_item_category_column).tap do |criteria|
              expect(criteria.count).to eq 0
            end
          end
        end
      end
    end

    context "when reference_type is 'one_to_many'" do
      let(:reference_type) { "one_to_many" }

      context "with id and name joined with '_'" do
        let(:csv_filepath) do
          I18n.with_locale(I18n.default_locale) do
            tmpfile(extname: ".csv") do |file|
              headers = [ recycle_item_model.t(:id), recycle_item_category_column.name ]
              file.write SS::Csv::UTF8_BOM
              file.write headers.to_csv

              value = [
                [ category1.id, category1_name_translations[I18n.default_locale] ].join("_"),
                [ category2.id, category2_name_translations[I18n.default_locale] ].join("_")
              ].join("\n")
              data_row = [ nil, value ]
              file.write data_row.to_csv
            end
          end
        end
        let(:ss_csv_file) { tmp_ss_file(user: user, contents: csv_filepath) }

        it do
          job = described_class.bind(site_id: site, user_id: user)
          job.perform_now(space.id.to_s, recycle_item_form.id.to_s, recycle_item_form.current_release.id.to_s, ss_csv_file.id)

          expect(Gws::Job::Log.count).to eq 3
          Gws::Job::Log.all.each do |log|
            expect(log.state).to eq Gws::Job::Log::STATE_COMPLETED
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
            expect(log.logs).not_to include(include('WARN'))
            expect(log.logs).not_to include(include('ERROR'))
          end

          expect(recycle_item_model.all.count).to eq 1
          recycle_item_model.all.first.tap do |recycle_item|
            expect(recycle_item.site_id).to eq site.id
            expect(recycle_item.space_id.to_s).to eq space.id.to_s
            expect(recycle_item.form_id.to_s).to eq recycle_item_form.id.to_s
            recycle_item.read_tabular_value(recycle_item_category_column).tap do |criteria|
              expect(criteria.count).to eq 2
              expect(criteria.pluck(:id)).to match_array [ category1.id, category2.id ]
            end
          end
        end
      end

      context "with only id" do
        let(:csv_filepath) do
          I18n.with_locale(I18n.default_locale) do
            tmpfile(extname: ".csv") do |file|
              headers = [ recycle_item_model.t(:id), recycle_item_category_column.name ]
              file.write SS::Csv::UTF8_BOM
              file.write headers.to_csv

              data_row = [ nil, [ category1.id.to_s, category2.id.to_s ].join("\n") ]
              file.write data_row.to_csv
            end
          end
        end
        let(:ss_csv_file) { tmp_ss_file(user: user, contents: csv_filepath) }

        it do
          job = described_class.bind(site_id: site, user_id: user)
          job.perform_now(space.id.to_s, recycle_item_form.id.to_s, recycle_item_form.current_release.id.to_s, ss_csv_file.id)

          expect(Gws::Job::Log.count).to eq 3
          Gws::Job::Log.all.each do |log|
            expect(log.state).to eq Gws::Job::Log::STATE_COMPLETED
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
            expect(log.logs).not_to include(include('WARN'))
            expect(log.logs).not_to include(include('ERROR'))
          end

          expect(recycle_item_model.all.count).to eq 1
          recycle_item_model.all.first.tap do |recycle_item|
            expect(recycle_item.site_id).to eq site.id
            expect(recycle_item.space_id.to_s).to eq space.id.to_s
            expect(recycle_item.form_id.to_s).to eq recycle_item_form.id.to_s
            recycle_item.read_tabular_value(recycle_item_category_column).tap do |criteria|
              expect(criteria.count).to eq 2
              expect(criteria.pluck(:id)).to match_array [ category1.id, category2.id ]
            end
          end
        end
      end

      context "with name (ja)" do
        let(:csv_filepath) do
          I18n.with_locale(I18n.default_locale) do
            tmpfile(extname: ".csv") do |file|
              headers = [ recycle_item_model.t(:id), recycle_item_category_column.name ]
              file.write SS::Csv::UTF8_BOM
              file.write headers.to_csv

              values = [ category1_name_translations[I18n.default_locale], category2_name_translations[I18n.default_locale] ]
              data_row = [ nil, values.join("\n") ]
              file.write data_row.to_csv
            end
          end
        end
        let(:ss_csv_file) { tmp_ss_file(user: user, contents: csv_filepath) }

        it do
          job = described_class.bind(site_id: site, user_id: user)
          job.perform_now(space.id.to_s, recycle_item_form.id.to_s, recycle_item_form.current_release.id.to_s, ss_csv_file.id)

          expect(Gws::Job::Log.count).to eq 3
          Gws::Job::Log.all.each do |log|
            expect(log.state).to eq Gws::Job::Log::STATE_COMPLETED
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
            expect(log.logs).not_to include(include('WARN'))
            expect(log.logs).not_to include(include('ERROR'))
          end

          expect(recycle_item_model.all.count).to eq 1
          recycle_item_model.all.first.tap do |recycle_item|
            expect(recycle_item.site_id).to eq site.id
            expect(recycle_item.space_id.to_s).to eq space.id.to_s
            expect(recycle_item.form_id.to_s).to eq recycle_item_form.id.to_s
            recycle_item.read_tabular_value(recycle_item_category_column).tap do |criteria|
              expect(criteria.count).to eq 2
              expect(criteria.pluck(:id)).to match_array [ category1.id, category2.id ]
            end
          end
        end
      end

      context "with name (en)" do
        let(:csv_filepath) do
          I18n.with_locale(I18n.default_locale) do
            tmpfile(extname: ".csv") do |file|
              headers = [ recycle_item_model.t(:id), recycle_item_category_column.name ]
              file.write SS::Csv::UTF8_BOM
              file.write headers.to_csv

              alternative_locales = I18n.available_locales - [ I18n.default_locale ]
              alternative_locale = alternative_locales.sample
              values = [ category1_name_translations[alternative_locale], category2_name_translations[alternative_locale] ]
              data_row = [ nil, values.join("\n") ]
              file.write data_row.to_csv
            end
          end
        end
        let(:ss_csv_file) { tmp_ss_file(user: user, contents: csv_filepath) }

        it do
          job = described_class.bind(site_id: site, user_id: user)
          job.perform_now(space.id.to_s, recycle_item_form.id.to_s, recycle_item_form.current_release.id.to_s, ss_csv_file.id)

          expect(Gws::Job::Log.count).to eq 3
          Gws::Job::Log.all.each do |log|
            expect(log.state).to eq Gws::Job::Log::STATE_COMPLETED
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
            expect(log.logs).not_to include(include('WARN'))
            expect(log.logs).not_to include(include('ERROR'))
          end

          expect(recycle_item_model.all.count).to eq 1
          recycle_item_model.all.first.tap do |recycle_item|
            expect(recycle_item.site_id).to eq site.id
            expect(recycle_item.space_id.to_s).to eq space.id.to_s
            expect(recycle_item.form_id.to_s).to eq recycle_item_form.id.to_s
            recycle_item.read_tabular_value(recycle_item_category_column).tap do |criteria|
              expect(criteria.count).to eq 0
            end
          end
        end
      end
    end
  end
end
