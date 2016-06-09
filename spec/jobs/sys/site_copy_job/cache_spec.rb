require 'spec_helper'

describe Sys::SiteCopyJob, dbscope: :example do
  describe "cache" do
    subject { Sys::SiteCopyJob.new }

    it "returns empty hash" do
      expect(subject.cache_store).to eq({})
    end

    it "returns nil" do
      expect(subject.cache(:id, :key)).to be_nil
    end

    it "executes a block only once" do
      count = 0
      10.times do
        subject.cache(:id, :key) {
          count += 1
          nil
        }
      end
      expect(count).to eq 1
    end
  end
end
