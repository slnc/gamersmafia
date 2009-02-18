class BetsOption < ActiveRecord::Base
  belongs_to :bet
  has_many :bets_tickets, :dependent => :destroy
end
