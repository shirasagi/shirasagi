require 'spec_helper'

describe SS::File do
  describe "shirasagi-434" do
    context "when pdf file is uploaded with application/octet-stream" do
      before do
        @tmpdir = ::Dir.mktmpdir
        @pdf_file_path = "#{@tmpdir}/a.pdf"
        File.open(@pdf_file_path, "wb") do |file|
          file.write [1]
        end
      end

      after do
        ::FileUtils.rm_rf(@tmpdir)
      end

      it do
        file = SS::File.new model: "article/page"
        Fs::UploadedFile.create_from_file(@pdf_file_path, basename: "spec", content_type: "application/octet-stream") do |f|
          file.in_file = f
          file.save!
          file.in_file = nil
        end
        file.reload

        expect(file.content_type).to eq "application/pdf"
      end
    end

    context "when js file is uploaded with application/octet-stream" do
      before do
        @tmpdir = ::Dir.mktmpdir
        @js_file_path = "#{@tmpdir}/a.js"
        File.open(@js_file_path, "wb") do |file|
          file.write [1]
        end
      end

      after do
        ::FileUtils.rm_rf(@tmpdir)
      end

      it do
        file = SS::File.new model: "article/page"
        Fs::UploadedFile.create_from_file(@js_file_path, basename: "spec", content_type: "application/octet-stream") do |f|
          file.in_file = f
          file.save!
          file.in_file = nil
        end
        file.reload

        expect(file.content_type).to eq "application/javascript"
      end
    end
  end
end
