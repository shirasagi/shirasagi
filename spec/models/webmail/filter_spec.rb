require 'spec_helper'

describe Webmail::Filter, type: :model, dbscope: :example do
  let(:user) { create :webmail_user }
  let(:setting) { user.imap_settings.first }
  let(:imap) { Webmail::Imap::Base.new_by_user(user, setting) }

  describe "with default factory" do
    subject { create :webmail_filter, imap.account_scope.merge(cur_user: user, imap: imap) }

    it do
      expect(subject).to be_valid
      expect(subject.conditions_summary).to be_present
      expect { subject.mailbox_required? }.not_to raise_error
      expect(subject.decode_mailbox).to be_present
      expect(subject.search_keys).to be_present
    end
  end

  describe "#search_keys" do
    subject { create :webmail_filter, imap.account_scope.merge(cur_user: user, imap: imap) }

    context "with a single condition" do
      let(:field) { %w(from to cc subject body).sample }
      let(:value) { unique_id }

      context "with and conjunction" do
        it "with include operator" do
          subject.conjunction = "and"
          subject.conditions = [{ field: field, operator: "include", value: value }]
          subject.save!

          expect(subject.search_keys).to eq [field.upcase, value]
        end

        it "with exclude operator" do
          subject.conjunction = "and"
          subject.conditions = [{ field: field, operator: "exclude", value: value }]
          subject.save!

          expect(subject.search_keys).to eq ["NOT", field.upcase, value]
        end
      end

      context "with or conjunction" do
        it "with include operator" do
          subject.conjunction = "or"
          subject.conditions = [{ field: field, operator: "include", value: value }]
          subject.save!

          expect(subject.search_keys).to eq [field.upcase, value]
        end

        it "with exclude operator" do
          subject.conjunction = "or"
          subject.conditions = [{ field: field, operator: "exclude", value: value }]
          subject.save!

          expect(subject.search_keys).to eq ["NOT", field.upcase, value]
        end
      end
    end

    context "with two conditions" do
      let(:field1) { %w(from to cc subject body).sample }
      let(:field2) { %w(from to cc subject body).sample }
      let(:value1) { unique_id }
      let(:value2) { unique_id }

      context "with and conjunction" do
        it "with include operator" do
          subject.conjunction = "and"
          subject.conditions = [
            { field: field1, operator: "include", value: value1 },
            { field: field2, operator: "include", value: value2 }
          ]
          subject.save!

          expect(subject.search_keys).to eq [field1.upcase, value1, field2.upcase, value2]
        end

        it "with exclude operator" do
          subject.conjunction = "and"
          subject.conditions = [
            { field: field1, operator: "exclude", value: value1 },
            { field: field2, operator: "exclude", value: value2 }
          ]
          subject.save!

          expect(subject.search_keys).to eq ["NOT", field1.upcase, value1, "NOT", field2.upcase, value2]
        end
      end

      context "with or conjunction" do
        it "with include operator" do
          subject.conjunction = "or"
          subject.conditions = [
            { field: field1, operator: "include", value: value1 },
            { field: field2, operator: "include", value: value2 }
          ]
          subject.save!

          expect(subject.search_keys).to eq ["OR", field1.upcase, value1, field2.upcase, value2]
        end

        it "with exclude operator" do
          subject.conjunction = "or"
          subject.conditions = [
            { field: field1, operator: "exclude", value: value1 },
            { field: field2, operator: "exclude", value: value2 }
          ]
          subject.save!

          expect(subject.search_keys).to eq ["OR", "NOT", field1.upcase, value1, "NOT", field2.upcase, value2]
        end
      end
    end

    context "with three conditions" do
      let(:field1) { %w(from to cc subject body).sample }
      let(:field2) { %w(from to cc subject body).sample }
      let(:field3) { %w(from to cc subject body).sample }
      let(:value1) { unique_id }
      let(:value2) { unique_id }
      let(:value3) { unique_id }

      context "with and conjunction" do
        it "with include operator" do
          subject.conjunction = "and"
          subject.conditions = [
            { field: field1, operator: "include", value: value1 },
            { field: field2, operator: "include", value: value2 },
            { field: field3, operator: "include", value: value3 }
          ]
          subject.save!

          expect(subject.search_keys).to eq [field1.upcase, value1, field2.upcase, value2, field3.upcase, value3]
        end

        it "with exclude operator" do
          subject.conjunction = "and"
          subject.conditions = [
            { field: field1, operator: "exclude", value: value1 },
            { field: field2, operator: "exclude", value: value2 },
            { field: field3, operator: "exclude", value: value3 }
          ]
          subject.save!

          expect(subject.search_keys).to eq [ "NOT", field1.upcase, value1, "NOT", field2.upcase, value2, "NOT", field3.upcase, value3 ]
        end
      end

      context "with or conjunction" do
        it "with include operator" do
          subject.conjunction = "or"
          subject.conditions = [
            { field: field1, operator: "include", value: value1 },
            { field: field2, operator: "include", value: value2 },
            { field: field3, operator: "include", value: value3 }
          ]
          subject.save!

          expect(subject.search_keys).to eq ["OR", field1.upcase, value1, "OR", field2.upcase, value2, field3.upcase, value3]
        end

        it "with exclude operator" do
          subject.conjunction = "or"
          subject.conditions = [
            { field: field1, operator: "exclude", value: value1 },
            { field: field2, operator: "exclude", value: value2 },
            { field: field3, operator: "exclude", value: value3 }
          ]
          subject.save!

          expect(subject.search_keys).to eq [ "OR", "NOT", field1.upcase, value1, "OR", "NOT", field2.upcase, value2, "NOT", field3.upcase, value3 ]
        end
      end
    end
  end
end
