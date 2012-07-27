# -*- encoding : utf-8 -*-
class CreateDictionaryWords < ActiveRecord::Migration
  def change
    create_table :dictionary_words do |t|

      t.timestamps
    end
  end
end
