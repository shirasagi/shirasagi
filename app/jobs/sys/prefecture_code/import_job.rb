require 'csv'

class Sys::PrefectureCode::ImportJob < Sys::PostalCode::ImportBase
  def import_file
    SS::Csv.foreach_row(@cur_file, headers: true) do |row, i|
      import_row(row, i)
    end
    nil
  end

  def import_row(row, index)
    code = row[0]
    pref = row[1]
    pref_kana = row[2]
    city = row[3]
    city_kana = row[4]

    item = Sys::PrefectureCode.where(code: code).first_or_create
    item.prefecture = pref
    item.prefecture_kana = pref_kana
    item.city = city
    item.city_kana = city_kana
    item.save!
  end
end
