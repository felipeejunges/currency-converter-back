# syntax=docker/dockerfile:1
FROM ruby:3.2.1
RUN apt-get update -yq \
    && apt-get -yq install curl gnupg ca-certificates \
    && curl -L https://deb.nodesource.com/setup_16.x | bash
RUN apt-get update -qq && apt-get install -y \
    libffi-dev \
    libc-dev \ 
    libxml2-dev \
    libxslt-dev \
    libgcrypt-dev \
    nodejs \
    openssl \
    python3 \
    tzdata
WORKDIR /currency-converter-back
COPY Gemfile /currency-converter-back/Gemfile
COPY Gemfile.lock /currency-converter-back/Gemfile.lock
RUN bundle install

# Add a script to be executed every time the container starts.
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3000

# Configure the main process to run when running the image
CMD ["rails", "server", "-b", "0.0.0.0"]