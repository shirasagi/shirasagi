require 'spec_helper'

describe Gws::Tabular::File, type: :model, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:space) { create :gws_tabular_space, cur_site: site }
  let!(:form) { create :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1 }

  context "with enum_field" do
    let(:required) { "optional" }
    let(:select_options) { Array.new(5) { unique_id } }
    let(:input_type) { "radio" }
    let(:index_state) { 'none' }
    let!(:column1) do
      create(
        :gws_tabular_column_enum_field, cur_site: site, cur_form: form,
        required: required, select_options: select_options, input_type: input_type, index_state: index_state
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
        message = I18n.t("errors.messages.blank")
        expect(file.errors["col_#{column1.id}"]).to include(message)
        expect(file.errors.full_messages).to have(1).items
        full_message = I18n.t("errors.format", attribute: column1.name, message: message)
        expect(file.errors.full_messages).to include(full_message)
      end
    end

    context "when input_type is 'radio'" do
      let(:input_type) { "radio" }

      it do
        file = file_model.new(cur_site: site, cur_space: space, cur_form: form)
        file.send("col_#{column1.id}=", select_options.sample(2))
        expect(file.valid?).to be_falsey
        # puts file.errors.full_messages.join("\n")
        expect(file.errors["col_#{column1.id}"]).to have(1).items
        message = I18n.t("errors.messages.too_long", count: 1)
        expect(file.errors["col_#{column1.id}"]).to include(message)
        expect(file.errors.full_messages).to have(1).items
        full_message = I18n.t("errors.format", attribute: column1.name, message: message)
        expect(file.errors.full_messages).to include(full_message)
      end
    end

    context "when input_type is 'select'" do
      let(:input_type) { "select" }

      it do
        file = file_model.new(cur_site: site, cur_space: space, cur_form: form)
        file.send("col_#{column1.id}=", select_options.sample(2))
        expect(file.valid?).to be_falsey
        # puts file.errors.full_messages.join("\n")
        expect(file.errors["col_#{column1.id}"]).to have(1).items
        message = I18n.t("errors.messages.too_long", count: 1)
        expect(file.errors["col_#{column1.id}"]).to include(message)
        expect(file.errors.full_messages).to have(1).items
        full_message = I18n.t("errors.format", attribute: column1.name, message: message)
        expect(file.errors.full_messages).to include(full_message)
      end
    end

    context "when input_type is 'checkbox'" do
      let(:input_type) { "checkbox" }

      it do
        file = file_model.new(cur_site: site, cur_space: space, cur_form: form)
        file.send("col_#{column1.id}=", [ "check-#{unique_id}" ])
        expect(file.valid?).to be_falsey
        # puts file.errors.full_messages.join("\n")
        expect(file.errors["col_#{column1.id}"]).to have(1).items
        message = I18n.t("errors.messages.inclusion")
        expect(file.errors["col_#{column1.id}"]).to include(message)
        expect(file.errors.full_messages).to have(1).items
        full_message = I18n.t("errors.format", attribute: column1.name, message: message)
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

    context "#to_liquid" do
      let(:item) do
        item = file_model.new(cur_site: site, cur_space: space, cur_form: form)
        item.send("col_#{column1.id}=", Array(column1_value))
        item.save!

        file_model.find(item.id)
      end

      context "when input_type is 'radio' or 'select'" do
        let(:input_type) { %w(radio select).sample }
        let(:column1_value) { select_options.sample }

        it do
          I18n.available_locales.each do |lang|
            I18n.with_locale(lang) do
              result = "{{ item.values[\"#{column1.name}\"] }}"
                .then { Liquid::Template.parse(_1) }
                .then { _1.render({ "item" => item }).to_s.strip }
              expect(result).to eq column1_value
            end
          end

          result = "{{ item.values[\"#{column1.name}\"]['ja'] }}"
            .then { Liquid::Template.parse(_1) }
            .then { _1.render({ "item" => item }).to_s.strip }
          expect(result).to eq column1_value

          result = "{{ item.values[\"#{column1.name}\"]['en'] }}"
            .then { Liquid::Template.parse(_1) }
            .then { _1.render({ "item" => item }).to_s.strip }
          expect(result).to be_blank

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
          expect(result).to eq column1_value

          result = <<~SOURCE
            {% assign value = item.values[\"#{column1.name}\"] -%}
            {{ value['invalid'] | default: value['current'] -}}
          SOURCE
            .then { Liquid::Template.parse(_1) }
            .then { _1.render({ "item" => item }).to_s.strip }
          expect(result).to eq column1_value

          I18n.available_locales.each do |lang|
            I18n.with_locale(lang) do
              result = "{{ item.values[\"#{column1.name}\"].raw_value }}"
                .then { Liquid::Template.parse(_1) }
                .then { _1.render({ "item" => item }).to_s.strip }
              expect(result).to eq column1_value
            end
          end
        end
      end

      context "when input_type is 'checkbox'" do
        let(:input_type) { "checkbox" }
        let(:column1_value) { select_options.sample(2) }

        it do
          I18n.available_locales.each do |lang|
            I18n.with_locale(lang) do
              result = "{{ item.values[\"#{column1.name}\"][0] }}"
                .then { Liquid::Template.parse(_1) }
                .then { _1.render({ "item" => item }).to_s.strip }
              expect(result).to eq column1_value[0]
            end
          end

          result = "{{ item.values[\"#{column1.name}\"][0]['ja'] }}"
            .then { Liquid::Template.parse(_1) }
            .then { _1.render({ "item" => item }).to_s.strip }
          expect(result).to eq column1_value[0]

          result = "{{ item.values[\"#{column1.name}\"][0]['en'] }}"
            .then { Liquid::Template.parse(_1) }
            .then { _1.render({ "item" => item }).to_s.strip }
          expect(result).to be_blank

          result = "{{ item.values[\"#{column1.name}\"][0]['invalid'] }}"
            .then { Liquid::Template.parse(_1) }
            .then { _1.render({ "item" => item }).to_s.strip }
          expect(result).to be_blank

          result = <<~SOURCE
            {% assign value = item.values[\"#{column1.name}\"][0] -%}
            {{ value['invalid'] | default: value['default'] -}}
          SOURCE
            .then { Liquid::Template.parse(_1) }
            .then { _1.render({ "item" => item }).to_s.strip }
          expect(result).to eq column1_value[0]

          result = <<~SOURCE
            {% assign value = item.values[\"#{column1.name}\"][0] -%}
            {{ value['invalid'] | default: value['current'] -}}
          SOURCE
            .then { Liquid::Template.parse(_1) }
            .then { _1.render({ "item" => item }).to_s.strip }
          expect(result).to eq column1_value[0]

          I18n.available_locales.each do |lang|
            I18n.with_locale(lang) do
              result = "{{ item.values[\"#{column1.name}\"][0].raw_value }}"
                .then { Liquid::Template.parse(_1) }
                .then { _1.render({ "item" => item }).to_s.strip }
              expect(result).to eq column1_value[0]
            end
          end
        end
      end
    end
  end
end
