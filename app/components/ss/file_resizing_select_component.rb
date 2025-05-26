#frozen_string_literal: true

class SS::FileResizingSelectComponent < ApplicationComponent
  include ActiveModel::Model

  attr_accessor :cur_user
  attr_writer :name, :css_class

  DEFAULT_NAME = "item[files][][resizing]"
  DEFAULT_CSS_CLASS = "image-size"

  def name
    @name ||= DEFAULT_NAME
  end

  def css_class
    @css_class ||= DEFAULT_CSS_CLASS
  end

  def resizing_options
    @resizing_options ||= begin
      options = system_resizing_options.dup

      if additional_options.present?
        options = add_resizing_options(options, additional_options)
      end

      if user_image_resize
        options = filter_out_resizing_options(options, user_image_resize)
      end

      if additional_options.present?
        options = set_selected_resizing_options(options, additional_options)
      end

      options
    end
  end

  def call
    if resizing_options.present?
      include_blank = user_image_resize.blank? ? t("ss.no_resize_image") : false
      select_tag name, options_for_select(resizing_options), include_blank: include_blank, class: css_class, id: nil
    end
  end

  private

  def system_resizing_options
    @system_resizing_options ||= begin
      options = [
        [ 380, 380 ], # suitable for 3 columns in https://www.digital.go.jp/
        [ 580, 580 ], # suitable for 2 columns in https://www.digital.go.jp/
        [ 1200, 1200 ], # suitable for full-width in https://www.digital.go.jp/
      ]
      options.map! { |w, h| [ I18n.t("ss.options.resizing.#{w}x#{h}").freeze, "#{w},#{h}".freeze ] }
      options.freeze
    end
  end

  def user_image_resize
    return @user_image_resize if instance_variable_defined?(:@user_image_resize)
    @user_image_resize = SS::File.effective_image_resize(user: cur_user, request_disable: true)
  end

  def system_image_resize
    return @system_image_resize if instance_variable_defined?(:@system_image_resize)
    @system_image_resize = SS::File.effective_image_resize(user: cur_user, request_disable: false)
  end

  def additional_options
    @additional_options ||= begin
      additional_options = []
      if system_image_resize.present? && (system_image_resize.max_width || system_image_resize.max_height)
        size = "#{system_image_resize.max_width}x#{system_image_resize.max_height}"
        system_resizing_label = I18n.t("ss.auto_resizing_label", size: size)
        additional_options << {
          width: system_image_resize.max_width, height: system_image_resize.max_height, label: system_resizing_label
        }
      end
      additional_options
    end
  end

  def add_resizing_options(options, additional_options)
    additional_options.each do |additional_option|
      additional_option_value = "#{additional_option[:width]},#{additional_option[:height]}"
      found_option = options.find { |_label, value, _attr| value == additional_option_value }
      if found_option
        found_option[0] = additional_option[:label]
      else
        options << [ additional_option[:label], additional_option_value ]
      end
    end
    sort_file_resizing_options(options)
    options
  end

  def sort_file_resizing_options(options)
    return options if options.blank?

    options.sort! do |lhs, rhs|
      _lhs_label, lhs_value, _lhs_options = lhs
      _rhs_label, rhs_value, _rhs_options = rhs

      lhs_width, lhs_height = lhs_value.split(",", 2).map(&:to_i)
      rhs_width, rhs_height = rhs_value.split(",", 2).map(&:to_i)
      lhs_square = lhs_width * lhs_height
      rhs_square = rhs_width * rhs_height

      # 1. 面積の小さい方が上位
      diff = lhs_square <=> rhs_square
      next diff if diff != 0

      # 2. width の大きい方が上位
      diff = rhs_width <=> lhs_width
      next diff if diff != 0

      # 3. height の大きい方が上位
      rhs_height <=> rhs_width
    end

    options
  end

  def filter_out_resizing_options(options, image_resize)
    return options if image_resize.nil?

    max_width = image_resize.max_width
    max_height = image_resize.max_height
    return options if max_width.blank? && max_height.blank?

    options.select! do |_label, value, _attr|
      width, height = value.split(',', 2).map(&:to_i)
      next false if max_width && width > max_width
      next false if max_height && height > max_height
      true
    end

    options
  end

  def set_selected_resizing_options(options, additional_options)
    additional_options.each do |additional_option|
      additional_option_value = "#{additional_option[:width]},#{additional_option[:height]}"
      found_option = options.find { |_label, value, _attr| value == additional_option_value }
      next unless found_option

      found_option[2] ||= {}
      found_option[2][:selected] = true
      break
    end

    options
  end
end
