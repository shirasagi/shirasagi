require 'spec_helper'

describe SS::Config do
  describe "#env" do
    it { expect(SS.config.env.storage).not_to be_nil }
  end

  describe "#method_missing" do
    it { expect(SS.config.cms.serve_static_pages).not_to be_nil }

    it "not to raise NoMethodError" do
      method_name = "method_#{unique_id}".to_sym
      expect { SS.config.send(method_name) }.not_to raise_error
    end
  end
end
