FactoryBot.define do
  factory :sys_prefecture_code, class: Sys::PrefectureCode do
    code do
      c = Array.new(5) { rand(0..9) }.join
      c + Sys::PrefectureCode.check_digit(c)
    end
    prefecture { unique_id }
  end
end
