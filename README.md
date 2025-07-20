# Vinyl Collection Manager

[![CI](https://github.com/csalasb86/vinyl-collection-manager/workflows/CI/badge.svg)](https://github.com/csalasb86/vinyl-collection-manager/actions)
[![Ruby](https://img.shields.io/badge/ruby-3.3.5-red.svg)](https://ruby-lang.org)
[![Rails](https://img.shields.io/badge/rails-8.0.2-red.svg)](https://rubyonrails.org)
[![Test Coverage](https://img.shields.io/badge/coverage-86.84%25-brightgreen.svg)](https://github.com/csalasb86/vinyl-collection-manager)
[![Code Style](https://img.shields.io/badge/code_style-rubocop_rails_omakase-blue.svg)](https://github.com/rails/rubocop-rails-omakase)
[![Security](https://img.shields.io/badge/security-brakeman-green.svg)](https://brakemanscanner.org)

**Vinyl Collection Manager** is a modern Rails 8.0 application designed to help users catalog and manage their vinyl record collections with seamless Discogs API integration. Built with PostgreSQL, TailwindCSS, Stimulus, and modern Rails features including Solid Queue for background jobs.

## Features

- **🎵 Collection Management**: Complete CRUD operations for vinyl records with cover art support via Active Storage
- **🔍 Advanced Search**: Multi-criteria search by artist, album title, genre, and format with pagination
- **🔐 User Authentication**: Secure Devise-based authentication with session management
- **📱 Responsive Design**: Modern TailwindCSS interface optimized for all devices
- **🎧 Discogs Integration**:
  - OAuth authentication with Discogs API
  - Full collection synchronization
  - Individual album import from Discogs database
  - Automatic artist and track metadata import
- **⚡ Modern Rails 8.0 Features**:
  - Solid Queue for background job processing
  - Solid Cache for efficient caching
  - Solid Cable for real-time features
  - Propshaft asset pipeline
- **🎨 Frontend Technologies**: Stimulus controllers, Turbo for SPA-like experience, importmap-rails
- **📊 Data Model**: Normalized schema with many-to-many artist-album relationships and comprehensive track listings

## Getting Started

### Prerequisites

- **Ruby**: 3.3.5 (see `.ruby-version`)
- **Rails**: 8.0.2 or higher
- **PostgreSQL**: 12+ recommended
- **Node.js**: For asset compilation (if needed)

### Installation

1. **Clone the Repository**:

   ```bash
   git clone https://github.com/csalasb86/vinyl-collection-manager.git
   cd vinyl-collection-manager
   ```

2. **Install Dependencies**:

   ```bash
   bundle install
   ```

3. **Set Up Environment Variables** (optional):

   ```bash
   cp .env.example .env
   # Edit .env with your Discogs API credentials (optional)
   ```

4. **Set Up the Database**:

   ```bash
   bin/rails db:setup    # Creates, migrates, and seeds the database
   ```

5. **Start the Development Environment**:

   ```bash
   bin/dev               # Starts Rails server + TailwindCSS watcher
   ```

   Access the application at `http://localhost:3000`.

### Background Jobs

To process background jobs (for Discogs synchronization):

```bash
bin/jobs              # Start Solid Queue processor
```

## Development & Testing

### Running Tests

The project uses **SimpleCov** for test coverage analysis with an **80% minimum threshold**. Current coverage: **86.84%**.

```bash
# Run all tests with coverage report
bin/rails test

# Run specific test types
bin/rails test:system        # System tests (Capybara + Selenium)
bin/rails test test/models/  # Model tests only
bin/rails test test/controllers/  # Controller tests only
```

Coverage reports are generated in `/coverage/index.html` after running tests.

### Code Quality & Security

**MANDATORY before every commit:**

```bash
# 1. Code style compliance (Rails Omakase)
bin/rubocop --autocorrect

# 2. Security vulnerability scanning
bin/brakeman

# 3. Run full test suite
bin/rails test
```

### Asset Development

```bash
# Build TailwindCSS for production
rails tailwindcss:build

# Watch for CSS changes during development
rails tailwindcss:watch

# Or use bin/dev which includes CSS watching
bin/dev
```

### CI/CD Pipeline

The project uses GitHub Actions for continuous integration:

- **Security scanning**: Brakeman (Ruby) + importmap audit (JS)
- **Code style**: RuboCop Rails Omakase
- **Testing**: Full test suite with PostgreSQL
- **System tests**: Chrome headless with screenshot capture on failure

## Deployment

This application is configured for modern deployment with **Kamal**:

```bash
# Initial deployment setup
bin/kamal setup

# Deploy application
bin/kamal deploy

# Deploy with environment variables
bin/kamal deploy --env-file .env.production
```

The application includes Docker configuration and can be deployed to any container-compatible platform.

## Technology Stack

### Backend

- **Framework**: Ruby on Rails 8.0.2
- **Ruby Version**: 3.3.5
- **Database**: PostgreSQL with Active Record
- **Authentication**: Devise (~> 4.9)
- **Background Jobs**: Solid Queue
- **Caching**: Solid Cache
- **Real-time**: Solid Cable

### Frontend

- **CSS Framework**: TailwindCSS
- **JavaScript**: Stimulus + Turbo (Hotwire)
- **Module System**: importmap-rails
- **Asset Pipeline**: Propshaft
- **File Storage**: Active Storage

### APIs & Integrations

- **Discogs API**: discogs-wrapper (~> 2.5)
- **HTTP Client**: Faraday (~> 2.13)
- **Pagination**: Pagy (~> 9.3)

### Development & Testing

- **Testing**: Minitest with SimpleCov (86.84% coverage)
- **System Testing**: Capybara + Selenium WebDriver
- **Code Style**: RuboCop Rails Omakase
- **Security**: Brakeman static analysis
- **CI/CD**: GitHub Actions

## Contributing

Contributions are welcome! Please follow these guidelines:

1. **Fork the repository** and create a feature branch

2. **Follow code quality standards**:
   - Run `bin/rubocop --autocorrect` for style compliance
   - Run `bin/brakeman` for security scanning
   - Ensure tests pass with `bin/rails test`
   - Maintain or improve test coverage (currently 86.84%)

3. **Write tests** for new features and bug fixes

4. **Update documentation** as needed

5. **Create a pull request** with a clear description of changes

### Development Setup

```bash
git clone https://github.com/your-fork/vinyl-collection-manager.git
cd vinyl-collection-manager
bundle install
bin/rails db:setup
bin/dev
```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Thanks to the open-source community for various gems and tools utilized in this project.

For more information, visit the [GitHub repository](https://github.com/csalasb86/vinyl-collection-manager).
