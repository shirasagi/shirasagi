require 'csv'
require 'nkf'

class Sys::PostalCode::OfficialCsvImportJob < Sys::PostalCode::ImportBase
  def import_file
    error_count = 0
    SS::Csv.foreach_row(@cur_file, headers: false) do |row, i|
      Rails.logger.tagged("#{i + 1}行目") do
        import_row(row, i)
      rescue => e
        Rails.logger.error { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
        error_count += 1
      end
    end
    throw :abort if error_count > 0
    nil
  end

  def import_row(row, index)
    pref_code = row[0]
    postal_code = row[2]
    pref_kana = row[3]
    city_kana = row[4]
    town_kana = row[5]
    pref = row[6]
    city = row[7]
    town = row[8]

    item = Sys::PostalCode.where(code: postal_code).first_or_create
    item.prefecture = pref
    item.prefecture_kana = normalize_pref_kana(pref_kana, max_length: Sys::PostalCode::MAX_PREFECTURE_KANA_LENGTH)
    item.prefecture_code = pref_code
    item.city = normalize_city(city, max_length: Sys::PostalCode::MAX_CITY_LENGTH)
    item.city_kana = normalize_city_kana(city_kana, max_length: Sys::PostalCode::MAX_CITY_KANA_LENGTH)
    item.town = normalize_town(town, max_length: Sys::PostalCode::MAX_TOWN_LENGTH)
    item.town_kana = normalize_town_kana(town_kana, max_length: Sys::PostalCode::MAX_TOWN_KANA_LENGTH)
    item.save!
  end

  def normalize_pref_kana(pref_kana, max_length:)
    pref_kana = NKF::nkf('-Z1 -Ww', pref_kana)
    if pref_kana.length > max_length
      Rails.logger.warn { "#{Sys::PostalCode.t(:prefecture_kana)}が#{max_length}を超えています。超過分は切り捨てられます。" }
      pref_kana = pref_kana[0, max_length]
    end
    pref_kana
  end

  def normalize_city(city, max_length:, field_name: nil)
    city = city.sub(I18n.t('sys.postal_code_normalize_city'), "")
    city = city.gsub(/（.+）/, "")
    if city.length > max_length
      Rails.logger.warn { "#{field_name || Sys::PostalCode.t(:city)}が#{max_length}を超えています。超過分は切り捨てられます。" }
      city = city[0, max_length]
    end
    city
  end

  def normalize_city_kana(city_kana, max_length:, field_name: nil)
    city_kana = city_kana.sub("ｲｶﾆｹｲｻｲｶﾞﾅｲﾊﾞｱｲ", "")
    city_kana = city_kana.gsub(/\(.+\)/, "")
    city_kana = NKF::nkf('-Z1 -Ww', city_kana)
    if city_kana.length > max_length
      Rails.logger.warn { "#{field_name || Sys::PostalCode.t(:city_kana)}が#{max_length}を超えています。超過分は切り捨てられます。" }
      city_kana = city_kana[0, max_length]
    end
    city_kana
  end

  def normalize_town(town, max_length:)
    normalize_city(town, max_length: max_length, field_name: Sys::PostalCode.t(:town))
  end

  def normalize_town_kana(town_kana, max_length:)
    normalize_city_kana(town_kana, max_length: max_length, field_name: Sys::PostalCode.t(:town_kana))
  end
end
