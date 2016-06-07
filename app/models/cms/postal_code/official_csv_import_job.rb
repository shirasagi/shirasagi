require 'csv'
require 'nkf'

class Cms::PostalCode::OfficialCsvImportJob
  include Job::Worker

  def call(temp_file_id)
    @cur_file = SS::TempFile.find(temp_file_id)

    import_file
  ensure
    @cur_file.destroy
  end

  private
    def import_file
      table = ::CSV.read(@cur_file.path, headers: false, encoding: 'SJIS:UTF-8')
      table.each_with_index do |row, i|
        import_row(row, i)
      end
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

      item = Cms::PostalCode.where(code: postal_code).first_or_create
      item.prefecture = pref
      item.prefecture_kana = normalize_pref_kana(pref_kana)
      item.prefecture_code = pref_code
      item.city = normalize_city(city)
      item.city_kana = normalize_city_kana(city_kana)
      item.town = normalize_town(town)
      item.town_kana = normalize_town_kana(town_kana)
      item.save!
    end

    def normalize_pref_kana(pref_kana)
      pref_kana = NKF::nkf('-Z1 -Ww', pref_kana)
      pref_kana
    end

    def normalize_city(city)
      city = city.sub("以下に掲載がない場合", "")
      city = city.gsub(/（.+）/, "")
      city
    end

    def normalize_city_kana(city_kana)
      city_kana = city_kana.sub("ｲｶﾆｹｲｻｲｶﾞﾅｲﾊﾞｱｲ", "")
      city_kana = city_kana.gsub(/\(.+\)/, "")
      city_kana = NKF::nkf('-Z1 -Ww', city_kana)
      city_kana
    end

    def normalize_town(town)
      normalize_city(town)
    end

    def normalize_town_kana(town_kana)
      normalize_city_kana(town_kana)
    end
end
