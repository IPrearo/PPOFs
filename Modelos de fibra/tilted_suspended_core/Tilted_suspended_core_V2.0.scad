

/* [ Miscellanious ] */
//The resolution of the curves. Higher values give smoother curves but may increase the model render time.
resolution = 50; //[50, 100, 200, 500]
$fn = resolution;


/* [ Preform ] */
// Length for the preform portion.
preform_length = 50;
// Diameter for the preform portion
preform_diameter = 15;
// How much of the preform's middle should be hollow (0 to 1)
hollow_ratio = 0;

/* [ Microstructure ] */
// Microstructure type, read more about them in the start of the script.
// Microstructure core diameter
ms_core = 2.4;
// Microstructure cladding thickness
ms_clad_thick = 3;
// Microstructure strut width
ms_strut_width = 0.55;
// Microstructure strut angle
ms_strut_angle = 5;
// Microstructure number of struts
ms_strut_number = 3;
// Microstruct distance between strut groups
ms_strut_dist = 1.1;
// Microstruct struts are spiral? This rearranges the struts to be evenly spaced in z within each group
ms_strut_spiral = true; // [true, false]



/* [ Head/Foot ] */
// Wether to include the head or not
include_head = true; // [true, false]
// Chooses wether the head/foot transition is gradual
hf_grad_transition = true; // [true, false]
// Wether the head/foot should have a solid diameter (for support)
solid_hf_diam = 6;
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
    union(){
        circle(d=ms_core);
        difference(){
            circle(d=preform_diameter);
            circle(d=preform_diameter-2*ms_clad_thick);
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


module single_strut(){
    corrected_size = (0.5*preform_diameter-ms_clad_thick) / cos(ms_strut_angle);
    translate([-ms_strut_width/2, 0, 0])
    cube([ms_strut_width, corrected_size, ms_strut_width]);
}

module strut_group(){
    for(i=[0:ms_strut_number],
        theta=i*360/ms_strut_number,
        z=ms_strut_spiral ? i*ms_strut_dist/ms_strut_number : 0)
        translate([0,0, z])
        rotate([ms_strut_angle,0,0])
        rotate([0,0,theta])
            single_strut();
}

module preform_struts(){
    N_groups = floor(preform_length/ms_strut_dist);
    echo("N_groups in preform", N_groups);
    
    intersection(){
        cylinder(h=preform_length, d=preform_diameter);
        
        for(i=[0:N_groups-1],
            z=i*preform_length/N_groups)
            translate([0,0,z])
                strut_group();
    }
}

module overall_shape(){
    union(){
        foot();
        body();
        if(include_head){
            head();
        }
        
        translate([0,0,foot_height])
            preform_struts();
    }
}

module reflatten_base(){
    h_angled = 0.5*preform_diameter*sin(ms_strut_angle);
    union(){
        difference(){
            children();
            translate([0,0,-h_angled])
            cylinder(h=h_angled, d=preform_diameter+1);
        }
        
        linear_extrude(h_angled){
            microstructure();
            
            if(solid_hf_diam != 0)
                circle(d=solid_hf_diam);
        }
    }
}

module preform(){
    rotate([-ms_strut_angle,0,0])
    difference(){
        if(hollow_ratio>0){ 
        difference(){
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


color("darkseagreen")
rotate([ms_strut_angle,0,0])
reflatten_base()
    preform();

/*
//  CORTE TRANSVERSAL
difference(){
    rotate([ms_strut_angle,0,0])
    reflatten_base()
        preform();
        
    translate([0,-150,0])
    cube([300,300,300]);
}
*/













