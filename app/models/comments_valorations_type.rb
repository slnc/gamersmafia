# -*- encoding : utf-8 -*-
class CommentsValorationsType < ActiveRecord::Base
  scope :positive, :conditions => 'direction = 1'
  scope :negative, :conditions => 'direction = -1'
  scope :neutral, :conditions => 'direction = 0'

  def self.find_positive
    self.positive.find(:all, :order => 'lower(name) ASC')
  end

  def self.find_negative
    self.negative.find(:all, :order => 'lower(name) ASC')
  end

  def self.find_neutral
    self.neutral.find(:all, :order => 'lower(name) ASC')
  end
end
