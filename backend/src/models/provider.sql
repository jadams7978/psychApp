-- Example SQL (for future reporting/joins)
CREATE TABLE IF NOT EXISTS providers_index (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  city TEXT,
  state TEXT,
  specialties TEXT[]  -- e.g., {'CBT','Anxiety'}
);

-- Helpful indexes
CREATE INDEX IF NOT EXISTS providers_name_trgm ON providers_index USING gin (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS providers_specialties_gin ON providers_index USING gin (specialties);