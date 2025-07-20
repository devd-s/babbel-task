# ----------------------------
  # Stage 1: Build the Go binary
  # ----------------------------
FROM golang:1.23-alpine AS builder

# Set working directory
WORKDIR /app
  
# Copy go.mod and go.sum files
COPY go.mod go.sum ./
  
# Download dependencies
RUN go mod download
  
# Copy the rest of the application code
COPY . .

RUN apk add --no-cache gcc musl-dev sqlite-dev

# Build the Go app
RUN CGO_ENABLED=1 go build -o url-shortener .
  
# ----------------------------
# Stage 2: Create a slim runtime image
# ----------------------------
FROM alpine:latest
  
# Create a non-root user for security (UID 1000, GID 3000 to match K8s security context)
RUN apk add --no-cache sqlite && \
    addgroup -g 3000 appgroup && \
    adduser -D -s /bin/sh -u 1000 -G appgroup appuser
  
WORKDIR /app
  
# Copy the binary from the builder
COPY --from=builder /app/url-shortener .
  
# This is not required when we are using RDS in prod env
COPY --from=builder /app/urls.db .
  
# Set permissions and make executable
RUN chown -R appuser /app && chmod +x /app/url-shortener
USER appuser
  
# Expose the port your app listens on
EXPOSE 8080
  
# Run the Go app
CMD ["./url-shortener"]
