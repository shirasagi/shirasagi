require 'spec_helper'

describe SS::Config do
  describe "env" do
    it { expect(SS::Config.env.storage).not_to be_nil }
  end

  describe "cms" do
    it { expect(SS::Config.cms.serve_static_pages).not_to be_nil }
  end
end
