-- 2013-11-30
DELETE FROM sivers.comments WHERE id = 41964;
ALTER TABLE sivers.comments ADD FOREIGN KEY (person_id) REFERENCES peeps.people(id);

