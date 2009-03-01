class AddAmountToQuestions < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table questions add column ammount decimal(10, 2);"
    slonik_execute "alter table questions alter column description drop not null;"
    qb = QuestionsCategory.create(:name => 'Bazar', :code => 'bazar')
    BazarPortal.new.news_categories.each do |c|
      qb.children.create(:name => c.name, :code => c.code)
    end
  end

  def self.down
  end
end
