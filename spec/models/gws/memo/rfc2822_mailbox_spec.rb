require 'spec_helper'

RSpec.describe Gws::Memo, type: :model do
  let(:site) { gws_site }

  describe '.rfc2822_mailbox' do
    context 'with blank email' do
      it do
        expect(described_class.rfc2822_mailbox(site: site, name: "鈴木　茂", email: "", sub: "users")).to \
          eq "\"鈴木 茂\" <6Yi05pyoIOiMgg@users.replace-me.example.jp>"
      end
    end
  end
end
