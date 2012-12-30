module Categories
  def self.top_level_entity_groups(category_type)
    [
      ['Juegos', Stats::Games.top_games(10)],
      ['Plataformas', Stats::GamingPlatforms.top_platforms(10)],
      ['Gamersmafia', Term.with_taxonomy('Homepage').find_by_slug!('gm')],
      ['Bazar', Term.with_taxonomy('Homepage').find_by_slug!('bazar')],
      ['Distritos', Stats::BazarDistricts.top_districts(10)],
    ]
  end

  def self.top_level_categories(entity, taxonomy)
  end
end
