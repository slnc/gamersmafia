class Fixurlsofblogentires < ActiveRecord::Migration
  def self.up
    SoldProduct.find(:all, :conditions => 'product_id = 8').each do |sp|
      Blogentry.reset_urls_of_user_id(sp.user_id)
    end
  end

  def self.down
  end
end
