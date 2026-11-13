-- List the agent in CoWork. One-time, per environment, run by an admin (the
-- deployer role cannot change the account-level CoWork object). Run it after the
-- first successful pipeline run, which creates the agent.
--   uv run ops sql TEST bootstrap/cowork.sql -c <connection>
--   uv run ops sql PROD bootstrap/cowork.sql -c <connection>
--
-- Only roles with USAGE on the agent (the generated audience roles) will see it.
-- Fails if the agent is already listed, so run it once.

ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
  ADD AGENT AGENTS_<% env %>.CORE.<% agent %>;
