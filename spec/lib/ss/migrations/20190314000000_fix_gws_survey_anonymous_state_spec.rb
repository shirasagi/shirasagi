require 'spec_helper'
require Rails.root.join("lib/migrations/gws/20190314000000_fix_gws_survey_anonymous_state.rb")

RSpec.describe SS::Migration20190314000000, dbscope: :example do
  let!(:site) { gws_site }
  let!(:form) { create :gws_survey_form, cur_site: site, anonymous_state: "enabled" }
  let!(:column) do
    column = Gws::Column::TextField.new(
      site: site, cur_site: site, form: form, name: unique_id, input_type: 'text', order: 10, required: 'optional'
    )
    column.save!
    column
  end
  let!(:file) do
    file = Gws::Survey::File.new(site: site, cur_site: site, form: form, name: unique_id, anonymous_state: nil)
    file.save!
    file
  end
  let!(:column_value) do
    column_value = file.column_values.build(column.serialize_value(unique_id).attributes)
    column_value.save!
    column_value
  end

  it do
    file.reload
    expect(file.anonymous_state).to be_nil

    described_class.new.change

    file.reload
    expect(file.anonymous_state).to eq "enabled"
  end
end
