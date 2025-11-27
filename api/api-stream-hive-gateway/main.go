package main

import (
	"log"
	"net/http"
	"stream-hive/api/api-stream-hive-gateway/di"
	"stream-hive/api/middlewares"
	"stream-hive/core"
	"time"

	"github.com/gin-contrib/gzip"
	"github.com/gin-gonic/gin"
)

func main() {
	serviceName := core.STREAM_HIVE_GATEWAY_NAME
	container := di.BuildContainer(serviceName)
	err := container.Invoke(func(p di.Params) {
		log.Print("Stream Hive API Gateway Config: ", p.Config)

		if p.Config.Env == core.PRODUCTION || p.Config.Env == core.DEVELOPMENT || p.Config.Env == core.STAGING {
			gin.SetMode(gin.ReleaseMode)
			log.Println("Running in Production Mode")
		} else {
			gin.SetMode(gin.DebugMode)
			log.Println("Running in Debug/Local Mode")
		}

		r := gin.Default()

		// Initialize middlewares
		r.Use(gin.Recovery())
		r.Use(gzip.Gzip(gzip.BestSpeed))
		r.Use(middlewares.CorsMiddleware())

		// Define Routes
		for _, h := range p.Handler {
			h.RegisterRoutes(r)
		}

		srv := &http.Server{
			Addr:         ":" + p.Config.HTTPPort,
			Handler:      r,
			ReadTimeout:  10 * time.Second,
			WriteTimeout: 10 * time.Second,
			IdleTimeout:  120 * time.Second,
		}

		if err := srv.ListenAndServe(); err != nil {
			log.Printf("Failed to run api gateway: %v", err)
		}
	})

	if err != nil {
		log.Printf("Failed to start API Gateway: %v", err)
	}
}
