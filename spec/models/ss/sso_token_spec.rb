require 'spec_helper'

describe SS::SSOToken, dbscope: :example do
  describe "#available?" do
    let(:now) { Time.zone.now.beginning_of_hour }
    subject do
      sso_token = nil
      Timecop.freeze(now) do
        sso_token = described_class.create_token!
      end
      sso_token
    end

    it do
      Timecop.freeze(now + Sys::Auth::Base::READY_STATE_EXPIRES_IN) do
        expect(subject.available?).to be_truthy
        expect(described_class.and_unavailable).to be_blank
      end

      Timecop.freeze(now + Sys::Auth::Base::READY_STATE_EXPIRES_IN + 1.second) do
        expect(subject.available?).to be_falsey
        expect(described_class.and_unavailable).to be_present
      end
    end
  end
end
