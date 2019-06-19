require 'spec_helper'

describe Gws::Group, type: :model, dbscope: :example do
  describe "#sender_address" do
    subject { gws_site }
    let(:sender_name) { unique_id }
    let(:sender_email) { "#{unique_id}@example.jp" }
    let(:sender_user) { gws_user }

    context "when all sender fields are blank" do
      before do
        subject.set(sender_name: nil, sender_email: nil, sender_user_id: nil)
      end

      its(:sender_address) { is_expected.to eq SS.config.mail.default_from }
    end

    context "when only sender_name is given" do
      before do
        subject.set(sender_name: sender_name, sender_email: nil, sender_user_id: nil)
      end

      its(:sender_address) { is_expected.to eq SS.config.mail.default_from }
    end

    context "when only sender_email is given" do
      before do
        subject.set(sender_name: nil, sender_email: sender_email, sender_user_id: nil)
      end

      its(:sender_address) { is_expected.to eq sender_email }
    end

    context "when sender_name and sender_email is given" do
      before do
        subject.set(sender_name: sender_name, sender_email: sender_email, sender_user_id: nil)
      end

      its(:sender_address) { is_expected.to eq "#{sender_name} <#{sender_email}>" }
    end

    context "when only sender_user is given" do
      before do
        sender_user.set(name: unique_id, email: "#{unique_id}@example.jp")
        subject.set(sender_name: nil, sender_email: nil, sender_user_id: sender_user.id)
      end

      its(:sender_address) { is_expected.to eq "#{sender_user.name} <#{sender_user.email}>" }
    end
  end
end
