# Build stage
FROM dart:stable AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart compile exe bin/server.dart -o bin/server

# Runtime stage
FROM debian:bullseye-slim

# Install system dependencies
RUN apt-get update && apt-get install -y libpq5 ca-certificates && rm -rf /var/lib/apt/lists/*

# Cloud SQL socket will be mounted automatically in Cloud Run
VOLUME ["/cloudsql"]

# Copy runtime and app
COPY --from=build /runtime/ /runtime/
COPY --from=build /app/bin/server /app/server

# Set environment
ENV PATH="/runtime/bin:$PATH"

# Expose the default port used by Shelf/Cloud Run
EXPOSE 8080

# Run the server
CMD ["/app/server"]
