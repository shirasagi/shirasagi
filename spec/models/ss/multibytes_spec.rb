require 'spec_helper'

describe SS::File, dbscope: :example do
  before do
    @save_multibyte_filename = SS.config.env.multibyte_filename
    @save_unicode_normalization_method = SS.config.env.unicode_normalization_method

    SS.config.replace_value_at(:env, :multibyte_filename, "underscore")
    SS.config.replace_value_at(:env, :unicode_normalization_method, :nfc)
  end

  after do
    SS.config.replace_value_at(:env, :multibyte_filename, @save_multibyte_filename)
    SS.config.replace_value_at(:env, :unicode_normalization_method, @save_unicode_normalization_method)
  end

  context "運用途中で name や filename が変化してしまうと、リンク切れを起こしてしまうかもしれないので変化させないようにする" do
    context "multibyte_filename: underscore --> sequence" do
      it do
        SS.config.replace_value_at(:env, :multibyte_filename, "underscore")

        file = tmp_ss_file(contents: '0123456789', basename: "プロ.txt")
        expect(file.name).to eq "プロ.txt"
        expect(file.filename).to eq "__.txt"

        SS.config.replace_value_at(:env, :multibyte_filename, "sequence")
        # file.touch
        file.save!
        expect(file.name).to eq "プロ.txt"
        expect(file.filename).to eq "__.txt"
      end
    end

    context "multibyte_filename: underscore --> hex" do
      it do
        SS.config.replace_value_at(:env, :multibyte_filename, "underscore")

        file = tmp_ss_file(contents: '0123456789', basename: "プロ.txt")
        expect(file.name).to eq "プロ.txt"
        expect(file.filename).to eq "__.txt"

        SS.config.replace_value_at(:env, :multibyte_filename, "hex")
        # file.touch
        file.save!
        expect(file.name).to eq "プロ.txt"
        expect(file.filename).to eq "__.txt"
      end
    end

    context "multibyte_filename: sequence --> underscore" do
      it do
        SS.config.replace_value_at(:env, :multibyte_filename, "sequence")

        file = tmp_ss_file(contents: '0123456789', basename: "プロ.txt")
        expect(file.name).to eq "プロ.txt"
        expect(file.filename).to eq "#{file.id}.txt"

        SS.config.replace_value_at(:env, :multibyte_filename, "underscore")
        # file.touch
        file.save!
        expect(file.name).to eq "プロ.txt"
        expect(file.filename).to eq "#{file.id}.txt"
      end
    end

    context "multibyte_filename: sequence --> hex" do
      it do
        SS.config.replace_value_at(:env, :multibyte_filename, "sequence")

        file = tmp_ss_file(contents: '0123456789', basename: "プロ.txt")
        expect(file.name).to eq "プロ.txt"
        expect(file.filename).to eq "#{file.id}.txt"

        SS.config.replace_value_at(:env, :multibyte_filename, "hex")
        # file.touch
        file.save!
        expect(file.name).to eq "プロ.txt"
        expect(file.filename).to eq "#{file.id}.txt"
      end
    end

    context "multibyte_filename: hex --> underscore" do
      it do
        SS.config.replace_value_at(:env, :multibyte_filename, "hex")

        file = tmp_ss_file(contents: '0123456789', basename: "プロ.txt")
        expect(file.name).to eq "プロ.txt"
        expect(file.filename).to match(/\A[0-9a-f]{32}\.txt\z/)
        save_filename = file.filename

        SS.config.replace_value_at(:env, :multibyte_filename, "underscore")
        # file.touch
        file.save!
        expect(file.name).to eq "プロ.txt"
        expect(file.filename).to eq save_filename
      end
    end

    context "multibyte_filename: hex --> sequence" do
      it do
        SS.config.replace_value_at(:env, :multibyte_filename, "hex")

        file = tmp_ss_file(contents: '0123456789', basename: "プロ.txt")
        expect(file.name).to eq "プロ.txt"
        expect(file.filename).to match(/\A[0-9a-f]{32}\.txt\z/)
        save_filename = file.filename

        SS.config.replace_value_at(:env, :multibyte_filename, "sequence")
        # file.touch
        file.save!
        expect(file.name).to eq "プロ.txt"
        expect(file.filename).to eq save_filename
      end
    end

    context "unicode_normalization_method: nfc --> nfkc" do
      it do
        SS.config.replace_value_at(:env, :unicode_normalization_method, :nfc)

        file = tmp_ss_file(contents: '0123456789', basename: "①.txt")
        expect(file.name).to eq "①.txt"
        expect(file.filename).to eq "_.txt"

        SS.config.replace_value_at(:env, :unicode_normalization_method, :nfkc)
        # file.touch
        file.save!
        expect(file.name).to eq "①.txt"
        expect(file.filename).to eq "_.txt"
      end
    end

    context "unicode_normalization_method: nfkc --> nfc" do
      it do
        SS.config.replace_value_at(:env, :unicode_normalization_method, :nfkc)

        file = tmp_ss_file(contents: '0123456789', basename: "①.txt")
        expect(file.name).to eq "1.txt"
        expect(file.filename).to eq "1.txt"

        SS.config.replace_value_at(:env, :unicode_normalization_method, :nfc)
        # file.touch
        file.save!
        expect(file.name).to eq "1.txt"
        expect(file.filename).to eq "1.txt"
      end
    end
  end
end
