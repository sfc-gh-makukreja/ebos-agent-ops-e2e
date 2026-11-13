-- Create the agent once per environment, after its first DCM deploy has created
-- AGENTS_<ENV>.CORE. From then on the pipeline only adds versions.
--   uv run ops sql DEV  bootstrap/agent.sql -c <connection>
--   uv run ops sql TEST bootstrap/agent.sql -c <connection>
--   uv run ops sql PROD bootstrap/agent.sql -c <connection>
--
-- Run as ACCOUNTADMIN. It does not switch role, so it also works in sessions that
-- cannot USE ROLE (for example a programmatic access token). ACCOUNTADMIN reaches
-- AGENTS_<ENV> through the deployer roles, which bootstrap/setup.sql grants to
-- SYSADMIN. Ownership then moves to the deployer, which is what the pipeline needs
-- to ADD VERSION.

CREATE AGENT IF NOT EXISTS AGENTS_<% env %>.CORE.<% agent %>
  COMMENT = '<% comment %>'
  PROFILE = '{"display_name": "<% display %>"}'
  FROM SPECIFICATION $$
  instructions:
    response: "Not released yet."
  $$;

-- CREATE leaves a LIVE version, and ADD VERSION is refused while one exists.
ALTER AGENT AGENTS_<% env %>.CORE.<% agent %> COMMIT COMMENT = 'bootstrap';

-- Pin the default. Unpinned, it follows every new version, so a release would go
-- live before promote. VERSION$2 is the first committed version after the bootstrap
-- version; check with SHOW VERSIONS IN AGENT if CREATE was run more than once.
ALTER AGENT AGENTS_<% env %>.CORE.<% agent %> SET DEFAULT_VERSION = 'VERSION$2';

-- List it in CoWork. Only roles with USAGE on it (generated access.sql) see it.
-- Fails if the agent is already listed, so this runs once, here.
ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
  ADD AGENT AGENTS_<% env %>.CORE.<% agent %>;

-- The pipeline's deployer role must own the agent to add versions to it.
GRANT OWNERSHIP ON AGENT AGENTS_<% env %>.CORE.<% agent %>
  TO ROLE AGENTOPS_DEPLOYER_<% env %> COPY CURRENT GRANTS;
