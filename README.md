# Fuller Focus Backend - Setup Guide

This project consists of a Ruby on Rails (API) backend. Follow the steps below to set up your local development environment.

## Demo
https://drive.google.com/file/d/1aWwSwAVXjrsvUEW68D7aydEr1UenoC2d/view?usp=drive_link

## 📋 Prerequisites
Ensure you have the following installed:
* [Docker Desktop](https://www.docker.com/products/docker-desktop/)
* [asdf version manager](https://asdf-vm.com/guide/getting-started.html)

---

## 🗄️ 1. Database Setup (MySQL via Docker)

We use Docker to ensure a consistent database environment without needing to install MySQL directly on your OS.

1.  **Install Docker:** Download and install Docker Desktop from the link above. Ensure the Docker engine is running.
2.  **Build the Container:** From the project root, run:
    ```bash
    docker compose build
    ```
3.  **Start the Database:**
    ```bash
    docker compose up -d
    ```
    *Note: This will run the MySQL container in the background.*

---

## 💎 2. Backend Setup (Ruby on Rails 8)

### Ruby Installation (via asdf)
We use Ruby 3.3.1. To install it using the `asdf` version manager:

1.  **Add Ruby Plugin:**
    ```bash
    asdf plugin add ruby
    ```
2.  **Install Version 3.3.1:**
    ```bash
    asdf install ruby 3.3.1
    ```
3.  **Verify Version:**
    ```bash
    ruby -v
    # Should return ruby 3.3.1
    ```

### Rails & Dependencies
1.  **Install Rails:**
    ```bash
    gem install rails
    ```
2.  **Verify Rails:**
    ```bash
    rails --version
    # Should return 8.x.x
    ```
3.  **Install Gems:**
    ```bash
    bundle install
    ```
    If you ever encounter this error:
    ```bash
    mysql client is missing. You may need to 'sudo apt-get install libmariadb-dev', 'sudo apt-get install
    libmysqlclient-dev' or 'sudo yum install mysql-devel', and try again.
    -----
    *** extconf.rb failed ***
    Could not create Makefile due to some reason, probably lack of necessary
    libraries and/or headers.  Check the mkmf.log file for more details.  You may
    need configuration options.
    ```

    Run `sudo apt-get install libmysqlclient-dev`

### Database Migration & Initialization
Ensure your Docker MySQL container is running, then execute the setup script:
```bash
./bin/script.sh
```

### API Key
To generate the API Key to be used for `POST /dataset`, open the rails console via `bin/rails c` and enter `ApiKey.generate!(name: "Test")`. This should return the API Key. Use this API Key as the value of the `X-API-Key` header of the POST request.
