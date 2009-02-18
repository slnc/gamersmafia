create table demos_categories (id serial primary key not null unique,
                              name varchar not null,
                              parent_id int,
                              updated_on timestamp not null default now(),
                              root_id int,
                              code varchar,
                              description varchar,
                              last_updated_item_id int,
                              demos_count int not null default 0,
                              
                              foreign key(parent_id) references demos_categories(id),
                              foreign key(root_id) references demos_categories(id)
                              );
                              
create table games_modes(id serial primary key, name varchar not null, game_id int not null references games match full);
create unique index games_modes_uniq on games_modes(name, game_id);

create table games_versions(id serial primary key, version varchar not null, game_id int not null references games match full);
create unique index games_versions_uniq on games_versions(version, game_id);


create table demos (id serial primary key not null unique, 
                   created_on timestamp not null default now(), 
                   updated_on timestamp not null default now(), 
                   user_id int not null, 
                   approved_by_user_id int, 
                   hits_registered int not null default 0, 
                   hits_anonymous int not null default 0, 
                   deleted bool not null default false, 
                   cache_rating smallint, 
                   cache_rated_times smallint, 
                   cache_comments_count int not null default 0, 
                   log varchar,
                   state smallint not null default 0,

                   title varchar not null unique, 
                   description varchar, 
                   demos_category_id int not null,
                   entity_type smallint not null,
                   entity1_local_id int,
                   entity2_local_id int,
                   entity1_external varchar,
                   entity2_external varchar,
                   games_map_id int references games_maps match full,
                   event_id int references events match full,
                   pov_type smallint,
                   pov_entity smallint,
                   file varchar,
                   file_hash_md5 varchar,
                   downloaded_times int not null default 0,
                   file_size bigint, 
                   games_mode_id int references games_modes match full,
                   games_version_id int references games_versions match full,
                   demotype smallint,
                   played_on timestamp,

                   foreign key(user_id) references users,
                   foreign key(approved_by_user_id) references users,
                   foreign key(demos_category_id) references demos_categories
                   
                   );

alter table demos add column closes_on timestamp;

create index demos_approved_by_user_id on demos(approved_by_user_id);
create index demos_approved_by_user_id_deleted on demos(approved_by_user_id, deleted);
create index demos_common on demos(created_on, approved_by_user_id, deleted, user_id, demos_category_id);
create index demos_user_id on demos(user_id);
create unique index demos_categories_unique on demos_categories (name, parent_id);
create unique index demos_hash_md5 on demos (file_hash_md5);
create unique index demos_file on demos (file);
create unique index demos_state on demos (state);

alter table demos_categories add foreign key(last_updated_item_id) references demos;