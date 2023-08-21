# require 'spec_helper'
#
# describe SS::ThumbFile, dbscope: :example do
#   before do
#     @save_file_url_with = SS.config.ss.file_url_with
#     SS.config.replace_value_at(:ss, :file_url_with, "name")
#   end
#
#   after do
#     SS.config.replace_value_at(:ss, :file_url_with, @save_file_url_with)
#   end
#
#   context "with item related to sub-dir site" do
#     let(:site0) { ss_site }
#     let(:site1) { create(:ss_site_subdir, domains: site0.domains, parent_id: site0.id) }
#     let(:base_of_name) { ss_japanese_text }
#     let(:name) { "#{base_of_name}.png" }
#     let(:base_file) { create :ss_file, site_id: site1.id, name: name }
#     subject { base_file.thumb }
#
#     its(:valid?) { is_expected.to be_truthy }
#     its(:path) { is_expected.to eq "#{SS::File.root}/ss_files/#{subject.id}/_/#{subject.id}" }
#     its(:url) { is_expected.to eq "/fs/#{base_file.id}/_/thumb/#{subject.filename}" }
#     its(:thumb_url) { is_expected.to eq "/fs/#{base_file.id}/_/thumb/#{subject.filename}" }
#     its(:public?) { is_expected.to be_falsey }
#     its(:public_dir) { is_expected.to eq "#{site0.root_path}/fs/#{base_file.id}/_/thumb" }
#     its(:public_path) { is_expected.to eq "#{site0.root_path}/fs/#{base_file.id}/_/thumb/#{subject.filename}" }
#     its(:full_url) { is_expected.to eq "http://#{site0.domain}/fs/#{base_file.id}/_/thumb/#{subject.filename}" }
#     its(:name) { is_expected.to eq base_file.filename }
#     its(:humanized_name) { is_expected.to match /^#{::File.basename(base_file.filename, ".*")} \(PNG \d.\d\dKB\)$/ }
#     its(:download_filename) { is_expected.to eq base_file.filename }
#     its(:basename) { is_expected.to eq base_file.filename }
#     its(:extname) { is_expected.to eq 'png' }
#     its(:image?) { is_expected.to be_truthy }
#   end
# end
