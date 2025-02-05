require 'spec_helper'

describe SS::File, dbscope: :example do
  let(:basename) { "logo-#{unique_id}.avif" }
  subject! { tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.avif", basename: basename) }
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
  its(:humanized_name) { is_expected.to eq "#{::File.basename(basename, ".*")} (AVIF 15.6KB)" }
  its(:download_filename) { is_expected.to eq basename }
  its(:basename) { is_expected.to eq basename }
  its(:extname) { is_expected.to eq 'avif' }
  its(:content_type) { is_expected.to eq "image/avif" }
  its(:image?) { is_expected.to be_truthy }
end
