# Use an official Elixir runtime as a parent image
FROM elixir:1.14-alpine

# Install build dependencies
RUN apk add --no-cache build-base npm git python3 postgresql-client

# Set environment variables
ARG MIX_ENV=prod
ENV MIX_ENV=${MIX_ENV}

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

# Build the frontend assets
RUN npm run build

# Move back to the main app directory
WORKDIR /app

# Compile and digest the Phoenix assets
RUN mix phx.digest

# Compile the project
RUN mix compile

# Create the release
RUN mix release

# Make entrypoint script executable
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

# Expose port 4000
EXPOSE 4000

# Set the entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]

# Set the default command
CMD ["mix", "phx.server"]