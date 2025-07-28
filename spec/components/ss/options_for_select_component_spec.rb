require 'spec_helper'

describe SS::OptionsForSelectComponent, type: :component, dbscope: :example do
  let!(:component) { described_class.new(options: options, selected: selected) }
  let(:selected) { nil }
  subject! { render_inline component }

  context "flat options" do
    let(:options) { %w(enabled disabled).map { |v| [ I18n.t("ss.options.state.#{v}"), v ] } }
    let(:selected) { %w(enabled disabled).sample }

    it do
      subject.css("optgroup").tap do |optgroup_tags|
        expect(optgroup_tags).to have(0).items
      end
      subject.css("option").tap do |option_tags|
        expect(option_tags).to have(2).items
        option_tags[0].tap do |option_tag|
          expect(option_tag['value']).to eq 'enabled'
          expect(option_tag.text).to eq I18n.t("ss.options.state.enabled")
          if selected == 'enabled'
            expect(option_tag['selected']).to be_present
          else
            expect(option_tag['selected']).to be_blank
          end
        end
        option_tags[1].tap do |option_tag|
          expect(option_tag['value']).to eq 'disabled'
          expect(option_tag.text).to eq I18n.t("ss.options.state.disabled")
          if selected == 'disabled'
            expect(option_tag['selected']).to be_present
          else
            expect(option_tag['selected']).to be_blank
          end
        end
      end
    end
  end

  context "flat options with data-attributes" do
    let(:options) do
      %w(name filename created).map do |v|
        [ I18n.t("cms.sort_options.#{v}.title"), v, data: { description: I18n.t("cms.sort_options.#{v}.description") } ]
      end
    end
    let(:selected) { %w(name filename created).sample }

    it do
      subject.css("optgroup").tap do |optgroup_tags|
        expect(optgroup_tags).to have(0).items
      end
      subject.css("option").tap do |option_tags|
        expect(option_tags).to have(3).items
        option_tags[0].tap do |option_tag|
          expect(option_tag['value']).to eq 'name'
          expect(option_tag.text).to eq I18n.t("cms.sort_options.name.title")
          expect(option_tag['data-description']).to eq I18n.t("cms.sort_options.name.description")
          if selected == option_tag['value']
            expect(option_tag['selected']).to be_present
          else
            expect(option_tag['selected']).to be_blank
          end
        end
        option_tags[1].tap do |option_tag|
          expect(option_tag['value']).to eq 'filename'
          expect(option_tag.text).to eq I18n.t("cms.sort_options.filename.title")
          expect(option_tag['data-description']).to eq I18n.t("cms.sort_options.filename.description")
          if selected == option_tag['value']
            expect(option_tag['selected']).to be_present
          else
            expect(option_tag['selected']).to be_blank
          end
        end
        option_tags[2].tap do |option_tag|
          expect(option_tag['value']).to eq 'created'
          expect(option_tag.text).to eq I18n.t("cms.sort_options.created.title")
          expect(option_tag['data-description']).to eq I18n.t("cms.sort_options.created.description")
          if selected == option_tag['value']
            expect(option_tag['selected']).to be_present
          else
            expect(option_tag['selected']).to be_blank
          end
        end
      end
    end
  end

  context "2-layer options like categories" do
    let(:options) do
      # name is shuffled but ordered by id
      [
        [ "parent1/child1", 89 ],
        [ "parent2/child3", 90 ],
        [ "parent3/child5", 91 ],
        [ "parent1/child2", 92 ],
        [ "parent2/child4", 93 ],
      ]
    end
    let(:selected) { 90 }

    it do
      subject.css("optgroup").tap do |optgroup_tags|
        expect(optgroup_tags).to have(3).items
        optgroup_tags[0].tap do |optgroup_tag|
          expect(optgroup_tag['label']).to eq 'parent1'
          optgroup_tag.css("option").tap do |option_tags|
            expect(option_tags).to have(2).items
            option_tags[0].tap do |option_tag|
              expect(option_tag['value']).to eq '89'
              expect(option_tag.text).to eq "child1"
              expect(option_tag['selected']).to be_blank
            end
            option_tags[1].tap do |option_tag|
              expect(option_tag['value']).to eq '92'
              expect(option_tag.text).to eq "child2"
              expect(option_tag['selected']).to be_blank
            end
          end
        end
        optgroup_tags[1].tap do |optgroup_tag|
          expect(optgroup_tag['label']).to eq 'parent2'
          optgroup_tag.css("option").tap do |option_tags|
            expect(option_tags).to have(2).items
            option_tags[0].tap do |option_tag|
              expect(option_tag['value']).to eq '90'
              expect(option_tag.text).to eq "child3"
              expect(option_tag['selected']).to be_present
            end
            option_tags[1].tap do |option_tag|
              expect(option_tag['value']).to eq '93'
              expect(option_tag.text).to eq "child4"
              expect(option_tag['selected']).to be_blank
            end
          end
        end
        optgroup_tags[2].tap do |optgroup_tag|
          expect(optgroup_tag['label']).to eq 'parent3'
          optgroup_tag.css("option").tap do |option_tags|
            expect(option_tags).to have(1).items
            option_tags[0].tap do |option_tag|
              expect(option_tag['value']).to eq '91'
              expect(option_tag.text).to eq "child5"
              expect(option_tag['selected']).to be_blank
            end
          end
        end
      end
    end
  end
end
