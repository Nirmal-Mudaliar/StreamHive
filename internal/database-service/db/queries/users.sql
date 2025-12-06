-- name: GetUserById :one
SELECT
    *
FROM
    users
WHERE
    id = sqlc.arg('user_id')
LIMIT
    1;