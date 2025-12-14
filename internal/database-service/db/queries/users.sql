-- name: GetUserById :one
SELECT
    *
FROM
    users
WHERE
    id = sqlc.arg('user_id')
LIMIT
    1;

-- name: InsertUser :one
INSERT INTO users (
    email,
    password_hash,
    full_name
) VALUES (
    sqlc.arg(email),
    sqlc.arg(password_hash),
    sqlc.arg(full_name)
) RETURNING *;

-- name: GetUserByEmail :one
SELECT
    *
FROM
    users
WHERE
    email = sqlc.arg('email');