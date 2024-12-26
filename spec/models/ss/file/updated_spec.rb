require 'spec_helper'

describe SS::File, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:file) { "#{Rails.root}/spec/fixtures/ss/logo.png" }
  let!(:item) { tmp_ss_file(contents: file, site: site) }

  let(:before_updated) { item.updated.change(sec: 0) }
  let(:after_file_updated) { item.updated.change(sec: 0) }
  let(:after_thumb_updated) { item.thumb.updated.change(sec: 0) }

  context "no changed" do
    it do
      before_updated
      Timecop.travel(1.hour.from_now) do
        item.update
        item.reload
        expect(after_file_updated).to eq before_updated
        expect(after_thumb_updated).to eq after_file_updated
      end
    end
  end

  context "update filename" do
    it do
      before_updated
      Timecop.travel(1.hour.from_now) do
        item.filename = unique_id
        item.update
        item.reload
        expect(after_file_updated > before_updated).to be_truthy
        expect(after_thumb_updated).to eq after_file_updated
      end
    end
  end

  context "update in_file (same file)" do
    let!(:in_file) { Rack::Test::UploadedFile.new(file, nil, true) }

    it do
      before_updated
      Timecop.travel(1.hour.from_now) do
        item.in_file = in_file
        item.update
        item.reload
        expect(after_file_updated > before_updated).to be_truthy
        expect(after_thumb_updated).to eq after_file_updated
      end
    end
  end
end
