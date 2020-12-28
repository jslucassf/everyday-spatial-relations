CREATE OR REPLACE FUNCTION left_of(place_id integer, frame_of_reference text DEFAULT 'egocentric') RETURNS geometry AS $$
DECLARE
	place			geometry;
	front			geometry;
	front_portion	geometry;
	next_to			geometry;
	central_point	geometry;
	side			geometry;
	side_name		text;
	left_buffer		geometry;
	left_of			geometry;
BEGIN
	IF frame_of_reference='egocentric' THEN
		side_name = 'right';
	ELSIF frame_of_reference='allocentric' THEN
		side_name = 'left';
	END IF;	

	place = (SELECT geom FROM cg_landmarks WHERE id=place_id);
	front = front(place_id);
	next_to = next_to(place_id);
	
	--FOR front_portion IN (SELECT (ST_Dump(front)).geom) LOOP
	FOR front_portion IN (SELECT ST_Intersection(geom, front) FROM cg_estradas WHERE ST_Intersects(geom, front)) LOOP
		IF ST_Area(ST_Buffer(front_portion::geography, 3)) > 50 THEN
			IF ST_AsText(place) LIKE 'POINT%' THEN
				central_point = ST_LineInterpolatePoint(ST_LineMerge(front_portion),
														ST_LineLocatePoint(ST_LineMerge(front_portion), place));

				left_buffer = ST_Buffer(ST_MakeLine(place, central_point)::geography, 
										ST_Distance(ST_Centroid(place)::geography, central_point) * 2,
										('side=' || side_name))::geometry;
			ELSE
				front_portion = ST_Buffer(front_portion::geography, 3, 'endcap=square')::geometry;
				left_buffer = ST_Buffer(ST_MakeLine(ST_Centroid(place), ST_Centroid(front_portion))::geography,
								ST_Distance(ST_Centroid(place)::geography, ST_Centroid(front_portion)::geography) * 2,
								('side=' || side_name))::geometry;
			END IF;

			FOR side IN (SELECT (ST_Dump(next_to)).geom) LOOP
				IF ST_Intersects(side, left_buffer) AND
					ST_Intersects(side, ST_Buffer(front_portion::geography, 5)) THEN
					IF left_of IS NULL THEN
						left_of = side;
					ELSE
						left_of = ST_Union(left_of, side);
					END IF;
				END IF;
			END LOOP;
		END IF;
	END LOOP;

	RETURN left_of;
END $$ LANGUAGE plpgsql;
SELECT left_of(1923);

