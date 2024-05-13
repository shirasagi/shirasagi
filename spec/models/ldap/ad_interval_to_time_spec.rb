require 'spec_helper'

describe Ldap, dbscope: :example do
  describe ".normalize_dn" do
    it do
      expect(Ldap.ad_interval_to_time("0")).to be_nil
      expect(Ldap.ad_interval_to_time(0)).to be_nil
      expect(Ldap.ad_interval_to_time("9223372036854775807")).to be_nil
      expect(Ldap.ad_interval_to_time(9_223_372_036_854_775_807)).to be_nil
    end

    it do
      expect(Ldap.ad_interval_to_time("133573332606108311").change(usec: 0)).to eq Time.zone.parse("2024-04-12 03:21:00")
      expect(Ldap.ad_interval_to_time(133_573_332_606_108_311).change(usec: 0)).to eq Time.zone.parse("2024-04-12 03:21:00")
    end

    it do
      expect(Ldap.ad_interval_to_time(nil)).to be_nil
      expect(Ldap.ad_interval_to_time("")).to be_nil
      expect(Ldap.ad_interval_to_time("xyz")).to be_nil
    end
  end
end
