require 'spec_helper'
require Rails.root.join("lib/migrations/gws/20200120000000_memo_forward_email.rb")

RSpec.describe SS::Migration20200120000000, dbscope: :example do
  let(:site) { create :gws_group }
  let!(:forward0) { Gws::Memo::Forward.create(cur_site: site, cur_user: gws_user, default: "disabled") }
  let!(:forward1) { Gws::Memo::Forward.create(cur_site: site, cur_user: gws_user, default: "disabled") }
  let!(:forward2) { Gws::Memo::Forward.create(cur_site: site, cur_user: gws_user, default: "disabled") }
  let(:valid_email1) { "#{unique_id}@example.jp" }
  let(:invalid_email1) { unique_id }

  before do
    # forward1 has valid email address
    forward1[:email] = valid_email1
    forward1.save!

    # forward2 has invalid email address
    forward2[:email] = invalid_email1
    forward2.save!

    described_class.new.change
  end

  it do
    forward0.reload
    expect(forward0.default).to eq "disabled"
    expect(forward0[:email]).to be_blank
    expect(forward0.emails).to be_blank

    forward1.reload
    expect(forward1.default).to eq "disabled"
    expect(forward1[:email]).to be_blank
    expect(forward1.emails).to eq [ valid_email1 ]

    forward2.reload
    expect(forward2.default).to eq "disabled"
    expect(forward2[:email]).to be_blank
    expect(forward2.emails).to eq [ invalid_email1 ]
  end
end
