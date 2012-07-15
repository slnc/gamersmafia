# -*- encoding : utf-8 -*-
class ClansMovement < ActiveRecord::Base
  IN = 0
  OUT = 1

  belongs_to :clan
  belongs_to :user

  def self.translate_direction(dir)
    case dir
      when IN then
      'entra en'
    when OUT then
      'sale de'
    else
      raise "direction #{dir} unknown"
    end
  end
end
