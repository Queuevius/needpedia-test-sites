# Needpedia multi-copy test server

This folder turns one Linux machine into a small test server that can
run several independent copies of Needpedia at the same time. Each copy
has its own web address, its own database, and its own Redis cache.

A copy goes to sleep when nobody is using it, and wakes up by itself
when somebody visits its address.

## The three pieces

1. **The front door (Traefik).** Reads the web address a visitor typed
   and sends them to the right copy. You run one front door for the
   whole machine.
2. **The doorman (Sablier).** Watches each copy. When a copy is asleep
   and a visitor arrives, it starts the copy, shows a "starting…" page,
   and stops the copy again after a set time with no visitors.
3. **The copy (Needpedia).** One developer's version of the site, with
   its own database and Redis. Many copies run side by side without
   touching each other.

## What you must supply

- A Linux machine with Docker Engine and the Docker Compose plugin.
- A real DNS name for each copy, pointing at this machine. For example
  `john.needpedia.org`.
- HTTPS certificates if you want `https://`. This package includes the
  plain-HTTP front door only. TLS is configured on your side; see the
  note at the bottom.

The package needs **no passwords, keys, or service accounts**.

## First-time setup

1. Put this whole project on the machine (for example with `git clone`).
2. Build the Needpedia image once. This takes a while:

   docker build -t needpedia-m6:latest .

3. Start the front door and the doorman:

   cd m6/frontdoor
   docker compose up -d

4. Check it is running:

   docker compose ps

   You should see two containers: `frontdoor-front-1` and
   `frontdoor-sablier-1`, both Up.

## Add a developer copy

1. Make a settings file from the example. Do not edit the example:

   cp m6/copy.env.example m6/john.env

2. Edit `m6/john.env`. The three things you normally change are:

   - COPY_NAME=john
   - DOMAIN=john.needpedia.org
   - PG_DB=needpedia_john

   Set DOMAIN_PROTOCOL=https if you have set up TLS for that name.

3. Start the copy:

   ./m6/start-copy.sh john john.needpedia.org needpedia_john

   (Or run it by hand:

   COPY_NAME=john DOMAIN=john.needpedia.org DOMAIN_PROTOCOL=http PG_DB=needpedia_john WEB_PORT=0 \
     docker compose -p np-john -f m6/needpedia-copy.yml up -d

   )

4. Wait about two minutes, then check it is healthy:

   docker compose -p np-john -f m6/needpedia-copy.yml ps

   The `web` container should say `(healthy)`.

5. Load the sample content so the copy is not empty:

   docker compose -p np-john -f m6/needpedia-copy.yml exec -e DISABLE_SPRING=1 web bundle exec rails runner m6/demo_seeds.rb

   This creates three login-ready accounts:

   - demo.founder@example.test  (admin)
   - demo.dev@example.test
   - demo.builder@example.test

   The password for all three is `DemoPass!2026`. Change these for
   anything that will face the public internet.

6. Visit `http://john.needpedia.org`. The first visit may show a
   "starting…" page for up to two minutes while the copy wakes up.

## Add another copy

Repeat the steps above with a different COPY_NAME, DOMAIN, and PG_DB.
Nothing else changes.

## Stop or remove a copy

- Stop it (keeps data):

  docker compose -p np-john -f m6/needpedia-copy.yml down

- Remove it and its data permanently (careful):

  docker compose -p np-john -f m6/needpedia-copy.yml down -v

## Notes

- **Databases are created automatically** on first boot. The web
  container waits for the database to be ready, then creates and
  migrates it before starting the site. No manual migration step is
  needed.

- **HTTPS / certificates.** This package ships the plain-HTTP front
  door so it can be tested anywhere. On a real server, add a TLS
  certificate resolver and a `websecure` entry point to the Traefik
  configuration in `m6/frontdoor/docker-compose.yml`, then set
  `DOMAIN_PROTOCOL=https` for each copy.

- **Passwords.** The only passwords in this package are local
  development defaults for Postgres and the demo logins. Never put a
  real credential in any file in this folder.
