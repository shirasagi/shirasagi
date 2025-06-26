require 'spec_helper'

describe Gws::Tabular::File, type: :model, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:space) { create :gws_tabular_space, cur_site: site }
  let!(:form) { create :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1 }

  context "with text_field" do
    let(:required) { "optional" }
    let(:unique_state) { "disabled" }
    let(:input_type) { "single" }
    let(:max_length) { nil }
    let(:i18n_default_value_translations) { nil }
    let(:validation_type) { "none" }
    let(:i18n_state) { "disabled" }
    let(:index_state) { 'none' }
    let!(:column1) do
      create(
        :gws_tabular_column_text_field, cur_site: site, cur_form: form,
        required: required, unique_state: unique_state, input_type: input_type, max_length: max_length,
        validation_type: validation_type, i18n_state: i18n_state,
        i18n_default_value_translations: i18n_default_value_translations, index_state: index_state
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
        text = "text-#{unique_id}"
        file_model.create!(cur_site: site, cur_space: space, cur_form: form, "col_#{column1.id}" => text)
        file = file_model.new(cur_site: site, cur_space: space, cur_form: form, "col_#{column1.id}" => text)
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

    context "when max_length is presented" do
      let(:max_length) { 10 }

      it do
        file = file_model.new(cur_site: site, cur_space: space, cur_form: form)
        file.send("col_#{column1.id}=", "a" * 11)
        expect(file.valid?).to be_falsey
        # puts file.errors.full_messages.join("\n")
        expect(file.errors["col_#{column1.id}"]).to have(1).items
        base_message = I18n.t("errors.messages.too_long", count: max_length)
        expect(file.errors["col_#{column1.id}"]).to include(base_message)
        expect(file.errors.full_messages).to have(1).items
        full_message = I18n.t("errors.format", attribute: column1.name, message: base_message)
        expect(file.errors.full_messages).to include(full_message)
      end
    end

    context "when i18n_default_value is presented" do
      let(:i18n_default_value_translations) { i18n_translations(prefix: "default") }

      it do
        I18n.with_locale(:ja) do
          file = file_model.new(cur_site: site, cur_space: space, cur_form: form)
          expect(file.send("col_#{column1.id}")).to eq i18n_default_value_translations[I18n.locale]
        end
        I18n.with_locale(:en) do
          file = file_model.new(cur_site: site, cur_space: space, cur_form: form)
          expect(file.send("col_#{column1.id}")).to eq i18n_default_value_translations[I18n.locale]
        end
      end
    end

    context "when validation_type is 'email'" do
      let(:validation_type) { "email" }

      it do
        file = file_model.new(cur_site: site, cur_space: space, cur_form: form)
        file.send("col_#{column1.id}=", "invalid email xxx ...")
        expect(file.valid?).to be_falsey
        # puts file.errors.full_messages.join("\n")
        expect(file.errors["col_#{column1.id}"]).to have(1).items
        base_message = I18n.t("errors.messages.email")
        expect(file.errors["col_#{column1.id}"]).to include(base_message)
        expect(file.errors.full_messages).to have(1).items
        full_message = I18n.t("errors.format", attribute: column1.name, message: base_message)
        expect(file.errors.full_messages).to include(full_message)
      end
    end

    context "when validation_type is 'tel'" do
      let(:validation_type) { "tel" }

      it do
        file = file_model.new(cur_site: site, cur_space: space, cur_form: form)
        file.send("col_#{column1.id}=", "invalid tel あいう")
        expect(file.valid?).to be_falsey
        # puts file.errors.full_messages.join("\n")
        expect(file.errors["col_#{column1.id}"]).to have(1).items
        base_message = I18n.t("errors.messages.tel")
        expect(file.errors["col_#{column1.id}"]).to include(base_message)
        expect(file.errors.full_messages).to have(1).items
        full_message = I18n.t("errors.format", attribute: column1.name, message: base_message)
        expect(file.errors.full_messages).to include(full_message)
      end
    end

    context "when validation_type is 'url'" do
      let(:validation_type) { "url" }

      it do
        file = file_model.new(cur_site: site, cur_space: space, cur_form: form)
        file.send("col_#{column1.id}=", "xxxyyyzzz")
        expect(file.valid?).to be_falsey
        # puts file.errors.full_messages.join("\n")
        expect(file.errors["col_#{column1.id}"]).to have(1).items
        base_message = I18n.t("errors.messages.url")
        expect(file.errors["col_#{column1.id}"]).to include(base_message)
        expect(file.errors.full_messages).to have(1).items
        full_message = I18n.t("errors.format", attribute: column1.name, message: base_message)
        expect(file.errors.full_messages).to include(full_message)
      end
    end

    context "when validation_type is 'color'" do
      let(:validation_type) { "color" }

      it do
        file = file_model.new(cur_site: site, cur_space: space, cur_form: form)
        file.send("col_#{column1.id}=", "xxxyyyzzz")
        expect(file.valid?).to be_falsey
        # puts file.errors.full_messages.join("\n")
        expect(file.errors["col_#{column1.id}"]).to have(1).items
        base_message = I18n.t("errors.messages.malformed_color")
        expect(file.errors["col_#{column1.id}"]).to include(base_message)
        expect(file.errors.full_messages).to have(1).items
        full_message = I18n.t("errors.format", attribute: column1.name, message: base_message)
        expect(file.errors.full_messages).to include(full_message)
      end
    end

    context "when i18n_state is 'enabled'" do
      let(:i18n_state) { "enabled" }

      it do
        file = file_model.new(cur_site: site, cur_space: space, cur_form: form)
        translations = i18n_translations(prefix: unique_id)
        file.send("col_#{column1.id}_translations=", translations)
        I18n.with_locale(:ja) do
          expect(file.send("col_#{column1.id}")).to eq translations[I18n.locale]
        end
        I18n.with_locale(:en) do
          expect(file.send("col_#{column1.id}")).to eq translations[I18n.locale]
        end
      end
    end

    context "when unique_state is 'enabled' and i18n_state is 'enabled'" do
      let(:unique_state) { "enabled" }
      let(:i18n_state) { "enabled" }

      it do
        translations = i18n_translations(prefix: "text")
        file_model.create!(cur_site: site, cur_space: space, cur_form: form, "col_#{column1.id}_translations" => translations)

        file = file_model.new(cur_site: site, cur_space: space, cur_form: form, "col_#{column1.id}_translations" => translations)
        expect(file.valid?).to be_falsey
        # puts file.errors.full_messages.join("\n")
        expect(file.errors["col_#{column1.id}"]).to have(1).items
        base_message = I18n.t("errors.messages.taken")
        expect(file.errors["col_#{column1.id}"]).to include(base_message)
        expect(file.errors.full_messages).to have(1).items
        full_message = I18n.t("errors.format", attribute: column1.name, message: base_message)
        expect(file.errors.full_messages).to include(full_message)

        I18n.with_locale(:ja) do
          file = file_model.new(cur_site: site, cur_space: space, cur_form: form, "col_#{column1.id}" => translations[:ja])
          expect(file.valid?).to be_falsey
          expect(file.errors["col_#{column1.id}"]).to have(1).items
          base_message = I18n.t("errors.messages.taken")
          expect(file.errors["col_#{column1.id}"]).to include(base_message)
          expect(file.errors.full_messages).to have(1).items
          full_message = I18n.t("errors.format", attribute: column1.name, message: base_message)
          expect(file.errors.full_messages).to include(full_message)
        end

        I18n.with_locale(:en) do
          file = file_model.new(cur_site: site, cur_space: space, cur_form: form, "col_#{column1.id}" => translations[:en])
          expect(file.valid?).to be_falsey
          expect(file.errors["col_#{column1.id}"]).to have(1).items
          base_message = I18n.t("errors.messages.taken")
          expect(file.errors["col_#{column1.id}"]).to include(base_message)
          expect(file.errors.full_messages).to have(1).items
          full_message = I18n.t("errors.format", attribute: column1.name, message: base_message)
          expect(file.errors.full_messages).to include(full_message)
        end
      end
    end

    context "when i18n_default_value is presented and i18n_state is 'enabled'" do
      let(:i18n_default_value_translations) { i18n_translations(prefix: "default") }
      let(:i18n_state) { "enabled" }

      it do
        file = file_model.new(cur_site: site, cur_space: space, cur_form: form)
        I18n.with_locale(:ja) do
          expect(file.send("col_#{column1.id}")).to eq i18n_default_value_translations[I18n.locale]
        end
        I18n.with_locale(:en) do
          expect(file.send("col_#{column1.id}")).to eq i18n_default_value_translations[I18n.locale]
        end
        expect(file.send("col_#{column1.id}_translations")).to eq i18n_default_value_translations
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

    context "when index_state is 'desc' and i18n_state is 'enabled'" do
      let(:index_state) { 'desc' }
      let(:i18n_state) { "enabled" }

      it do
        coll = file_model.collection
        index_view = coll.indexes
        index = index_view.get("col_#{column1.id}.ja" => -1)
        expect(index).to be_present
        expect(index[:unique]).to be_falsey

        index = index_view.get("col_#{column1.id}.en" => -1)
        expect(index).to be_present
        expect(index[:unique]).to be_falsey
      end
    end

    context "when index_state is 'desc', required is 'required', unique_state is 'enabled' and i18n_state is 'enabled'" do
      let(:index_state) { 'desc' }
      let(:required) { "required" }
      let(:unique_state) { "enabled" }
      let(:i18n_state) { "enabled" }

      it do
        coll = file_model.collection
        index_view = coll.indexes
        index = index_view.get("col_#{column1.id}.ja" => -1)
        expect(index).to be_present
        expect(index[:unique]).to be_truthy

        index = index_view.get("col_#{column1.id}.en" => -1)
        expect(index).to be_present
        expect(index[:unique]).to be_truthy
      end
    end

    context "#to_liquid" do
      let(:column1_value) { "text-#{unique_id}" }
      let(:item) do
        item = file_model.new(cur_site: site, cur_space: space, cur_form: form)
        if i18n_state == "enabled"
          item.send("col_#{column1.id}_translations=", column1_value)
        else
          item.send("col_#{column1.id}=", column1_value)
        end
        item.save!

        file_model.find(item.id)
      end

      context "when input_type is 'single'" do
        let(:input_type) { "single" }

        it do
          result = "{{ item.values[\"#{column1.name}\"] }}"
            .then { Liquid::Template.parse(_1) }
            .then { _1.render({ "item" => item }).to_s.strip }
          expect(result).to eq column1_value
        end
      end

      context "when input_type is 'multi_html'" do
        let(:column1_value) do
          <<~HTML
            <p>text-#{unique_id}</p>
            <p>text-#{unique_id}</p>
            <p>text-#{unique_id}</p>
          HTML
        end
        let(:input_type) { "multi_html" }

        it do
          result = "{{ item.values[\"#{column1.name}\"] }}"
            .then { Liquid::Template.parse(_1) }
            .then { _1.render({ "item" => item }).to_s.strip }
          expect(result).to eq column1_value.strip
        end
      end

      context "when i18n_state is 'enabled'" do
        let(:input_type) { "single" }
        let(:i18n_state) { "enabled" }
        let(:column1_value) { i18n_translations(prefix: "text") }

        it do
          I18n.available_locales.each do |lang|
            I18n.with_locale(lang) do
              result = "{{ item.values[\"#{column1.name}\"] }}"
                .then { Liquid::Template.parse(_1) }
                .then { _1.render({ "item" => item }).to_s.strip }
              expect(result).to eq column1_value[lang]
            end
          end

          result = "{{ item.values[\"#{column1.name}\"]['ja'] }}"
            .then { Liquid::Template.parse(_1) }
            .then { _1.render({ "item" => item }).to_s.strip }
          expect(result).to eq column1_value[:ja]

          result = "{{ item.values[\"#{column1.name}\"]['en'] }}"
            .then { Liquid::Template.parse(_1) }
            .then { _1.render({ "item" => item }).to_s.strip }
          expect(result).to eq column1_value[:en]

          result = "{{ item.values[\"#{column1.name}\"]['invalid'] }}"
            .then { Liquid::Template.parse(_1) }
            .then { _1.render({ "item" => item }).to_s.strip }
          expect(result).to be_blank

          result = <<~SOURCE
            {% assign value = item.values[\"#{column1.name}\"] -%}
            {{ value['invalid'] | default: value['default'] -}}
          SOURCE
            .then { Liquid::Template.parse(_1) }
            .then { _1.render({ "item" => item }).to_s.strip }
          expect(result).to eq column1_value[I18n.default_locale]

          result = <<~SOURCE
            {% assign value = item.values[\"#{column1.name}\"] -%}
            {{ value['invalid'] | default: value['current'] -}}
          SOURCE
            .then { Liquid::Template.parse(_1) }
            .then { _1.render({ "item" => item }).to_s.strip }
          expect(result).to eq column1_value[I18n.locale]
        end
      end
    end
  end
end
