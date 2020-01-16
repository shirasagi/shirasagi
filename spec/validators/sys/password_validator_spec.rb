require 'spec_helper'

describe Sys::PasswordValidator, type: :validator, dbscope: :example do
  let(:chars) { (" ".."~").to_a }
  let(:upcases) { ("A".."Z").to_a }
  let(:downcases) { ("a".."z").to_a }
  let(:digits) { ("0".."9").to_a }
  let(:symbols) { chars - upcases - downcases - digits }

  let!(:user) do
    u = sys_user
    u.decrypted_password = u.in_password
    u
  end

  before do
    user.in_password = [ password ].flatten.join
    setting.password_validator.validate(user)
  end

  describe "#validate_password_min" do
    let(:setting) do
      Sys::Setting.create(password_min_use: "enabled", password_min_length: rand(8..12))
    end

    context "when invalid password is given" do
      let(:password) { chars.sample(setting.password_min_length - 1).join }

      it do
        expect(user.errors).not_to be_blank
      end
    end

    context "when valid password is given" do
      let(:password) { chars.sample(setting.password_min_length - 1).join }

      it do
        expect(user.errors).not_to be_blank
      end
    end
  end

  describe "#validate_password_min_upcase" do
    let(:setting) do
      Sys::Setting.create(
        password_min_use: "enabled", password_min_length: rand(8..12),
        password_min_upcase_use: "enabled", password_min_upcase_length: rand(2..4)
      )
    end

    context "when invalid password is given" do
      let(:password) { downcases.sample(setting.password_min_length).join }

      it do
        expect(user.errors).not_to be_blank
      end
    end

    context "when valid password is given" do
      let(:password) do
        upcases.sample(setting.password_min_upcase_length).join + downcases.sample(setting.password_min_length).join
      end

      it do
        expect(user.errors).to be_blank
      end
    end
  end

  describe "#validate_password_min_downcase" do
    let(:setting) do
      Sys::Setting.create(
        password_min_use: "enabled", password_min_length: rand(8..12),
        password_min_downcase_use: "enabled", password_min_downcase_length: rand(2..4)
      )
    end

    context "when invalid password is given" do
      let(:password) { upcases.sample(setting.password_min_length).join }

      it do
        expect(user.errors).not_to be_blank
      end
    end

    context "when valid password is given" do
      let(:password) do
        downcases.sample(setting.password_min_downcase_length).join + upcases.sample(setting.password_min_length).join
      end

      it do
        expect(user.errors).to be_blank
      end
    end
  end

  describe "#validate_password_min_digit" do
    let(:setting) do
      Sys::Setting.create(
        password_min_use: "enabled", password_min_length: rand(8..12),
        password_min_digit_use: "enabled", password_min_digit_length: rand(2..4)
      )
    end

    context "when invalid password is given" do
      let(:password) { upcases.sample(setting.password_min_length).join }

      it do
        expect(user.errors).not_to be_blank
      end
    end

    context "when valid password is given" do
      let(:password) do
        digits.sample(setting.password_min_digit_length).join + upcases.sample(setting.password_min_length).join
      end

      it do
        expect(user.errors).to be_blank
      end
    end
  end

  describe "#validate_password_min_symbol" do
    let(:setting) do
      Sys::Setting.create(
        password_min_use: "enabled", password_min_length: rand(8..12),
        password_min_symbol_use: "enabled", password_min_symbol_length: rand(2..4)
      )
    end

    context "when invalid password is given" do
      let(:password) { upcases.sample(setting.password_min_length).join }

      it do
        expect(user.errors).not_to be_blank
      end
    end

    context "when valid password is given" do
      let(:password) do
        symbols.sample(setting.password_min_symbol_length).join + upcases.sample(setting.password_min_length).join
      end

      it do
        expect(user.errors).to be_blank
      end
    end
  end

  describe "#validate_password_prohibited_char" do
    context "usual case" do
      let(:setting) do
        Sys::Setting.create(
          password_min_use: "enabled", password_min_length: rand(8..12),
          password_prohibited_char_use: "enabled", password_prohibited_char: chars.sample(rand(2..4)).join
        )
      end

      context "when invalid password is given" do
        let(:password) { chars.sample(setting.password_min_length).join + setting.password_prohibited_char }

        it do
          expect(user.errors).not_to be_blank
        end
      end

      context "when valid password is given" do
        let(:password) do
          (chars - setting.password_prohibited_char.split("")).sample(setting.password_min_length)
        end

        it do
          expect(user.errors).to be_blank
        end
      end
    end

    context "edge case: '(-#'" do
      let(:setting) do
        Sys::Setting.create(
          password_min_use: "enabled", password_min_length: rand(8..12),
          password_prohibited_char_use: "enabled", password_prohibited_char: "(-#"
        )
      end
      let(:password) do
        (chars - setting.password_prohibited_char.split("")).sample(setting.password_min_length)
      end

      it do
        expect(user.errors).to be_blank
      end
    end
  end

  describe "#validate_password_min_change_char" do
    let(:setting) do
      Sys::Setting.create(
        password_min_use: "enabled", password_min_length: 4,
        password_min_change_char_use: "enabled", password_min_change_char_count: 3
      )
    end

    context "when invalid password is given" do
      let(:password) do
        prev_chars = user.decrypted_password.split("").uniq
        prev_chars.sample(2).join + (chars - prev_chars).sample(2).join
      end

      it do
        expect(user.errors).not_to be_blank
      end
    end

    context "when valid password is given" do
      let(:password) do
        prev_chars = user.decrypted_password.split("").uniq
        prev_chars.sample(1).join + (chars - prev_chars).sample(3).join
      end

      it do
        expect(user.errors).to be_blank
      end
    end
  end
end
