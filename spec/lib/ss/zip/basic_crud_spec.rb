require 'spec_helper'

describe SS::Zip::Writer do
  let(:path) { "#{tmpdir}/#{unique_id}.zip" }

  it do
    SS::Zip::Writer.create(path) do |zip|
      "logo.png".tap do |name|
        zip.add_file(name) do |io|
          IO.copy_stream("#{Rails.root}/spec/fixtures/ss/#{name}", io)
        end
      end
      "sample.js".tap do |name|
        zip.add_file(name) do |io|
          IO.copy_stream("#{Rails.root}/spec/fixtures/ss/#{name}", io)
        end
      end
      "shirasagi.pdf".tap do |name|
        zip.add_file(name) do |io|
          IO.copy_stream("#{Rails.root}/spec/fixtures/ss/#{name}", io)
        end
      end
      "ロゴ.png".tap do |name|
        zip.add_file(name) do |io|
          IO.copy_stream("#{Rails.root}/spec/fixtures/ss/#{name}", io)
        end
      end
    end

    Zip::File.open(path) do |zip|
      binary = zip.read(zip.get_entry("logo.png"))
      expect(binary).to eq File.binread("#{Rails.root}/spec/fixtures/ss/logo.png")

      binary = zip.read(zip.get_entry("sample.js"))
      expect(binary).to eq File.binread("#{Rails.root}/spec/fixtures/ss/sample.js")

      binary = zip.read(zip.get_entry("shirasagi.pdf"))
      expect(binary).to eq File.binread("#{Rails.root}/spec/fixtures/ss/shirasagi.pdf")

      "ロゴ.png".tap do |name|
        entry = zip.get_entry(name.dup.force_encoding(Encoding::ASCII_8BIT))
        expect(entry).to be_present

        binary = zip.read(entry)
        expect(binary).to be_present
        expect(binary).to eq File.binread("#{Rails.root}/spec/fixtures/ss/#{name}")
      end
    end
  end

  xcontext "archive with ruby zip" do
    it do
      Zip::File.open(path, Zip::File::CREATE) do |zip|
        "logo.png".tap do |name|
          zip.add(name, "#{Rails.root}/spec/fixtures/ss/#{name}")
        end
        "ロゴ.png".tap do |name|
          zip.add(name, "#{Rails.root}/spec/fixtures/ss/#{name}")
        end
      end

      Zip::File.open(path) do |zip|
        binary = zip.read(zip.get_entry("logo.png"))
        expect(binary).to eq File.binread("#{Rails.root}/spec/fixtures/ss/logo.png")

        "ロゴ.png".tap do |name|
          entry = zip.get_entry(name.dup.force_encoding(Encoding::ASCII_8BIT))
          expect(entry).to be_present

          binary = zip.read(entry)
          expect(binary).to be_present
          expect(binary).to eq File.binread("#{Rails.root}/spec/fixtures/ss/#{name}")
        end
      end
    end
  end
end
