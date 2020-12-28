CREATE OR REPLACE FUNCTION front(place_id integer) RETURNS geometry AS $$
DECLARE
	place			geometry;
	region			geometry;
	region_test 	geometry;
	region_size		integer DEFAULT 20;
	prev_vertex		geometry;
	vertex 			geometry;
	street_front	geometry;
	front 			geometry;
BEGIN
	place = (SELECT geom FROM cg_landmarks WHERE id=place_id);

	IF ST_AsText(place) LIKE 'POINT%' THEN
	
		place = geometry(ST_Buffer(geography(place), 30));
		front = (SELECT ST_Union(ST_Intersection(geom, place)) FROM cg_estradas WHERE ST_Intersects(geom, place));
		
		front = nearest_from_double_streets((SELECT geom FROM cg_pois WHERE name=place_name LIMIT 1),
											ST_Buffer(front::geography, 3)::geometry);
		RETURN front;
	END IF;

	FOR vertex IN SELECT (ST_DumpPoints(place)).geom LOOP
		IF prev_vertex IS NOT NULL THEN
			-- CREATING A REGION FOR EACH SIDE OF THE GEOMETRY
			region = ST_Buffer(geography(ST_MakeLine(prev_vertex, vertex)), region_size , 'side=left');
			
			street_front = (SELECT ST_Union(ST_Buffer(geography(geom), 3)::geometry)
						  FROM cg_estradas WHERE ST_Intersects(region, geom));
						  
			-- CREATING A SMALLER REGION TO TEST WHETHER THERE'S A LANDMARK BETWEEN THE PLACE AND THE STREET 
			region_test = ST_Buffer(geography(ST_MakeLine(prev_vertex, vertex)),
								   ST_Distance(ST_MakeLine(prev_vertex, vertex)::geography, street_front),
								   'side=left');
		
			IF (SELECT COUNT(*) FROM cg_pois 
						  WHERE ST_Intersects(ST_Difference(region_test, ST_Buffer(place::geography, 0.1)::geometry), geom)
							AND (code IN (2961, 5250, 5260, 5262) OR
							(code::varchar NOT LIKE '2602' AND
							 code::varchar NOT LIKE '29%' AND
							 code::varchar NOT LIKE '41%' AND
							 code::varchar NOT LIKE '52%'))) = 0 THEN
				IF front IS NULL THEN
					front = ST_Intersection(street_front, region);
				ELSIF street_front IS NOT NULL THEN			
					front = ST_Union(front, ST_Intersection(street_front, region) );
				END IF;
			END IF;		
		END IF;

		prev_vertex = vertex;
	END LOOP;

	RETURN front;--ST_ConcaveHull(front, 0.99);
END;
$$ LANGUAGE plpgsql;

SELECT front(1923);
