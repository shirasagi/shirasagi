require 'spec_helper'

describe "gws_survey", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:cate) { create(:gws_survey_category, cur_site: site) }

  let!(:form) do
    create(
      :gws_survey_form, cur_site: site, cur_user: gws_user, category_ids: [ cate.id ],
      readable_setting_range: 'public')
  end
  let(:column_options) { Array.new(3) { "option-#{unique_id}" } }
  let!(:column1) do
    create(
      :gws_column_number_field, cur_site: site, form: form, min_decimal: 1, max_decimal: 10, initial_decimal: 1, scale: 0)
  end

  before do
    form.update(state: 'public')
    login_gws_user
  end

  context "number field" do
    it do
      visit gws_survey_main_path(site: site)
      click_on form.name

      within "form#item-form" do
        field = find("[name='custom[#{column1.id}]']")
        value = page.evaluate_script("arguments[0].value", field)
        expect(value).to eq "1"
        step = page.evaluate_script("arguments[0].step", field)
        expect(step).to eq "1"
        min = page.evaluate_script("arguments[0].min", field)
        expect(min).to eq "1"
        max = page.evaluate_script("arguments[0].max", field)
        expect(max).to eq "10"
      end
    end
  end
end
