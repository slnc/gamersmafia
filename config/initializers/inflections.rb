# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format 
# (all these examples are active by default):
# ActiveSupport::Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

module ActiveSupport::Inflector
  def self.sexualize(word, sex)
    if sex == User::FEMALE
      word.gsub(/(o)$/, 'a')
    else
      word
    end
  end
end
