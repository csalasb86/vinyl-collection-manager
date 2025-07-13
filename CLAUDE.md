# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Vinyl Collection Manager is a Rails 8.0 application for managing vinyl record collections with Discogs API integration. Built with PostgreSQL, TailwindCSS, Stimulus, and modern Rails features including Solid Queue for background jobs.

## Essential Development Commands

### Development Server

```bash
bin/dev                          # Start full development environment (Rails server + Tailwind CSS watching)
bin/rails server                # Rails server only
```

### Database Management

```bash
bin/rails db:create              # Create database
bin/rails db:migrate             # Run migrations
bin/rails db:seed                # Load seed data
bin/rails db:setup               # Complete database setup (create + migrate + seed)
bin/rails db:reset               # Drop and recreate database
```

### Testing

```bash
bin/rails test                   # Run all tests
bin/rails test:system            # Run system tests (Capybara + Selenium)
```

### Code Quality & Security

```bash
bin/rubocop                      # Check and fix Ruby code style (Rails Omakase style guide)
bin/rubocop --auto-correct       # Automatically fix style issues
bin/brakeman                     # Security vulnerability scanner
```

### Asset Management

```bash
rails tailwindcss:build          # Build Tailwind CSS for production
rails tailwindcss:watch          # Watch for CSS changes and rebuild
```

### Background Jobs

```bash
bin/jobs                         # Start Solid Queue job processor
```

### Deployment

```bash
bin/kamal deploy                 # Deploy with Kamal
bin/kamal setup                  # Initial deployment setup
```

## Code Architecture

### Data Model Structure

The application uses a normalized database schema with the following relationships:

- **User**: Devise authentication with Discogs API integration (`discogs_token`, `discogs_username`)
- **Artist**: Core artist data with Discogs synchronization (`name`, `discogs_id`, `profile`)
- **Album**: Vinyl records with comprehensive metadata (`title`, `year`, `format`, `genre[]`, Active Storage cover art)
- **Track**: Individual tracks per album (`title`, `position`, `duration`)
- **AlbumArtist**: Join table for many-to-many Artist-Album relationships

Key relationships:

```text
Artist ←─── AlbumArtist ───→ Album ───→ Track (1:many)
  │ (many:many via join)      │
  │                           └─ has_one_attached :cover
  │
User (separate, manages Discogs integration)
```

### Controllers & Routes

- **AlbumsController**: CRUD operations with Discogs import/sync features (`search_discogs`, `import_from_discogs`, `sync_collection`)
- **DiscogsController**: OAuth authentication with Discogs API
- **ApplicationController**: Base controller with Devise integration

### Services

- **DiscogsService**: API wrapper for importing artist, album, and track data from Discogs

### Key Gems & Dependencies

- **Authentication**: Devise (~> 4.9)
- **API Integration**: discogs-wrapper (~> 2.5), faraday (~> 2.7)
- **Frontend**: TailwindCSS, Stimulus, Turbo
- **Background Jobs**: Solid Queue (Rails 8.0 default)
- **Pagination**: Pagy (~> 9.3)
- **Development**: RuboCop Rails Omakase, Brakeman, Web Console

### Frontend Architecture

- **CSS Framework**: TailwindCSS with Rails asset pipeline
- **JavaScript**: Stimulus controllers with importmap-rails
- **Asset Management**: Propshaft (Rails 8.0 default)
- **Image Storage**: Active Storage for album cover art

### Discogs Integration Features

- OAuth authentication with 30-day token expiry
- Full collection synchronization
- Individual album import from Discogs database
- Automatic artist and track creation
- Cover art downloading and storage

### Environment Configuration

- **Development**: Uses dotenv-rails for environment variables
- **Production**: Supports Docker deployment with Kamal
- **Database**: PostgreSQL with Solid Cache/Queue/Cable for modern Rails features

## Development Guidelines

### Database Changes

Always create migrations for schema changes and run `bin/rails db:migrate` after pulling changes.

### Code Style

The project uses RuboCop Rails Omakase configuration. Run `bin/rubocop --auto-correct` before committing.

### Security

Run `bin/brakeman` regularly to check for security vulnerabilities, especially when modifying authentication or API integrations.

### Test Requirements

System tests require Selenium WebDriver. Ensure Capybara and Selenium gems are available when running `bin/rails test:system`.

### Discogs API Guidelines

All Discogs API calls should go through the DiscogsService. User authentication with Discogs requires valid `discogs_token` and `discogs_username`.

### Background Job Processing

Use Solid Queue for background processing. Start job processor with `bin/jobs` during development.
