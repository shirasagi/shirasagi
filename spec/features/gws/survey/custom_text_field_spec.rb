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
    # 追加属性を次のように設定することで、数値入力欄相当になる。
    # しかも、こちらは前ゼロを入力可能で汎用性が高い。
    create(
      :gws_column_text_field, cur_site: site, form: form, input_type: "text",
      additional_attr: 'inputmode="numeric" pattern="\d*"')
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
        input_mode = page.evaluate_script("arguments[0].inputMode", field)
        expect(input_mode).to eq "numeric"
        pattern = page.evaluate_script("arguments[0].pattern", field)
        expect(pattern).to eq "\\d*"
      end
    end
  end
end
