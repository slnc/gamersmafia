class MigrateContentAttributes < ActiveRecord::Migration
  def up
    # news
    execute "
    update contents set
        description = (select description from news where id = external_id),
        main = (select main from news where id = external_id),
        hits_registered = (select hits_registered from news where id = external_id),
        hits_anonymous = (select hits_anonymous from news where id = external_id),
        cache_rating = (select cache_rating from news where id = external_id),
        cache_rated_times = (select cache_rated_times from news where id = external_id),
        cache_comments_count = (select cache_comments_count from news where id = external_id),
        log = (select log from news where id = external_id),
        cache_weighted_rank = (select cache_weighted_rank from news where id = external_id)
     WHERE type = 'News';
    "

    # bets
    execute "
    update contents set
        description = (select description from bets where id = external_id),
        main = (select main from bets where id = external_id),
        hits_registered = (select hits_registered from bets where id = external_id),
        hits_anonymous = (select hits_anonymous from bets where id = external_id),
        cache_rating = (select cache_rating from bets where id = external_id),
        cache_rated_times = (select cache_rated_times from bets where id = external_id),
        cache_comments_count = (select cache_comments_count from bets where id = external_id),
        log = (select log from bets where id = external_id),
        cache_weighted_rank = (select cache_weighted_rank from bets where id = external_id),
        cancelled = (select cancelled from bets where id = external_id),
        closes_on = (select closes_on from bets where id = external_id),
        forfeit = (select forfeit from bets where id = external_id),
        tie = (select tie from bets where id = external_id),
        total_ammount = (select total_ammount from bets where id = external_id),
        winning_bets_option_id = (select winning_bets_option_id from bets where id = external_id)
     WHERE type = 'Bet';
    "

    # images
    execute "
    update contents set
        description = (select description from images where id = external_id),
        main = (select main from images where id = external_id),
        hits_registered = (select hits_registered from images where id = external_id),
        hits_anonymous = (select hits_anonymous from images where id = external_id),
        cache_rating = (select cache_rating from images where id = external_id),
        cache_rated_times = (select cache_rated_times from images where id = external_id),
        cache_comments_count = (select cache_comments_count from images where id = external_id),
        log = (select log from images where id = external_id),
        cache_weighted_rank = (select cache_weighted_rank from images where id = external_id),
        file = (select file from images where id = external_id),
        file_hash_md5 = (select file_hash_md5 from images where id = external_id)
     WHERE type = 'Image';
    "

    # downloads
    execute "
    update contents set
        description = (select description from downloads where id = external_id),
        main = (select main from downloads where id = external_id),
        hits_registered = (select hits_registered from downloads where id = external_id),
        hits_anonymous = (select hits_anonymous from downloads where id = external_id),
        cache_rating = (select cache_rating from downloads where id = external_id),
        cache_rated_times = (select cache_rated_times from downloads where id = external_id),
        cache_comments_count = (select cache_comments_count from downloads where id = external_id),
        log = (select log from downloads where id = external_id),
        cache_weighted_rank = (select cache_weighted_rank from downloads where id = external_id),
        downloaded_times = (select downloaded_times from downloads where id = external_id),
        essential = (select essential from downloads where id = external_id),
        file = (select file from downloads where id = external_id),
        file_hash_md5 = (select file_hash_md5 from downloads where id = external_id)
     WHERE type = 'Download';
    "

    # topics
    execute "
    update contents set
        description = (select description from topics where id = external_id),
        main = (select main from topics where id = external_id),
        hits_registered = (select hits_registered from topics where id = external_id),
        hits_anonymous = (select hits_anonymous from topics where id = external_id),
        cache_rating = (select cache_rating from topics where id = external_id),
        cache_rated_times = (select cache_rated_times from topics where id = external_id),
        cache_comments_count = (select cache_comments_count from topics where id = external_id),
        log = (select log from topics where id = external_id),
        cache_weighted_rank = (select cache_weighted_rank from topics where id = external_id),
        downloaded_times = (select downloaded_times from topics where id = external_id),
        sticky = (select sticky from topics where id = external_id),
        moved_on = (select moved_on from topics where id = external_id)
     WHERE type = 'Topic';
    "

    # polls
    execute "
    update contents set
        description = (select description from polls where id = external_id),
        main = (select main from polls where id = external_id),
        hits_registered = (select hits_registered from polls where id = external_id),
        hits_anonymous = (select hits_anonymous from polls where id = external_id),
        cache_rating = (select cache_rating from polls where id = external_id),
        cache_rated_times = (select cache_rated_times from polls where id = external_id),
        cache_comments_count = (select cache_comments_count from polls where id = external_id),
        log = (select log from polls where id = external_id),
        cache_weighted_rank = (select cache_weighted_rank from polls where id = external_id),
        starts_on = (select starts_on from polls where id = external_id),
        ends_on = (select ends_on from polls where id = external_id),
        polls_votes_count = (select polls_votes_count from polls where id = external_id)
     WHERE type = 'Poll';
    "

    # events
    execute "
    update contents set
        description = (select description from events where id = external_id),
        main = (select main from events where id = external_id),
        hits_registered = (select hits_registered from events where id = external_id),
        hits_anonymous = (select hits_anonymous from events where id = external_id),
        cache_rating = (select cache_rating from events where id = external_id),
        cache_rated_times = (select cache_rated_times from events where id = external_id),
        cache_comments_count = (select cache_comments_count from events where id = external_id),
        log = (select log from events where id = external_id),
        cache_weighted_rank = (select cache_weighted_rank from events where id = external_id),
        event_id = (select event_id from events where id = external_id)
     WHERE type = 'Event';
    "

    # coverages
    execute "
    update contents set
        description = (select description from coverages where id = external_id),
        main = (select main from coverages where id = external_id),
        hits_registered = (select hits_registered from coverages where id = external_id),
        hits_anonymous = (select hits_anonymous from coverages where id = external_id),
        cache_rating = (select cache_rating from coverages where id = external_id),
        cache_rated_times = (select cache_rated_times from coverages where id = external_id),
        cache_comments_count = (select cache_comments_count from coverages where id = external_id),
        log = (select log from coverages where id = external_id),
        cache_weighted_rank = (select cache_weighted_rank from coverages where id = external_id),
        event_id = (select event_id from coverages where id = external_id)
     WHERE type = 'Coverage';
    "

    # home_image
    execute "
    update contents set
        description = (select description from tutorials where id = external_id),
        main = (select main from tutorials where id = external_id),
        hits_registered = (select hits_registered from tutorials where id = external_id),
        hits_anonymous = (select hits_anonymous from tutorials where id = external_id),
        cache_rating = (select cache_rating from tutorials where id = external_id),
        cache_rated_times = (select cache_rated_times from tutorials where id = external_id),
        cache_comments_count = (select cache_comments_count from tutorials where id = external_id),
        log = (select log from tutorials where id = external_id),
        cache_weighted_rank = (select cache_weighted_rank from tutorials where id = external_id),
        home_image = (select home_image from tutorials where id = external_id)
     WHERE type = 'Tutorial';
    "

    # home_image
    execute "
    update contents set
        description = (select description from interviews where id = external_id),
        main = (select main from interviews where id = external_id),
        hits_registered = (select hits_registered from interviews where id = external_id),
        hits_anonymous = (select hits_anonymous from interviews where id = external_id),
        cache_rating = (select cache_rating from interviews where id = external_id),
        cache_rated_times = (select cache_rated_times from interviews where id = external_id),
        cache_comments_count = (select cache_comments_count from interviews where id = external_id),
        log = (select log from interviews where id = external_id),
        cache_weighted_rank = (select cache_weighted_rank from interviews where id = external_id),
        home_image = (select home_image from interviews where id = external_id)
     WHERE type = 'Interview';
    "

    execute "
    update contents set
        description = (select description from columns where id = external_id),
        main = (select main from columns where id = external_id),
        hits_registered = (select hits_registered from columns where id = external_id),
        hits_anonymous = (select hits_anonymous from columns where id = external_id),
        cache_rating = (select cache_rating from columns where id = external_id),
        cache_rated_times = (select cache_rated_times from columns where id = external_id),
        cache_comments_count = (select cache_comments_count from columns where id = external_id),
        log = (select log from columns where id = external_id),
        cache_weighted_rank = (select cache_weighted_rank from columns where id = external_id),
        home_image = (select home_image from columns where id = external_id)
     WHERE type = 'Column';
    "

    execute "
    update contents set
        description = (select description from reviews where id = external_id),
        main = (select main from reviews where id = external_id),
        hits_registered = (select hits_registered from reviews where id = external_id),
        hits_anonymous = (select hits_anonymous from reviews where id = external_id),
        cache_rating = (select cache_rating from reviews where id = external_id),
        cache_rated_times = (select cache_rated_times from reviews where id = external_id),
        cache_comments_count = (select cache_comments_count from reviews where id = external_id),
        log = (select log from reviews where id = external_id),
        cache_weighted_rank = (select cache_weighted_rank from reviews where id = external_id),
        home_image = (select home_image from reviews where id = external_id)
     WHERE type = 'Review';
    "

    execute "
    update contents set
        description = (select description from funthings where id = external_id),
        main = (select main from funthings where id = external_id),
        hits_registered = (select hits_registered from funthings where id = external_id),
        hits_anonymous = (select hits_anonymous from funthings where id = external_id),
        cache_rating = (select cache_rating from funthings where id = external_id),
        cache_rated_times = (select cache_rated_times from funthings where id = external_id),
        cache_comments_count = (select cache_comments_count from funthings where id = external_id),
        log = (select log from funthings where id = external_id),
        cache_weighted_rank = (select cache_weighted_rank from funthings where id = external_id)
     WHERE type = 'Funthing';
    "

    execute "
    update contents set
        description = (select description from blogentries where id = external_id),
        main = (select main from blogentries where id = external_id),
        hits_registered = (select hits_registered from blogentries where id = external_id),
        hits_anonymous = (select hits_anonymous from blogentries where id = external_id),
        cache_rating = (select cache_rating from blogentries where id = external_id),
        cache_rated_times = (select cache_rated_times from blogentries where id = external_id),
        cache_comments_count = (select cache_comments_count from blogentries where id = external_id),
        log = (select log from blogentries where id = external_id),
        cache_weighted_rank = (select cache_weighted_rank from blogentries where id = external_id)
     WHERE type = 'Blogentry';
    "

    execute "
    update contents set
        description = (select description from demos where id = external_id),
        main = (select main from demos where id = external_id),
        hits_registered = (select hits_registered from demos where id = external_id),
        hits_anonymous = (select hits_anonymous from demos where id = external_id),
        cache_rating = (select cache_rating from demos where id = external_id),
        cache_rated_times = (select cache_rated_times from demos where id = external_id),
        cache_comments_count = (select cache_comments_count from demos where id = external_id),
        log = (select log from demos where id = external_id),
        cache_weighted_rank = (select cache_weighted_rank from demos where id = external_id),
        entity1_local_id = (select entity1_local_id from demos where id = external_id),
        entity2_local_id = (select entity2_local_id from demos where id = external_id),
        entity1_external = (select entity1_external from demos where id = external_id),
        entity2_external = (select entity2_external from demos where id = external_id),
        games_map_id = (select games_map_id from demos where id = external_id),
        event_id = (select event_id from demos where id = external_id),
        pov_type = (select pov_type from demos where id = external_id),
        pov_entity = (select pov_entity from demos where id = external_id),
        file = (select file from demos where id = external_id),
        file_hash_md5 = (select file_hash_md5 from demos where id = external_id),
        downloaded_times = (select downloaded_times from demos where id = external_id),
        file_size = (select file_size from demos where id = external_id),
        games_mode_id = (select games_mode_id from demos where id = external_id),
        games_version_id = (select games_version_id from demos where id = external_id),
        demotype = (select demotype from demos where id = external_id),
        played_on = (select played_on from demos where id = external_id)
     WHERE type = 'Demo';
    "

    execute "
    update contents set
        description = (select description from questions where id = external_id),
        main = (select main from questions where id = external_id),
        hits_registered = (select hits_registered from questions where id = external_id),
        hits_anonymous = (select hits_anonymous from questions where id = external_id),
        cache_rating = (select cache_rating from questions where id = external_id),
        cache_rated_times = (select cache_rated_times from questions where id = external_id),
        cache_comments_count = (select cache_comments_count from questions where id = external_id),
        log = (select log from questions where id = external_id),
        cache_weighted_rank = (select cache_weighted_rank from questions where id = external_id),
        ammount = (select ammount from questions where id = external_id),
        answered_on = (select answered_on from questions where id = external_id),
        answer_selected_by_user_id = (select answer_selected_by_user_id from questions where id = external_id)
     WHERE type = 'Question';
    "

    execute "
    update contents set
        description = (select description from recruitment_ads where id = external_id),
        main = (select main from recruitment_ads where id = external_id),
        hits_registered = (select hits_registered from recruitment_ads where id = external_id),
        hits_anonymous = (select hits_anonymous from recruitment_ads where id = external_id),
        cache_rating = (select cache_rating from recruitment_ads where id = external_id),
        cache_rated_times = (select cache_rated_times from recruitment_ads where id = external_id),
        cache_comments_count = (select cache_comments_count from recruitment_ads where id = external_id),
        log = (select log from recruitment_ads where id = external_id),
        cache_weighted_rank = (select cache_weighted_rank from recruitment_ads where id = external_id),
        country_id = (select country_id from recruitment_ads where id = external_id),
        levels = (select levels from recruitment_ads where id = external_id),
        clan_id = (select clan_id from recruitment_ads where id = external_id),
        game_id = (select game_id from recruitment_ads where id = external_id)
     WHERE type = 'RecruitmentAd';
    "

  end

  def down
  end
end
