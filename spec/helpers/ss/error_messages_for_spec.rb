require 'spec_helper'

RSpec.describe SS::ErrorMessagesFor, type: :helper do
  describe "#error_messages_for" do
    context "without instance" do
      subject { helper.error_messages_for(:item) }
      it { is_expected.to be_blank }
    end

    context "with instance which has no error" do
      subject { helper.error_messages_for(:item) }
      before { @item = create(:article_page) }
      it { is_expected.to be_blank }
    end

    context "with instance which has errors" do
      subject { helper.error_messages_for(:item) }

      before do
        @item = Article::Page.new
        @item.valid?
      end

      it do
        is_expected.to include("<div id=\"errorExplanation\" class=\"errorExplanation\">")
        is_expected.to include("<h2>#{I18n.t("activerecord.errors.template.header", count: @item.errors.count)}</h2>")
        is_expected.to include("<p>#{I18n.t("activerecord.errors.template.body")}</p>")
        @item.errors.full_messages.each do |message|
          is_expected.to include("<li>#{message}</li>")
        end
      end
    end

    context "with instance having errors and header_message as false" do
      subject { helper.error_messages_for(:item, header_message: false) }

      before do
        @item = Article::Page.new
        @item.valid?
      end

      it do
        is_expected.to include("<div id=\"errorExplanation\" class=\"errorExplanation\">")
        is_expected.not_to include("<h2>#{I18n.t("activerecord.errors.template.header", count: @item.errors.count)}</h2>")
        is_expected.to include("<p>#{I18n.t("activerecord.errors.template.body")}</p>")
        @item.errors.full_messages.each do |message|
          is_expected.to include("<li>#{message}</li>")
        end
      end
    end
  end
end
