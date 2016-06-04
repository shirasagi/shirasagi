require 'spec_helper'

describe Cms::File, type: :model, dbscope: :example do
  let(:site) { cms_site }

  describe "basic attributes" do
    let(:test_file_path) { Rails.root.join("spec", "fixtures", "ss", "logo.png") }

    subject do
      file = Cms::File.new model: "cms/file", site_id: site.id
      Fs::UploadedFile.create_from_file(test_file_path, basename: "spec") do |test_file|
        file.in_file = test_file
        file.save!
      end
      file
    end

    its(:model) { is_expected.to eq "cms/file" }
    its(:state) { is_expected.to eq "closed" }
    its(:name) { is_expected.to eq "logo.png" }
    its(:filename) { is_expected.to eq "logo.png" }
    its(:size) { is_expected.to eq ::File.size(subject.path) }
    its(:content_type) { is_expected.to eq "image/png" }
    its(:site_id) { is_expected.to eq site.id }
  end
end
