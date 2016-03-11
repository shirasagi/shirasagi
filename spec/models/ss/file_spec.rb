require 'spec_helper'

describe SS::File do
  describe "shirasagi-434" do
    before do
      @tmpdir = ::Dir.mktmpdir
      @file_path = "#{@tmpdir}/#{filename}"
      File.open(@file_path, "wb") do |file|
        file.write [1]
      end
    end

    after do
      ::FileUtils.rm_rf(@tmpdir)
    end

    before do
      # we need custom setting for jtd
      @save_config = SS.config.env.mime_type_map
      SS.config.replace_value_at(:env, :mime_type_map, mime_type_map)
    end

    after do
      SS.config.replace_value_at(:env, :mime_type_map, @save_config)
    end

    subject do
      file = SS::File.new model: "article/page"
      Fs::UploadedFile.create_from_file(@file_path, basename: "spec", content_type: "application/octet-stream") do |f|
        file.in_file = f
        file.save!
        file.in_file = nil
      end
      file.reload
      file
    end

    context "when pdf file is uploaded with application/octet-stream" do
      let(:filename) { "a.pdf" }
      let(:mime_type_map) { {} }
      its(:content_type) { is_expected.to eq "application/pdf" }
    end

    context "when js file is uploaded with application/octet-stream" do
      let(:filename) { "a.js" }
      let(:mime_type_map) { {} }
      its(:content_type) { is_expected.to eq "application/javascript" }
    end

    context "when jtd file is uploaded with application/octet-stream" do
      let(:filename) { "a.jtd" }
      let(:mime_type_map) { { "jtd" => "application/x-js-taro" } }
      its(:content_type) { is_expected.to eq "application/x-js-taro" }
    end

    context "when wmv file is uploaded with application/octet-stream" do
      let(:filename) { "a.wmv" }
      let(:mime_type_map) { { "wmv" => "video/x-ms-wmv" } }
      its(:content_type) { is_expected.to eq "video/x-ms-wmv" }
    end
  end

  describe "#validate_size" do
    let(:test_file_path) { Rails.root.join("spec", "fixtures", "ss", "logo.png") }
    let(:test_file) { Fs::UploadedFile.create_from_file(test_file_path, basename: "spec") }

    after do
      test_file.close unless test_file.closed?
    end

    subject do
      file = SS::File.new model: "article/page"
      file.in_file = test_file
      file
    end

    context "when max_filesize is limited" do
      before do
        @save_config = SS.config.env.max_filesize
        SS.config.replace_value_at(:env, :max_filesize, 50)
      end

      after do
        SS.config.replace_value_at(:env, :max_filesize, @save_config)
      end

      it do
        expect(subject.save).to be_falsey
        expect(subject.errors[:base]).not_to be_empty
        expect(subject.errors[:base].first).to include("logo.png", "サイズが大きすぎます", "制限値: 50バイト")
      end
    end

    context "when max_filesize_ext is limited" do
      before do
        @save_config = SS.config.env.max_filesize_ext
        SS.config.replace_value_at(:env, :max_filesize_ext, { "png" => 23 })
      end

      after do
        SS.config.replace_value_at(:env, :max_filesize_ext, @save_config)
      end

      it do
        expect(subject.save).to be_falsey
        expect(subject.errors[:base]).not_to be_empty
        expect(subject.errors[:base].first).to include("logo.png", "サイズが大きすぎます", "制限値: 23バイト")
      end
    end
  end
end
