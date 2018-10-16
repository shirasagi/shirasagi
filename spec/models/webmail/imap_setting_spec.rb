require 'spec_helper'

describe Webmail::ImapSetting, type: :model, dbscope: :example do
  describe ".default" do
    it do
      expect(Webmail::ImapSetting.default).to be_valid
    end

    it do
      setting1 = Webmail::ImapSetting.default
      setting2 = Webmail::ImapSetting.default
      expect(setting1.object_id).not_to eq setting2.object_id
    end
  end
end
