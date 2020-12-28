CREATE OR REPLACE FUNCTION near(place_id integer, distance int DEFAULT 300) RETURNS geometry AS $$
DECLARE
BEGIN
	RETURN (SELECT geometry(ST_Buffer(geography(geom), distance))
	FROM cg_landmarks
	WHERE id=place_id);
END $$ LANGUAGE plpgsql;
SELECT near(1923);