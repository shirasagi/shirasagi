require 'spec_helper'

describe Gws::Tabular::File, type: :model, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:space) { create :gws_tabular_space, cur_site: site }
  let!(:form) { create :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1 }

  context "with number_field" do
    let(:required) { "optional" }
    let(:unique_state) { "disabled" }
    let(:index_state) { 'none' }
    let(:field_type) { "integer" }
    let(:min_value) { nil }
    let(:max_value) { nil }
    let(:default_value) { nil }
    let!(:column1) do
      create(
        :gws_tabular_column_number_field, cur_site: site, cur_form: form,
        required: required, unique_state: unique_state, index_state: index_state,
        field_type: field_type, min_value: min_value, max_value: max_value, default_value: default_value
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
        base_message = I18n.t("errors.messages.blank")
        expect(file.errors["col_#{column1.id}"]).to include(base_message)
        expect(file.errors.full_messages).to have(1).items
        full_message = I18n.t("errors.format", attribute: column1.name, message: base_message)
        expect(file.errors.full_messages).to include(full_message)
      end
    end

    context "when unique_state is 'enabled'" do
      let(:unique_state) { "enabled" }

      it do
        value = 23
        file_model.create!(cur_site: site, cur_space: space, cur_form: form, "col_#{column1.id}" => value)
        file = file_model.new(cur_site: site, cur_space: space, cur_form: form, "col_#{column1.id}" => value)
        expect(file.valid?).to be_falsey
        # puts file.errors.full_messages.join("\n")
        expect(file.errors["col_#{column1.id}"]).to have(1).items
        base_message = I18n.t("errors.messages.taken")
        expect(file.errors["col_#{column1.id}"]).to include(base_message)
        expect(file.errors.full_messages).to have(1).items
        full_message = I18n.t("errors.format", attribute: column1.name, message: base_message)
        expect(file.errors.full_messages).to include(full_message)
      end
    end

    context "when field_type is 'integer'" do
      let(:field_type) { "integer" }

      it do
        file = file_model.new(cur_site: site, cur_space: space, cur_form: form)
        file.send("col_#{column1.id}=", "5.71")
        expect(file.valid?).to be_falsey
        # puts file.errors.full_messages.join("\n")
        expect(file.errors["col_#{column1.id}"]).to have(1).items
        base_message = I18n.t("errors.messages.not_an_integer")
        expect(file.errors["col_#{column1.id}"]).to include(base_message)
        expect(file.errors.full_messages).to have(1).items
        full_message = I18n.t("errors.format", attribute: column1.name, message: base_message)
        expect(file.errors.full_messages).to include(full_message)
      end
    end

    context "when min_value is presented" do
      let(:field_type) { "decimal" }
      let(:min_value) { 10 }

      it do
        file = file_model.new(cur_site: site, cur_space: space, cur_form: form)
        file.send("col_#{column1.id}=", 9)
        expect(file.valid?).to be_falsey
        # puts file.errors.full_messages.join("\n")
        expect(file.errors["col_#{column1.id}"]).to have(1).items
        base_message = I18n.t("errors.messages.greater_than_or_equal_to", count: min_value.to_f)
        expect(file.errors["col_#{column1.id}"]).to include(base_message)
        expect(file.errors.full_messages).to have(1).items
        full_message = I18n.t("errors.format", attribute: column1.name, message: base_message)
        expect(file.errors.full_messages).to include(full_message)
      end
    end

    context "when max_value is presented" do
      let(:field_type) { "float" }
      let(:max_value) { 10 }

      it do
        file = file_model.new(cur_site: site, cur_space: space, cur_form: form)
        file.send("col_#{column1.id}=", 11)
        expect(file.valid?).to be_falsey
        # puts file.errors.full_messages.join("\n")
        expect(file.errors["col_#{column1.id}"]).to have(1).items
        base_message = I18n.t("errors.messages.less_than_or_equal_to", count: max_value.to_f)
        expect(file.errors["col_#{column1.id}"]).to include(base_message)
        expect(file.errors.full_messages).to have(1).items
        full_message = I18n.t("errors.format", attribute: column1.name, message: base_message)
        expect(file.errors.full_messages).to include(full_message)
      end
    end

    context "when index_state is 'asc'" do
      let(:index_state) { 'asc' }

      it do
        coll = file_model.collection
        index_view = coll.indexes
        index = index_view.get("col_#{column1.id}" => 1)
        expect(index).to be_present
        expect(index[:unique]).to be_falsey
      end
    end

    context "when index_state is 'asc', required is 'required' and unique_state is 'enabled'" do
      let(:index_state) { 'asc' }
      let(:required) { "required" }
      let(:unique_state) { "enabled" }

      it do
        coll = file_model.collection
        index_view = coll.indexes
        index = index_view.get("col_#{column1.id}" => 1)
        expect(index).to be_present
        expect(index[:unique]).to be_truthy
      end
    end

    context "when index_state is 'asc', required is 'optional' and unique_state is 'enabled'" do
      let(:index_state) { 'asc' }
      let(:required) { "optional" }
      let(:unique_state) { "enabled" }

      # MongoDBのsparse indexはソート時に用いられない（用いることができない）。
      # index付与の主目的の一つにソートの改善があるので、ソート時に用いることのできないsparse indexは都合が悪い。
      # そこで、required が 'optional' の場合、indexによる unique 制約は設けない。
      it do
        coll = file_model.collection
        index_view = coll.indexes
        index = index_view.get("col_#{column1.id}" => 1)
        expect(index).to be_present
        expect(index[:unique]).to be_falsey
      end
    end

    context "when index_state is 'desc'" do
      let(:index_state) { 'desc' }

      it do
        coll = file_model.collection
        index_view = coll.indexes
        index = index_view.get("col_#{column1.id}" => -1)
        expect(index).to be_present
        expect(index[:unique]).to be_falsey
      end
    end
  end
end
