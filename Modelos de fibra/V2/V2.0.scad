
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
        additional parameter 4: inner capillary excentricity
        
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
// Whether to render at every save
always_render = false; // [true, false]
// Make a transversal cut to check the preform?
cut_transversal = false; // [true,false]
// Make a longitudinal cut to check the preform?
cut_longitudinal = false; // [true,false]
// Longitudinal cut angle
longitudinal_cut_angle = 0;
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
ms_ap4 = 3.1;


/* [ Head/Foot ] */
// Wether to include the head or not
include_head = true; // [true, false]
// Wether to include the foot or not
include_foot = true; // [true, false]
// Chooses wether the head/foot transition is gradual
hf_grad_transition = true; // [true, false]
// Whether to use the pressurization lid version for head and foot
pressurizing = false; // [true, false]
// Number of holes for the air to escape
escape_air_holes = 0;
// Angle for the escaping air holes
air_holes_angle = 0;
// Diameter for the escaping air holes
air_holes_diameter = 2;
// Whether the head/foot should have a solid diameter (for support)
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
H_hole1_height = 3.5;
// Second hole's height
H_hole2_height = 8.0;
// Elefant's foot compensation for resin (SLA/MSLA) printing
elefant_foot = 0; // [0, 0.5]



total_height = head_height+preform_length+foot_height;
assert(hollow_ratio<1.0 && hollow_ratio >=0, "Hollow_ratio must be between 0 and 1.");


module microstructure(){
    rotate([0,0,ms_rotation])
    _microstructure(ms_type,preform_diameter,ms_core,ms_ap1,ms_ap2,ms_ap3,ms_ap4);
}

module pressure_lid(){
    rotate([0,0,ms_rotation])
    _pressure_lid(ms_type,preform_diameter,ms_core,ms_ap1,ms_ap2,ms_ap3,ms_ap4);
}


module copy_and_rotate(n){
    for(i=[0:n-1], t=360/n*i){
        rotate([0,0,t])
            children();
    }
}

module border(delta){
    difference(){
        children();
        offset(delta=-delta) children();
    }
}



module foot_holes(){
    hole_length = max(foot_diameter, preform_diameter);
    union(){
        // Hole closest to the end of the model
        translate([-0.5*hole_length, 0 , H_hole1_height])
            rotate([0, 90, 0])
                cylinder(h=hole_length , d=hole_diameter);
        
        // Hole closest to the preform portion
        translate([0, 0.5*hole_length, H_hole2_height])
            rotate([90, 0, 0])
                cylinder(h=hole_length , d=hole_diameter);
    }   
}

module head_holes(){
    translate([0,0,total_height])
        rotate([180,0,0])
            foot_holes();
}

module one_sided_escaping_air_holes(){
    delta=0.2;
    hole_len=0.5*(preform_diameter-ms_core)+delta;
    
    rotate([0,0,air_holes_angle])
    copy_and_rotate(escape_air_holes){
        translate([ms_core/2-delta,0,head_height+hole_diameter/2])
        rotate([0,90,0])
            cylinder(h=hole_len, d=air_holes_diameter);
    }
}

module escaping_air_holes(){
    one_sided_escaping_air_holes();
    translate([0,0,preform_length-hole_diameter])
    one_sided_escaping_air_holes();
}

module all_holes(){
    union(){
        foot_holes();
        if(include_head){
            head_holes();
            if(escape_air_holes>0){
                escaping_air_holes();
            }
        }
        else{
            if(escape_air_holes>0){
                one_sided_escaping_air_holes();
            }
        }
        
    }
}

module foot(){
    rescaling = foot_diameter / preform_diameter;
    
    ratio = hf_grad_transition ? preform_diameter/foot_diameter : 1;
    
    
    difference(){
        linear_extrude(foot_height, scale=ratio)
            union(){
                if(!pressurizing){
                    scale([rescaling,rescaling,1])
                        microstructure();
                        
                    if(solid_hf_diam != 0){
                        circle(d=solid_hf_diam);
                    }
                }
                else {
                    intersection(){
                        circle(d=foot_diameter);
                        pressure_lid();    
                    }
                }
            }
        
        if(pressurizing){
            // Height for equalization volume ir based on
            //  the minimal distance between the start of a
            //  pin hole and the end of the preform.
            //  It is, in fact, half of that.
            equalization_h = (min(H_hole1_height, H_hole2_height) - hole_diameter/2) / 2;
            cylinder(h=equalization_h, d=ms_core);
        }
    
    }
}

module head(){
    total_len = foot_height+preform_length+head_height;
    translate([0,0,total_len])
        union(){
            mirror([0,0,1])
                foot();
                    
            if(pressurizing){
                translate([0,0,-head_height])
                cylinder(h=head_height, d=preform_diameter);
            }
        }
}

module body(){
    translate([0,0,foot_height])
        linear_extrude(preform_length)
            microstructure();
}

module overall_shape(){
    union(){
        if(include_foot){
            if(elefant_foot>0){
                difference(){
                    foot();
                    
                    linear_extrude(h=elefant_foot)
                        border(elefant_foot)
                        projection() foot();
                }
            } else{
                foot();
            }
            
        }
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

module show_preform(){

    color("aquamarine")
    if(!cut_transversal && !cut_longitudinal){
        preform();
    }
    else{
        difference(){
            preform();
            
            if(cut_longitudinal){
                rotate([0,0,longitudinal_cut_angle])
                translate([-preform_diameter,0,-preform_length/2])
                    cube([preform_diameter*2,preform_diameter*2,preform_length*2+head_height*2]);
            }
            
            
            if(cut_transversal){
                translate([-preform_diameter,-preform_diameter,preform_length/2+head_height])
                    cube([preform_diameter*2,preform_diameter*2,preform_length+2*head_height]);
            }
        }
    }
}



if(always_render){
    render() show_preform();
} else{
    show_preform();
}







