class CommentsValorationsType < ActiveRecord::Base
  def self.find_positive
    find(:all, :conditions => 'direction = 1', :order => 'lower(name) ASC')
  end

  def self.find_negative
    find(:all, :conditions => 'direction = -1', :order => 'lower(name) ASC')
  end

  def self.find_neutral
    find(:all, :conditions => 'direction = 0', :order => 'lower(name) ASC')
  end
end
