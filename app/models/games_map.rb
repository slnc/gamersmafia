class GamesMap < ActiveRecord::Base
  belongs_to :game
  has_and_belongs_to_many :competitions
  has_many :competitions_matches_games_map, :dependent => :destroy
  belongs_to :download

  file_column :screenshot

  plain_text :name
  validates_uniqueness_of :name, :scope => :game_id, :message => 'Ya hay un mapa con ese nombre'
end
