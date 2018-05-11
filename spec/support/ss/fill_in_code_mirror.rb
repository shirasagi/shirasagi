def fill_in_code_mirror(locator, options = {})
  with = options.delete(:with)
  options[:visible] = :all

  element = find(:fillable_field, locator, options)
  page.execute_script("$(arguments[0]).data('editor').setValue(arguments[1])", element, with)
end
