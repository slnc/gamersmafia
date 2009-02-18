class AddPollsCategories < ActiveRecord::Migration
  def self.up
    pc = PollsCategory.create(:code => 'bazar', :name => 'Bazar')
    # pc = PollsCategory.find_by_code('bazar')
    BazarDistrict.find(:all).each do |bd|
      pc.children.create(:code => bd.code, :name => bd.name)
    end
    
    execute "delete from users_preferences where name = 'user_forums';"
  end

  def self.down
  end
end
