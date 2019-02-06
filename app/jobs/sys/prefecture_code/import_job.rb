require 'csv'

class Sys::PrefectureCode::ImportJob < Sys::PostalCode::ImportBase
  def import_file
    open_csv_table(headers: true, encoding: 'SJIS:UTF-8') do |table|
      table.each_with_index do |row, i|
        import_row(row, i)
      end
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
