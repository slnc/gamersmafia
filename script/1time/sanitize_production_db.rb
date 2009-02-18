update users set email = login || '@gamersmafia.com', password = (SELECT password from users where id = 1);
