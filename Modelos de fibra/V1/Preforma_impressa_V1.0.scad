
use </bigdrive/openSCAD_utils/intermediary_points.scad>


/* [ Miscellanious ] */
//The resolution of the curves. Higher values give smoother curves but may increase the model render time.
resolution = 50; //[30, 50, 100, 200]
$fn = resolution;


/* [ Preform ] */
// Length for the preform portion.
preform_length = 100;
// Diameter for the preform portion
preform_diameter = 15;


/* [ Head ] */
// Diameter for the head section
head_diameter = 30;
// Diameter for the head holes
hole_diameter = 3.3;
// Head heigth
head_height = 15;
// First hole's height
H_hole1_height = 7.25;
// Second hole's height
H_hole2_height = 12;
// Connection height. Changes how long the connecion is between the heads and the preform.
conn_height = 10;
// Is there a top head?
top_head = true; // [true, false]
// If there is no top head, do you want to extend the preform to fill it's place?
preform_top_extension = true; // [true, false]


/* [ Microstructure ] */
// Does this preform have a microstrucure?
has_MS = false; // [false, true]
// Number of holes per microstructure ring
N_holes_per_ring = 3;
// Number of microstructure rings
N_rings = 1;
// Pitch for the microstructure
MS_pitch = 0.9;
// Diameter of microstructure holes
MS_hole_diameter = 0.5;




top_extending = preform_top_extension && !top_head;
h_preform_l = 0.5*preform_length;
full_preform_l = preform_length+2*head_height;


module head_holes(){
    union(){
        // Hole closest to the end of the model
        translate([-0.5*head_diameter, 0 , H_hole1_height])
            rotate([0, 90, 0])
                cylinder(h=head_diameter , d=hole_diameter);
        
        // Hole closest to the preform portion
        translate([0, 0.5*head_diameter, H_hole2_height])
            rotate([90, 0, 0])
                cylinder(h=head_diameter , d=hole_diameter);
    }
    
}


module head()
{
    radius = 0.5*head_diameter;
    
    // Translates the head to the bottom of the preform
    translate([0,0, -conn_height -h_preform_l])
    {
        // Head
        translate([0, 0, -head_height])
        {
            difference()
            {
                // Main cylinder
                cylinder(h=head_height, r=radius);
                
                head_holes();
            }
        }
        
        // Connection
        if (conn_height > 0){
            cylinder(h=conn_height, r1=radius, r2=0.5*preform_diameter);
        }
        
    }
}


module both_heads(){
    head();
    rotate([180, 0, 0])
        head();
}


module preform(){
    translate([0,0, -h_preform_l])
        cylinder(h=preform_length, r=preform_diameter/2);
}


function MS_ring_points(r, int_points) = [
    for(i=[0:N_holes_per_ring-1],
        t0=360*i/N_holes_per_ring,
        t1=360*(i+1)/N_holes_per_ring,
        x1=r*cos(t0), y1=r*sin(t0),
        x2=r*cos(t1), y2=r*sin(t1) )
        each iinclusive_interm([ [x1,y1], [x2,y1] ], int_points)
];
    
    
function reg_MS(r) = [
    for(i=[0:N_holes_per_ring-1],
        t0=360*i/N_holes_per_ring,
        x=r*cos(t0), y=r*sin(t0) )
        [x, y]
];


module microstructure_holes(){
    translate([0,0,-full_preform_l/2])
    union(){
        for(i=[1,N_rings], r=MS_pitch*i){
            hole_centers = i==1? reg_MS(r) : MS_ring_points(r, i-1);
            for(center=hole_centers){
                translate(center)
                    cylinder(h=full_preform_l, d=MS_hole_diameter);
            }
        }
    }
}
 

module outside_obj(){
    difference(){
        union(){
            if (top_head)
                both_heads();
            else
                head();
            preform();    
            
            if (top_extending){
                translate([0,0,h_preform_l+(conn_height+head_height)/2])
                    scale([1,1,(conn_height+head_height)/preform_length])
                        preform();
            }
        }
        
        if (top_extending)
            rotate([180,0,0])
                translate([0,0,-(h_preform_l+conn_height+head_height-H_hole1_height)])
                    rotate([90,0,0]) translate([0,0,-preform_diameter/2])
                        cylinder(h=preform_diameter, d=hole_diameter);
    }
}


module printing_obj(){
    if(has_MS){
        difference(){
            outside_obj();
            microstructure_holes();
        }
    } else
        outside_obj();
}

printing_obj();





