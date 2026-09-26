<%# mkdir -p sql && pnpm dlx ejs -n -l pkg init.sql.ejs.t -f package.json -o sql/init.sql -%>
-- Schema

create schema api;
create role web_anon nologin;

grant usage on schema api to web_anon;

create table api.todos (
  id   serial primary key,
  done boolean not null default false,
  task text    not null,
  due  timestamptz
);

grant select on api.todos to web_anon;

-- Data

insert into api.todos (task) values
  ('finish tutorial 0'), ('pat self on back');
