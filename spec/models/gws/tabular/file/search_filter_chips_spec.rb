require 'spec_helper'

describe "Gws::Tabular search_filter_chips", type: :model, dbscope: :example do
  let!(:site) { gws_site }
  let!(:space) { create :gws_tabular_space, cur_site: site }
  let!(:form) { create :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1 }

  context "with enum_field" do
    let!(:column) do
      create(
        :gws_tabular_column_enum_field, cur_site: site, cur_form: form,
        name: "分類", select_options: %w[alpha bravo charlie], input_type: "checkbox")
    end

    it "returns one chip per selected value with the remaining values" do
      expect(column.search_filter_chips(%w[alpha charlie])).to eq(
        [
          { label: "分類: alpha", remaining: %w[charlie] },
          { label: "分類: charlie", remaining: %w[alpha] }
        ]
      )
    end

    it "sets remaining to nil when removing the only selected value" do
      expect(column.search_filter_chips(%w[alpha])).to eq([{ label: "分類: alpha", remaining: nil }])
    end

    it "ignores blanks and values not in the options" do
      expect(column.search_filter_chips(["", "unknown"])).to eq([])
    end
  end

  context "with date_time_field" do
    let!(:column) do
      create(
        :gws_tabular_column_date_time_field, cur_site: site, cur_form: form,
        name: "使用日", input_type: "date", unique_state: "disabled")
    end

    it "returns a single range chip that clears the whole range" do
      expect(column.search_filter_chips("from" => "2026/01/01", "to" => "2026/03/31")).to eq(
        [{ label: "使用日: 2026/01/01〜2026/03/31", remaining: nil }]
      )
    end

    it "supports a one-sided range" do
      expect(column.search_filter_chips("from" => "2026/01/01")).to eq(
        [{ label: "使用日: 2026/01/01〜", remaining: nil }]
      )
    end

    it "returns empty when no range is given" do
      expect(column.search_filter_chips({})).to eq([])
    end
  end
end
