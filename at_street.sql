CREATE OR REPLACE FUNCTION at_street(place_id integer) RETURNS geometry AS $$
DECLARE
	front 			geometry;
	street			record;
	street_par		geometry;
	streets			geometry;
	int_area		decimal;
BEGIN
	-- IF POI HAS ADDRESS ...

	front = front(place_id);
	   
	FOR street in (SELECT * FROM cg_estradas WHERE ST_Intersects(geom, front)) LOOP
		RAISE NOTICE '%', ST_Area(front::geography);
		RAISE NOTICE '% - %', street.name, ST_Area(ST_Intersection(front, St_Buffer(street.geom::geography, 2)));
		
		int_area = (ST_Area(ST_Intersection(front, St_Buffer(street.geom::geography, 2))));
		IF int_area > 30  AND int_area > ST_Area(front::geography) * .01 THEN
			street_par = (SELECT ST_Union(ST_Buffer(geom::geography, 2)::geometry) 
						   FROM cg_estradas WHERE name=street.name);
			IF street_par IS NOT NULL THEN
				IF streets IS NULL THEN
					streets = street_par;
				ELSE
					streets = ST_Union(streets, street_par);
				END IF;
			END IF;
		END IF;
	END LOOP;
	
	RETURN streets;
END $$ LANGUAGE plpgsql;
SELECT at_street(1923);