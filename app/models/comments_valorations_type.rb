# -*- encoding : utf-8 -*-
class CommentsValorationsType < ActiveRecord::Base
  scope :positive, :conditions => 'direction = 1'
  scope :negative, :conditions => 'direction = -1'
  scope :neutral, :conditions => 'direction = 0'

  ICON_MAPPING = {
    "divertido" => "lol",
    "informativo" => "informativo",
    "interesante" => "interesting",
    "profundo" => "deep",
    "normal" => "normal",
    "flame" => "flame",
    "irrelevante" => "irrelevant",
    "redundante" => "redundant",
    "spam" => "spam",
  }

  def self.find_positive
    self.positive.find(:all, :order => 'lower(name) ASC')
  end

  def self.find_negative
    self.negative.find(:all, :order => 'lower(name) ASC')
  end

  def self.find_neutral
    self.neutral.find(:all, :order => 'lower(name) ASC')
  end

  def positive?
    self.direction != -1
  end

  def negative?
    !self.positive?
  end

  def icon
    ICON_MAPPING.fetch(self.name.downcase)
  end
end
