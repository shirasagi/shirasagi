require 'spec_helper'

RSpec.describe Gws::Memo, type: :model do
  let(:site) { gws_site }

  describe '.rfc2822_mailbox' do
    context 'with blank email' do
      context 'with atext' do
        let(:name) { "name-h40182e34dd" }

        it do
          expect(described_class.rfc2822_mailbox(site: site, name: name, email: "", sub: "users")).to \
            eq "#{name} <#{name}@users.replace-me.example.jp>"
        end
      end

      context 'with non-atext' do
        let(:name) { "鈴木#{Cms::SyntaxChecker::FULL_WIDTH_SPACE}茂" }

        it do
          expect(described_class.rfc2822_mailbox(site: site, name: name, email: "", sub: "users")).to \
            eq "\"#{name}\" <6Yi05pyo44CA6IyC@users.replace-me.example.jp>"
        end
      end
    end
  end
end
