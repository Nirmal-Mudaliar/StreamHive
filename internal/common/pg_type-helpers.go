package common

import "github.com/jackc/pgx/v5/pgtype"

func ToPgText(input *string) pgtype.Text {
	var value pgtype.Text
	if input == nil || *input == "" {
		_ = value.Scan(nil)
	} else {
		_ = value.Scan(*input)
	}
	return value
}
