# -*- encoding : utf-8 -*-
# ContentAttribute:
# (none)
class News < Content
  acts_as_categorizable

  validates_format_of :source,
      :with => Cms::URL_REGEXP_FULL,
      :if => Proc.new { |c| c.source.to_s != '' },
      :message => 'no es válida. La fuente de la noticia debe ser una url.'
end
