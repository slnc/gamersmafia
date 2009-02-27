class CreateContentsTerms < ActiveRecord::Migration
  def self.up
    create_table :contents_terms do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :contents_terms
  end
end
