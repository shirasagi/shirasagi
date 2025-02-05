require 'spec_helper'

describe SS::File, dbscope: :example do
  let(:basename) { "logo-#{unique_id}.webp" }
  subject! { tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.webp", basename: basename) }
  let(:thumb_basename) { "#{::File.basename(subject.filename, ".*")}_thumb.#{subject.extname}" }

  its(:valid?) { is_expected.to be_truthy }
  its(:path) { is_expected.to eq "#{SS::File.root}/ss_files/#{subject.id}/_/#{subject.id}" }
  its(:url) { is_expected.to eq "/fs/#{subject.id}/_/#{subject.filename}" }
  its(:thumb_url) { is_expected.to eq "/fs/#{subject.id}/_/#{thumb_basename}" }
  its(:public?) { is_expected.to be_falsey }
  its(:public_dir) { is_expected.to be_nil }
  its(:public_path) { is_expected.to be_nil }
  its(:full_url) { is_expected.to be_nil }
  its(:name) { is_expected.to eq basename }
  its(:humanized_name) { is_expected.to eq "#{::File.basename(basename, ".*")} (WEBP 8.99KB)" }
  its(:download_filename) { is_expected.to eq basename }
  its(:basename) { is_expected.to eq basename }
  its(:extname) { is_expected.to eq 'webp' }
  its(:content_type) { is_expected.to eq "image/webp" }
  its(:image?) { is_expected.to be_truthy }
  it do
    subject.thumb.tap do |thumb|
      expect(thumb).to be_a(SS::VariantProcessor::Variant)
      expect(thumb.path).to eq "#{SS::File.root}/ss_files/#{subject.id}/_/#{subject.id}_thumb"
      expect(thumb.url).to eq "/fs/#{subject.id}/_/#{::File.basename(basename, ".*")}_thumb.webp"
      expect(thumb.full_url).to be_nil
      expect(thumb.name).to eq "#{::File.basename(basename, ".*")}_thumb.webp"
      expect(thumb.filename).to eq "#{::File.basename(basename, ".*")}_thumb.webp"
      expect(thumb.download_filename).to eq "#{::File.basename(basename, ".*")}_thumb.webp"
      expect(thumb.content_type).to eq "image/webp"
      expect(thumb.size).to eq ::File.size(thumb.path)
      thumb.image_dimension.tap do |width, height|
        expect(width).to be <= SS::ImageConverter::DEFAULT_THUMB_WIDTH
        expect(height).to be <= SS::ImageConverter::DEFAULT_THUMB_HEIGHT
      end
    end
  end
end
