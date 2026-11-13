-- Make sure the agent exists, then let the audience role use it. Runs in every
-- deploy, as the deployer role, after DCM has created AGENTS_<ENV> and the
-- audience role. Safe to re-run: it only creates and pins the agent the first time.
--   uv run ops sql TEST ops/ensure_agent.sql -D audience_role=MY_AGENT_TEST_USER
--
-- Why not in DCM: DCM has no DEFINE AGENT, and a GRANT on an agent that does not
-- exist yet fails DCM's compile, which would stop AGENTS_<ENV> ever being created.

EXECUTE IMMEDIATE $$
DECLARE
  n INTEGER;
  bootstrap_version STRING;
BEGIN
  SHOW AGENTS LIKE '<% agent %>' IN SCHEMA AGENTS_<% env %>.CORE;
  SELECT COUNT(*) INTO :n FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

  IF (n = 0) THEN
    CREATE AGENT AGENTS_<% env %>.CORE.<% agent %>
      COMMENT = '<% comment %>'
      PROFILE = '{"display_name": "<% display %>"}'
      FROM SPECIFICATION '{"instructions": {"response": "Not released yet."}}';

    -- CREATE leaves a LIVE version, and ADD VERSION is refused while one exists.
    ALTER AGENT AGENTS_<% env %>.CORE.<% agent %> COMMIT COMMENT = 'bootstrap';

    -- Pin the default. Unpinned, it follows every new version, so a release
    -- would go live before promote.
    SHOW VERSIONS IN AGENT AGENTS_<% env %>.CORE.<% agent %>;
    SELECT MAX_BY("name", "created_on") INTO :bootstrap_version
      FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())) WHERE "comment" = 'bootstrap';
    EXECUTE IMMEDIATE 'ALTER AGENT AGENTS_<% env %>.CORE.<% agent %> SET DEFAULT_VERSION = ''' || bootstrap_version || '''';
  END IF;
  RETURN 'agent ready';
END;
$$;

GRANT USAGE ON AGENT AGENTS_<% env %>.CORE.<% agent %> TO ROLE <% audience_role %>;
