require 'spec_helper'

describe SS::File, dbscope: :example do
  describe "#sanitizer_restore_file" do
    before do
      @save_config = SS.config.ss.upload_policy
      SS.config.replace_value_at(:ss, :upload_policy, 'sanitizer')
    end

    after do
      SS::File.each do |file|
        Fs.rm_rf(file.path) if Fs.exists?(file.path)
        Fs.rm_rf(file.sanitizer_input_path) if Fs.exists?(file.sanitizer_input_path)
      end
      SS.config.replace_value_at(:ss, :upload_policy, @save_config)
    end

    context "when local file" do
      subject { create :ss_file }

      it do
        expect(subject.sanitizer_state).to be_nil
        expect(FileTest.size(subject.path) > 0).to be_truthy
      end
    end

    context "when upload file" do
      let(:path) { "#{::Rails.root}/spec/fixtures/ss/file/keyvisual.jpg" }

      subject do
        file = SS::File.new model: "share/file"
        file.in_file = ActionDispatch::Http::UploadedFile.new(
          filename: ::File.basename(path), type: "image/jpg", tempfile: ::File.open(path)
        )
        file.save!
        file.in_file = nil
        file.reload
        file
      end

      it 'restore' do
        expect(subject.sanitizer_state).to eq 'wait'
        expect(FileTest.size(subject.path) == 0).to be_truthy
        expect(FileTest.size(subject.sanitizer_input_path) > 0).to be_truthy

        subject.sanitizer_restore_file(subject.sanitizer_input_path)
        expect(subject.sanitizer_state).to eq 'complete'
        expect(FileTest.size(subject.path) > 0).to be_truthy
        expect(FileTest.exist?(subject.sanitizer_input_path)).to be_falsey
      end
    end
  end
end
