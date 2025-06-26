require 'spec_helper'

describe Gws::Tabular::File, type: :model, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:space) { create :gws_tabular_space, cur_site: site }
  let!(:form) { create :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1 }
  let!(:column1) do
    create(
      :gws_tabular_column_number_field, cur_site: site, cur_form: form, required: 'optional',
      field_type: field_type, min_value: nil, max_value: nil, default_value: nil)
  end

  before do
    Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: user).perform_now(form.id.to_s)

    expect(Gws::Job::Log.count).to eq 1
    Gws::Job::Log.all.each do |log|
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
    end

    form.reload
    release = form.current_release
    expect(release).to be_present
  end

  context "field_type is integer" do
    let(:field_type) { "integer" }

    context "with actual value" do
      let(:file_model) { Gws::Tabular::File[form.current_release] }
      let(:int_value) { 17 }
      let!(:file_data) do
        file_model.create!(cur_site: site, cur_user: user, cur_space: space, cur_form: form, "col_#{column1.id}" => int_value)
      end

      it do
        text = file_data.read_csv_value(column1)
        expect(text).to eq "17"
      end
    end

    context "with nil value" do
      let(:file_model) { Gws::Tabular::File[form.current_release] }
      let!(:file_data) do
        file_model.create!(cur_site: site, cur_user: user, cur_space: space, cur_form: form)
      end

      it do
        text = file_data.read_csv_value(column1)
        expect(text).to be_blank
      end
    end
  end

  context "field_type is float" do
    let(:field_type) { "float" }

    context "with decimal place 0" do
      let(:file_model) { Gws::Tabular::File[form.current_release] }
      let(:float_value) { 10.0 }
      let!(:file_data) do
        file_model.create!(cur_site: site, cur_user: user, cur_space: space, cur_form: form, "col_#{column1.id}" => float_value)
      end

      it do
        text = file_data.read_csv_value(column1)
        expect(text).to eq "10.0"
      end
    end

    context "with decimal place not 0" do
      let(:file_model) { Gws::Tabular::File[form.current_release] }
      let(:float_value) { 3.14 }
      let!(:file_data) do
        file_model.create!(cur_site: site, cur_user: user, cur_space: space, cur_form: form, "col_#{column1.id}" => float_value)
      end

      it do
        text = file_data.read_csv_value(column1)
        expect(text).to eq "3.14"
      end
    end

    context "with nil value" do
      let(:file_model) { Gws::Tabular::File[form.current_release] }
      let!(:file_data) do
        file_model.create!(cur_site: site, cur_user: user, cur_space: space, cur_form: form)
      end

      it do
        text = file_data.read_csv_value(column1)
        expect(text).to be_blank
      end
    end
  end

  context "field_type is decimal" do
    let(:field_type) { "decimal" }

    context "with decimal place 0" do
      let(:file_model) { Gws::Tabular::File[form.current_release] }
      let(:decimal_value) { BigDecimal("10") }
      let!(:file_data) do
        file_model.create!(cur_site: site, cur_user: user, cur_space: space, cur_form: form, "col_#{column1.id}" => decimal_value)
      end

      it do
        text = file_data.read_csv_value(column1)
        expect(text).to eq "10.0"
      end
    end

    context "with decimal place not 0" do
      let(:file_model) { Gws::Tabular::File[form.current_release] }
      let(:decimal_value) { BigDecimal("3.14") }
      let!(:file_data) do
        file_model.create!(cur_site: site, cur_user: user, cur_space: space, cur_form: form, "col_#{column1.id}" => decimal_value)
      end

      it do
        text = file_data.read_csv_value(column1)
        expect(text).to eq "3.14"
      end
    end

    context "with nil value" do
      let(:file_model) { Gws::Tabular::File[form.current_release] }
      let!(:file_data) do
        file_model.create!(cur_site: site, cur_user: user, cur_space: space, cur_form: form)
      end

      it do
        text = file_data.read_csv_value(column1)
        expect(text).to be_blank
      end
    end
  end
end
