require 'spec_helper'

describe ApplicationHelper do
  include ActionView::Helpers
  include ApplicationHelper

  describe ".mail_to_entity" do
    context "when only email address is given" do
      subject { mail_to_entity("test@example.jp") }
      it { is_expected.to eq '<a href="mailto:test&#64;example&#46;jp">test&#64;example&#46;jp</a>' }
    end

    context "when email address and name is given" do
      subject { mail_to_entity("test@example.jp", "テスト") }
      it { is_expected.to eq '<a href="mailto:test&#64;example&#46;jp">テスト</a>' }
    end
  end
end
