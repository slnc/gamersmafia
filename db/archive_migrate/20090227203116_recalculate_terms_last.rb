class RecalculateTermsLast < ActiveRecord::Migration
  def self.up
    Term.find(:all, :conditions => 'last_updated_item_id IS NULL').each do |t| 
      t.recalculate_last_updated_item_id 
    end
  end

  def self.down
  end
end
