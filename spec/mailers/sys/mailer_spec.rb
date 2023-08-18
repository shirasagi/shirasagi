require 'spec_helper'

describe Sys::Mailer, type: :mailer, dbscope: :example do
  let(:user1) { create :ss_user, email: "user1@example.jp" }
  let(:user2) { create :ss_user, email: "user2@example.jp" }

  describe "#test_mail" do
    let(:mail) do
      Sys::Mailer.test_mail(
        from: user1.email,
        to: user2.email,
        subject: "subject",
        body: "body"
      )
    end

    it "mail attributes" do
      expect(mail.from.first).to eq user1.email
      expect(mail.to.first).to eq user2.email
      expect(mail.subject.to_s).not_to eq ""
      expect(mail.body.to_s).not_to eq ""
    end
  end
end
