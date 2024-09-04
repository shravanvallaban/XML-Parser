# Use an official Elixir runtime as a parent image
FROM elixir:1.14-alpine

# Install build dependencies
RUN apk add --no-cache build-base npm git python3 postgresql-client

# Set environment variables
ENV MIX_ENV=dev

# Create app directory and copy the Elixir projects into it
WORKDIR /app
COPY . .

# Install hex package manager and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Install mix dependencies
RUN mix deps.get
RUN mix deps.compile

# Install npm dependencies for the React frontend
WORKDIR /app/assets
RUN npm install

# Move back to the main app directory
WORKDIR /app

# Compile the project
RUN mix compile

# Make entrypoint script executable
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

# Expose ports
EXPOSE 4000 3000

# Set the entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]