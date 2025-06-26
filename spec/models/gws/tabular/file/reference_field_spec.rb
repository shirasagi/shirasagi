require 'spec_helper'

describe Gws::Tabular::File, type: :model, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:space) { create :gws_tabular_space, cur_site: site }
  let!(:form) { create :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1 }

  context "with reference_field" do
    let(:required) { "optional" }
    let(:index_state) { 'none' }
    let!(:reference_form) { create :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1 }
    let(:reference_type) { "one_to_one" }
    let!(:column1) do
      create(
        :gws_tabular_column_reference_field, cur_site: site, cur_form: form,
        required: required, reference_form: reference_form, reference_type: reference_type, index_state: index_state
      )
    end
    let(:file_model) { Gws::Tabular::File[form.current_release] }

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

    context "when required is 'required'" do
      let(:required) { "required" }

      it do
        file = file_model.new(cur_site: site, cur_space: space, cur_form: form)
        expect(file.valid?).to be_falsey
        # puts file.errors.full_messages.join("\n")
        expect(file.errors["col_#{column1.id}"]).to have(1).items
        expect(file.errors["col_#{column1.id}"]).to include(I18n.t("errors.messages.blank"))
        expect(file.errors.full_messages).to have(1).items
        message = I18n.t("errors.format", attribute: column1.name, message: I18n.t("errors.messages.blank"))
        expect(file.errors.full_messages).to include(message)
      end
    end

    context "when reference_type is 'one_to_one'" do
      let(:reference_type) { "one_to_one" }

      it do
        file = file_model.new(cur_site: site, cur_space: space, cur_form: form)
        file.send("col_#{column1.id}_ids=", Array.new(2) { BSON::ObjectId.new.to_s })
        expect(file.valid?).to be_falsey
        # puts file.errors.full_messages.join("\n")
        expect(file.errors["col_#{column1.id}"]).to have(1).items
        expect(file.errors["col_#{column1.id}"]).to have(1).items
        base_message = I18n.t("errors.messages.too_long", count: 1)
        expect(file.errors["col_#{column1.id}"]).to include(base_message)
        expect(file.errors.full_messages).to have(1).items
        message = I18n.t("errors.format", attribute: column1.name, message: base_message)
        expect(file.errors.full_messages).to include(message)
      end
    end

    context "when index_state is 'asc'" do
      let(:index_state) { 'asc' }

      it do
        coll = file_model.collection
        index_view = coll.indexes
        index = index_view.get("col_#{column1.id}_ids" => 1)
        expect(index).to be_present
        expect(index[:unique]).to be_falsey
      end
    end

    context "when index_state is 'desc'" do
      let(:index_state) { 'desc' }

      it do
        coll = file_model.collection
        index_view = coll.indexes
        index = index_view.get("col_#{column1.id}_ids" => -1)
        expect(index).to be_present
        expect(index[:unique]).to be_falsey
      end
    end

    context "#to_liquid" do
      let!(:reference_column1) do
        create(
          :gws_tabular_column_text_field, cur_site: site, cur_form: reference_form,
          required: "optional", input_type: "single", max_length: nil, validation_type: "none",
          i18n_state: "disabled", i18n_default_value_translations: nil
        )
      end
      let(:reference_column1_value) { "reference_column1_value-#{unique_id}" }

      before do
        Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: user).perform_now(reference_form.id.to_s)

        Gws::Job::Log.all.each do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        reference_form.reload
        expect(reference_form.state).to eq 'public'

        reference_file_model = Gws::Tabular::File[reference_form.current_release]
        reference_item = reference_file_model.new(cur_site: site, cur_space: space, cur_form: reference_form)
        reference_item.send("col_#{reference_column1.id}=", reference_column1_value)
        reference_item.save!

        item = file_model.new(cur_site: site, cur_space: space, cur_form: form)
        item.send("col_#{column1.id}_ids=", [ reference_item.id ])
        item.save!
      end

      it do
        item = file_model.first

        result = "{{ item.values[\"#{column1.name}\"] | size -}}"
          .then { Liquid::Template.parse(_1) }
          .then { _1.render({ "item" => item }).to_s.strip }
        expect(result).to eq item.send("col_#{column1.id}").count.to_s

        result = <<~SOURCE
          {% for sub_item in item.values[\"#{column1.name}\"] -%}
          - {{ sub_item.values[\"#{reference_column1.name}\"] -}}
          {% endfor -%}
        SOURCE
          .then { Liquid::Template.parse(_1) }
          .then { _1.render({ "item" => item }).to_s.strip }
        expect(result).to eq "- #{reference_column1_value}"
      end
    end
  end
end
