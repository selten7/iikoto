CREATE TABLE boards (
  route TEXT PRIMARY KEY NOT NULL,
  name TEXT NOT NULL
);

CREATE TABLE yarns (
  number INTEGER PRIMARY KEY NOT NULL,
  board TEXT NOT NULL,
  updated DATETIME NOT NULL,
  subject TEXT,
  locked BOOLEAN,
  FOREIGN KEY(board) REFERENCES boards(route),
  FOREIGN KEY(number) REFERENCES posts(number)
);

CREATE TABLE posts (
  number INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  yarn INTEGER,
  name TEXT NOT NULL,
  time DATETIME NOT NULL,
  body TEXT,
  spoiler BOOLEAN
);

CREATE TABLE images (
  number INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  post INTEGER NOT NULL,
  extension TEXT NOT NULL,
  name TEXT NOT NULL,
  width INTEGER NOT NULL,
  height INTEGER NOT NULL,
  FOREIGN KEY(post) REFERENCES posts(number)
);

CREATE TABLE users (
  username TEXT PRIMARY KEY NOT NULL,
  password TEXT NOT NULL,
  salt TEXT NOT NULL
);
