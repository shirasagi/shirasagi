require 'spec_helper'

RSpec.describe SS::EditorHelper, type: :helper do
  describe '#ckeditor_editor_options' do
    before do
      controller.request.path_parameters = { site: 1 }
    end

    context 'with no options' do
      subject { helper.ckeditor_editor_options }

      it do
        expect(subject.delete(:extraPlugins)).to eq 'templates,justify'
        expect(subject.delete(:removePlugins)).to eq ''
        expect(subject.delete(:allowedContent)).to eq true
        expect(subject.delete(:height)).to eq '360px'
        expect(subject.delete(:templates)).to eq 'shirasagi'
        expect(subject.delete(:templates_files)).to include(start_with('/.s1/cms/editor_templates/template.js'))
        expect(subject.blank?).to be_truthy
      end
    end

    context 'with readonly options' do
      subject { helper.ckeditor_editor_options(readonly: true) }

      it do
        expect(subject.delete(:readOnly)).to eq true
        expect(subject.delete(:extraPlugins)).to eq 'templates,justify'
        expect(subject.delete(:removePlugins)).to eq 'toolbar'
        expect(subject.delete(:allowedContent)).to eq true
        expect(subject.delete(:height)).to eq '360px'
        expect(subject.delete(:templates)).to eq 'shirasagi'
        expect(subject.delete(:templates_files)).to include(start_with('/.s1/cms/editor_templates/template.js'))
        expect(subject.blank?).to be_truthy
      end
    end

    context 'with public_side options' do
      subject { helper.ckeditor_editor_options(public_side: true) }

      it do
        expect(subject.delete(:extraPlugins)).to eq 'templates,justify'
        expect(subject.delete(:removePlugins)).to eq ''
        expect(subject.delete(:allowedContent)).to eq true
        expect(subject.delete(:height)).to eq '360px'
        expect(subject.key?(:templates)).to be_falsey
        expect(subject.key?(:templates_files)).to be_falsey
        expect(subject.blank?).to be_truthy
      end
    end

    context 'with height and readonly options' do
      subject { helper.ckeditor_editor_options(height: '400px', readonly: true) }

      it do
        expect(subject.delete(:readOnly)).to eq true
        expect(subject.delete(:extraPlugins)).to eq 'templates,justify'
        expect(subject.delete(:removePlugins)).to eq 'toolbar'
        expect(subject.delete(:allowedContent)).to eq true
        expect(subject.delete(:height)).to eq '400px'
        expect(subject.delete(:templates)).to eq 'shirasagi'
        expect(subject.delete(:templates_files)).to include(start_with('/.s1/cms/editor_templates/template.js'))
        expect(subject.blank?).to be_truthy
      end
    end

    context 'with enterMode and shiftEnterMode options' do
      subject { helper.ckeditor_editor_options('enterMode' => 2, 'shiftEnterMode' => 1) }

      it do
        expect(subject.delete(:enterMode)).to eq 2
        expect(subject.delete(:shiftEnterMode)).to eq 1
        expect(subject.delete(:extraPlugins)).to eq 'templates,justify'
        expect(subject.delete(:removePlugins)).to eq ''
        expect(subject.delete(:allowedContent)).to eq true
        expect(subject.delete(:height)).to eq '360px'
        expect(subject.delete(:templates)).to eq 'shirasagi'
        expect(subject.delete(:templates_files)).to include(start_with('/.s1/cms/editor_templates/template.js'))
        expect(subject.blank?).to be_truthy
      end
    end
  end
end
