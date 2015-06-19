require 'spec_helper'

describe Cms::EditorTemplate, dbscope: :example do
  describe ".search" do
    context "when nil is given" do
      subject { described_class.search(nil) }
      it { expect(subject.selector.to_h).to be_empty }
    end

    context "when name is given" do
      subject { described_class.search(name: "名前 なまえ") }
      it { expect(subject.selector.to_h).to include("name" => include("$all" => include(/名前/i, /なまえ/i))) }
    end

    context "when name includes regex meta characters" do
      subject { described_class.search(name: "名|前 な(*.?)まえ") }
      it { expect(subject.selector.to_h).to include("name" => include("$all" => include(/名\|前/i, /な\(\*\.\?\)まえ/i))) }
    end

    context "when keyword is given" do
      subject { described_class.search(keyword: "キーワード1 キーワード2") }
      it { expect(subject.selector.to_h).to include("$and" => include("$or" => include("name" => /キーワード1/i))) }
      it { expect(subject.selector.to_h).to include("$and" => include("$or" => include("name" => /キーワード2/i))) }
    end
  end

  describe ".ckeditor?" do
    context "when editor is ckeditor" do
      before do
        @save = SS.config.cms.html_editor
        SS.config.replace_value_at(:cms, :html_editor, "ckeditor")
      end
      after do
        SS.config.replace_value_at(:cms, :html_editor, @save)
      end
      subject { described_class.ckeditor? }
      it { is_expected.to be_truthy }
    end

    context "when editor is tinymce" do
      before do
        @save = SS.config.cms.html_editor
        SS.config.replace_value_at(:cms, :html_editor, "tinymce")
      end
      after do
        SS.config.replace_value_at(:cms, :html_editor, @save)
      end
      subject { described_class.ckeditor? }
      it { is_expected.to be_falsey }
    end
  end

  describe ".tinymce?" do
    context "when editor is ckeditor" do
      before do
        @save = SS.config.cms.html_editor
        SS.config.replace_value_at(:cms, :html_editor, "ckeditor")
      end
      after do
        SS.config.replace_value_at(:cms, :html_editor, @save)
      end
      subject { described_class.tinymce? }
      it { is_expected.to be_falsey }
    end

    context "when editor is tinymce" do
      before do
        @save = SS.config.cms.html_editor
        SS.config.replace_value_at(:cms, :html_editor, "tinymce")
      end
      after do
        SS.config.replace_value_at(:cms, :html_editor, @save)
      end
      subject { described_class.tinymce? }
      it { is_expected.to be_truthy }
    end
  end

  describe "#export_for_ckeditor" do
    context "when thumb is not given" do
      let(:site) { cms_site }
      let(:template) { create(:cms_editor_template, site: site) }
      subject { JSON.parse(template.export_for_ckeditor) }

      it do
        expect(subject).to include("title" => template.name)
        expect(subject).to include("description" => template.description)
        expect(subject).to include("html" => template.html)
        expect(subject).to include("image" => SS.config.cms.editor_template_thumb.gsub(/^\//, ''))
      end
    end

    context "when thumb is given" do
      let(:site) { cms_site }
      let(:thumb_path) { Rails.root.join("spec", "fixtures", "ss", "logo.png")}
      let(:thumb_file) { Fs::UploadedFile.create_from_file(thumb_path, basename: "spec") }
      let(:template) { create(:cms_editor_template, site: site, in_thumb: thumb_file) }
      subject { JSON.parse(template.export_for_ckeditor) }

      it do
        expect(subject).to include("title" => template.name)
        expect(subject).to include("description" => template.description)
        expect(subject).to include("html" => template.html)
        expect(subject).to include("image" => start_with("fs/"))
      end
    end
  end
end
