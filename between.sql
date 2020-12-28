CREATE OR REPLACE FUNCTION in_between(place1_id integer, place2_id integer) RETURNS geometry AS $$
DECLARE
	point1		geometry;
	point2		geometry;
	distance	int;
	percentage	float;
	line_bet	geometry;
BEGIN
	point1 = (SELECT ST_PointOnSurface(geom) FROM cg_landmarks WHERE id=place1_id);
	point2 = (SELECT ST_PointOnSurface(geom) FROM cg_landmarks WHERE id=place2_id);
	distance = ST_DistanceSphere(point1, point2);
	line_bet = ST_MakeLine(point1, point2);
	
	percentage = (100*SQRT(distance*120))/ST_Length(geography(line_bet));
	point1 = ST_LineInterpolatePoint(line_bet, percentage/100);
	point2 = ST_LineInterpolatePoint(line_bet, (100 - percentage)/100);
	
	return ST_Buffer(geography(ST_MakeLine(point1, point2)), SQRT(distance*120));
END;
$$ LANGUAGE plpgsql;
					  
SELECT in_between(1923, 3309);