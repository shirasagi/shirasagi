require 'spec_helper'

describe Member::PhotoFile, dbscope: :example do
  describe "member/photo_file" do
    let(:file_path) { "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg" }
    let(:basename) { File.basename(file_path) }

    shared_examples "member/photo_file is" do
      context "without resizing" do
        subject do
          Fs::UploadedFile.create_from_file(file_path, basename: basename) do |upload_file|
            new_file = described_class.new
            new_file.site_id = cms_site.id
            new_file.user_id = cms_user.id
            new_file.filename = upload_file.original_filename
            new_file.in_file = upload_file
            new_file.save!
            new_file
          end
        end

        it do
          expect(subject).to be_persisted
          expect(subject).to be_valid
          expect(::Fs.size(subject.path)).to be > 0
          expect(subject.site_id).to eq cms_site.id
          expect(subject.user_id).to eq cms_user.id
          expect(subject.model).to eq "member/photo"
          expect(subject.image_dimension).to eq [ 712, 210 ]
          expect(subject.content_type).to eq "image/jpeg"

          # variant test
          expect(subject.variants.count).to eq 2
          subject.variants[:thumb].tap do |variant|
            expect(variant).to be_present
            expect(variant.variant_name).to eq :thumb

            expect(variant.id).to eq subject.id
            expect(variant.site_id).to eq subject.site_id
            expect(variant.user_id).to eq subject.user_id
            expect(variant.content_type).to eq subject.content_type
            expect(variant.updated).to eq subject.updated
            expect(variant.created).to eq subject.created

            expect(variant.path).to end_with("_thumb")
            expect(variant.public_dir).to eq subject.public_dir
            expect(variant.public_path).to be_present
            expect(variant.url).to be_present
            expect(variant.full_url).to be_present

            expect(variant.name).to be_present
            expect(variant.filename).to be_present
            expect(variant.size).to be_present



            expect(variant.image_dimension).to eq [ 360, 106 ]
          end
          subject.variants[:detail].tap do |variant|
            expect(variant).to be_present
            expect(variant.variant_name).to eq :detail

            expect(variant.id).to eq subject.id
            expect(variant.site_id).to eq subject.site_id
            expect(variant.user_id).to eq subject.user_id
            expect(variant.content_type).to eq subject.content_type
            expect(variant.updated).to eq subject.updated
            expect(variant.created).to eq subject.created

            expect(variant.path).to end_with("_detail")
            expect(variant.public_dir).to eq subject.public_dir
            expect(variant.public_path).to be_present
            expect(variant.url).to be_present
            expect(variant.full_url).to be_present

            expect(variant.name).to be_present
            expect(variant.filename).to be_present
            expect(variant.size).to be_present
            expect(variant.image_dimension).to eq [ 712, 210 ]
          end
          subject.variants["thumb"].tap do |variant|
            expect(variant).to be_present
            expect(variant.variant_name).to eq :thumb
          end
          subject.variants["detail"].tap do |variant|
            expect(variant).to be_present
            expect(variant.variant_name).to eq :detail
          end
          subject.variants[unique_id].tap do |variant|
            expect(variant).to be_nil
          end
          subject.variants[0].tap do |variant|
            expect(variant).to be_nil
          end
          subject.variants[{ width: 160, height: 120 }].tap do |variant|
            expect(variant).to be_present
            expect(variant.variant_name).to eq :thumb
          end
          subject.variants[{ width: 800, height: 600 }].tap do |variant|
            expect(variant).to be_present
            expect(variant.variant_name).to eq :detail
          end
          subject.variants[{ width: 1200, height: 900 }].tap do |variant|
            expect(variant).to be_present
            expect(variant.variant_name).to eq "1200x900"

            expect(variant.id).to eq subject.id
            expect(variant.site_id).to eq subject.site_id
            expect(variant.user_id).to eq subject.user_id
            expect(variant.content_type).to eq subject.content_type
            expect(variant.updated).to eq subject.updated
            expect(variant.created).to eq subject.created

            expect(variant.path).to end_with("_1200x900")
          end
        end
      end

      context "with resizing" do
        subject do
          Fs::UploadedFile.create_from_file(file_path, basename: basename) do |upload_file|
            new_file = described_class.new
            new_file.filename = upload_file.original_filename
            new_file.in_file = upload_file
            new_file.resizing = [ 180, 180 ]
            new_file.save!
            new_file
          end
        end

        it do
          expect(subject).to be_persisted
          expect(subject).to be_valid
          expect(subject.site_id).to be_blank
          expect(subject.user_id).to be_blank
          expect(subject.model).to eq "member/photo"
          expect(::Fs.size(subject.path)).to be > 0
          expect(subject.image_dimension).to eq [ 180, 53 ]

          expect(subject.variants.count).to eq 2
          expect(subject.variants[:thumb]).to be_present
          expect(subject.variants[:thumb].url).to be_present



          expect(subject.variants[:thumb].image_dimension).to eq [ 180, 53 ]
          expect(subject.variants[:detail]).to be_present
          expect(subject.variants[:detail].url).to be_present
          expect(subject.variants[:detail].image_dimension).to eq [ 180, 53 ]
        end
      end
    end

    context "with ImageMagick6/7" do
      include_context "member/photo_file is"
    end

    context "with GraphicsMagick" do
      # As of MiniMagick 5+, GraphicsMagick isn't officially supported. However, we can work with it
      around do |example|
        save_cli_prefix = nil
        MiniMagick.configure do |config|
          save_cli_prefix = config.cli_prefix
          config.cli_prefix = "gm"
        end

        example.run
      ensure
        MiniMagick.configure do |config|
          config.cli_prefix = save_cli_prefix
        end
      end

      include_context "member/photo_file is"
    end
  end
end
