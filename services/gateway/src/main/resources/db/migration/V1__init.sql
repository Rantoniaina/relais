create table provider (
  id          bigint generated always as identity primary key,
  code        text        not null unique,
  base_url    text        not null,
  kind        text        not null check (kind in ('ollama', 'openai', 'anthropic')),
  enabled     boolean     not null default true,
  created_at  timestamptz not null default now()
);

insert into provider (code, base_url, kind)
values ('ollama-local', 'http://localhost:11434', 'ollama');