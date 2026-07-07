

/* [ Miscellanious ] */
// Resolution for circular patterns
resolution = 50; // [30, 50, 100]
$fn = resolution;


/* [ Microstructure ] */
// Core diameter
core_diameter = 3;
// Suspension diameter
susp_diameter = 0.4;
// Number of suspenders
N_susp = 3;


/* [ Outer Structure ] */
// Shell inner diameter
s_inner_diameter = 13;
// Shell outer diameter
s_outer_diameter = 15;
// Preform length
preform_length = 10;


susp_len = (s_inner_diameter - core_diameter)/2;


module core(){
    cylinder(preform_length, d=core_diameter);
}


module shell(){
    difference(){
        cylinder(preform_length, d=s_outer_diameter);
        cylinder(preform_length, d=s_inner_diameter);
    }
}


module suspender(){
    translate([core_diameter/2,0,0])
        rotate([0, 90-susp_angle, 0])
            translate([-susp_diameter/2,0,0])
                cylinder(suspender_length, d=susp_diameter);
}


module anti_suspender(){
    translate([s_inner_diameter/2,0,-suspender_height])
        rotate([0, susp_angle-90, 0])
            translate([susp_diameter/2,0,0])
                cylinder(suspender_length, d=susp_diameter);
}


module suspension(N=3){
    assert(N>0, "Number of suspenders must be at least 1");
    
    union(){
        for(i=[1:N], theta=360*i/N){
            rotate([0,0,theta])
                suspender();
        }
    }
}


module suspensions(){
    
    linear_extrude(preform_length) union(){
        for(i=[1:N_susp], t=360*i/N_susp){
            rotate([0,0,t]) translate([0,-susp_diameter/2,0])
                square([s_inner_diameter/2, susp_diameter]);
        }
    }
}



module structure(){
    union(){
        core();
        #shell();
    }
}




union(){
    structure();
    intersection(){
        difference(){
            cylinder(h=preform_length, d=s_inner_diameter);
            cylinder(h=preform_length, d=core_diameter);
        }
        suspensions();
    }
}

