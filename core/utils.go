package core

import (
	"log"
	"os"
	"strconv"
)

func GetEnv(key string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return ""
}

func GetInt32Env(key string, defaultValue int32) int32 {
	if value, exists := os.LookupEnv(key); exists {
		parsedValue, err := strconv.Atoi(value)
		if err != nil {
			log.Printf("Error converting %s to int: %v", key, err)
			return defaultValue // Default value
		}
		return int32(parsedValue)
	}
	return defaultValue
}

func GetIntEnv(key string, defaultValue int) int {
	if value, exists := os.LookupEnv(key); exists {
		parsedValue, err := strconv.Atoi(value)
		if err != nil {
			log.Printf("Error converting %s to int: %v", key, err)
			return defaultValue // Default value
		}
		return parsedValue
	}
	return defaultValue
}
