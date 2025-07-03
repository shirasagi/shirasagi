require 'spec_helper'

describe Gws::Tabular::File, type: :model, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:space) { create :gws_tabular_space, cur_site: site }
  let!(:form) { create :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1 }

  context "with reference_field" do
    let!(:reference_form) { create :gws_tabular_form, cur_site: site, cur_space: space, state: 'public', revision: 1 }
    let!(:reference_form_column) do
      create(:gws_tabular_column_text_field, cur_site: site, cur_form: reference_form)
    end
    let!(:reference_column) do
      create(
        :gws_tabular_column_reference_field, cur_site: site, cur_form: form,
        required: "optional", reference_form: reference_form
      )
    end
    let!(:column1) do
      create(
        :gws_tabular_column_lookup_field, cur_site: site, cur_form: form,
        reference_column: reference_column, lookup_column: reference_form_column
      )
    end

    before do
      Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: user).perform_now(form.id.to_s)

      expect(Gws::Job::Log.count).to eq 1
      Gws::Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      form.reload
      expect(form.state).to eq 'public'
    end

    context "basic configuration" do
      it do
        file = Gws::Tabular::File[form.current_release].new(cur_site: site, cur_space: space, cur_form: form)
        file.fields["col_#{column1.id}"].tap do |field|
          expect(field).to be_a(::Mongoid::Fields::Standard)
          expect(field.type).to be Array
        end
        expect(file.valid?).to be_truthy
      end
    end
  end
end
