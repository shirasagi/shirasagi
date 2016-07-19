require 'spec_helper'

RSpec.describe SS::EditorHelper, type: :helper do
  describe '#ckeditor_editor_options' do
    before do
      controller.request.path_parameters = { site: 1 }
    end
    let(:fontSize_sizes) do
      %w(
         60%/60%; 70%/70%; 80%/80%; 90%/90%; 100%/100%; 110%/110%; 120%/120%; 130%/130%;
         140%/140%; 150%/150%; 160%/160%; 170%/170%; 180%/180%; 190%/190%; 200%/200%;
        ).join
    end

    context 'with no options' do
      subject { helper.ckeditor_editor_options }

      it do
        expect(subject.delete(:extraPlugins)).to eq 'templates,justify,panelbutton,colorbutton,font'
        expect(subject.delete(:removePlugins)).to eq ''
        expect(subject.delete(:allowedContent)).to eq true
        expect(subject.delete(:height)).to eq '360px'
        expect(subject.delete(:templates)).to eq 'shirasagi'
        expect(subject.delete(:templates_files)).to include(start_with('/.s1/cms/editor_templates/template.js'))
        expect(subject.delete(:removeButtons)).to eq 'Underline,Subscript,Superscript,Font,BGColor,Source'
        expect(subject.delete(:fontSize_sizes)).to eq fontSize_sizes
        expect(subject.blank?).to be_truthy
      end
    end

    context 'with readonly options' do
      subject { helper.ckeditor_editor_options(readonly: true) }

      it do
        expect(subject.delete(:readOnly)).to eq true
        expect(subject.delete(:extraPlugins)).to eq 'templates,justify,panelbutton,colorbutton,font'
        expect(subject.delete(:removePlugins)).to eq 'toolbar'
        expect(subject.delete(:allowedContent)).to eq true
        expect(subject.delete(:height)).to eq '360px'
        expect(subject.delete(:templates)).to eq 'shirasagi'
        expect(subject.delete(:templates_files)).to include(start_with('/.s1/cms/editor_templates/template.js'))
        expect(subject.delete(:removeButtons)).to eq 'Underline,Subscript,Superscript,Font,BGColor,Source'
        expect(subject.delete(:fontSize_sizes)).to eq fontSize_sizes
        expect(subject.blank?).to be_truthy
      end
    end

    context 'with public_side options' do
      subject { helper.ckeditor_editor_options(public_side: true) }

      it do
        expect(subject.delete(:extraPlugins)).to eq 'templates,justify,panelbutton,colorbutton,font'
        expect(subject.delete(:removePlugins)).to eq ''
        expect(subject.delete(:allowedContent)).to eq true
        expect(subject.delete(:height)).to eq '360px'
        expect(subject.key?(:templates)).to be_falsey
        expect(subject.key?(:templates_files)).to be_falsey
        expect(subject.delete(:removeButtons)).to eq 'Underline,Subscript,Superscript,Font,BGColor,Source'
        expect(subject.delete(:fontSize_sizes)).to eq fontSize_sizes
        expect(subject.blank?).to be_truthy
      end
    end

    context 'with height and readonly options' do
      subject { helper.ckeditor_editor_options(height: '400px', readonly: true) }

      it do
        expect(subject.delete(:readOnly)).to eq true
        expect(subject.delete(:extraPlugins)).to eq 'templates,justify,panelbutton,colorbutton,font'
        expect(subject.delete(:removePlugins)).to eq 'toolbar'
        expect(subject.delete(:allowedContent)).to eq true
        expect(subject.delete(:height)).to eq '400px'
        expect(subject.delete(:templates)).to eq 'shirasagi'
        expect(subject.delete(:templates_files)).to include(start_with('/.s1/cms/editor_templates/template.js'))
        expect(subject.delete(:removeButtons)).to eq 'Underline,Subscript,Superscript,Font,BGColor,Source'
        expect(subject.delete(:fontSize_sizes)).to eq fontSize_sizes
        expect(subject.blank?).to be_truthy
      end
    end

    context 'with enterMode and shiftEnterMode options' do
      subject { helper.ckeditor_editor_options('enterMode' => 2, 'shiftEnterMode' => 1) }

      it do
        expect(subject.delete(:enterMode)).to eq 2
        expect(subject.delete(:shiftEnterMode)).to eq 1
        expect(subject.delete(:extraPlugins)).to eq 'templates,justify,panelbutton,colorbutton,font'
        expect(subject.delete(:removePlugins)).to eq ''
        expect(subject.delete(:allowedContent)).to eq true
        expect(subject.delete(:height)).to eq '360px'
        expect(subject.delete(:templates)).to eq 'shirasagi'
        expect(subject.delete(:templates_files)).to include(start_with('/.s1/cms/editor_templates/template.js'))
        expect(subject.delete(:removeButtons)).to eq 'Underline,Subscript,Superscript,Font,BGColor,Source'
        expect(subject.delete(:fontSize_sizes)).to eq fontSize_sizes
        expect(subject.blank?).to be_truthy
      end
    end

    context 'with advanced options' do
      let(:site) { cms_site }
      let(:group) { create(:cms_group, name: unique_id) }
      let(:role) { create(:cms_role, name: unique_id) }
      let(:admin_role) { create(:cms_role_admin, name: unique_id) }
      let(:user) do
        create(:cms_user, name: unique_id, email: "#{unique_id}@example.jp", in_password: "pass",
          group_ids: [group.id], cms_role_ids: [role.id])
      end
      let(:admin) do
        create(:cms_user, name: unique_id, email: "#{unique_id}@example.jp", in_password: "pass",
          group_ids: [group.id], cms_role_ids: [admin_role.id])
      end

      subject(:standard) { helper.ckeditor_editor_options(advanced: Cms::EditorExtension.allowed?(:use, user, site: site)) }
      subject(:advanced) { helper.ckeditor_editor_options(advanced: Cms::EditorExtension.allowed?(:use, admin, site: site)) }

      it "advanced: false" do
        expect(standard.delete(:extraPlugins)).to eq 'templates,justify,panelbutton,colorbutton,font'
        expect(standard.delete(:removePlugins)).to eq ''
        expect(standard.delete(:allowedContent)).to eq true
        expect(standard.delete(:height)).to eq '360px'
        expect(standard.delete(:templates)).to eq 'shirasagi'
        expect(standard.delete(:templates_files)).to include(start_with('/.s1/cms/editor_templates/template.js'))
        expect(standard.delete(:removeButtons)).to eq 'Underline,Subscript,Superscript,Font,BGColor,Source'
        expect(standard.delete(:fontSize_sizes)).to eq fontSize_sizes
        expect(standard.blank?).to be_truthy
      end

      it "advanced: true" do
        expect(advanced.delete(:extraPlugins)).to eq 'templates,justify,panelbutton,colorbutton,font'
        expect(advanced.delete(:removePlugins)).to eq ''
        expect(advanced.delete(:allowedContent)).to eq true
        expect(advanced.delete(:height)).to eq '360px'
        expect(advanced.delete(:templates)).to eq 'shirasagi'
        expect(advanced.delete(:templates_files)).to include(start_with('/.s1/cms/editor_templates/template.js'))
        expect(advanced.delete(:removeButtons)).to eq 'Underline,Subscript,Superscript,Font,BGColor'
        expect(advanced.delete(:fontSize_sizes)).to eq fontSize_sizes
        expect(advanced.blank?).to be_truthy
      end
    end
  end
end
