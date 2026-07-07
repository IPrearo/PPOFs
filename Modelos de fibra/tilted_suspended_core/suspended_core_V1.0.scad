

/* [ Miscellanious ] */
// Resolution for circular patterns
resolution = 50; // [30, 50, 100, 200]
// Includes an "N" in the negative Y side of the sample
show_north = true; // [true, false]

$fn = resolution;


/* [ Microstructure ] */
// Core diameter
core_diameter = 3;
// Suspension diameter
susp_diameter = 1.3;
// Suspension height
susp_height= 0.1;
// Suspension angle [deg]
susp_angle = 0;
// Suspensionless length
susp_distance = 0.2;
// Number of suspenders
N_susp = 1;
// Spiral suspenders?
SPIRAL_SUSP = true; // [false, true]
// Number of suspenders to cause an exact rotation
SPIRAL_NSUSP = 8;
// Are the suspenders unidirectional?
UNIDIRECTIONAL_SUSP = true; // [false, true]


/* [ Outer Structure ] */
// Shell inner diameter
s_inner_diameter = 13;
// Shell outer diameter
s_outer_diameter = 15;
// Preform length
preform_length = 5.3;


susp_len = (s_inner_diameter - core_diameter)/2;
susp_correction = susp_diameter * tan(susp_angle);
suspender_length = susp_len/cos(susp_angle) + susp_correction;
suspender_height = suspender_length * sin(susp_angle);

echo("Suspender height:", suspender_height);


N_suspensions = ceil( (preform_length-suspender_height) / susp_distance );


module core(){
    cylinder(preform_length, d=core_diameter);
}


module shell(){
    difference(){
        cylinder(preform_length, d=s_outer_diameter);
        cylinder(preform_length, d=s_inner_diameter);
    }
}


module suspender_shape(){
    //cylinder(suspender_length, d=susp_diameter);
    translate([0,0,-1])
    linear_extrude(suspender_length+1)
        translate([-susp_height/2, -susp_diameter/2, 0])
            square([susp_height, susp_diameter]);
}


module suspender(){
    translate([core_diameter/2,0,0])
        rotate([0, 90-susp_angle, 0])
            translate([-susp_diameter/2,0,0])
                suspender_shape();
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


module repeating_suspensions(){
    
    intersection(){
        cylinder(h=preform_length, d=s_inner_diameter);
        union(){
            for(i=[0:N_suspensions-1], H=i*susp_distance){
                translate([0,0,H])
                    suspension(N=N_susp);
            }
        }
    }
}


module spiral_suspensions(){
    
    delta_angle = 360/SPIRAL_NSUSP;///N_suspensions;
    z_angle = 360/N_susp;
    
    for(i=[0:N_suspensions-1],
        theta=i*delta_angle,
        translation=i*susp_distance
    ){
        translate([0,0,translation]){
            for(i=[0:N_susp-1],
                ntheta=theta+z_angle*i)
            {
                rotate([0,0,ntheta])
                if((i+1)%2 || UNIDIRECTIONAL_SUSP)
                    suspender();
                else
                    anti_suspender();
            }
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
        if(SPIRAL_SUSP)
            spiral_suspensions();
        else
            repeating_suspensions();
    }
    
    if (show_north){
        translate([-1.5, -s_outer_diameter/2+0.5, 0])
            rotate([90,0,0]) linear_extrude(1.5)
                text("N", size=3);
    }
}

