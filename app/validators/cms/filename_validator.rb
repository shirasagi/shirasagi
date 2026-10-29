class Cms::FilenameValidator < ActiveModel::EachValidator
  FILENAME_RE = /\A[\w\-]+\z/

  class << self
    def valid?(value, site_modifier: false, allow_suffixes: nil)
      return true if value.blank?

      values = to_array(value)
      allow_suffixes = to_array(allow_suffixes)
      values.all? do |val|
        components = val.to_s.split("/")
        next false if components.any?(&:blank?)

        if site_modifier
          site_host, component = components.first.split(":", 2)
          components[0] = component || site_host
        end

        components.each_with_index.all? do |component, index|
          if index < components.length - 1
            next FILENAME_RE.match?(component)
          end

          # last
          basename = File.basename(component, ".*")
          next false unless FILENAME_RE.match?(basename)

          extname = File.extname(component)
          next true if extname.blank?
          next false if allow_suffixes.blank? # allow_suffixes.blank? means suffixes are not allowed
          allow_suffixes.include?(extname)
        end
      end
    end

    private

    def to_array(str_or_array)
      if str_or_array.nil?
        SS::EMPTY_ARRAY
      elsif !str_or_array.is_a?(Array)
        Array(str_or_array)
      else
        str_or_array
      end
    end
  end

  def validate_each(record, attribute, value)
    return if value.blank?

    unless self.class.valid?(value, **options)
      record.errors.add(attribute, options[:message] || :invalid)
    end
  rescue => e
    Rails.logger.info { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
    record.errors.add(attribute, options[:message] || :invalid)
  end
end
