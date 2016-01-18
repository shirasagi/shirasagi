require 'spec_helper'

RSpec.describe Ckan::Part::Status, type: :model, dbscope: :example do
  describe "validation" do
    subject { @status.valid? }

    before { @status = build :ckan_part_status }
    it { is_expected.to be_truthy }

    describe "ckan_url" do
      context "valid format http" do
        before { @status.ckan_url = 'http://example.com' }
        it { is_expected.to be_truthy }
      end

      context "valid format https" do
        before { @status.ckan_url = 'https://example.com' }
        it { is_expected.to be_truthy }
      end

      context "invalid format" do
        before { @status.ckan_url = 'ftp://example.com' }
        it { is_expected.to be_falsy }
      end
    end

    describe "ckan_status" do
      %w(dataset tag group related_item).each do |e|
        context "valid status of \"#{e}\"" do
          before { @status.ckan_status = e }
          it { is_expected.to be_truthy }
        end
      end

      context "invalid status" do
        before { @status.ckan_status = 'fake_status' }
        it { is_expected.to be_falsy }
      end
    end
  end
end
