/*
    M I C R O S T R U C T U R E S
    
    Hexagonal:
        core diameter: defines the pitch (ms_core = 2*pitch-d)
        additional parameter 1: defines hole diameter (ap1 = hole_diameter)
        additional parameter 2: number of hexagonal rings
*/

use <Microstructures.scad>


/* [ Miscellanious ] */
//The resolution of the curves. Higher values give smoother curves but may increase the model render time.
resolution = 50; //[50, 100, 200, 500]
$fn = resolution;


/* [ Preform ] */
// Length for the preform portion.
preform_length = 5;
// Diameter for the preform portion
preform_diameter = 15;
// How much of the preform's middle should be hollow (0 to 1)
hollow_ratio = 0;

/* [ Microstructure ] */
// Microstructure type, read more about them in the start of the script.
ms_type = "Hexagonal"; // ["No-core", "Hexagonal", "Suspended"]
// Microstructure core diameter
ms_core = 7.142857143;
// Microstructure additional parameter 1
ms_ap1 = 1.5;
// Microstructure additional parameter 2
ms_ap2 = 1;
// Microstructure additional parameter 3
ms_ap3 = 2;


/* [ Head/Foot ] */
// Head heigth
head_height = 0;
// Bottom foot diameter
foot_diameter = 25;
// Foot height. Changes how gradual is the transition between foot diameter and preform diameter
foot_height = 5;
// Diameter for the head holes
hole_diameter = 4;
// First hole's height
H_hole1_height = 7.25;
// Second hole's height
H_hole2_height = 12;



total_height = head_height+preform_length+foot_height;
assert(hollow_ratio<1.0 && hollow_ratio >=0, "Hollow_ratio must be between 0 and 1.");


module microstructure(){
    //_microstructure(ms_type,preform_diameter,ms_core,ms_ap1,ms_ap2,ms_ap3);
    
    difference(){
        circle(d=preform_diameter);
        
        for(i=[0:5],
            d=ms_ap1+i*0.5,
            t=60*i, r=(ms_core+ms_ap1)/2,
            x=r*cos(t), y=r*sin(t)){
                translate([x,y,0])
                    circle(d=d);
        }
    }
}

module foot_holes(){
    union(){
        // Hole closest to the end of the model
        translate([-0.5*foot_diameter, 0 , H_hole1_height])
            rotate([0, 90, 0])
                cylinder(h=foot_diameter , d=hole_diameter);
        
        // Hole closest to the preform portion
        translate([0, 0.5*foot_diameter, H_hole2_height])
            rotate([90, 0, 0])
                cylinder(h=foot_diameter , d=hole_diameter);
    }   
}

module head_holes(){
    translate([0,0,total_height])
        rotate([180,0,0])
            foot_holes();
}

module all_holes(){
    union(){
        foot_holes();
        // head_holes();
    }
}

module foot(){
    ratio = preform_diameter/foot_diameter;
    linear_extrude(foot_height, scale=ratio)
        scale([1/ratio,1/ratio,1])
            microstructure();
    //cylinder(h=foot_height, d1=foot_diameter, d2=preform_diameter);
}

module body(){
    total_len = preform_length+head_height;
    translate([0,0,foot_height])
        linear_extrude(total_len)
            microstructure();
}

module overall_shape(){
    union(){
        foot();
        body();
    }
}

module preform(){
    difference(){
        if(hollow_ratio>0){ difference(){
            overall_shape();
            // Corrects float imprecision
            translate([0,0,-0.5])
                scale([hollow_ratio,hollow_ratio,1.1])
                overall_shape();
        }
        } else{
            overall_shape();
        }
        //all_holes();
    }
}


preform();


/*
difference(){
    foot();
    foot_holes();
}
*/








