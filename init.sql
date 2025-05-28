-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_tasks_external_id ON tasks(external_id);
CREATE INDEX IF NOT EXISTS idx_tasks_source ON tasks(source);
CREATE INDEX IF NOT EXISTS idx_tasks_project_id ON tasks(project_id);
CREATE INDEX IF NOT EXISTS idx_task_events_task_id ON task_events(task_id);
CREATE INDEX IF NOT EXISTS idx_user_patterns_type ON user_patterns(pattern_type);

-- Insert default user patterns
INSERT INTO user_patterns (pattern_type, pattern_data, confidence_score) VALUES
('default_work_hours', '{"start": 9, "end": 17}', 0.8),
('default_break_duration', '{"minutes": 15}', 0.7)
ON CONFLICT DO NOTHING;
