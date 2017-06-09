require 'csv'

class Sys::PostalCode::ImportJob < Sys::PostalCode::ImportBase
  def import_file
    open_csv_table(headers: false, encoding: 'SJIS:UTF-8') do |table|
      table.each_with_index do |row, i|
        import_row(row, i)
      end
    end
    nil
  end

  def import_row(row, index)
    postal_code = row[0]
    pref = row[1]
    pref_kana = row[2]
    pref_code = row[3]
    city = row[4]
    city_kana = row[5]
    town = row[6]
    town_kana = row[7]

    item = Sys::PostalCode.where(code: postal_code).first_or_create
    item.prefecture = pref
    item.prefecture_kana = pref_kana
    item.prefecture_code = pref_code
    item.city = city
    item.city_kana = city_kana
    item.town = town
    item.town_kana = town_kana
    item.save!
  end
end
