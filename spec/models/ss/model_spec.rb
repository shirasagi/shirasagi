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

  describe ".container_of" do
    context "when nil is given" do
      it do
        expect(SS::Model.container_of(nil)).to be_nil
      end
    end

    context "when regular model is given" do
      let!(:item) { cms_site }

      it do
        expect(SS::Model.container_of(item)).to eq item
      end
    end

    context "when embedded model is given" do
      let!(:site) { cms_site }
      let!(:user) { cms_user }
      let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
      let!(:column1) do
        create(:cms_column_file_upload, cur_site: site, cur_form: form, order: 1, file_type: "image")
      end
      let!(:item) { create :article_page, cur_site: site, cur_user: user, form: form }
      let!(:file1) { tmp_ss_file(site: site, user: user, contents: "#{Rails.root}/spec/fixtures/ss/logo.png") }

      before do
        item.column_values = [
          column1.value_type.new(column: column1, file_id: file1.id, file_label: file1.humanized_name),
        ]
        item.save!
      end

      it do
        expect(SS::Model.container_of(item.column_values.first)).to eq item
      end
    end

    context "when non-model is given" do
      it do
        expect { SS::Model.container_of({}) }.to raise_error NoMethodError
      end
    end
  end

  describe ".record_timestamps? / .without_record_timestamps" do
    let(:now) { Time.zone.now.change(usec: 0) }
    let(:time) { now - 2.weeks }
    let!(:item) do
      Timecop.freeze(time) { create(:sys_postal_code) }
    end

    context "normal" do
      it do
        expect(described_class.record_timestamps?).to be_truthy

        item.prefecture = unique_id
        item.save!

        Sys::PostalCode.find(item.id).tap do |new_item|
          expect(new_item.updated.in_time_zone).to be_within(30.seconds).of(Time.zone.now)
          expect(new_item.created.in_time_zone).to eq time
        end
      end
    end

    context "execute '#save' within without_record_timestamps" do
      it do
        described_class.without_record_timestamps do
          expect(described_class.record_timestamps?).to be_falsey

          item.prefecture = unique_id
          item.save!

          Sys::PostalCode.find(item.id).tap do |new_item|
            expect(new_item.updated.in_time_zone).to eq time
            expect(new_item.created.in_time_zone).to eq time
          end
        end
      end

      context "but individual record_timestamps set to true" do
        it do
          described_class.without_record_timestamps do
            expect(described_class.record_timestamps?).to be_falsey

            item.record_timestamps = true
            item.prefecture = unique_id
            item.save!

            Sys::PostalCode.find(item.id).tap do |new_item|
              expect(new_item.updated.in_time_zone).to be_within(30.seconds).of(Time.zone.now)
              expect(new_item.created.in_time_zone).to eq time
            end
          end
        end
      end
    end
  end
end
