CREATE OR REPLACE FUNCTION next_to(place_id integer) RETURNS geometry AS $$
DECLARE
	place			geometry;
	street			geometry;
	front			geometry;
	front_portion	geometry;
	central_point	geometry;
	next_to			geometry;
	next_final		geometry;
	street_r		geometry;
BEGIN
	place = (SELECT geom FROM cg_landmarks WHERE id=place_id LIMIT 1);

	front = front(place_id);
		
	street = at_street(place_id);
	
	next_to = (SELECT ST_Buffer(place::geography, 50, 'endcap=square join=mitre')::geometry);
	
	next_to = ST_Intersection(next_to, street);
	
	FOR street_r IN (SELECT ST_Intersection(ST_Buffer(geom::geography, 3)::geometry, next_to) 
					 FROM cg_estradas WHERE ST_Intersects(geom, next_to)) LOOP
		IF NOT ST_Crosses(ST_MakeLine(ST_Centroid(place), ST_Centroid(street_r)), ST_Difference(next_to, street_r)) THEN
			IF next_final IS NULL THEN
				next_final = street_r;
			ELSE
				next_final = ST_Union(next_final, street_r);
			END IF;
		END IF;
	END LOOP;
	
	IF ST_AsText(place) LIKE 'POINT%' THEN
		FOR front_portion IN (SELECT ST_Intersection(geom, next_final)
							  from cg_estradas WHERE ST_Intersects(geom, next_final)) LOOP
			IF ST_Area(ST_Buffer(front_portion::geography, 3)) > 50 THEN
				central_point = ST_LineInterpolatePoint(ST_LineMerge(front_portion),
														ST_LineLocatePoint(ST_LineMerge(front_portion), place));

				next_final = ST_Difference(next_final,
											  ST_Buffer(ST_MakeLine(place, central_point)::geography,
														5, 'endcap=square')::geometry);
			END IF;
		END LOOP;
		RETURN next_final;
	
	END IF;

	next_final = ST_Difference(next_final, ST_Buffer(front::geography, 1, 'endcap=square join=mitre')::geometry);

	RETURN next_final;
END $$ LANGUAGE plpgsql;
SELECT next_to(1923);