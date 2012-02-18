-- CHEATSHEET FOR DOING DUMPS
-- For specific tables:
-- pg_dump -Oxa --column-inserts -t terms gamersmafia > terms.sql
--
-- For specific rows:
-- CREATE temptable as SELECT ...
-- pg_dump -Oxa --column-inserts -t temptable gamersmafia > temptable.sql

TRUNCATE comments_valorations_types CASCADE;
TRUNCATE content_types CASCADE;
TRUNCATE global_vars;
TRUNCATE terms CASCADE;
TRUNCATE users CASCADE;

INSERT INTO global_vars (id, online_anonymous, online_registered, svn_revision, ads_slots_updated_on, gmtv_channels_updated_on, pending_contents, portals_updated_on, max_cache_valorations_weights_on_self_comments) VALUES (1, 363, 73, '68d5428', '2011-07-30 18:17:39.727069', '2010-01-10 21:44:56.169444', 0, '2011-12-25 04:39:59.003601', 242403.0);

INSERT INTO content_types (id, name) VALUES (1, 'News');
INSERT INTO content_types (id, name) VALUES (15, 'Bet');
INSERT INTO content_types (id, name) VALUES (4, 'Image');
INSERT INTO content_types (id, name) VALUES (5, 'Download');
INSERT INTO content_types (id, name) VALUES (23, 'Demo');
INSERT INTO content_types (id, name) VALUES (7, 'Poll');
INSERT INTO content_types (id, name) VALUES (8, 'Event');
INSERT INTO content_types (id, name) VALUES (10, 'Tutorial');
INSERT INTO content_types (id, name) VALUES (11, 'Interview');
INSERT INTO content_types (id, name) VALUES (12, 'Column');
INSERT INTO content_types (id, name) VALUES (13, 'Review');
INSERT INTO content_types (id, name) VALUES (14, 'Funthing');
INSERT INTO content_types (id, name) VALUES (17, 'Blogentry');
INSERT INTO content_types (id, name) VALUES (6, 'Topic');
INSERT INTO content_types (id, name) VALUES (9, 'Coverage');
INSERT INTO content_types (id, name) VALUES (24, 'Question');
INSERT INTO content_types (id, name) VALUES (25, 'RecruitmentAd');

INSERT INTO terms (id, name, slug, description, parent_id, game_id, platform_id, bazar_district_id, clan_id, contents_count, last_updated_item_id, comments_count, root_id, taxonomy)
  VALUES (95, 'Gamersmafia', 'gm', '', NULL, NULL, NULL, NULL, NULL, 0, NULL, 35966, 95, NULL);

INSERT INTO terms (id, name, slug, description, parent_id, game_id, platform_id, bazar_district_id, clan_id, contents_count, last_updated_item_id, comments_count, root_id, taxonomy)
  VALUES (4988, 'GmVersion', 'gmversion', '', NULL, NULL, NULL, NULL, NULL, 89, NULL, -18199, 4988, NULL);

INSERT INTO terms (id, name, slug, description, parent_id, game_id, platform_id, bazar_district_id, clan_id, contents_count, last_updated_item_id, comments_count, root_id, taxonomy)
  VALUES (97, 'Bazar', 'bazar', '', NULL, NULL, NULL, NULL, NULL, 0, NULL, -16394, 97, NULL);

INSERT INTO terms (id, name, slug, description, parent_id, game_id, platform_id, bazar_district_id, clan_id, contents_count, last_updated_item_id, comments_count, root_id, taxonomy)
  VALUES (908, 'Arena', 'arena', '', NULL, NULL, NULL, NULL, NULL, 0, NULL, -16443, 908, NULL);

INSERT INTO terms (id, name, slug, description, parent_id, game_id, platform_id, bazar_district_id, clan_id, contents_count, last_updated_item_id, comments_count, root_id, taxonomy)
  VALUES (1559, 'Babes', 'babes', '', 97, NULL, NULL, NULL, NULL, 0, NULL, -16351, 97, 'ImagesCategory');

INSERT INTO terms (id, name, slug, description, parent_id, game_id, platform_id, bazar_district_id, clan_id, contents_count, last_updated_item_id, comments_count, root_id, taxonomy)
  VALUES (1560, 'Dudes', 'dudes', '', 97, NULL, NULL, NULL, NULL, 0, NULL, -16502, 97, 'ImagesCategory');

INSERT INTO terms (id, name, slug, taxonomy, parent_id, root_id) VALUES (474, 'General', 'general_23', 'DownloadsCategory', 95, 95);
INSERT INTO terms (id, name, slug, taxonomy, parent_id, root_id) VALUES (2396, 'Party Larga', 'party-larga_2', 'EventsCategory', 95, 95);
INSERT INTO terms (id, name, slug, taxonomy, parent_id, root_id) VALUES (2397, 'Party Corta', 'party-corta_2', 'EventsCategory', 95, 95);
INSERT INTO terms (id, name, slug, taxonomy, parent_id, root_id) VALUES (1570, 'Wallpapers GM', 'wallpapers-gm', 'ImagesCategory', 95, 95);
INSERT INTO terms (id, name, slug, taxonomy, parent_id, root_id) VALUES (2170, 'Partys', 'partys_4', 'NewsCategory', 95, 95);
INSERT INTO terms (id, name, slug, taxonomy, parent_id, root_id) VALUES (2171, 'Competiciones', 'competiciones_36', 'NewsCategory', 95, 95);
INSERT INTO terms (id, name, slug, taxonomy, parent_id, root_id) VALUES (869, 'General', 'general_86', 'TopicsCategory', 95, 95);
INSERT INTO terms (id, name, slug, taxonomy, parent_id, root_id) VALUES (871, 'Sugerencias', 'sugerencias', 'TopicsCategory', 95, 95);
INSERT INTO terms (id, name, slug, taxonomy, parent_id, root_id) VALUES (2262, 'General', 'general_264', 'TutorialsCategory', 95, 95);
INSERT INTO terms (id, name, slug, taxonomy, parent_id, root_id) VALUES (2282, 'Programas de Comunicacion', 'programas-de-comunicacion_1', 'TutorialsCategory', 95, 95);
INSERT INTO terms (id, name, slug, taxonomy, parent_id, root_id) VALUES (2283, 'Pc//Sistema Operativo', 'pc-sistema-operativo', 'TutorialsCategory', 95, 95);
INSERT INTO terms (id, name, slug, taxonomy, parent_id, root_id) VALUES (2284, 'Punkbuster', 'punkbuster_13', 'TutorialsCategory', 95, 95);
INSERT INTO terms (id, name, slug, taxonomy, parent_id, root_id) VALUES (2285, 'Conceptos', 'conceptos', 'TutorialsCategory', 95, 95);
INSERT INTO terms (id, name, slug, taxonomy, parent_id, root_id) VALUES (2286, 'Clanbase', 'clanbase_7', 'TutorialsCategory', 95, 95);
INSERT INTO terms (id, name, slug, taxonomy, parent_id, root_id) VALUES (2287, 'Tutoriales para videofrags', 'tutoriales-para-videofrags', 'TutorialsCategory', 95, 95);

INSERT INTO comments_valorations_types (id, name, direction) VALUES (1, 'Normal', 0);
INSERT INTO comments_valorations_types (id, name, direction) VALUES (2, 'Divertido', 1);
INSERT INTO comments_valorations_types (id, name, direction) VALUES (3, 'Informativo', 1);
INSERT INTO comments_valorations_types (id, name, direction) VALUES (4, 'Profundo', 1);
INSERT INTO comments_valorations_types (id, name, direction) VALUES (5, 'Flame', -1);
INSERT INTO comments_valorations_types (id, name, direction) VALUES (6, 'Redundante', -1);
INSERT INTO comments_valorations_types (id, name, direction) VALUES (7, 'Irrelevante', -1);
INSERT INTO comments_valorations_types (id, name, direction) VALUES (8, 'Interesante', 1);
INSERT INTO comments_valorations_types (id, name, direction) VALUES (9, 'Spam', -1);

INSERT INTO users (id, login, password, validkey, email, newemail, ipaddr, created_on, updated_at, firstname, lastname, image, lastseen_on, faction_id, faction_last_changed_on, avatar_id, city, homepage, sex, msn, icq, birthday, cache_karma_points, irc, country_id, photo, hw_mouse, hw_processor, hw_motherboard, hw_ram, hw_hdd, hw_graphiccard, hw_soundcard, hw_headphones, hw_monitor, hw_connection, description, is_superadmin, comments_count, referer_user_id, cache_faith_points, notifications_global, notifications_newmessages, notifications_newregistrations, notifications_trackerupdates, xfire, cache_unread_messages, resurrected_by_user_id, resurrection_started_on, using_tracker, secret, cash, lastcommented_on, global_bans, last_clan_id, antiflood_level, last_competition_id, competition_roster, enable_competition_indicator, is_hq, enable_profile_signatures, profile_signatures_count, wii_code, email_public, gamertag, googletalk, yahoo_im, notifications_newprofilesignature, tracker_autodelete_old_contents, comment_adds_to_tracker_enabled, cache_remaining_rating_slots, has_seen_tour, is_bot, admin_permissions, state, cache_is_faction_leader, profile_last_updated_on, visitor_id, comments_valorations_type_id, comments_valorations_strength, enable_comments_sig, comments_sig, comment_show_sigs, has_new_friend_requests, default_portal, emblems_mask, random_id, is_staff, pending_slog, ranking_karma_pos, ranking_faith_pos, ranking_popularity_pos, cache_popularity, login_is_ne_unfriendly, cache_valorations_weights_on_self_comments, default_comments_valorations_weight) VALUES (26740, 'nagato', 'd3d32e24b51d4a1641315b9a0af6d338', 'e72c5d921b364aa275daecf7815eef40', 'nagato@gamersmafia.com', NULL, '130.126.77.77', '2007-01-01 03:37:46.550389', '2011-12-17 00:51:34.876367', 'Nagato', '', NULL, '2010-04-14 01:15:14.166181', NULL, NULL, NULL, 'Desconocida', '', 1, '', NULL, '1982-03-07', 475, '', 115, 'storage/users/0026/740_nagato.jpg', '', '', '', '', '', '', '', '', '', '', 'Hola, trabajo para Gamersmafia. Soy la encargada de comunicar distintos tipos de mensajes a los usuarios.^M
^M
¡Encantada de conocerte!', false, 7, NULL, 80, false, false, false, false, '', 937, 21591, '2011-12-17 00:51:34.844138', true, NULL, 141.00, '2010-04-14 01:13:51.743674', 0, NULL, -1, NULL, NULL, false, false, true, 27, NULL, false, NULL, NULL, NULL, false, true, true, NULL, false, true, '000000000', 2, false, NULL, '1548943521', 2, 0.92, false, NULL, NULL, true, NULL, NULL, 0.48878867365419898, true, 0, 1652, 1066, 73, 8, false, 584.438, 1);

INSERT INTO users (id, login, password, validkey, email, newemail, ipaddr, created_on, updated_at, firstname, lastname, image, lastseen_on, faction_id, faction_last_changed_on, avatar_id, city, homepage, sex, msn, icq, birthday, cache_karma_points, irc, country_id, photo, hw_mouse, hw_processor, hw_motherboard, hw_ram, hw_hdd, hw_graphiccard, hw_soundcard, hw_headphones, hw_monitor, hw_connection, description, is_superadmin, comments_count, referer_user_id, cache_faith_points, notifications_global, notifications_newmessages, notifications_newregistrations, notifications_trackerupdates, xfire, cache_unread_messages, resurrected_by_user_id, resurrection_started_on, using_tracker, secret, cash, lastcommented_on, global_bans, last_clan_id, antiflood_level, last_competition_id, competition_roster, enable_competition_indicator, is_hq, enable_profile_signatures, profile_signatures_count, wii_code, email_public, gamertag, googletalk, yahoo_im, notifications_newprofilesignature, tracker_autodelete_old_contents, comment_adds_to_tracker_enabled, cache_remaining_rating_slots, has_seen_tour, is_bot, admin_permissions, state, cache_is_faction_leader, profile_last_updated_on, visitor_id, comments_valorations_type_id, comments_valorations_strength, enable_comments_sig, comments_sig, comment_show_sigs, has_new_friend_requests, default_portal, emblems_mask, random_id, is_staff, pending_slog, ranking_karma_pos, ranking_faith_pos, ranking_popularity_pos, cache_popularity, login_is_ne_unfriendly, cache_valorations_weights_on_self_comments, default_comments_valorations_weight) VALUES (1, 'unnamed', '6756261aa0fbca41602bb3e68fd1be83', 'ed73c0cffec07a74b180bc395e2922f5', 'unnamed@example.com', NULL, '10.211.55.2', '2012-02-05 12:01:33.913929', '2012-02-18 16:18:31.885697', '', '', NULL, '2012-02-18 16:17:51.946291', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 45, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, true, 1, NULL, 0, true, true, true, true, NULL, 0, NULL, NULL, true, NULL, 1000.00, '2012-02-05 13:52:47.172554', 0, NULL, -1, NULL, NULL, false, false, false, 0, NULL, false, NULL, NULL, NULL, true, true, true, 5, false, false, '00000', 1, false, NULL, '1509458161', 1, 1.00, false, NULL, NULL, false, NULL, NULL, NULL, false, 0, NULL, NULL, NULL, NULL, false, 0.0, 1);
