require 'spec_helper'

describe Webmail::ImapSetting, type: :model, dbscope: :example do
  describe ".default" do
    it do
      expect(Webmail::ImapSetting.default).to be_valid
    end
  end
end
