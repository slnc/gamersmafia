update users set email = login || '@gamersmafia.dev', password = (SELECT password from users where id = 1) where id <> 1;
