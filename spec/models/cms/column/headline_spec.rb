require 'spec_helper'

describe Cms::Column::Headline, type: :model, dbscope: :example do
  let(:site) { cms_site }
  let(:form) { create(:cms_form, cur_site: site, sub_type: 'entry') }

  describe 'after_initialize defaults' do
    context 'when instantiated without arguments' do
      subject { described_class.new }

      it 'applies new-column defaults (h2/h4)' do
        expect(subject.min_headline_level).to eq 'h2'
        expect(subject.max_headline_level).to eq 'h4'
      end
    end

    context 'when instantiated with explicit nil (legacy simulation)' do
      subject do
        c = described_class.new
        c.min_headline_level = nil
        c.max_headline_level = nil
        c
      end

      it 'preserves nil (legacy behavior)' do
        expect(subject.min_headline_level).to be_nil
        expect(subject.max_headline_level).to be_nil
      end
    end

    context 'when instantiated with explicit values' do
      subject { described_class.new(min_headline_level: 'h3', max_headline_level: 'h5') }

      it 'preserves explicit values' do
        expect(subject.min_headline_level).to eq 'h3'
        expect(subject.max_headline_level).to eq 'h5'
      end
    end

    context 'when loaded from DB' do
      let!(:saved) do
        column = described_class.new(cur_site: site, cur_form: form, name: "legacy-#{unique_id}", order: 1)
        column.min_headline_level = nil
        column.max_headline_level = nil
        column.save!
        column
      end

      it 'does not re-apply defaults to existing records' do
        reloaded = described_class.find(saved.id)
        expect(reloaded.min_headline_level).to be_nil
        expect(reloaded.max_headline_level).to be_nil
      end
    end
  end

  describe '#headline_list' do
    context 'with new defaults' do
      subject { described_class.new(min_headline_level: 'h2', max_headline_level: 'h4').headline_list }

      it { is_expected.to eq(h2: 'h2', h3: 'h3', h4: 'h4') }
    end

    context 'with legacy nil values' do
      subject do
        c = described_class.new
        c.min_headline_level = nil
        c.max_headline_level = nil
        c.headline_list
      end

      it 'falls back to legacy h1-h4 range' do
        is_expected.to eq(h1: 'h1', h2: 'h2', h3: 'h3', h4: 'h4')
      end
    end

    context 'with extended range h3-h6' do
      subject { described_class.new(min_headline_level: 'h3', max_headline_level: 'h6').headline_list }

      it { is_expected.to eq(h3: 'h3', h4: 'h4', h5: 'h5', h6: 'h6') }
    end

    context 'with full selectable range h2-h6' do
      subject { described_class.new(min_headline_level: 'h2', max_headline_level: 'h6').headline_list }

      it { is_expected.to eq(h2: 'h2', h3: 'h3', h4: 'h4', h5: 'h5', h6: 'h6') }
    end
  end

  describe '#headline_level_options' do
    subject { described_class.new.headline_level_options.map(&:last) }

    it 'excludes h1 and returns h2 through h6' do
      is_expected.to eq %w(h2 h3 h4 h5 h6)
    end
  end

  describe '#effective_min_headline_level / #effective_max_headline_level' do
    context 'when nil (legacy)' do
      let(:column) do
        c = described_class.new
        c.min_headline_level = nil
        c.max_headline_level = nil
        c
      end

      it 'returns legacy h1 for min' do
        expect(column.effective_min_headline_level).to eq 'h1'
      end

      it 'returns legacy h4 for max' do
        expect(column.effective_max_headline_level).to eq 'h4'
      end
    end

    context 'when set' do
      let(:column) { described_class.new(min_headline_level: 'h3', max_headline_level: 'h5') }

      it { expect(column.effective_min_headline_level).to eq 'h3' }
      it { expect(column.effective_max_headline_level).to eq 'h5' }
    end
  end

  describe 'validations' do
    let(:column) do
      described_class.new(
        cur_site: site, cur_form: form,
        name: "spec-#{unique_id}", order: 1
      )
    end

    describe 'inclusion of min_headline_level / max_headline_level' do
      it 'rejects h1 because h1 is not a selectable boundary' do
        column.min_headline_level = 'h1'
        column.max_headline_level = 'h4'
        expect(column).not_to be_valid
        expect(column.errors[:min_headline_level]).not_to be_empty
      end

      it 'accepts h2 through h6 for min' do
        %w(h2 h3 h4 h5 h6).each do |level|
          column.min_headline_level = level
          column.max_headline_level = 'h6'
          expect(column).to be_valid, "expected min=#{level} to be valid but got: #{column.errors.full_messages}"
        end
      end

      it 'accepts nil for legacy columns' do
        column.min_headline_level = nil
        column.max_headline_level = nil
        expect(column).to be_valid
      end

      it 'rejects unknown value' do
        column.min_headline_level = 'h9'
        expect(column).not_to be_valid
      end
    end

    describe 'range validation (min <= max)' do
      it 'rejects min > max' do
        column.min_headline_level = 'h5'
        column.max_headline_level = 'h3'
        expect(column).not_to be_valid
        expect(column.errors[:max_headline_level]).not_to be_empty
      end

      it 'accepts min == max' do
        column.min_headline_level = 'h3'
        column.max_headline_level = 'h3'
        expect(column).to be_valid
      end

      it 'accepts min < max' do
        column.min_headline_level = 'h2'
        column.max_headline_level = 'h6'
        expect(column).to be_valid
      end

      # min が legacy フォールバック (h1) より大きい値で、max だけ blank だと、
      # effective_max が h4 にフォールバックして実効レンジが反転する。
      it 'rejects when only max is blank and min is greater than legacy max (h4)' do
        column.min_headline_level = 'h5'
        column.max_headline_level = nil
        expect(column).not_to be_valid
        expect(column.errors[:max_headline_level]).not_to be_empty
      end

      it 'accepts when only max is blank and min is within legacy range' do
        column.min_headline_level = 'h2'
        column.max_headline_level = nil
        expect(column).to be_valid
      end
    end
  end
end
