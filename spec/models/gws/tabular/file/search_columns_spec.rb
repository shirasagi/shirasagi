require 'spec_helper'

describe Gws::Tabular::File, type: :model, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:space) { create :gws_tabular_space, cur_site: site }
  let!(:form) { create :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1 }

  let(:select_options) { %w(alpha bravo charlie) }
  let!(:enum_column) do
    create(
      :gws_tabular_column_enum_field, cur_site: site, cur_form: form, order: 10,
      required: "optional", select_options: select_options, input_type: "checkbox", index_state: 'asc'
    )
  end
  let!(:date_column) do
    create(
      :gws_tabular_column_date_time_field, cur_site: site, cur_form: form, order: 20,
      required: "optional", input_type: input_type, index_state: 'asc', unique_state: 'disabled'
    )
  end

  let(:file_model) { Gws::Tabular::File[form.current_release] }
  let(:enum_field) { "col_#{enum_column.id}" }
  let(:date_field) { "col_#{date_column.id}" }

  before do
    Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: user).perform_now(form.id.to_s)
    form.reload
    expect(form.state).to eq 'public'
  end

  ##
  # Creates and saves a file record for the form's current release and assigns optional column values.
  # @param [Array<String>, nil] enum_values - Values to set on the enum column, or `nil` to leave unset.
  # @param [Date, Time, String, nil] date_value - Value to set on the date/datetime column, or `nil` to leave unset.
  # @return [Gws::Tabular::File] The saved file record.
  def create_file(enum_values: nil, date_value: nil)
    file = file_model.new(cur_site: site, cur_space: space, cur_form: form)
    file.send("#{enum_field}=", enum_values) if enum_values
    file.send("#{date_field}=", date_value) if date_value
    file.save!
    file
  end

  context "with date input_type" do
    let(:input_type) { "date" }

    let!(:file_alpha) { create_file(enum_values: %w(alpha), date_value: Date.new(2026, 6, 1)) }
    let!(:file_bravo) { create_file(enum_values: %w(bravo), date_value: Date.new(2026, 6, 10)) }
    let!(:file_charlie) { create_file(enum_values: %w(charlie), date_value: Date.new(2026, 6, 20)) }

    it "filters by enum column ($in / exact match)" do
      result = file_model.search(col: { enum_column.id.to_s => %w(alpha) }).to_a
      expect(result.map(&:id)).to contain_exactly(file_alpha.id)
    end

    it "filters by multiple enum values" do
      result = file_model.search(col: { enum_column.id.to_s => %w(alpha charlie) }).to_a
      expect(result.map(&:id)).to contain_exactly(file_alpha.id, file_charlie.id)
    end

    it "ignores blank enum selection" do
      result = file_model.search(col: { enum_column.id.to_s => [ "" ] }).to_a
      expect(result.map(&:id)).to contain_exactly(file_alpha.id, file_bravo.id, file_charlie.id)
    end

    it "filters by date range (from / to, inclusive of boundary days)" do
      result = file_model.search(col: { date_column.id.to_s => { "from" => "2026/06/05", "to" => "2026/06/20" } }).to_a
      expect(result.map(&:id)).to contain_exactly(file_bravo.id, file_charlie.id)
    end

    it "filters by date range with only from" do
      result = file_model.search(col: { date_column.id.to_s => { "from" => "2026/06/10" } }).to_a
      expect(result.map(&:id)).to contain_exactly(file_bravo.id, file_charlie.id)
    end

    it "filters by date range with only to" do
      result = file_model.search(col: { date_column.id.to_s => { "to" => "2026/06/10" } }).to_a
      expect(result.map(&:id)).to contain_exactly(file_alpha.id, file_bravo.id)
    end

    it "combines enum and date conditions (AND)" do
      result = file_model.search(
        col: { enum_column.id.to_s => %w(bravo charlie), date_column.id.to_s => { "to" => "2026/06/10" } }
      ).to_a
      expect(result.map(&:id)).to contain_exactly(file_bravo.id)
    end
  end

  context "with datetime input_type" do
    let(:input_type) { "datetime" }

    let!(:file_morning) { create_file(date_value: Time.zone.local(2026, 6, 10, 9, 0, 0)) }
    let!(:file_night) { create_file(date_value: Time.zone.local(2026, 6, 10, 23, 30, 0)) }
    let!(:file_next_day) { create_file(date_value: Time.zone.local(2026, 6, 11, 0, 30, 0)) }

    it "treats from / to as the whole-day range" do
      result = file_model.search(col: { date_column.id.to_s => { "from" => "2026/06/10", "to" => "2026/06/10" } }).to_a
      expect(result.map(&:id)).to contain_exactly(file_morning.id, file_night.id)
    end
  end

  context "search_column_candidates" do
    let(:input_type) { "date" }

    it "includes enum and date columns" do
      candidates = file_model.search_column_candidates
      expect(candidates.map(&:id)).to contain_exactly(enum_column.id, date_column.id)
    end
  end
end
