DROP TABLE IF EXISTS users;

CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    firstname TEXT NOT NULL, 
    lastname TEXT NOT NULL
)

DROP TABLE IF EXISTS questions;

CREATE TABLE questions(
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL, 
    body TEXT NOT NULL,
    author_id INTEGER NOT NULL,

    FOREIGN KEY (author_id) REFERENCES users(id)
)

DROP TABLE IF EXISTS question_follows;

CREATE TABLE question_follows(
    question_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,

    FOREIGN KEY (question_id) REFERENCES questions(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
)

DROP TABLE IF EXISTS replies;

CREATE TABLE replies(
    id INTEGER PRIMARY KEY,
    original_q_id INTEGER NOT NULL,
    reply_id INTEGER,
    replier_id INTEGER NOT NULL,
    body TEXT NOT NULL,

    FOREIGN KEY (original_q_id) REFERENCES questions(id),
    FOREIGN KEY (reply_id) REFERENCES replies(id),
    FOREIGN KEY (replier_id) REFERENCES users(id)
)

DROP TABLE IF EXISTS question_likes;

CREATE TABLE question_likes(
    user_id INTEGER NOT NULL,
    question_id INTEGER NOT NULL,

    FOREIGN KEY (question_id) REFERENCES questions(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
)



