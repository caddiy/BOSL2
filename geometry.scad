//////////////////////////////////////////////////////////////////////
// LibFile: geometry.scad
//   Geometry helpers.
//   To use, add the following lines to the beginning of your file:
//   ```
//   use <BOSL2/std.scad>
//   ```
//////////////////////////////////////////////////////////////////////


// CommonCode:
//   include <BOSL2/rounding.scad>


// Section: Lines and Triangles

// Function: point_on_segment2d()
// Usage:
//   point_on_segment2d(point, edge);
// Description:
//   Determine if the point is on the line segment between two points.
//   Returns true if yes, and false if not.
// Arguments:
//   point = The point to test.
//   edge = Array of two points forming the line segment to test against.
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
function point_on_segment2d(point, edge, eps=EPSILON) =
	approx(point,edge[0],eps=eps) || approx(point,edge[1],eps=eps) ||  // The point is an endpoint
	sign(edge[0].x-point.x)==sign(point.x-edge[1].x)  // point is in between the
		&& sign(edge[0].y-point.y)==sign(point.y-edge[1].y)  // edge endpoints
		&& approx(point_left_of_segment2d(point, edge),0,eps=eps);  // and on the line defined by edge


// Function: point_left_of_segment2d()
// Usage:
//   point_left_of_segment2d(point, edge);
// Description:
//   Return >0 if point is left of the line defined by edge.
//   Return =0 if point is on the line.
//   Return <0 if point is right of the line.
// Arguments:
//   point = The point to check position of.
//   edge = Array of two points forming the line segment to test against.
function point_left_of_segment2d(point, edge) =
	(edge[1].x-edge[0].x) * (point.y-edge[0].y) - (point.x-edge[0].x) * (edge[1].y-edge[0].y);


// Internal non-exposed function.
function _point_above_below_segment(point, edge) =
	edge[0].y <= point.y? (
		(edge[1].y > point.y && point_left_of_segment2d(point, edge) > 0)? 1 : 0
	) : (
		(edge[1].y <= point.y && point_left_of_segment2d(point, edge) < 0)? -1 : 0
	);


// Function: collinear()
// Usage:
//   collinear(a, b, c, [eps]);
// Description:
//   Returns true if three points are co-linear.
// Arguments:
//   a = First point.
//   b = Second point.
//   c = Third point.
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
function collinear(a, b, c, eps=EPSILON) =
	distance_from_line([a,b], c) < eps;


// Function: collinear_indexed()
// Usage:
//   collinear_indexed(points, a, b, c, [eps]);
// Description:
//   Returns true if three points are co-linear.
// Arguments:
//   points = A list of points.
//   a = Index in `points` of first point.
//   b = Index in `points` of second point.
//   c = Index in `points` of third point.
//   eps = Acceptable max angle variance.  Default: EPSILON (1e-9) degrees.
function collinear_indexed(points, a, b, c, eps=EPSILON) =
	let(
		p1=points[a],
		p2=points[b],
		p3=points[c]
	) collinear(p1, p2, p3, eps);


// Function: distance_from_line()
// Usage:
//   distance_from_line(line, pt);
// Description:
//   Finds the perpendicular distance of a point `pt` from the line `line`.
// Arguments:
//   line = A list of two points, defining a line that both are on.
//   pt = A point to find the distance of from the line.
// Example:
//   distance_from_line([[-10,0], [10,0]], [3,8]);  // Returns: 8
function distance_from_line(line, pt) =
	let(a=line[0], n=normalize(line[1]-a), d=a-pt)
	norm(d - ((d * n) * n));


// Function: line_normal()
// Usage:
//   line_normal([P1,P2])
//   line_normal(p1,p2)
// Description:
//   Returns the 2D normal vector to the given 2D line. This is otherwise known as the perpendicular vector counter-clockwise to the given ray.
// Arguments:
//   p1 = First point on 2D line.
//   p2 = Second point on 2D line.
// Example(2D):
//   p1 = [10,10];
//   p2 = [50,30];
//   n = line_normal(p1,p2);
//   stroke([p1,p2], endcap2="arrow2");
//   color("green") stroke([p1,p1+10*n], endcap2="arrow2");
//   color("blue") place_copies([p1,p2]) circle(d=2, $fn=12);
function line_normal(p1,p2) =
	is_undef(p2)? line_normal(p1[0],p1[1]) :
	normalize([p1.y-p2.y,p2.x-p1.x]);


// 2D Line intersection from two segments.
// This function returns [p,t,u] where p is the intersection point of
// the lines defined by the two segments, t is the proportional distance
// of the intersection point along s1, and u is the proportional distance
// of the intersection point along s2.  The proportional values run over
// the range of 0 to 1 for each segment, so if it is in this range, then
// the intersection lies on the segment.  Otherwise it lies somewhere on
// the extension of the segment.
function _general_line_intersection(s1,s2,eps=EPSILON) =
	let(
		denominator = det2([s1[0],s2[0]]-[s1[1],s2[1]])
	) approx(denominator,0,eps=eps)? [undef,undef,undef] : let(
		t = det2([s1[0],s2[0]]-s2) / denominator,
		u = det2([s1[0],s1[0]]-[s2[0],s1[1]]) / denominator
	) [s1[0]+t*(s1[1]-s1[0]), t, u];


// Function: line_intersection()
// Usage:
//   line_intersection(l1, l2);
// Description:
//   Returns the 2D intersection point of two unbounded 2D lines.
//   Returns `undef` if the lines are parallel.
// Arguments:
//   l1 = First 2D line, given as a list of two 2D points on the line.
//   l2 = Second 2D line, given as a list of two 2D points on the line.
function line_intersection(l1,l2,eps=EPSILON) =
	let(isect = _general_line_intersection(l1,l2,eps=eps)) isect[0];


// Function: segment_intersection()
// Usage:
//   segment_intersection(s1, s2);
// Description:
//   Returns the 2D intersection point of two 2D line segments.
//   Returns `undef` if they do not intersect.
// Arguments:
//   s1 = First 2D segment, given as a list of the two 2D endpoints of the line segment.
//   s2 = Second 2D segment, given as a list of the two 2D endpoints of the line segment.
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
function segment_intersection(s1,s2,eps=EPSILON) =
	let(
		isect = _general_line_intersection(s1,s2,eps=eps)
	) isect[1]<0-eps || isect[1]>1+eps || isect[2]<0-eps || isect[2]>1+eps ? undef : isect[0];


// Function: line_segment_intersection()
// Usage:
//   line_segment_intersection(line, segment);
// Description:
//   Returns the 2D intersection point of an unbounded 2D line, and a bounded 2D line segment.
//   Returns `undef` if they do not intersect.
// Arguments:
//   line = The unbounded 2D line, defined by two 2D points on the line.
//   segment = The bounded 2D line  segment, given as a list of the two 2D endpoints of the segment.
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
function line_segment_intersection(line,segment,eps=EPSILON) =
	let(
		isect = _general_line_intersection(line,segment,eps=eps)
	) isect[2]<0-eps || isect[2]>1+eps ? undef : isect[0];


// Function: line_closest_point()
// Usage:
//   line_closest_point(line,pt);
// Description:
//   Returns the point on the given `line` that is closest to the given point `pt`.
// Arguments:
//   line = A list of two points that are on the unbounded line.
//   pt = The point to find the closest point on the line to.
function line_closest_point(line,pt) =
	let(
		n = line_normal(line),
		isect = _general_line_intersection(line,[pt,pt+n])
	) isect[0];


// Function: segment_closest_point()
// Usage:
//   segment_closest_point(seg,pt);
// Description:
//   Returns the point on the given line segment `seg` that is closest to the given point `pt`.
// Arguments:
//   seg = A list of two points that are the endpoints of the bounded line segment.
//   pt = The point to find the closest point on the segment to.
function segment_closest_point(seg,pt) =
	let(
		n = line_normal(seg),
		isect = _general_line_intersection(seg,[pt,pt+n])
	)
	norm(n)==0? seg[0] :
	isect[1]<=0? seg[0] :
	isect[1]>=1? seg[1] :
	isect[0];


// Function: find_circle_2tangents()
// Usage:
//   find_circle_2tangents(pt1, pt2, pt3, r|d);
// Description:
//   Returns [centerpoint, normal] of a circle of known size that is between and tangent to two rays with the same starting point.
//   Both rays start at `pt2`, and one passes through `pt1`, while the other passes through `pt3`.
//   If the rays given are 180º apart, `undef` is returned.  If the rays are 3D, the normal returned is the plane normal of the circle.
// Arguments:
//   pt1 = A point that the first ray passes though.
//   pt2 = The starting point of both rays.
//   pt3 = A point that the second ray passes though.
//   r = The radius of the circle to find.
//   d = The diameter of the circle to find.
// Example(2D):
//   pts = [[60,40], [10,10], [65,5]];
//   rad = 10;
//   stroke([pts[1],pts[0]], endcap2="arrow2");
//   stroke([pts[1],pts[2]], endcap2="arrow2");
//   circ = find_circle_2tangents(pt1=pts[0], pt2=pts[1], pt3=pts[2], r=rad);
//   translate(circ[0]) {
//       color("green") {
//           stroke(circle(r=rad),closed=true);
//           stroke([[0,0],rad*[cos(315),sin(315)]]);
//       }
//   }
//   place_copies(pts) color("blue") circle(d=2, $fn=12);
//   translate(circ[0]) color("red") circle(d=2, $fn=12);
//   labels = [[pts[0], "pt1"], [pts[1],"pt2"], [pts[2],"pt3"], [circ[0], "CP"], [circ[0]+[cos(315),sin(315)]*rad*0.7, "r"]];
//   for(l=labels) translate(l[0]+[0,2]) color("black") text(text=l[1], size=2.5, halign="center");
function find_circle_2tangents(pt1, pt2, pt3, r=undef, d=undef) =
	let(
		r = get_radius(r=r, d=d, dflt=undef),
		v1 = normalize(pt1 - pt2),
		v2 = normalize(pt3 - pt2)
	) approx(norm(v1+v2))? undef :
	assert(r!=undef, "Must specify either r or d.")
	let(
		a = vector_angle(v1,v2),
		n = vector_axis(v1,v2),
		v = normalize(mean([v1,v2])),
		s = r/sin(a/2),
		cp = pt2 + s*v/norm(v)
	) [cp, n];


// Function: find_circle_3points()
// Usage:
//   find_circle_3points(pt1, pt2, pt3);
// Description:
//   Returns the [CENTERPOINT, RADIUS, NORMAL] of the circle that passes through three non-collinear
//   points.  The centerpoint will be a 2D or 3D vector, depending on the points input.  If all three
//   points are 2D, then the resulting centerpoint will be 2D, and the normal will be UP ([0,0,1]).
//   If any of the points are 3D, then the resulting centerpoint will be 3D.  If the three points are
//   collinear, then `[undef,undef,undef]` will be returned.  The normal will be a normalized 3D
//   vector with a non-negative Z axis.
// Arguments:
//   pt1 = The first point.
//   pt2 = The second point.
//   pt3 = The third point.
// Example(2D):
//   pts = [[60,40], [10,10], [65,5]];
//   circ = find_circle_3points(pts[0], pts[1], pts[2]);
//   translate(circ[0]) color("green") stroke(circle(r=circ[1]),closed=true,$fn=72);
//   translate(circ[0]) color("red") circle(d=3, $fn=12);
//   place_copies(pts) color("blue") circle(d=3, $fn=12);
function find_circle_3points(pt1, pt2, pt3) =
	collinear(pt1,pt2,pt3)? [undef,undef,undef] :
	let(
		v1 = pt1-pt2,
		v2 = pt3-pt2,
		n = vector_axis(v1,v2),
		n2 = n.z<0? -n : n
	) len(pt1)+len(pt2)+len(pt3)>6? (
		let(
			a = project_plane(pt1, pt1, pt2, pt3),
			b = project_plane(pt2, pt1, pt2, pt3),
			c = project_plane(pt3, pt1, pt2, pt3),
			res = find_circle_3points(a, b, c)
		) res[0]==undef? [undef,undef,undef] : let(
			cp = lift_plane(res[0], pt1, pt2, pt3),
			r = norm(p2-cp)
		) [cp, r, n2]
	) : let(
		mp1 = pt2 + v1/2,
		mp2 = pt2 + v2/2,
		mpv1 = rot(90, v=n, p=v1),
		mpv2 = rot(90, v=n, p=v2),
		l1 = [mp1, mp1+mpv1],
		l2 = [mp2, mp2+mpv2],
		isect = line_intersection(l1,l2)
	) is_undef(isect)? [undef,undef,undef] : let(
		r = norm(pt2-isect)
	) [isect, r, n2];



// Function: tri_calc()
// Usage:
//   tri_calc(ang,ang2,adj,opp,hyp);
// Description:
//   Given a side length and an angle, or two side lengths, calculates the rest of the side lengths
//   and angles of a right triangle.  Returns [ADJACENT, OPPOSITE, HYPOTENUSE, ANGLE, ANGLE2] where
//   ADJACENT is the length of the side adjacent to ANGLE, and OPPOSITE is the length of the side
//   opposite of ANGLE and adjacent to ANGLE2.  ANGLE and ANGLE2 are measured in degrees.
//   This is certainly more verbose and slower than writing your own calculations, but has the nice
//   benefit that you can just specify the info you have, and don't have to figure out which trig
//   formulas you need to use.
// Figure(2D):
//   color("#ccc") {
//       stroke(closed=false, width=0.5, [[45,0], [45,5], [50,5]]);
//       stroke(closed=false, width=0.5, arc(N=6, r=15, cp=[0,0], start=0, angle=30));
//       stroke(closed=false, width=0.5, arc(N=6, r=14, cp=[50,30], start=212, angle=58));
//   }
//   color("black") stroke(closed=true, [[0,0], [50,30], [50,0]]);
//   color("#0c0") {
//       translate([10.5,2.5]) text(size=3,text="ang",halign="center",valign="center");
//       translate([44.5,22]) text(size=3,text="ang2",halign="center",valign="center");
//   }
//   color("blue") {
//       translate([25,-3]) text(size=3,text="Adjacent",halign="center",valign="center");
//       translate([53,15]) rotate(-90) text(size=3,text="Opposite",halign="center",valign="center");
//       translate([25,18]) rotate(30) text(size=3,text="Hypotenuse",halign="center",valign="center");
//   }
// Arguments:
//   ang = The angle in degrees of the primary corner of the triangle.
//   ang2 = The angle in degrees of the other non-right corner of the triangle.
//   adj = The length of the side adjacent to the primary corner.
//   opp = The length of the side opposite to the primary corner.
//   hyp = The length of the hypotenuse.
// Example:
//   tri = tri_calc(opp=15,hyp=30);
//   echo(adjacent=tri[0], opposite=tri[1], hypotenuse=tri[2], angle=tri[3], angle2=tri[4]);
// Examples:
//   adj = tri_calc(ang=30,opp=10)[0];
//   opp = tri_calc(ang=20,hyp=30)[1];
//   hyp = tri_calc(ang2=50,adj=20)[2];
//   ang = tri_calc(adj=20,hyp=30)[3];
//   ang2 = tri_calc(adj=20,hyp=40)[4];
function tri_calc(ang,ang2,adj,opp,hyp) =
	assert(num_defined([ang,ang2])<2,"You cannot specify both ang and ang2.")
	assert(num_defined([ang,ang2,adj,opp,hyp])==2, "You must specify exactly two arguments.")
	let(
		ang = ang!=undef? assert(ang>0&&ang<90) ang :
			ang2!=undef? (90-ang2) :
			adj==undef? asin(constrain(opp/hyp,-1,1)) :
			opp==undef? acos(constrain(adj/hyp,-1,1)) :
			atan2(opp,adj),
		ang2 = ang2!=undef? assert(ang2>0&&ang2<90) ang2 : (90-ang),
		adj = adj!=undef? assert(adj>0) adj :
			(opp!=undef? (opp/tan(ang)) : (hyp*cos(ang))),
		opp = opp!=undef? assert(opp>0) opp :
			(adj!=undef? (adj*tan(ang)) : (hyp*sin(ang))),
		hyp = hyp!=undef? assert(hyp>0) assert(adj<hyp) assert(opp<hyp) hyp :
			(adj!=undef? (adj/cos(ang)) : (opp/sin(ang)))
	)
	[adj, opp, hyp, ang, ang2];



// Function: triangle_area()
// Usage:
//   triangle_area(a,b,c);
// Description:
//   Returns the area of a triangle formed between three 2D or 3D vertices.
//   Result will be negative if the points are 2D and in in clockwise order.
// Examples:
//   triangle_area([0,0], [5,10], [10,0]);  // Returns -50
//   triangle_area([10,0], [5,10], [0,0]);  // Returns 50
function triangle_area(a,b,c) =
	len(a)==3? 0.5*norm(cross(c-a,c-b)) : (
		a.x * (b.y - c.y) +
		b.x * (c.y - a.y) +
		c.x * (a.y - b.y)
	) / 2;



// Section: Planes

// Function: plane3pt()
// Usage:
//   plane3pt(p1, p2, p3);
// Description:
//   Generates the cartesian equation of a plane from three non-collinear points on the plane.
//   Returns [A,B,C,D] where Ax+By+Cz+D=0 is the equation of a plane.
// Arguments:
//   p1 = The first point on the plane.
//   p2 = The second point on the plane.
//   p3 = The third point on the plane.
function plane3pt(p1, p2, p3) =
	let(
		p1=point3d(p1),
		p2=point3d(p2),
		p3=point3d(p3),
		normal = normalize(cross(p3-p1, p2-p1))
	) concat(normal, [normal*p1]);


// Function: plane3pt_indexed()
// Usage:
//   plane3pt_indexed(points, i1, i2, i3);
// Description:
//   Given a list of points, and the indexes of three of those points,
//   generates the cartesian equation of a plane that those points all
//   lie on.  Requires that the three indexed points be non-collinear.
//   Returns [A,B,C,D] where Ax+By+Cz+D=0 is the equation of a plane.
// Arguments:
//   points = A list of points.
//   i1 = The index into `points` of the first point on the plane.
//   i2 = The index into `points` of the second point on the plane.
//   i3 = The index into `points` of the third point on the plane.
function plane3pt_indexed(points, i1, i2, i3) =
	let(
		p1 = points[i1],
		p2 = points[i2],
		p3 = points[i3]
	) plane3pt(p1,p2,p3);


// Function: plane_from_pointslist()
// Usage:
//   plane_from_pointslist(points);
// Description:
//   Given a list of coplanar points, returns the cartesian equation of a plane.
//   Returns [A,B,C,D] where Ax+By+Cz+D=0 is the equation of the plane.
function plane_from_pointslist(points) =
	let(
		points = deduplicate(points),
		indices = find_noncollinear_points(points),
		p1 = points[indices[0]],
		p2 = points[indices[1]],
		p3 = points[indices[2]]
	) plane3pt(p1,p2,p3);


// Function: plane_normal()
// Usage:
//   plane_normal(plane);
// Description:
//   Returns the normal vector for the given plane.
function plane_normal(plane) = [for (i=[0:2]) plane[i]];


// Function: distance_from_plane()
// Usage:
//   distance_from_plane(plane, point)
// Description:
//   Given a plane as [A,B,C,D] where the cartesian equation for that plane
//   is Ax+By+Cz+D=0, determines how far from that plane the given point is.
//   The returned distance will be positive if the point is in front of the
//   plane; on the same side of the plane as the normal of that plane points
//   towards.  If the point is behind the plane, then the distance returned
//   will be negative.  The normal of the plane is the same as [A,B,C].
// Arguments:
//   plane = The [A,B,C,D] values for the equation of the plane.
//   point = The point to test.
function distance_from_plane(plane, point) =
	[plane.x, plane.y, plane.z] * point - plane[3];


// Function: coplanar()
// Usage:
//   coplanar(plane, point);
// Description:
//   Given a plane as [A,B,C,D] where the cartesian equation for that plane
//   is Ax+By+Cz+D=0, determines if the given point is on that plane.
//   Returns true if the point is on that plane.
// Arguments:
//   plane = The [A,B,C,D] values for the equation of the plane.
//   point = The point to test.
function coplanar(plane, point) =
	abs(distance_from_plane(plane, point)) <= EPSILON;


// Function: in_front_of_plane()
// Usage:
//   in_front_of_plane(plane, point);
// Description:
//   Given a plane as [A,B,C,D] where the cartesian equation for that plane
//   is Ax+By+Cz+D=0, determines if the given point is on the side of that
//   plane that the normal points towards.  The normal of the plane is the
//   same as [A,B,C].
// Arguments:
//   plane = The [A,B,C,D] values for the equation of the plane.
//   point = The point to test.
function in_front_of_plane(plane, point) =
	distance_from_plane(plane, point) > EPSILON;



// Section: Paths and Polygons


// Function: is_path()
// Usage:
//   is_path(x);
// Description:
//   Returns true if the given item looks like a path.  A path is defined as a list of two or more points.
function is_path(x) = is_list(x) && is_vector(x.x) && len(x)>1;


// Function: is_closed_path()
// Usage:
//   is_closed_path(path, [eps]);
// Description:
//   Returns true if the first and last points in the given path are coincident.
function is_closed_path(path, eps=EPSILON) = approx(path[0], path[len(path)-1], eps=eps);


// Function: close_path()
// Usage:
//   close_path(path);
// Description:
//   If a path's last point does not coincide with its first point, closes the path so it does.
function close_path(path, eps=EPSILON) = is_closed_path(path,eps=eps)? path : concat(path,[path[0]]);


// Function: cleanup_path()
// Usage:
//   cleanup_path(path);
// Description:
//   If a path's last point coincides with its first point, deletes the last point in the path.
function cleanup_path(path, eps=EPSILON) = is_closed_path(path,eps=eps)? select(path,0,-2) : path;


// Function: path_self_intersections()
// Usage:
//   isects = path_self_intersections(path, [eps]);
// Description:
//   Locates all self intersections of the given path.  Returns a list of intersections, where
//   each intersection is a list like [POINT, SEGNUM1, PROPORTION1, SEGNUM2, PROPORTION2] where
//   POINT is the coordinates of the intersection point, SEGNUMs are the integer indices of the
//   intersecting segments along the path, and the PROPORTIONS are the 0.0 to 1.0 proportions
//   of how far along those segments they intersect at.  A proportion of 0.0 indicates the start
//   of the segment, and a proportion of 1.0 indicates the end of the segment.
// Arguments:
//   path = The path to find self intersections of.
//   closed = If true, treat path like a closed polygon.  Default: true
//   eps = The epsilon error value to determine whether two points coincide.  Default: `EPSILON` (1e-9)
// Example(2D):
//   path = [
//       [-100,100], [0,-50], [100,100], [100,-100], [0,50], [-100,-100]
//   ];
//   isects = path_self_intersections(path, closed=true);
//   // isects == [[[-33.3333, 0], 0, 0.666667, 4, 0.333333], [[33.3333, 0], 1, 0.333333, 3, 0.666667]]
//   stroke(path, closed=true, width=1);
//   for (isect=isects) translate(isect[0]) color("blue") sphere(d=10);
function path_self_intersections(path, closed=true, eps=EPSILON) =
	let(
		path = cleanup_path(path, eps=eps),
		plen = len(path)
	) [
		for (i = [0:1:plen-(closed?2:3)], j=[i+1:1:plen-(closed?1:2)]) let(
			a1 = path[i],
			a2 = path[(i+1)%plen],
			b1 = path[j],
			b2 = path[(j+1)%plen],
			isect =
				(max(a1.x, a2.x) < min(b1.x, b2.x))? undef :
				(min(a1.x, a2.x) > max(b1.x, b2.x))? undef :
				(max(a1.y, a2.y) < min(b1.y, b2.y))? undef :
				(min(a1.y, a2.y) > max(b1.y, b2.y))? undef :
				let(
					c = a1-a2,
					d = b1-b2,
					denom = (c.x*d.y)-(c.y*d.x)
				) abs(denom)<eps? undef : let(
					e = a1-b1,
					t = ((e.x*d.y)-(e.y*d.x)) / denom,
					u = ((e.x*c.y)-(e.y*c.x)) / denom
				) [a1+t*(a2-a1), t, u]
		) if (
			isect != undef &&
			isect[1]>eps && isect[1]<=1+eps &&
			isect[2]>eps && isect[2]<=1+eps
		) [isect[0], i, isect[1], j, isect[2]]
	];


function _tag_self_crossing_subpaths(path, closed=true, eps=EPSILON) =
	let(
		subpaths = split_path_at_self_crossings(
			path, closed=closed, eps=eps
		)
	) [
		for (subpath = subpaths) let(
			seg = select(subpath,0,1),
			mp = mean(seg),
			n = line_normal(seg) / 2048,
			p1 = mp + n,
			p2 = mp - n,
			p1in = point_in_polygon(p1, path) >= 0,
			p2in = point_in_polygon(p2, path) >= 0,
			tag = (p1in && p2in)? "I" : "O"
		) [tag, subpath]
	];


// Function: decompose_path()
// Usage:
//   splitpaths = decompose_path(path, [closed], [eps]);
// Description:
//   Given a possibly self-crossing path, decompose it into non-crossing paths that are on the perimeter
//   of the areas bounded by that path.
// Arguments:
//   path = The path to split up.
//   closed = If true, treat path like a closed polygon.  Default: true
//   eps = The epsilon error value to determine whether two points coincide.  Default: `EPSILON` (1e-9)
// Example(2D):
//   path = [
//       [-100,100], [0,-50], [100,100], [100,-100], [0,50], [-100,-100]
//   ];
//   splitpaths = decompose_path(path, closed=true);
//   rainbow(splitpaths) stroke($item, closed=true, width=3);
function decompose_path(path, closed=true, eps=EPSILON) =
	let(
		path = cleanup_path(path, eps=eps),
		tagged = _tag_self_crossing_subpaths(path, closed=closed, eps=eps),
		kept = [for (sub = tagged) if(sub[0] == "O") sub[1]],
		outregion = assemble_path_fragments(kept, eps=eps)
	) outregion;


// Function: path_subselect()
// Usage:
//   path_subselect(path,s1,u1,s2,u2,[closed]):
// Description:
//   Returns a portion of a path, from between the `u1` part of segment `s1`, to the `u2` part of
//   segment `s2`.  Both `u1` and `u2` are values between 0.0 and 1.0, inclusive, where 0 is the start
//   of the segment, and 1 is the end.  Both `s1` and `s2` are integers, where 0 is the first segment.
// Arguments:
//   path = The path to get a section of.
//   s1 = The number of the starting segment.
//   u1 = The proportion along the starting segment, between 0.0 and 1.0, inclusive.
//   s2 = The number of the ending segment.
//   u2 = The proportion along the ending segment, between 0.0 and 1.0, inclusive.
//   closed = If true, treat path as a closed polygon.
function path_subselect(path, s1, u1, s2, u2, closed=false) =
	let(
		lp = len(path),
		l = lp-(closed?0:1),
		u1 = s1<0? 0 : s1>l? 1 : u1,
		u2 = s2<0? 0 : s2>l? 1 : u2,
		s1 = constrain(s1,0,l),
		s2 = constrain(s2,0,l),
		pathout = concat(
			(s1<l && u1<1)? [lerp(path[s1],path[(s1+1)%lp],u1)] : [],
			[for (i=[s1+1:1:s2]) path[i]],
			(s2<l && u2>0)? [lerp(path[s2],path[(s2+1)%lp],u2)] : []
		)
	) pathout;


// Function: polygon_area()
// Usage:
//   area = polygon_area(vertices);
// Description:
//   Given a polygon, returns the area of that polygon.  If the polygon is self-crossing, the results are undefined.
function polygon_area(vertices) =
	0.5*sum([for(i=[0:len(vertices)-1]) det2(select(vertices,i,i+1))]);


// Function: polygon_shift()
// Usage:
//   polygon_shift(poly, i);
// Description:
//   Given a polygon `poly`, rotates the point ordering so that the first point in the polygon path is the one at index `i`.
// Arguments:
//   poly = The list of points in the polygon path.
//   i = The index of the point to shift to the front of the path.
// Example:
//   polygon_shift([[3,4], [8,2], [0,2], [-4,0]], 2);   // Returns [[0,2], [-4,0], [3,4], [8,2]]
function polygon_shift(poly, i) =
	assert(i<len(poly))
	let(
		poly = cleanup_path(poly)
	) select(poly,i,i+len(poly)-1);


// Function: polygon_shift_to_closest_point()
// Usage:
//   polygon_shift_to_closest_point(path, pt);
// Description:
//   Given a polygon `path`, rotates the point ordering so that the first point in the path is the one closest to the given point `pt`.
function polygon_shift_to_closest_point(path, pt) =
	let(
		path = cleanup_path(path),
		closest = path_closest_point(path,pt),
		seg = select(path,closest[0],closest[0]+1),
		u = norm(closest[1]-seg[0]) / norm(seg[1]-seg[0]),
		segnum = closest[0] + (u>0.5? 1 : 0)
	) select(path,segnum,segnum+len(path)-1);


// Function: first_noncollinear()
// Usage:
//   first_noncollinear(i1, i2, points);
// Description:
//   Finds the first point in `points` that is not collinear with the points indexed by `i1` and `i2`.  Returns the index of the found point.
// Arguments:
//   i1 = The first point.
//   i2 = The second point.
//   points = The list of points to find a non-collinear point from.
function first_noncollinear(i1, i2, points, _i) =
	(_i>=len(points) || !collinear_indexed(points, i1, i2, _i))? _i :
	find_first_noncollinear(i1, i2, points, _i=_i+1);


// Function: noncollinear_points()
// Usage:
//   find_noncollinear_points(points);
// Description:
//   Finds the indexes of three good points in the points list `points` that are not collinear.
function find_noncollinear_points(points) =
	let(
		a = 0,
		b = furthest_point(a, points),
		c = first_noncollinear(a, b, points)
	) [a, b, c];


// Function: centroid()
// Usage:
//   centroid(vertices)
// Description:
//   Given a simple 2D polygon, returns the coordinates of the polygon's centroid.
//   If the polygon is self-intersecting, the results are undefined.
function centroid(vertices) =
	sum([
		for(i=[0:len(vertices)-1])
		let(segment=select(vertices,i,i+1))
		det2(segment)*sum(segment)
	]) / 6 / polygon_area(vertices);


function _extreme_angle_fragment(seg, fragments, rightmost=true, eps=EPSILON) =
	!fragments? [undef, []] :
	let(
		delta = seg[1] - seg[0],
		segang = atan2(delta.y,delta.x),
		frags = [
			for (i = idx(fragments)) let(
				fragment = fragments[i],
				fwdmatch = approx(seg[1], fragment[0], eps=eps),
				bakmatch =  approx(seg[1], select(fragment,-1), eps=eps)
			) [
				fwdmatch,
				bakmatch,
				bakmatch? reverse(fragment) : fragment
			]
		],
		angs = [
			for (frag = frags)
				(frag[0] || frag[1])? let(
					delta2 = frag[2][1] - frag[2][0],
					segang2 = atan2(delta2.y, delta2.x)
				) modang(segang2 - segang) : (
					rightmost? 999 : -999
				)
		],
		fi = rightmost? min_index(angs) : max_index(angs)
	) abs(angs[fi]) > 360? [undef, fragments] : let(
		remainder = [for (i=idx(fragments)) if (i!=fi) fragments[i]],
		frag = frags[fi],
		foundfrag = frag[2]
	) [foundfrag, remainder];


// Function: assemble_a_path_from_fragments()
// Usage:
//   assemble_a_path_from_fragments(subpaths);
// Description:
//   Given a list of incomplete paths, assembles them together into one complete closed path, and
//   remainder fragments.  Returns [PATH, FRAGMENTS] where FRAGMENTS is the list of remaining
//   polyline path fragments.
// Arguments:
//   fragments = List of polylines to be assembled into complete polygons.
//   rightmost = If true, assemble paths using rightmost turns. Leftmost if false.
//   eps = The epsilon error value to determine whether two points coincide.  Default: `EPSILON` (1e-9)
function assemble_a_path_from_fragments(fragments, rightmost=true, eps=EPSILON) =
	len(fragments)==0? _finished :
	let(
		path = fragments[0],
		newfrags = slice(fragments, 1, -1)
	) is_closed_path(path, eps=eps)? (
		// starting fragment is already closed
		[path, newfrags]
	) : let(
		// Find rightmost/leftmost continuation fragment
		seg = select(path,-2,-1),
		frags = slice(fragments,1,-1),
		extrema = _extreme_angle_fragment(seg=seg, fragments=frags, rightmost=rightmost, eps=eps),
		foundfrag = extrema[0],
		remainder = extrema[1],
		newfrags = remainder
	) is_undef(foundfrag)? (
		// No remaining fragments connect!  INCOMPLETE PATH!
		// Treat it as complete.
		[path, newfrags]
	) : is_closed_path(foundfrag, eps=eps)? (
		let(
			newfrags = concat([path], remainder)
		)
		// Found fragment is already closed
		[foundfrag, newfrags]
	) : let(
		fragend = select(foundfrag,-1),
		hits = [for (i = idx(path,end=-2)) if(approx(path[i],fragend,eps=eps)) i]
	) hits? (
		let(
			// Found fragment intersects with initial path
			hitidx = select(hits,-1),
			newpath = slice(path,0,hitidx+1),
			newfrags = concat(len(newpath)>1? [newpath] : [], remainder),
			outpath = concat(slice(path,hitidx,-2), foundfrag)
		)
		[outpath, newfrags]
	) : let(
		// Path still incomplete.  Continue building it.
		newpath = concat(path, slice(foundfrag, 1, -1)),
		newfrags = concat([newpath], remainder)
	)
	assemble_a_path_from_fragments(
		fragments=newfrags,
		rightmost=rightmost,
		eps=eps
	);


// Function: assemble_path_fragments()
// Usage:
//   assemble_path_fragments(subpaths);
// Description:
//   Given a list of incomplete paths, assembles them together into complete closed paths if it can.
// Arguments:
//   fragments = List of polylines to be assembled into complete polygons.
//   rightmost = If true, assemble paths using rightmost turns. Leftmost if false.
//   eps = The epsilon error value to determine whether two points coincide.  Default: `EPSILON` (1e-9)
function assemble_path_fragments(fragments, rightmost=true, eps=EPSILON, _finished=[]) =
	len(fragments)==0? _finished :
	let(
		result = assemble_a_path_from_fragments(
			fragments=fragments,
			rightmost=rightmost,
			eps=eps
		),
		newpath = result[0],
		remainder = result[1],
		finished = concat(_finished, [newpath])
	) assemble_path_fragments(
		fragments=remainder,
		rightmost=rightmost, eps=eps,
		_finished=finished
	);



// Function: simplify_path()
// Description:
//   Takes a path and removes unnecessary collinear points.
// Usage:
//   simplify_path(path, [eps])
// Arguments:
//   path = A list of 2D path points.
//   eps = Largest positional variance allowed.  Default: `EPSILON` (1-e9)
function simplify_path(path, eps=EPSILON) =
	len(path)<=2? path : let(
		indices = concat([0], [for (i=[1:1:len(path)-2]) if (!collinear_indexed(path, i-1, i, i+1, eps=eps)) i], [len(path)-1])
	) [for (i = indices) path[i]];



// Function: simplify_path_indexed()
// Description:
//   Takes a list of points, and a path as a list of indexes into `points`,
//   and removes all path points that are unecessarily collinear.
// Usage:
//   simplify_path_indexed(path, eps)
// Arguments:
//   points = A list of points.
//   path = A list of indexes into `points` that forms a path.
//   eps = Largest angle variance allowed.  Default: EPSILON (1-e9) degrees.
function simplify_path_indexed(points, path, eps=EPSILON) =
	len(path)<=2? path : let(
		indices = concat([0], [for (i=[1:1:len(path)-2]) if (!collinear_indexed(points, path[i-1], path[i], path[i+1], eps=eps)) i], [len(path)-1])
	) [for (i = indices) path[i]];



// Function: point_in_polygon()
// Usage:
//   point_in_polygon(point, path)
// Description:
//   This function tests whether the given point is inside, outside or on the boundary of
//   the specified 2D polygon using the Winding Number method.
//   The polygon is given as a list of 2D points, not including the repeated end point.
//   Returns -1 if the point is outside the polyon.
//   Returns 0 if the point is on the boundary.
//   Returns 1 if the point lies in the interior.
//   The polygon does not need to be simple: it can have self-intersections.
//   But the polygon cannot have holes (it must be simply connected).
//   Rounding error may give mixed results for points on or near the boundary.
// Arguments:
//   point = The point to check position of.
//   path = The list of 2D path points forming the perimeter of the polygon.
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
function point_in_polygon(point, path, eps=EPSILON) =
	// Original algorithm from http://geomalgorithms.com/a03-_inclusion.html
	// Does the point lie on any edges?  If so return 0.
	sum([for(i=[0:1:len(path)-1]) let(seg=select(path,i,i+1)) if(!approx(seg[0],seg[1],eps=eps)) point_on_segment2d(point, seg, eps=eps)?1:0]) > 0? 0 :
	// Otherwise compute winding number and return 1 for interior, -1 for exterior
	sum([for(i=[0:1:len(path)-1]) let(seg=select(path,i,i+1)) if(!approx(seg[0],seg[1],eps=eps)) _point_above_below_segment(point, seg)]) != 0? 1 : -1;


// Function: pointlist_bounds()
// Usage:
//   pointlist_bounds(pts);
// Description:
//   Finds the bounds containing all the 2D or 3D points in `pts`.
//   Returns `[[MINX, MINY, MINZ], [MAXX, MAXY, MAXZ]]`
// Arguments:
//   pts = List of points.
function pointlist_bounds(pts) = [
	[for (a=[0:2]) min([ for (x=pts) point3d(x)[a] ]) ],
	[for (a=[0:2]) max([ for (x=pts) point3d(x)[a] ]) ]
];


// Function: closest_point()
// Usage:
//   closest_point(pt, points);
// Description:
//   Given a list of `points`, finds the point that is closest to the given point `pt`, and returns the index of it.
// Arguments:
//   pt = The point to find the closest point to.
//   points = The list of points to search.
function closest_point(pt, points) =
	let(
		i = min_index([for (j=idx(points)) norm(points[j]-pt)])
	) i;


// Function: furthest_point()
// Usage:
//   furthest_point(pt, points);
// Description:
//   Given a list of `points`, finds the point that is farthest from the given point `pt`, and returns the index of it.
// Arguments:
//   pt = The point to find the farthest point from.
//   points = The list of points to search.
function furthest_point(pt, points) =
	let(
		i = max_index([for (j=idx(points)) norm(points[j]-pt)])
	) i;


// Function: polygon_is_clockwise()
// Usage:
//   polygon_is_clockwise(path);
// Description:
//   Return true if the given 2D simple polygon is in clockwise order, false otherwise.
//   Results for complex (self-intersecting) polygon are indeterminate.
// Arguments:
//   path = The list of 2D path points for the perimeter of the polygon.
function polygon_is_clockwise(path) =
	let(
		minx = min(subindex(path,0)),
		lowind = search(minx, path, 0, 0),
		lowpts = select(path, lowind),
		miny = min(subindex(lowpts, 1)),
		extreme_sub = search(miny, lowpts, 1, 1)[0],
		extreme = select(lowind,extreme_sub)
	) det2([select(path,extreme+1)-path[extreme], select(path, extreme-1)-path[extreme]])<0;


// Function: clockwise_polygon()
// Usage:
//   clockwise_polygon(path);
// Description:
//   Given a polygon path, returns the clockwise winding version of that path.
function clockwise_polygon(path) =
	polygon_is_clockwise(path)? path : reverse(path);


// Function: ccw_polygon()
// Usage:
//   ccw_polygon(path);
// Description:
//   Given a polygon path, returns the counter-clockwise winding version of that path.
function ccw_polygon(path) =
	polygon_is_clockwise(path)? reverse(path) : path;



// Section: Regions and Boolean 2D Geometry


// Function: is_region()
// Usage:
//   is_region(x);
// Description:
//   Returns true if the given item looks like a region.  A region is defined as a list of zero or more paths.
function is_region(x) = is_list(x) && is_path(x.x);


// Function: close_region()
// Usage:
//   close_region(region);
// Description:
//   Closes all paths within a given region.
function close_region(region, eps=EPSILON) = [for (path=region) close_path(path, eps=eps)];

// Function: check_and_fix_path()
// Usage:
//   check_and_fix_path(path, [valid_dim], [closed])
// Description:
//   Checks that the input is a path.  If it is a region with one component, converts it to a path.
//   valid_dim specfies the allowed dimension of the points in the path.
//   If the path is closed, removed duplicate endpoint if present.
// Arguments:
//   path = path to process
//   valid_dim = list of allowed dimensions for the points in the path, e.g. [2,3] to require 2 or 3 dimensional input.  If left undefined do not perform this check.  Default: undef
//   closed = set to true if the path is closed, which enables a check for endpoint duplication
function check_and_fix_path(path, valid_dim=undef, closed=false) =
	let(
		path = is_region(path)? (
			assert(len(path)==1,"Region supplied as path does not have exactly one component")
			path[0]
		) : (
			assert(is_path(path), "Input is not a path")
			path
		),
		dim = array_dim(path)
	)
	assert(dim[0]>1,"Path must have at least 2 points")
	assert(len(dim)==2,"Invalid path: path is either a list of scalars or a list of matrices")
	assert(is_def(dim[1]), "Invalid path: entries in the path have variable length")
	let(valid=is_undef(valid_dim) || in_list(dim[1],valid_dim))
	assert(
		valid, str(
			"The points on the path have length ",
			dim[1], " but length must be ",
			len(valid_dim)==1? valid_dim[0] : str("one of ",valid_dim)
		)
	)
	closed && approx(path[0],select(path,-1))? slice(path,0,-2) : path;


// Function: cleanup_region()
// Usage:
//   cleanup_region(region);
// Description:
//   For all paths in the given region, if the last point coincides with the first point, removes the last point.
// Arguments:
//   region = The region to clean up.  Given as a list of polygon paths.
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
function cleanup_region(region, eps=EPSILON) =
	[for (path=region) cleanup_path(path, eps=eps)];


// Function: point_in_region()
// Usage:
//   point_in_region(point, region);
// Description:
//   Tests if a point is inside, outside, or on the border of a region.
//   Returns -1 if the point is outside the region.
//   Returns 0 if the point is on the boundary.
//   Returns 1 if the point lies inside the region.
// Arguments:
//   point = The point to test.
//   region = The region to test against.  Given as a list of polygon paths.
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
function point_in_region(point, region, eps=EPSILON, _i=0, _cnt=0) =
	(_i >= len(region))? ((_cnt%2==1)? 1 : -1) : let(
		pip = point_in_polygon(point, region[_i], eps=eps)
	) pip==0? 0 : point_in_region(point, region, eps=eps, _i=_i+1, _cnt = _cnt + (pip>0? 1 : 0));


// Function: region_path_crossings()
// Usage:
//   region_path_crossings(path, region);
// Description:
//   Returns a sorted list of [SEGMENT, U] that describe where a given path is crossed by a second path.
// Arguments:
//   path = The path to find crossings on.
//   region = Region to test for crossings of.
//   closed = If true, treat path as a closed polygon.  Default: true
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
function region_path_crossings(path, region, closed=true, eps=EPSILON) = sort([
	let(
		segs = pair(closed? close_path(path) : cleanup_path(path))
	) for (
		si = idx(segs),
		p = close_region(region),
		s2 = pair(p)
	) let (
		isect = _general_line_intersection(segs[si], s2, eps=eps)
	) if (
		!is_undef(isect) &&
		isect[1] >= 0-eps && isect[1] < 1+eps &&
		isect[2] >= 0-eps && isect[2] < 1+eps
	)
	[si, isect[1]]
]);


function _offset_chamfer(center, points, delta) =
	let(
		dist = sign(delta)*norm(center-line_intersection(select(points,[0,2]), [center, points[1]])),
		endline = _shift_segment(select(points,[0,2]), delta-dist)
	) [
		line_intersection(endline, select(points,[0,1])),
		line_intersection(endline, select(points,[1,2]))
	];


function _shift_segment(segment, d) =
	move(d*line_normal(segment),segment);


// Extend to segments to their intersection point.  First check if the segments already have a point in common,
// which can happen if two colinear segments are input to the path variant of `offset()`
function _segment_extension(s1,s2) =
	norm(s1[1]-s2[0])<1e-6 ? s1[1] : line_intersection(s1,s2);


function _makefaces(direction, startind, good, pointcount, closed) =
	let(
		lenlist = list_bset(good, pointcount),
		numfirst = len(lenlist),
		numsecond = sum(lenlist),
		prelim_faces = _makefaces_recurse(startind, startind+len(lenlist), numfirst, numsecond, lenlist, closed)
	)
	direction? [for(entry=prelim_faces) reverse(entry)] : prelim_faces;


function _makefaces_recurse(startind1, startind2, numfirst, numsecond, lenlist, closed, firstind=0, secondind=0, faces=[]) =
	// We are done if *both* firstind and secondind reach their max value, which is the last point if !closed or one past
	// the last point if closed (wrapping around).  If you don't check both you can leave a triangular gap in the output.
	((firstind == numfirst - (closed?0:1)) && (secondind == numsecond - (closed?0:1)))? faces :
	_makefaces_recurse(
		startind1, startind2, numfirst, numsecond, lenlist, closed, firstind+1, secondind+lenlist[firstind],
		lenlist[firstind]==0? (
			// point in original path has been deleted in offset path, so it has no match.  We therefore
			// make a triangular face using the current point from the offset (second) path
			// (The current point in the second path can be equal to numsecond if firstind is the last point)
			concat(faces,[[secondind%numsecond+startind2, firstind+startind1, (firstind+1)%numfirst+startind1]])
			// in this case a point or points exist in the offset path corresponding to the original path
		) : (
			concat(faces,
				// First generate triangular faces for all of the extra points (if there are any---loop may be empty)
				[for(i=[0:1:lenlist[firstind]-2]) [firstind+startind1, secondind+i+1+startind2, secondind+i+startind2]],
				// Finish (unconditionally) with a quadrilateral face
				[
					[
						firstind+startind1,
						(firstind+1)%numfirst+startind1,
						(secondind+lenlist[firstind])%numsecond+startind2,
						(secondind+lenlist[firstind]-1)%numsecond+startind2
					]
				]
			)
		)
	);


// Determine which of the shifted segments are good
function _good_segments(path, d, shiftsegs, closed, quality) =
	let(
		maxind = len(path)-(closed ? 1 : 2),
		pathseg = [for(i=[0:maxind]) select(path,i+1)-path[i]],
		pathseg_len =  [for(seg=pathseg) norm(seg)],
		pathseg_unit = [for(i=[0:maxind]) pathseg[i]/pathseg_len[i]],
		// Order matters because as soon as a valid point is found, the test stops
		// This order works better for circular paths because they succeed in the center
		alpha = concat([for(i=[1:1:quality]) i/(quality+1)],[0,1])
	) [
		for (i=[0:len(shiftsegs)-1])
			(i>maxind)? true :
			_segment_good(path,pathseg_unit,pathseg_len, d - 1e-7, shiftsegs[i], alpha)
	];


// Determine if a segment is good (approximately)
// Input is the path, the path segments normalized to unit length, the length of each path segment
// the distance threshold, the segment to test, and the locations on the segment to test (normalized to [0,1])
// The last parameter, index, gives the current alpha index.
//
// A segment is good if any part of it is farther than distance d from the path.  The test is expensive, so
// we want to quit as soon as we find a point with distance > d, hence the recursive code structure.
//
// This test is approximate because it only samples the points listed in alpha.  Listing more points
// will make the test more accurate, but slower.
function _segment_good(path,pathseg_unit,pathseg_len, d, seg,alpha ,index=0) =
	index == len(alpha) ? false :
	_point_dist(path,pathseg_unit,pathseg_len, alpha[index]*seg[0]+(1-alpha[index])*seg[1]) > d ? true :
	_segment_good(path,pathseg_unit,pathseg_len,d,seg,alpha,index+1);


// Input is the path, the path segments normalized to unit length, the length of each path segment
// and a test point.  Computes the (minimum) distance from the path to the point, taking into
// account that the minimal distance may be anywhere along a path segment, not just at the ends.
function _point_dist(path,pathseg_unit,pathseg_len,pt) =
	min([
		for(i=[0:len(pathseg_unit)-1]) let(
			v = pt-path[i],
			projection = v*pathseg_unit[i],
			segdist = projection < 0? norm(pt-path[i]) :
				projection > pathseg_len[i]? norm(pt-select(path,i+1)) :
				norm(v-projection*pathseg_unit[i])
		) segdist
	]);


function _offset_region(
	paths, r, delta, chamfer, closed,
	maxstep, check_valid, quality,
	return_faces, firstface_index,
	flip_faces, _acc=[], _i=0
) =
	_i>=len(paths)? _acc :
	_offset_region(
		paths, _i=_i+1,
		_acc = (paths[_i].x % 2 == 0)? (
			union(_acc, [
				offset(
					paths[_i].y,
					r=r, delta=delta, chamfer=chamfer, closed=closed,
					maxstep=maxstep, check_valid=check_valid, quality=quality,
					return_faces=return_faces, firstface_index=firstface_index,
					flip_faces=flip_faces
				)
			])
		) : (
			difference(_acc, [
				offset(
					paths[_i].y,
					r=-r, delta=-delta, chamfer=chamfer, closed=closed,
					maxstep=maxstep, check_valid=check_valid, quality=quality,
					return_faces=return_faces, firstface_index=firstface_index,
					flip_faces=flip_faces
				)
			])
		),
		r=r, delta=delta, chamfer=chamfer, closed=closed,
		maxstep=maxstep, check_valid=check_valid, quality=quality,
		return_faces=return_faces, firstface_index=firstface_index, flip_faces=flip_faces
	);


// Function: offset()
//
// Description:
//   Takes an input path and returns a path offset by the specified amount.  As with the built-in
//   offset() module, you can use `r` to specify rounded offset and `delta` to specify offset with
//   corners.  Positive offsets shift the path to the left (relative to the direction of the path).
//   
//   When offsets shrink the path, segments cross and become invalid.  By default `offset()` checks
//   for this situation.  To test validity the code checks that segments have distance larger than (r
//   or delta) from the input path.  This check takes O(N^2) time and may mistakenly eliminate
//   segments you wanted included in various situations, so you can disable it if you wish by setting
//   check_valid=false.  Another situation is that the test is not sufficiently thorough and some
//   segments persist that should be eliminated.  In this case, increase `quality` to 2 or 3.  (This
//   increases the number of samples on the segment that are checked.)  Run time will increase.  In
//   some situations you may be able to decrease run time by setting quality to 0, which causes only
//   segment ends to be checked.
//   
//   For construction of polyhedra `offset()` can also return face lists.  These list faces between
//   the original path and the offset path where the vertices are ordered with the original path
//   first, starting at `firstface_index` and the offset path vertices appearing afterwords.  The
//   direction of the faces can be flipped using `flip_faces`.  When you request faces the return
//   value is a list: [offset_path, face_list].
// Arguments:
//   path = the path to process.  A list of 2d points.
//   r = offset radius.  Distance to offset.  Will round over corners.
//   delta = offset distance.  Distance to offset with pointed corners.
//   chamfer = chamfer corners when you specify `delta`.  Default: false
//   closed = path is a closed curve. Default: False.
//   check_valid = perform segment validity check.  Default: True.
//   quality = validity check quality parameter, a small integer.  Default: 1.
//   return_faces = return face list.  Default: False.
//   firstface_index = starting index for face list.  Default: 0.
//   flip_faces = flip face direction.  Default: false
// Example(2D):
//   star = star(5, r=100, ir=30);
//   #stroke(closed=true, star);
//   stroke(closed=true, offset(star, delta=10, closed=true));
// Example(2D):
//   star = star(5, r=100, ir=30);
//   #stroke(closed=true, star);
//   stroke(closed=true, offset(star, delta=10, chamfer=true, closed=true));
// Example(2D):
//   star = star(5, r=100, ir=30);
//   #stroke(closed=true, star);
//   stroke(closed=true, offset(star, r=10, closed=true));
// Example(2D):
//   star = star(5, r=100, ir=30);
//   #stroke(closed=true, star);
//   stroke(closed=true, offset(star, delta=-10, closed=true));
// Example(2D):
//   star = star(5, r=100, ir=30);
//   #stroke(closed=true, star);
//   stroke(closed=true, offset(star, delta=-10, chamfer=true, closed=true));
// Example(2D):
//   star = star(5, r=100, ir=30);
//   #stroke(closed=true, star);
//   stroke(closed=true, offset(star, r=-10, closed=true));
// Example(2D):  This case needs `quality=2` for success
//   test = [[0,0],[10,0],[10,7],[0,7], [-1,-3]];
//   polygon(offset(test,r=-1.9, closed=true, quality=2));
//   //polygon(offset(test,r=-1.9, closed=true, quality=1));  // Fails with erroneous 180 deg path error
//   %down(.1)polygon(test);
// Example(2D): This case fails if `check_valid=true` when delta is large enough because segments are too close to the opposite side of the curve.  
//   star = star(5, r=22, ir=13);
//   stroke(star,width=.2,closed=true);                                                           
//   color("green")
//     stroke(offset(star, delta=-9, closed=true),width=.2,closed=true); // Works with check_valid=true (the default)
//   color("red")
//     stroke(offset(star, delta=-10, closed=true, check_valid=false),   // Fails if check_valid=true 
//            width=.2,closed=true); 
// Example(2D): But if you use rounding with offset then you need `check_valid=true` when `r` is big enough.  It works without the validity check as long as the offset shape retains a some of the straight edges at the star tip, but once the shape shrinks smaller than that, it fails.  There is no simple way to get a correct result for the case with `r=10`, because as in the previous example, it will fail if you turn on validity checks.  
//   star = star(5, r=22, ir=13);
//   color("green")
//     stroke(offset(star, r=-8, closed=true,check_valid=false), width=.1, closed=true);
//   color("red")
//     stroke(offset(star, r=-10, closed=true,check_valid=false), width=.1, closed=true);
// Example(2D): The extra triangles in this example show that the validity check cannot be skipped
//   ellipse = scale([20,4], p=circle(r=1,$fn=64));
//   stroke(ellipse, closed=true, width=0.3);
//   stroke(offset(ellipse, r=-3, check_valid=false, closed=true), width=0.3, closed=true);
// Example(2D): The triangles are removed by the validity check
//   ellipse = scale([20,4], p=circle(r=1,$fn=64));
//   stroke(ellipse, closed=true, width=0.3);
//   stroke(offset(ellipse, r=-3, check_valid=true, closed=true), width=0.3, closed=true);
// Example(2D): Open path.  The path moves from left to right and the positive offset shifts to the left of the initial red path.
//   sinpath = 2*[for(theta=[-180:5:180]) [theta/4,45*sin(theta)]];
//   #stroke(sinpath);
//   stroke(offset(sinpath, r=17.5));
// Example(2D): Region
//   rgn = difference(circle(d=100), union(square([20,40], center=true), square([40,20], center=true)));
//   #linear_extrude(height=1.1) for (p=rgn) stroke(closed=true, width=0.5, p);
//   region(offset(rgn, r=-5));
function offset(
	path, r=undef, delta=undef, chamfer=false,
	maxstep=0.1, closed=false, check_valid=true,
	quality=1, return_faces=false, firstface_index=0,
	flip_faces=false
) =
	is_region(path)? (
		assert(!return_faces, "return_faces not supported for regions.")
		let(
			path = [for (p=path) polygon_is_clockwise(p)? p : reverse(p)],
			rgn = exclusive_or([for (p = path) [p]]),
			pathlist = sort(idx=0,[
				for (i=[0:1:len(rgn)-1]) [
					sum(concat([0],[
						for (j=[0:1:len(rgn)-1]) if (i!=j)
							point_in_polygon(rgn[i][0],rgn[j])>=0? 1 : 0
					])),
					rgn[i]
				]
			])
		) _offset_region(
			pathlist, r=r, delta=delta, chamfer=chamfer, closed=true,
			maxstep=maxstep, check_valid=check_valid, quality=quality,
			return_faces=return_faces, firstface_index=firstface_index,
			flip_faces=flip_faces
		)
	) : let(rcount = num_defined([r,delta]))
	assert(rcount==1,"Must define exactly one of 'delta' and 'r'")
	let(
		chamfer = is_def(r) ? false : chamfer,
		quality = max(0,round(quality)),
		flip_dir = closed && !polygon_is_clockwise(path)? -1 : 1,
		d = flip_dir * (is_def(r) ? r : delta),
		shiftsegs = [for(i=[0:len(path)-1]) _shift_segment(select(path,i,i+1), d)],
		// good segments are ones where no point on the segment is less than distance d from any point on the path
		good = check_valid ? _good_segments(path, abs(d), shiftsegs, closed, quality) : replist(true,len(shiftsegs)),
		goodsegs = bselect(shiftsegs, good),
		goodpath = bselect(path,good)
	)
	assert(len(goodsegs)>0,"Offset of path is degenerate")
	let(
		// Extend the shifted segments to their intersection points
		sharpcorners = [for(i=[0:len(goodsegs)-1]) _segment_extension(select(goodsegs,i-1), select(goodsegs,i))],
		// If some segments are parallel then the extended segments are undefined.  This case is not handled
		// Note if !closed the last corner doesn't matter, so exclude it
		parallelcheck =
			(len(sharpcorners)==2 && !closed) ||
			all_defined(select(sharpcorners,closed?0:1,-1))
	)
	assert(parallelcheck, "Path turns back on itself (180 deg turn)")
	let(
		// This is a boolean array that indicates whether a corner is an outside or inside corner
		// For outside corners, the newcorner is an extension (angle 0), for inside corners, it turns backward
		// If either side turns back it is an inside corner---must check both.
		// Outside corners can get rounded (if r is specified and there is space to round them)
		outsidecorner = [
			for(i=[0:len(goodsegs)-1]) let(
				prevseg=select(goodsegs,i-1)
			) (
				(goodsegs[i][1]-goodsegs[i][0]) *
				(goodsegs[i][0]-sharpcorners[i]) > 0
			) && (
				(prevseg[1]-prevseg[0]) *
				(sharpcorners[i]-prevseg[1]) > 0
			)
		],
		steps = is_def(delta) ? [] : [
			for(i=[0:len(goodsegs)-1])
			ceil(
				abs(r)*vector_angle(
					select(goodsegs,i-1)[1]-goodpath[i],
					goodsegs[i][0]-goodpath[i]
				)*PI/180/maxstep
			)
		],
		// If rounding is true then newcorners replaces sharpcorners with rounded arcs where needed
		// Otherwise it's the same as sharpcorners
		// If rounding is on then newcorners[i] will be the point list that replaces goodpath[i] and newcorners later
		// gets flattened.  If rounding is off then we set it to [sharpcorners] so we can later flatten it and get
		// plain sharpcorners back.
		newcorners = is_def(delta) && !chamfer ? [sharpcorners] : [
			for(i=[0:len(goodsegs)-1]) (
				(!chamfer && steps[i] <=2)  //Chamfer all points but only round if steps is 3 or more
				|| !outsidecorner[i]        // Don't round inside corners
				|| (!closed && (i==0 || i==len(goodsegs)-1))  // Don't round ends of an open path
			)? [sharpcorners[i]] : (
				chamfer?
					_offset_chamfer(
						goodpath[i], [
							select(goodsegs,i-1)[1],
							sharpcorners[i],
							goodsegs[i][0]
						], d
					) :
				arc(
					cp=goodpath[i],
					points=[
						select(goodsegs,i-1)[1],
						goodsegs[i][0]
					],
					N=steps[i]
				)
			)
		],
		pointcount = (is_def(delta) && !chamfer)?
			replist(1,len(sharpcorners)) :
			[for(i=[0:len(goodsegs)-1]) len(newcorners[i])],
		start = [goodsegs[0][0]],
		end = [goodsegs[len(goodsegs)-2][1]],
		edges =  closed?
			flatten(newcorners) :
			concat(start,slice(flatten(newcorners),1,-2),end),
		faces = !return_faces? [] :
			_makefaces(
				flip_faces, firstface_index, good,
				pointcount, closed
			)
	) return_faces? [edges,faces] : edges;


// Function: split_path_at_self_crossings()
// Usage:
//   polylines = split_path_at_self_crossings(path, [closed], [eps]);
// Description:
//   Splits a path into polyline sections wherever the path crosses itself.
//   Splits may occur mid-segment, so new vertices will be created at the intersection points.
// Arguments:
//   path = The path to split up.
//   closed = If true, treat path as a closed polygon.  Default: true
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
// Example(2D):
//   path = [ [-100,100], [0,-50], [100,100], [100,-100], [0,50], [-100,-100] ];
//   polylines = split_path_at_self_crossings(path);
//   rainbow(polylines) stroke($item, closed=false, width=2);
function split_path_at_self_crossings(path, closed=true, eps=EPSILON) =
	let(
		path = cleanup_path(path, eps=eps),
		isects = deduplicate(
			eps=eps,
			concat(
				[[0, 0]],
				sort([
					for (
						a = path_self_intersections(path, closed=closed, eps=eps),
						ss = [ [a[1],a[2]], [a[3],a[4]] ]
					) if (ss[0] != undef) ss
				]),
				[[len(path)-(closed?1:2), 1]]
			)
		)
	) [
		for (p = pair(isects))
			let(
				s1 = p[0][0],
				u1 = p[0][1],
				s2 = p[1][0],
				u2 = p[1][1],
				section = path_subselect(path, s1, u1, s2, u2, closed=closed),
				outpath = deduplicate(eps=eps, section)
			)
			outpath
	];


// Function: split_path_at_region_crossings()
// Usage:
//   polylines = split_path_at_region_crossings(path, region, [eps]);
// Description:
//   Splits a path into polyline sections wherever the path crosses the perimeter of a region.
//   Splits may occur mid-segment, so new vertices will be created at the intersection points.
// Arguments:
//   path = The path to split up.
//   region = The region to check for perimeter crossings of.
//   closed = If true, treat path as a closed polygon.  Default: true
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
// Example(2D):
//   path = square(50,center=false);
//   region = [circle(d=80), circle(d=40)];
//   polylines = split_path_at_region_crossings(path, region);
//   color("#aaa") region(region);
//   rainbow(polylines) stroke($item, closed=false, width=2);
function split_path_at_region_crossings(path, region, closed=true, eps=EPSILON) =
	let(
		path = deduplicate(path, eps=eps),
		region = [for (path=region) deduplicate(path, eps=eps)],
		xings = region_path_crossings(path, region, closed=closed, eps=eps),
		crossings = deduplicate(
			concat([[0,0]], xings, [[len(path)-1,1]]),
			eps=eps
		),
		subpaths = [
			for (p = pair(crossings))
				deduplicate(eps=eps,
					path_subselect(path, p[0][0], p[0][1], p[1][0], p[1][1], closed=closed)
				)
		]
	)
	subpaths;


function _tag_subpaths(path, region, eps=EPSILON) =
	let(
		subpaths = split_path_at_region_crossings(path, region, eps=eps),
		tagged = [
			for (sub = subpaths) let(
				subpath = deduplicate(sub)
			) if (len(sub)>1) let(
				midpt = lerp(subpath[0], subpath[1], 0.5),
				rel = point_in_region(midpt,region,eps=eps)
			) rel<0? ["O", subpath] : rel>0? ["I", subpath] : let(
				vec = normalize(subpath[1]-subpath[0]),
				perp = rot(90, planar=true, p=vec),
				sidept = midpt + perp*0.01,
				rel1 = point_in_polygon(sidept,path,eps=eps)>0,
				rel2 = point_in_region(sidept,region,eps=eps)>0
			) rel1==rel2? ["S", subpath] : ["U", subpath]
		]
	) tagged;


function _tag_region_subpaths(region1, region2, eps=EPSILON) =
	[for (path=region1) each _tag_subpaths(path, region2, eps=eps)];


function _tagged_region(region1,region2,keep1,keep2,eps=EPSILON) =
	let(
		region1 = close_region(region1, eps=eps),
		region2 = close_region(region2, eps=eps),
		tagged1 = _tag_region_subpaths(region1, region2, eps=eps),
		tagged2 = _tag_region_subpaths(region2, region1, eps=eps),
		tagged = concat(
			[for (tagpath = tagged1) if (in_list(tagpath[0], keep1)) tagpath[1]],
			[for (tagpath = tagged2) if (in_list(tagpath[0], keep2)) tagpath[1]]
		),
		outregion = assemble_path_fragments(tagged, eps=eps)
	) outregion;


// Function&Module: union()
// Usage:
//   union() {...}
//   region = union(regions);
//   region = union(REGION1,REGION2);
//   region = union(REGION1,REGION2,REGION3);
// Description:
//   When called as a function and given a list of regions, where each region is a list of closed
//   2D paths, returns the boolean union of all given regions.  Result is a single region.
//   When called as the built-in module, makes the boolean union of the given children.
// Arguments:
//   regions = List of regions to union.  Each region is a list of closed paths.
// Example(2D):
//   shape1 = move([-8,-8,0], p=circle(d=50));
//   shape2 = move([ 8, 8,0], p=circle(d=50));
//   for (shape = [shape1,shape2]) color("red") stroke(shape, width=0.5, closed=true);
//   color("green") region(union(shape1,shape2));
function union(regions=[],b=undef,c=undef,eps=EPSILON) =
	b!=undef? union(concat([regions],[b],c==undef?[]:[c]), eps=eps) :
	len(regions)<=1? regions[0] :
	union(
		let(regions=[for (r=regions) is_path(r)? [r] : r])
		concat(
			[_tagged_region(regions[0],regions[1],["O","S"],["O"], eps=eps)],
			[for (i=[2:1:len(regions)-1]) regions[i]]
		),
		eps=eps
	);


// Function&Module: difference()
// Usage:
//   difference() {...}
//   region = difference(regions);
//   region = difference(REGION1,REGION2);
//   region = difference(REGION1,REGION2,REGION3);
// Description:
//   When called as a function, and given a list of regions, where each region is a list of closed
//   2D paths, takes the first region and differences away all other regions from it.  The resulting
//   region is returned.
//   When called as the built-in module, makes the boolean difference of the given children.
// Arguments:
//   regions = List of regions to difference.  Each region is a list of closed paths.
// Example(2D):
//   shape1 = move([-8,-8,0], p=circle(d=50));
//   shape2 = move([ 8, 8,0], p=circle(d=50));
//   for (shape = [shape1,shape2]) color("red") stroke(shape, width=0.5, closed=true);
//   color("green") region(difference(shape1,shape2));
function difference(regions=[],b=undef,c=undef,eps=EPSILON) =
	b!=undef? difference(concat([regions],[b],c==undef?[]:[c]), eps=eps) :
	len(regions)<=1? regions[0] :
	difference(
		let(regions=[for (r=regions) is_path(r)? [r] : r])
		concat(
			[_tagged_region(regions[0],regions[1],["O","U"],["I"], eps=eps)],
			[for (i=[2:1:len(regions)-1]) regions[i]]
		),
		eps=eps
	);


// Function&Module: intersection()
// Usage:
//   intersection() {...}
//   region = intersection(regions);
//   region = intersection(REGION1,REGION2);
//   region = intersection(REGION1,REGION2,REGION3);
// Description:
//   When called as a function, and given a list of regions, where each region is a list of closed
//   2D paths, returns the boolean intersection of all given regions.  Result is a single region.
//   When called as the built-in module, makes the boolean intersection of all the given children.
// Arguments:
//   regions = List of regions to intersection.  Each region is a list of closed paths.
// Example(2D):
//   shape1 = move([-8,-8,0], p=circle(d=50));
//   shape2 = move([ 8, 8,0], p=circle(d=50));
//   for (shape = [shape1,shape2]) color("red") stroke(shape, width=0.5, closed=true);
//   color("green") region(intersection(shape1,shape2));
function intersection(regions=[],b=undef,c=undef,eps=EPSILON) =
	b!=undef? intersection(concat([regions],[b],c==undef?[]:[c]),eps=eps) :
	len(regions)<=1? regions[0] :
	intersection(
		let(regions=[for (r=regions) is_path(r)? [r] : r])
		concat(
			[_tagged_region(regions[0],regions[1],["I","S"],["I"],eps=eps)],
			[for (i=[2:1:len(regions)-1]) regions[i]]
		),
		eps=eps
	);


// Function&Module: exclusive_or()
// Usage:
//   exclusive_or() {...}
//   region = exclusive_or(regions);
//   region = exclusive_or(REGION1,REGION2);
//   region = exclusive_or(REGION1,REGION2,REGION3);
// Description:
//   When called as a function and given a list of regions, where each region is a list of closed
//   2D paths, returns the boolean exclusive_or of all given regions.  Result is a single region.
//   When called as a module, performs a boolean exclusive-or of up to 10 children.
// Arguments:
//   regions = List of regions to exclusive_or.  Each region is a list of closed paths.
// Example(2D): As Function
//   shape1 = move([-8,-8,0], p=circle(d=50));
//   shape2 = move([ 8, 8,0], p=circle(d=50));
//   for (shape = [shape1,shape2])
//       color("red") stroke(shape, width=0.5, closed=true);
//   color("green") region(exclusive_or(shape1,shape2));
// Example(2D): As Module
//   exclusive_or() {
//       square(40,center=false);
//       circle(d=40);
//   }
function exclusive_or(regions=[],b=undef,c=undef,eps=EPSILON) =
	b!=undef? exclusive_or(concat([regions],[b],c==undef?[]:[c]),eps=eps) :
	len(regions)<=1? regions[0] :
	exclusive_or(
		let(regions=[for (r=regions) is_path(r)? [r] : r])
		concat(
			[union([
				difference([regions[0],regions[1]], eps=eps),
				difference([regions[1],regions[0]], eps=eps)
			], eps=eps)],
			[for (i=[2:1:len(regions)-1]) regions[i]]
		),
		eps=eps
	);


module exclusive_or() {
	if ($children==1) {
		children();
	} else if ($children==2) {
		difference() {
			children(0);
			children(1);
		}
		difference() {
			children(1);
			children(0);
		}
	} else if ($children==3) {
		exclusive_or() {
			exclusive_or() {
				children(0);
				children(1);
			}
			children(2);
		}
	} else if ($children==4) {
		exclusive_or() {
			exclusive_or() {
				children(0);
				children(1);
			}
			exclusive_or() {
				children(2);
				children(3);
			}
		}
	} else if ($children==5) {
		exclusive_or() {
			exclusive_or() {
				children(0);
				children(1);
				children(2);
				children(3);
			}
			children(4);
		}
	} else if ($children==6) {
		exclusive_or() {
			exclusive_or() {
				children(0);
				children(1);
				children(2);
				children(3);
			}
			children(4);
			children(5);
		}
	} else if ($children==7) {
		exclusive_or() {
			exclusive_or() {
				children(0);
				children(1);
				children(2);
				children(3);
			}
			children(4);
			children(5);
			children(6);
		}
	} else if ($children==8) {
		exclusive_or() {
			exclusive_or() {
				children(0);
				children(1);
				children(2);
				children(3);
			}
			exclusive_or() {
				children(4);
				children(5);
				children(6);
				children(7);
			}
		}
	} else if ($children==9) {
		exclusive_or() {
			exclusive_or() {
				children(0);
				children(1);
				children(2);
				children(3);
			}
			exclusive_or() {
				children(4);
				children(5);
				children(6);
				children(7);
			}
			children(8);
		}
	} else if ($children==10) {
		exclusive_or() {
			exclusive_or() {
				children(0);
				children(1);
				children(2);
				children(3);
			}
			exclusive_or() {
				children(4);
				children(5);
				children(6);
				children(7);
			}
			children(8);
			children(9);
		}
	} else {
		assert($children<=10, "exclusive_or() can only handle up to 10 children.");
	}
}


// Module: region()
// Usage:
//   region(r);
// Description:
//   Creates 2D polygons for the given region.  The region given is a list of closed 2D paths.
//   Each path will be effectively exclusive-ORed from all other paths in the region, so if a
//   path is inside another path, it will be effectively subtracted from it.
// Example(2D):
//   region([circle(d=50), square(25,center=true)]);
// Example(2D):
//   rgn = concat(
//       [for (d=[50:-10:10]) circle(d=d-5)],
//       [square([60,10], center=true)]
//   );
//   region(rgn);
module region(r)
{
	points = flatten(r);
	paths = [
		for (i=[0:1:len(r)-1]) let(
			start = default(sum([for (j=[0:1:i-1]) len(r[j])]),0)
		) [for (k=[0:1:len(r[i])-1]) start+k]
	];
	polygon(points=points, paths=paths);
}


// Section: Creating Polyhedrons with VNF Structures
//   VNF stands for "Vertices'N'Faces".  VNF structures are 2-item lists, `[VERTICES,FACES]` where the
//   first item is a list of vertex points, and the second is a list of face indices into the vertex
//   list.  Each VNF is self contained, with face indices referring only to its own vertex list.
//   You can construct a `polyhedron()` in parts by describing each part in a self-contained VNF, then
//   merge the various VNFs to get the completed polyhedron vertex list and faces.


// Function: is_vnf()
// Description: Returns true if the given value looks passingly like a VNF structure.
function is_vnf(x) = is_list(x) && len(x)==2 && is_list(x[0]) && is_list(x[1]) && (x[0]==[] || is_vector(x[0][0])) && (x[1]==[] || is_vector(x[1][0]));


// Function: is_vnf_list()
// Description: Returns true if the given value looks passingly like a list of VNF structures.
function is_vnf_list(x) = is_list(x) && all([for (v=x) is_vnf(v)]);


// Function: vnf_vertices()
// Description: Given a VNF structure, returns the list of vertex points.
function vnf_vertices(vnf) = vnf[0];


// Function: vnf_faces()
// Description: Given a VNF structure, returns the list of faces, where each face is a list of indices into the VNF vertex list.
function vnf_faces(vnf) = vnf[1];


// Function: vnf_get_vertex()
// Usage:
//   vvnf = vnf_get_vertex(vnf, p);
// Description:
//   Finds the index number of the given vertex point `p` in the given VNF structure `vnf`.  If said
//   point does not already exist in the VNF vertex list, it is added.  Returns: `[INDEX, VNF]` where
//   INDEX if the index of the point, and VNF is the possibly modified new VNF structure.
//   If `p` is given as a list of points, then INDEX will be a list of indices.
// Arguments:
//   vnf = The VNF structue to get the point index from.
//   p = The point, or list of points to get the index of.
// Example:
//   vnf1 = vnf_get_vertex(p=[3,5,8]);  // Returns: [0, [[[3,5,8]],[]]]
//   vnf2 = vnf_get_vertex(vnf1, p=[3,2,1]);  // Returns: [1, [[[3,5,8],[3,2,1]],[]]]
//   vnf3 = vnf_get_vertex(vnf2, p=[3,5,8]);  // Returns: [0, [[[3,5,8],[3,2,1]],[]]]
//   vnf4 = vnf_get_vertex(vnf3, p=[[1,3,2],[3,2,1]]);  // Returns: [[1,2], [[[3,5,8],[3,2,1],[1,3,2]],[]]]
function vnf_get_vertex(vnf=[[],[]], p) =
	is_path(p)? _vnf_get_vertices(vnf, p) :
	let(
		p = quant(p,1/1024),  // OpenSCAD internally quantizes objects to 1/1024.
		v = search([p], vnf[0])[0]
	) [
		v != []? v : len(vnf[0]),
		[
			concat(vnf[0], v != []? [] : [p]),
			vnf[1]
		]
	];


// Internal use only
function _vnf_get_vertices(vnf=[[],[]], pts, _i=0, _idxs=[]) =
	_i>=len(pts)? [_idxs, vnf] :
	let(
		vvnf = vnf_get_vertex(vnf, pts[_i])
	) _vnf_get_vertices(vvnf[1], pts, _i=_i+1, _idxs=concat(_idxs,[vvnf[0]]));


// Function: vnf_add_face()
// Usage:
//   vnf_add_face(vnf, pts);
// Description:
//   Given a VNF structure and a list of face vertex points, adds the face to the VNF structure.
//   Returns the modified VNF structure `[VERTICES, FACES]`.  It is up to the caller to make
//   sure that the points are in the correct order to make the face normal point outwards.
// Arguments:
//   vnf = The VNF structure to add a face to.
//   pts = The vertex points for the face.
function vnf_add_face(vnf=[[],[]], pts) =
	let(
		vvnf = vnf_get_vertex(vnf, pts),
		face = deduplicate(vvnf[0], closed=true),
		vnf2 = vvnf[1]
	) [
		vnf_vertices(vnf2),
		concat(vnf_faces(vnf2), len(face)>2? [face] : [])
	];


// Function: vnf_add_faces()
// Usage:
//   vnf_add_faces(vnf, faces);
// Description:
//   Given a VNF structure and a list of faces, where each face is given as a list of vertex points,
//   adds the faces to the VNF structure.  Returns the modified VNF structure `[VERTICES, FACES]`.
//   It is up to the caller to make sure that the points are in the correct order to make the face
//   normals point outwards.
// Arguments:
//   vnf = The VNF structure to add a face to.
//   faces = The list of faces, where each face is given as a list of vertex points.
function vnf_add_faces(vnf=[[],[]], faces, _i=0) =
	_i<len(faces)? vnf_add_faces(vnf_add_face(vnf, faces[_i]), faces, _i=_i+1) : vnf;


// Function: vnf_merge()
// Usage:
//   vnf = vnf_merge([VNF, VNF, VNF, ...]);
// Description:
//   Given a list of VNF structures, merges them all into a single VNF structure.
function vnf_merge(vnfs=[],_i=0,_acc=[[],[]]) = _i>=len(vnfs)? _acc :
	vnf_merge(
		vnfs, _i=_i+1,
		_acc = let(base=len(_acc[0])) [
			concat(_acc[0], vnfs[_i][0]),
			concat(_acc[1], [for (f=vnfs[_i][1]) [for (i=f) i+base]]),
		]
	);


// Function: vnf_triangulate()
// Usage:
//   vnf2 = vnf_triangulate(vnf);
// Description:
//   Forces triangulation of faces in the VNF that have more than 3 vertices.
function vnf_triangulate(vnf) =
	let(
		vnf = is_vnf_list(vnf)? vnf_merge(vnf) : vnf
	) [vnf[0], triangulate_faces(vnf[0], vnf[1])];


// Function: vnf_vertex_array()
// Usage:
//   vnf = vnf_vertex_array(points, cols, [caps], [cap1], [cap2], [reverse], [col_wrap], [row_wrap], [vnf]);
// Description:
//   Creates a VNF structure from a vertex list, by dividing the vertices into columns and rows,
//   adding faces to tile the surface.  You can optionally have faces added to wrap the last column
//   back to the first column, or wrap the last row to the first.  Endcaps can be added to either
//   the first and/or last rows.
// Arguments:
//   points = A list of vertices to divide into columns and rows.
//   cols = The number of points in a column.
//   caps = If true, add endcap faces to the first AND last rows.
//   cap1 = If true, add an endcap face to the first row.
//   cap2 = If true, add an endcap face to the last row.
//   col_wrap = If true, add faces to connect the last column to the first.
//   row_wrap = If true, add faces to connect the last row to the first.
//   reverse = If true, reverse all face normals.
//   style = The style of subdividing the quads into faces.  Valid options are "default", "alt", and "quincunx".
//   vnf = If given, add all the vertices and faces to this existing VNF structure.
// Example(3D):
//   vnf = vnf_vertex_array(
//       points=[
//           for (h = [0:5:180-EPSILON]) [
//               for (t = [0:5:360-EPSILON])
//                   cylindrical_to_xyz(100 + 12 * cos((h/2 + t)*6), t, h)
//           ]
//       ],
//       col_wrap=true, caps=true, reverse=true, style="alt"
//   );
//   vnf_polyhedron(vnf);
// Example(3D): Both `col_wrap` and `row_wrap` are true to make a torus.
//   vnf = vnf_vertex_array(
//       points=[
//           for (a=[0:5:360-EPSILON])
//               affine3d_apply(
//                   circle(d=20),
//                   [xrot(90), right(30), zrot(a)]
//               )
//       ],
//       col_wrap=true, row_wrap=true, reverse=true
//   );
//   vnf_polyhedron(vnf);
// Example(3D): Möbius Strip.  Note that `row_wrap` is not used, and the first and last profile copies are the same.
//   vnf = vnf_vertex_array(
//       points=[
//           for (a=[0:5:360]) affine3d_apply(
//               square([1,10], center=true),
//               [zrot(a/2+60), xrot(90), right(30), zrot(a)]
//           )
//       ],
//       col_wrap=true, reverse=true
//   );
//   vnf_polyhedron(vnf);
// Example(3D): Assembling a Polyhedron from Multiple Parts
//   wall_points = [
//       for (a = [-90:2:90]) affine3d_apply(
//           circle(d=100),
//           [scale([1-0.1*cos(a*6), 1-0.1*cos((a+90)*6), 1]), up(a)]
//       )
//   ];
//   cap = [
//       for (a = [0:0.01:1+EPSILON]) affine3d_apply(
//           wall_points[0],
//           [scale([a,a,1]), up(90-5*sin(a*360*2))]
//       )
//   ];
//   cap1 = [for (p=cap) down(90, p=zscale(-1, p=p))];
//   cap2 = [for (p=cap) up(90, p=p)];
//   vnf1 = vnf_vertex_array(points=wall_points, col_wrap=true);
//   vnf2 = vnf_vertex_array(points=cap1, col_wrap=true);
//   vnf3 = vnf_vertex_array(points=cap2, col_wrap=true, reverse=true);
//   vnf_polyhedron([vnf1, vnf2, vnf3]);
function vnf_vertex_array(
	points,
	caps, cap1, cap2,
	col_wrap=false,
	row_wrap=false,
	reverse=false,
	style="default",
	vnf=[[],[]]
) =
	assert((!caps)||(caps&&col_wrap))
	assert(in_list(style,["default","alt","quincunx"]))
	let(
		pts = flatten(points),
		rows = len(points),
		cols = len(points[0]),
		errchk = [for (row=points) assert(len(row)==cols, "All rows much have the same number of columns.") 0],
		cap1 = first_defined([cap1,caps,false]),
		cap2 = first_defined([cap2,caps,false]),
		colcnt = cols - (col_wrap?0:1),
		rowcnt = rows - (row_wrap?0:1)
	)
	vnf_merge([
		vnf, [
			concat(
				pts,
				style!="quincunx"? [] : [
					for (r = [0:1:rowcnt-1]) (
						for (c = [0:1:colcnt-1]) (
							let(
								i1 = ((r+0)%rows)*cols + ((c+0)%cols),
								i2 = ((r+1)%rows)*cols + ((c+0)%cols),
								i3 = ((r+1)%rows)*cols + ((c+1)%cols),
								i4 = ((r+0)%rows)*cols + ((c+1)%cols)
							) mean([pts[i1], pts[i2], pts[i3], pts[i4]])
						)
					)
				]
			),
			concat(
				[
					for (r = [0:1:rowcnt-1]) (
						for (c = [0:1:colcnt-1]) each (
							let(
								i1 = ((r+0)%rows)*cols + ((c+0)%cols),
								i2 = ((r+1)%rows)*cols + ((c+0)%cols),
								i3 = ((r+1)%rows)*cols + ((c+1)%cols),
								i4 = ((r+0)%rows)*cols + ((c+1)%cols)
							)
							style=="quincunx"? (
								let(i5 = pcnt + r*colcnt + c)
								reverse? [[i1,i2,i5],[i2,i3,i5],[i3,i4,i5],[i4,i1,i5]] : [[i1,i5,i2],[i2,i5,i3],[i3,i5,i4],[i4,i5,i1]]
							) : style=="alt"? (
								reverse? [[i1,i2,i4],[i2,i3,i4]] : [[i1,i4,i2],[i2,i4,i3]]
							) : (
								reverse? [[i1,i2,i3],[i1,i3,i4]] : [[i1,i3,i2],[i1,i4,i3]]
							)
						)
					)
				],
				!cap1? [] : [
					reverse?
						[for (c = [0:1:cols-1]) c] :
						[for (c = [cols-1:-1:0]) c]
				],
				!cap2? [] : [
					reverse?
						[for (c = [cols-1:-1:0]) (rows-1)*cols + c] :
						[for (c = [0:1:cols-1]) (rows-1)*cols + c]
				]
			)
		]
	]);


// Module: vnf_polyhedron()
// Usage:
//   vnf_polyhedron(vnf);
//   vnf_polyhedron([VNF, VNF, VNF, ...]);
// Description:
//   Given a VNF structure, or a list of VNF structures, creates a polyhedron from them.
// Arguments:
//   vnf = A VNF structure, or list of VNF structures.
module vnf_polyhedron(vnf) {
	vnf = is_vnf_list(vnf)? vnf_merge(vnf) : vnf;
	polyhedron(vnf[0], vnf[1]);
}


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
