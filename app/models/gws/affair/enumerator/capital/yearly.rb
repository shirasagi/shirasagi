class Gws::Affair::Enumerator::Capital::Yearly < Gws::Affair::Enumerator::Base
  def initialize(prefs, capitals, fiscal_year, opts = {})
    @prefs = prefs
    @capitals = capitals
    @fiscal_year = fiscal_year
    @months = (4..12).to_a + (1..3).to_a

    @title = opts[:title]
    @encoding = opts[:encoding]

    super() do |y|
      y << bom + encode([@title.to_s].to_csv) if @title.present?
      y << encode(headers.to_csv)
      @capitals.each do |basic_code, name|
        enum_capital(y, basic_code, name)
      end
      enum_total(y)
    end
  end

  def headers
    terms = []
    terms << I18n.t("gws/affair.labels.overtime.capitals.capital")
    @months.each do |month|
      terms << "#{month}#{I18n.t("datetime.prompts.month")}"
    end
    terms << I18n.t("gws/affair.labels.overtime.capitals.total")
    terms
  end

  def enum_capital(yielder, basic_code, name)
    line = []
    line << name

    total = 0
    @months.each do |month|
      minute = @prefs.dig(@fiscal_year, month, basic_code).to_i
      total += minute
      line << format_minute(minute)
    end
    line << format_minute(total)
    yielder << encode(line.to_csv)
  end

  def enum_total(yielder)
    line = []
    line << I18n.t("gws/affair.labels.overtime.capitals.total_capitals")

    total = 0
    @months.each do |month|
      minute = @prefs.dig(@fiscal_year, month, "total").to_i
      total += minute
      line << format_minute(minute)
    end
    line << format_minute(total)
    yielder << encode(line.to_csv)
  end
end
