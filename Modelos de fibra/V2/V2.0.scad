
/*
    M I C R O S T R U C T U R E S
    
    None/No-core:
        No parameters.
        
    Capillary:
        core diameter: inner (hollow) diameter
    
    Hexagonal:
        core diameter: defines the pitch (ms_core = 2*pitch)
        additional parameter 1: defines hole diameter (ap1 = hole_diameter)
        additional parameter 2: number of hexagonal rings
        additional parameter 3: Is there a central hole (0=no, anything else is yes)
        
    Suspended:
        core diameter: defines the core's diameter
        additional parameter 1: width for suspension
        additional parameter 2: number of suspensions
        additional parameter 3: cladding thickness
        
    Hollow_core:
        core diameter: hollow cavity diameter
        additional parameter 1: inner capillary thickness
        additional parameter 2: spacing between inner capillaries
        additional parameter 3: number of inner capillaries
        
    MNANF (Multi-Nested Antiresonant Nodeless Fibre):
        core diameter: hollow cavity diameter
        additional parameter 1: inner capillary thickness
        additional parameter 2: spacing between inner capillaries
        additional parameter 3: number of inner capillaries
        additional parameter 4: number of nested capillaries
        
*/


use <Microstructures.scad>


/* [ Miscellanious ] */
//The resolution of the curves. Higher values give smoother curves but may increase the model render time.
resolution = 50; //[50, 100, 200, 500]
$fn = resolution;


/* [ Preform ] */
// Length for the preform portion.
preform_length = 100;
// Diameter for the preform portion
preform_diameter = 15;
// How much of the preform's middle should be hollow (0 to 1)
hollow_ratio = 0;

/* [ Microstructure ] */
// Microstructure rotation along Z axis in degrees
ms_rotation = 0;
// Microstructure type, read more about them in the start of the script.
ms_type = "Suspended"; // ["No-core", "Hexagonal", "Suspended", "Hollow_core", "MNANF"]
// Microstructure core diameter
ms_core = 2.4;
// Microstructure additional parameter 1
ms_ap1 = 0.6;
// Microstructure additional parameter 2
ms_ap2 = 3.2;
// Microstructure additional parameter 3
ms_ap3 = 3;
// Microstructure additional parameter 4
ms_ap4 = 3;


/* [ Head/Foot ] */
// Wether to include the head or not
include_head = true; // [true, false]
// Chooses wether the head/foot transition is gradual
hf_grad_transition = true; // [true, false]
// Wether the head/foot should have a solid diameter (for support)
solid_hf_diam = 0;
// Head heigth
head_height = 15;
// Bottom foot diameter
foot_diameter = 15;
// Foot height. Changes how gradual is the transition between foot diameter and preform diameter
foot_height = 15;
// Diameter for the head holes
hole_diameter = 4;
// First hole's height
H_hole1_height = 6.00;
// Second hole's height
H_hole2_height = 10.5;



total_height = head_height+preform_length+foot_height;
assert(hollow_ratio<1.0 && hollow_ratio >=0, "Hollow_ratio must be between 0 and 1.");


module microstructure(){
    rotate([0,0,ms_rotation])
    _microstructure(ms_type,preform_diameter,ms_core,ms_ap1,ms_ap2,ms_ap3,ms_ap4);
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
        if(include_head){
            head_holes();
        }
    }
}

module foot(){
    rescaling = foot_diameter / preform_diameter;
    
    ratio = hf_grad_transition ? preform_diameter/foot_diameter : 1;
    
    linear_extrude(foot_height, scale=ratio)
        union(){
            scale([rescaling,rescaling,1])
                microstructure();
            
            if(solid_hf_diam != 0)
                circle(d=solid_hf_diam);
        }
    //cylinder(h=foot_height, d1=foot_diameter, d2=preform_diameter);
}

module head(){
    total_len = foot_height+preform_length+head_height;
    translate([0,0,total_len])
        mirror([0,0,1]) foot();
}

module body(){
    translate([0,0,foot_height])
        linear_extrude(preform_length)
            microstructure();
}

module overall_shape(){
    union(){
        foot();
        body();
        if(include_head){
            head();
        }
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
        all_holes();
    }
}


preform();


/*
difference(){
    foot();
    foot_holes();
}
*/








