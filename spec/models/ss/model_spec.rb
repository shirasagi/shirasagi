require 'spec_helper'

describe SS::Model do
  describe ".copy_errors" do
    let(:src) { Article::Page.new }
    let(:dest) { Article::Page.new }

    context "without prefix" do
      it do
        src.valid?
        SS::Model.copy_errors(src, dest)
        expect(dest.errors).to be_present
      end
    end

    context "with prefix" do
      let(:prefix) { "#{unique_id}: " }

      it do
        src.valid?
        SS::Model.copy_errors(src, dest, prefix: prefix)
        expect(dest.errors).to be_present
        dest.errors.full_messages.each do |message|
          expect(message).to start_with(prefix)
        end
      end
    end
  end
end
