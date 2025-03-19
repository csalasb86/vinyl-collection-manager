# Vinyl Collection Manager

**Vinyl Collection Manager** is a web application designed to help users catalog and manage their vinyl record collections efficiently.

## Features

- **Collection Management**: Add, edit, and delete records in your collection.
- **Search Functionality**: Quickly find records by artist, album title, or genre.
- **User Authentication**: Secure login system to protect your collection data.
- **Responsive Design**: Accessible on various devices, including desktops, tablets, and smartphones.
- **Discogs integration**: Collection sync with [discogs.com](https://www.discogs.com/).

## Getting Started

### Prerequisites

- **Ruby**: Version 3.2 or higher.
- **Rails**: Version 8.0 or higher.
- **PostgreSQL**: Ensure you have PostgreSQL installed and running.

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

3. **Set Up the Database**:

   ```bash
   bin/rails db:create
   bin/rails db:migrate
   bin/rails db:seed
   ```

4. **Start the Server**:

   ```bash
   bin/rails server
   ```

   Access the application at `http://localhost:3000`.

## Running Tests

To run the test suite:

```bash
bin/rails test
```

## Deployment

For deployment instructions, please refer to the [official Rails deployment guide](https://guides.rubyonrails.org/deployment.html).

## Contributing

Contributions are welcome! Please fork the repository and create a pull request with your changes.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Thanks to the open-source community for various gems and tools utilized in this project.

For more information, visit the [GitHub repository](https://github.com/csalasb86/vinyl-collection-manager).
