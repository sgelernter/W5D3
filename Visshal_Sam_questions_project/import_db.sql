DROP TABLE IF EXISTS users;

CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    firstname TEXT NOT NULL, 
    lastname TEXT NOT NULL
);

DROP TABLE IF EXISTS questions;

CREATE TABLE questions(
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL, 
    body TEXT NOT NULL,
    author_id INTEGER NOT NULL,

    FOREIGN KEY (author_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS question_follows;

CREATE TABLE question_follows(
    question_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,

    FOREIGN KEY (question_id) REFERENCES questions(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

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
);

DROP TABLE IF EXISTS question_likes;

CREATE TABLE question_likes(
    user_id INTEGER NOT NULL,
    question_id INTEGER NOT NULL,

    FOREIGN KEY (question_id) REFERENCES questions(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

INSERT INTO users(firstname, lastname)
VALUES ('Visshal','Suresh');

INSERT INTO users(firstname, lastname)
VALUES ('Sam','Gelernter');

INSERT INTO questions(title, body, author_id)
VALUES ('How does this Work', 'No really, How does this work?', 
    (SELECT id FROM users WHERE firstname = 'Visshal'));

INSERT INTO questions(title, body, author_id)
VALUES ('How hard is SQL', 'It seems pretty hard', 
    (SELECT id FROM users WHERE firstname = 'Sam'));

INSERT INTO question_follows(question_id, user_id)
VALUES ((SELECT id FROM questions WHERE title = 'How does this Work'),
(SELECT id FROM users WHERE firstname = 'Sam'));

INSERT INTO question_follows(question_id, user_id)
VALUES ((SELECT id FROM questions WHERE title = 'How hard is SQL'),
(SELECT id FROM users WHERE firstname = 'Visshal'));

INSERT INTO question_likes(question_id, user_id)
VALUES ((SELECT id FROM questions WHERE title = 'How does this Work'),
(SELECT id FROM users WHERE firstname = 'Sam'));

INSERT INTO question_likes(question_id, user_id)
VALUES ((SELECT id FROM questions WHERE title = 'How hard is SQL'),
(SELECT id FROM users WHERE firstname = 'Visshal'));

INSERT INTO replies(original_q_id, replier_id, body)
VALUES ((SELECT id FROM questions WHERE title = 'How hard is SQL'),
    (SELECT id FROM users WHERE firstname = 'Visshal'),
    'I dont think so');

INSERT INTO replies(original_q_id, reply_id, replier_id, body)
VALUES ((SELECT id FROM questions WHERE title = 'How hard is SQL'),
    (SELECT id FROM replies WHERE body = 'I dont think so'),
    (SELECT id FROM users WHERE firstname = 'Sam'),
    'I dont think so either');









