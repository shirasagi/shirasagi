module Cms
  extend Sys::ModulePermission

  # factory method for Liquid::Template
  def self.parse_liquid(source, registers)
    template = Liquid::Template.parse(source)

    template.assigns["parts"] = SS::LiquidPartDrop.get(registers[:cur_site])

    registers.each do |key, value|
      template.registers[key] = value
    end

    template
  end
end
