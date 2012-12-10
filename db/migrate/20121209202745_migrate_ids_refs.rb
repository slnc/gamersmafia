class MigrateIdsRefs < ActiveRecord::Migration
  def up
    execute "alter table potds drop constraint potds_image_id_fkey;"
    execute "update potds set image_id = (SELECT unique_content_id FROM images WHERE id = image_id);"
    execute "alter table potds add constraint image_id_fkey foreign key (image_id) references contents;"
    execute "alter table potds rename image_id to content_id;"

    execute "update bets_options set bet_id = (SELECT unique_content_id FROM bets WHERE id = bet_id);"
    execute "alter table bets_options add constraint bet_id_fkey foreign key (bet_id) references contents;"
    execute "alter table potds rename bet_id to content_id;"

    execute "update games_maps set download_id = (SELECT unique_content_id FROM downloads WHERE id = download_id);"
    execute "alter table games_maps add constraint content_id_fkey foreign key (download_id) references contents;"
    execute "alter table games_maps rename download_id to content_id;"

    execute "update downloaded_downloads set download_id = (SELECT unique_content_id FROM downloads WHERE id = download_id);"
    execute "alter table downloaded_downloads add constraint content_id_fkey foreign key (download_id) references contents;"
    execute "alter table downloaded_downloads rename download_id to content_id;"

    execute "update download_mirrors set download_id = (SELECT unique_content_id FROM downloads WHERE id = download_id);"
    execute "alter table download_mirrors add constraint content_id_fkey foreign key (download_id) references contents; "
    execute "alter table download_mirrors rename download_id to content_id;"

    execute "update polls_options set poll_id = (SELECT unique_content_id FROM polls WHERE id = poll_id);        "
    execute "alter table polls_options add constraint content_id_fkey foreign key (poll_id) references contents; "
    execute "alter table polls_options rename poll_id to content_id;                                             "

    execute "update polls_options set poll_id = (SELECT unique_content_id FROM polls WHERE id = poll_id);        "
    execute "alter table polls_options add constraint content_id_fkey foreign key (poll_id) references contents; "
    execute "alter table polls_options rename poll_id to content_id;                                             "

    execute "update competitions_matches set event_id = (SELECT unique_content_id FROM events WHERE id = event_id);        "
    execute "alter table competitions_matches add constraint content_id_fkey foreign key (event_id) references contents; "
    execute "alter table competitions_matches rename event_id to content_id;                                             "

    execute "alter table coverages drop constraint events_news_event_id_fkey;                              "
    execute "update coverages set event_id = (SELECT unique_content_id FROM events WHERE id = event_id);   "
    execute "alter table coverages rename event_id to content_id;                                          "
    execute "alter table coverages add constraint event_id_fkey foreign key (content_id) references contents;  "

    execute "alter table demos drop constraint demos_event_id_fkey;                                           "
    execute "update demos set event_id = (SELECT unique_content_id FROM events WHERE id = event_id);         "
    execute "alter table demos rename event_id to content_id;                                               "
    execute "alter table demos add constraint content_id_fkey foreign key (content_id) references contents;  "

  end

  def down
  end
end
